package templates

import (
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	batchv1 "k8s.io/api/batch/v1"
)

monitoringLokiProvisioner: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	let enterprise = #config."hyperswitch-monitoring".loki.enterprise
	let provisioner = #config."hyperswitch-monitoring".loki.enterprise.provisioner
	let kubectl = #config."hyperswitch-monitoring".loki.kubectlImage
	let ns = #config.metadata.namespace
	let _name = #config.metadata.name

	let commonLabels = {
		"helm.sh/chart":              "loki-5.36.2"
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": _name
		"app.kubernetes.io/version": [if loki.image.tag != null {loki.image.tag}, #config.moduleVersion][0]
		"app.kubernetes.io/component":  "provisioner"
		"app.kubernetes.io/managed-by": "timoni"
	}

	let fullname = "\(_name)-loki-provisioner"

	if enterprise.enabled && provisioner.enabled {
		// File 1: serviceaccount-provisioner.yaml
		"serviceaccount": corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name:      fullname
				namespace: ns
				labels:    commonLabels & provisioner.labels
				annotations: {
					"helm.sh/hook": "post-install"
					for k, v in provisioner.annotations {"\(k)": v}
				}
			}
		}

		// File 2: role-provisioner.yaml
		if !loki.rbac.namespaced {
			"clusterrole": rbacv1.#ClusterRole & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRole"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels & provisioner.labels
					annotations: {
						"helm.sh/hook": "post-install"
						for k, v in provisioner.annotations {"\(k)": v}
					}
				}
				rules: [
					{
						apiGroups: [""]
						resources: ["secrets"]
						verbs: ["create"]
					},
				]
			}
		}

		// File 3: rolebinding-provisioner.yaml
		if !loki.rbac.namespaced {
			"clusterrolebinding": rbacv1.#ClusterRoleBinding & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRoleBinding"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels & provisioner.labels
					annotations: {
						"helm.sh/hook": "post-install"
						for k, v in provisioner.annotations {"\(k)": v}
					}
				}
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "ClusterRole"
					name:     fullname
				}
				subjects: [
					{
						kind:      "ServiceAccount"
						name:      fullname
						namespace: ns
					},
				]
			}
		}

		// File 4: job-provisioner.yaml
		"job": batchv1.#Job & {
			apiVersion: "batch/v1"
			kind:       "Job"
			metadata: {
				name:      fullname
				namespace: ns
				labels:    commonLabels & provisioner.labels
				annotations: {
					"helm.sh/hook":               "post-install"
					"helm.sh/hook-delete-policy": "before-hook-creation"
					for k, v in provisioner.annotations {"\(k)": v}
				}
			}
			spec: template: {
				metadata: {
					labels: commonLabels & provisioner.labels
					if len(provisioner.annotations) > 0 {
						annotations: provisioner.annotations
					}
				}
				spec: {
					if provisioner.priorityClassName != null {
						priorityClassName: provisioner.priorityClassName
					}
					securityContext: provisioner.securityContext
					if len(loki.imagePullSecrets) > 0 {
						imagePullSecrets: loki.imagePullSecrets
					}
					initContainers: [
						{
							name:            "provisioner"
							image:           "\(provisioner.image.repository):\([if provisioner.image.tag != "" {provisioner.image.tag}, "latest"][0])"
							imagePullPolicy: provisioner.image.pullPolicy
							command: [
								"/bin/sh",
								"-exuc",
								"""
								\( [for t in provisioner.additionalTenants {
									"/usr/bin/enterprise-logs-provisioner \\\n  -bootstrap-path=/bootstrap \\\n  -cluster-name=\(_name) \\\n  -gel-url=http://\(_name)-loki-gateway.\(ns).svc.\(#config.global.clusterDomain) \\\n  -instance=\(t.name) \\\n  -access-policy=write-\(t.name):\(t.name):logs:write \\\n  -access-policy=read-\(t.name):\(t.name):logs:read \\\n  -token=write-\(t.name) \\\n  -token=read-\(t.name)\n"
								}] )
								\( [if loki.monitoring.selfMonitoring.enabled {
									let tenant = loki.monitoring.selfMonitoring.tenant
									"/usr/bin/enterprise-logs-provisioner \\\n  -bootstrap-path=/bootstrap \\\n  -cluster-name=\(_name) \\\n  -gel-url=http://\(_name)-loki-gateway.\(ns).svc.\(#config.global.clusterDomain) \\\n  -instance=\(tenant.name) \\\n  -access-policy=self-monitoring:\(tenant.name):logs:write,logs:read \\\n  -token=self-monitoring\n"
								}, ""][0] )
								""",
							]
							volumeMounts: [
								for vm in provisioner.extraVolumeMounts {vm},
								{name: "bootstrap", mountPath: "/bootstrap"},
								{name: "admin-token", mountPath: "/bootstrap/token", subPath: "token"},
							]
							if len(provisioner.env) > 0 {
								env: provisioner.env
							}
						},
					]
					containers: [
						{
							name:            "create-secret"
							image:           "\(kubectl.repository):\(kubectl.tag)"
							imagePullPolicy: kubectl.pullPolicy
							command: [
								"/bin/bash",
								"-exuc",
								"""
								# In case, the admin resources have already been created, the provisioner job
								# does not write the token files to the bootstrap mount.
								# Therefore, secrets are only created if the respective token files exist.
								# Note: the following bash commands should always return a success status code. 
								# Therefore, in case the token file does not exist, the first clause of the 
								# or-operation is successful.
								\( [for t in provisioner.additionalTenants {
									"! test -s /bootstrap/token-write-\(t.name) || \\\n  kubectl --namespace \"\(t.secretNamespace)\" create secret generic \"\(_name)-loki-provisioned-\(t.name)\" \\\n    --from-literal=token-write=\"$(cat /bootstrap/token-write-\(t.name))\" \\\n    --from-literal=token-read=\"$(cat /bootstrap/token-read-\(t.name))\"\n"
								}] )
								\( [if loki.monitoring.selfMonitoring.enabled {
									let tenant = loki.monitoring.selfMonitoring.tenant
									let secretNamespace = [if tenant.secretNamespace != null {tenant.secretNamespace}, ns][0]
									"! test -s /bootstrap/token-self-monitoring || \\\n  kubectl --namespace \"\(ns)\" create secret generic \"\(_name)-loki-self-monitoring-tenant\" \\\n    --from-literal=username=\"\(tenant.name)\" \\\n    --from-literal=password=\"$(cat /bootstrap/token-self-monitoring)\"\n\( [if secretNamespace != ns {
										"! test -s /bootstrap/token-self-monitoring || \\\n  kubectl --namespace \"\(secretNamespace)\" create secret generic \"\(_name)-loki-self-monitoring-tenant\" \\\n    --from-literal=username=\"\(tenant.name)\" \\\n    --from-literal=password=\"$(cat /bootstrap/token-self-monitoring)\"\n"
									}, ""][0] )"
								}, ""][0] )
								""",
							]
							volumeMounts: [
								for vm in provisioner.extraVolumeMounts {vm},
								{name: "bootstrap", mountPath: "/bootstrap"},
							]
						},
					]
					if len(provisioner.affinity) > 0 {
						affinity: provisioner.affinity
					}
					if len(provisioner.nodeSelector) > 0 {
						nodeSelector: provisioner.nodeSelector
					}
					if len(provisioner.tolerations) > 0 {
						tolerations: provisioner.tolerations
					}
					restartPolicy:      "OnFailure"
					serviceAccountName: fullname
					volumes: [
						{
							name: "admin-token"
							secret: secretName: "\(_name)-loki-admin-token"
						},
						{name: "bootstrap", emptyDir: {}},
					]
				}
			}
		}
	}
}
