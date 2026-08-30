package templates

import (
	"strings"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	batchv1 "k8s.io/api/batch/v1"
)

monitoringPrometheusOperatorWebhookPatch: {
	#config: #Config
	let mon = #config."hyperswitch-monitoring"
	let kps = mon."kube-prometheus-stack"
	let op = kps.prometheusOperator
	let fullname = (#KubePrometheusStackFullname & {#config: #config}).result
	let chartName = (#KubePrometheusStackName & {#config: #config}).result
	let opFullname = (#KubePrometheusStackOperatorFullname & {#config: #config}).result
	let opNamespace = [if kps.namespaceOverride != "" {kps.namespaceOverride}, #config.metadata.namespace][0]
	let _labels = (#KubePrometheusStackLabels & {#config: #config}).result
	let webhookLabels = _labels & {
		"app.kubernetes.io/name":      chartName + "-prometheus-operator"
		"app.kubernetes.io/component": "prometheus-operator-webhook"
	}

	if op.enabled && op.admissionWebhooks.enabled && op.admissionWebhooks.patch.enabled && !op.admissionWebhooks.certManager.enabled {

		// 1. ciliumnetworkpolicy-createSecret.yaml
		if op.networkPolicy.enabled && op.networkPolicy.flavor == "cilium" {
			"#1-ciliumnetworkpolicy-createSecret": {
				apiVersion: "cilium.io/v2"
				kind:       "CiliumNetworkPolicy"
				metadata: {
					name:      fullname + "-admission-create"
					namespace: opNamespace
					labels: webhookLabels & {app: chartName + "-admission-create"}
				}
				spec: {
					endpointSelector: matchLabels: {
						app: chartName + "-admission-create"
						if len(op.networkPolicy.matchLabels) > 0 {
							op.networkPolicy.matchLabels
						}
					}
					egress: [
						if op.networkPolicy.cilium.egress != _|_ {
							for e in op.networkPolicy.cilium.egress {e}
						},
						if op.networkPolicy.cilium.egress == _|_ {
							{toEntities: ["kube-apiserver"]}
						},
					]
				}
			}
		}

		// 2. networkpolicy-createSecret.yaml
		if op.networkPolicy.enabled && op.networkPolicy.flavor == "kubernetes" {
			"#2-networkpolicy-createSecret": {
				apiVersion: "networking.k8s.io/v1"
				kind:       "NetworkPolicy"
				metadata: {
					name:      fullname + "-admission-create"
					namespace: opNamespace
					labels: webhookLabels & {app: chartName + "-admission-create"}
				}
				spec: {
					podSelector: matchLabels: {
						app: chartName + "-admission-create"
						if len(op.networkPolicy.matchLabels) > 0 {
							op.networkPolicy.matchLabels
						}
					}
					egress: [{}]
					policyTypes: ["Egress"]
				}
			}
		}

		// 3. ciliumnetworkpolicy-patchWebhook.yaml
		if op.networkPolicy.enabled && op.networkPolicy.flavor == "cilium" {
			"#3-ciliumnetworkpolicy-patchWebhook": {
				apiVersion: "cilium.io/v2"
				kind:       "CiliumNetworkPolicy"
				metadata: {
					name:      fullname + "-admission-patch"
					namespace: opNamespace
					labels: webhookLabels & {app: chartName + "-admission-patch"}
				}
				spec: {
					endpointSelector: matchLabels: {
						app: chartName + "-admission-patch"
						if len(op.networkPolicy.matchLabels) > 0 {
							op.networkPolicy.matchLabels
						}
					}
					egress: [
						if op.networkPolicy.cilium.egress != _|_ {
							for e in op.networkPolicy.cilium.egress {e}
						},
						if op.networkPolicy.cilium.egress == _|_ {
							{toEntities: ["kube-apiserver"]}
						},
					]
				}
			}
		}

		// 4. networkpolicy-patchWebhook.yaml
		if op.networkPolicy.enabled && op.networkPolicy.flavor == "kubernetes" {
			"#4-networkpolicy-patchWebhook": {
				apiVersion: "networking.k8s.io/v1"
				kind:       "NetworkPolicy"
				metadata: {
					name:      fullname + "-admission-patch"
					namespace: opNamespace
					labels: webhookLabels & {app: chartName + "-admission-patch"}
				}
				spec: {
					podSelector: matchLabels: {
						app: chartName + "-admission-patch"
						if len(op.networkPolicy.matchLabels) > 0 {
							op.networkPolicy.matchLabels
						}
					}
					egress: [{}]
					policyTypes: ["Egress"]
				}
			}
		}

		// 5. clusterrolebinding.yaml
		if mon.global.rbac.create {
			"#5-clusterrolebinding": rbacv1.#ClusterRoleBinding & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRoleBinding"
				metadata: {
					name: fullname + "-admission"
					labels: webhookLabels & {app: chartName + "-admission"}
				}
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "ClusterRole"
					name:     fullname + "-admission"
				}
				subjects: [{
					kind:      "ServiceAccount"
					name:      fullname + "-admission"
					namespace: opNamespace
				}]
			}
		}

		// 6. psp.yaml
		if mon.global.rbac.create && mon.global.rbac.pspEnabled {
			"#6-psp": {
				apiVersion: "policy/v1beta1"
				kind:       "PodSecurityPolicy"
				metadata: {
					name: fullname + "-admission"
					labels: webhookLabels & {app: chartName + "-admission"}
					if len(mon.global.rbac.pspAnnotations) > 0 {
						annotations: mon.global.rbac.pspAnnotations
					}
				}
				spec: {
					privileged: false
					volumes: ["configMap", "emptyDir", "projected", "secret", "downwardAPI", "persistentVolumeClaim"]
					hostNetwork: false
					hostIPC:     false
					hostPID:     false
					runAsUser: rule:          "RunAsAny"
					seLinux: rule:            "RunAsAny"
					supplementalGroups: rule: "MustRunAs"
					supplementalGroups: ranges: [{min: 0, max: 65535}]
					fsGroup: rule: "MustRunAs"
					fsGroup: ranges: [{min: 0, max: 65535}]
					readOnlyRootFilesystem: false
				}
			}
		}

		// 7. clusterrole.yaml
		if mon.global.rbac.create {
			"#7-clusterrole": rbacv1.#ClusterRole & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRole"
				metadata: {
					name: fullname + "-admission"
					labels: webhookLabels & {app: chartName + "-admission"}
				}
				rules: [
					{
						apiGroups: ["admissionregistration.k8s.io"]
						resources: ["validatingwebhookconfigurations", "mutatingwebhookconfigurations"]
						verbs: ["get", "update"]
					},
					if mon.global.rbac.pspEnabled {
						{
							apiGroups: ["policy"]
							resources: ["podsecuritypolicies"]
							resourceNames: [fullname + "-admission"]
							verbs: ["use"]
						}
					},
				]
			}
		}

		// 8. rolebinding.yaml
		if mon.global.rbac.create {
			"#8-rolebinding": rbacv1.#RoleBinding & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "RoleBinding"
				metadata: {
					name:      fullname + "-admission"
					namespace: opNamespace
					labels: webhookLabels & {app: chartName + "-admission"}
				}
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "Role"
					name:     fullname + "-admission"
				}
				subjects: [{
					kind:      "ServiceAccount"
					name:      fullname + "-admission"
					namespace: opNamespace
				}]
			}
		}

		// 9. job-createSecret.yaml
		"#9-job-createSecret": batchv1.#Job & {
			apiVersion: "batch/v1"
			kind:       "Job"
			metadata: {
				name:      fullname + "-admission-create"
				namespace: opNamespace
				labels: webhookLabels & {app: chartName + "-admission-create"}
				if len(op.admissionWebhooks.annotations) > 0 {
					annotations: op.admissionWebhooks.annotations
				}
			}
			spec: {
				ttlSecondsAfterFinished: op.admissionWebhooks.patch.ttlSecondsAfterFinished
				template: {
					metadata: {
						name: fullname + "-admission-create"
						labels: webhookLabels & {app: chartName + "-admission-create"}
						if len(op.admissionWebhooks.patch.podAnnotations) > 0 {
							annotations: op.admissionWebhooks.patch.podAnnotations
						}
					}
					spec: {
						if op.admissionWebhooks.patch.priorityClassName != "" {
							priorityClassName: op.admissionWebhooks.patch.priorityClassName
						}
						containers: [{
							name: "create"
							let registry = [if mon.global.imageRegistry != "" {mon.global.imageRegistry}, op.admissionWebhooks.patch.image.registry][0]
							let imageRepo = op.admissionWebhooks.patch.image.repository
							let imageTag = op.admissionWebhooks.patch.image.tag
							let imageSha = op.admissionWebhooks.patch.image.sha
							image: [
								if imageSha != "" {
									registry + "/" + imageRepo + ":" + imageTag + "@sha256:" + imageSha
								},
								registry + "/" + imageRepo + ":" + imageTag,
							][0]
							imagePullPolicy: op.admissionWebhooks.patch.image.pullPolicy
							let dnsNames = [
								opFullname,
								opFullname + "." + opNamespace + ".svc",
								if op.admissionWebhooks.deployment.enabled {
									opFullname + "-webhook"
								},
								if op.admissionWebhooks.deployment.enabled {
									opFullname + "-webhook." + opNamespace + ".svc"
								},
							]
							args: [
								"create",
								"--host=" + strings.Join([for d in dnsNames if d != _|_ {d}], ","),
								"--namespace=" + opNamespace,
								"--secret-name=" + fullname + "-admission",
							]
							if op.admissionWebhooks.patch.resources != _|_ {
								resources: op.admissionWebhooks.patch.resources
							}
							if op.admissionWebhooks.patch.securityContext != _|_ {
								securityContext: op.admissionWebhooks.patch.securityContext
							}
						}]
						restartPolicy:      "OnFailure"
						serviceAccountName: fullname + "-admission"
						nodeSelector:       op.admissionWebhooks.patch.nodeSelector
						affinity:           op.admissionWebhooks.patch.affinity
						tolerations:        op.admissionWebhooks.patch.tolerations
						if op.admissionWebhooks.patch.securityContext != _|_ {
							securityContext: op.admissionWebhooks.patch.securityContext
						}
					}
				}
			}
		}

		// 10. role.yaml
		if mon.global.rbac.create {
			"#10-role": rbacv1.#Role & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "Role"
				metadata: {
					name:      fullname + "-admission"
					namespace: opNamespace
					labels: webhookLabels & {app: chartName + "-admission"}
				}
				rules: [{
					apiGroups: [""]
					resources: ["secrets"]
					verbs: ["get", "create"]
				}]
			}
		}

		// 11. job-patchWebhook.yaml
		"#11-job-patchWebhook": batchv1.#Job & {
			apiVersion: "batch/v1"
			kind:       "Job"
			metadata: {
				name:      fullname + "-admission-patch"
				namespace: opNamespace
				labels: webhookLabels & {app: chartName + "-admission-patch"}
				if len(op.admissionWebhooks.patch.annotations) > 0 {
					annotations: op.admissionWebhooks.patch.annotations
				}
			}
			spec: {
				ttlSecondsAfterFinished: op.admissionWebhooks.patch.ttlSecondsAfterFinished
				template: {
					metadata: {
						name: fullname + "-admission-patch"
						labels: webhookLabels & {app: chartName + "-admission-patch"}
						if len(op.admissionWebhooks.patch.podAnnotations) > 0 {
							annotations: op.admissionWebhooks.patch.podAnnotations
						}
					}
					spec: {
						if op.admissionWebhooks.patch.priorityClassName != "" {
							priorityClassName: op.admissionWebhooks.patch.priorityClassName
						}
						containers: [{
							name: "patch"
							let registry = [if mon.global.imageRegistry != "" {mon.global.imageRegistry}, op.admissionWebhooks.patch.image.registry][0]
							let imageRepo = op.admissionWebhooks.patch.image.repository
							let imageTag = op.admissionWebhooks.patch.image.tag
							let imageSha = op.admissionWebhooks.patch.image.sha
							image: [
								if imageSha != "" {
									registry + "/" + imageRepo + ":" + imageTag + "@sha256:" + imageSha
								},
								registry + "/" + imageRepo + ":" + imageTag,
							][0]
							imagePullPolicy: op.admissionWebhooks.patch.image.pullPolicy
							args: [
								"patch",
								"--webhook-name=" + fullname + "-admission",
								"--namespace=" + opNamespace,
								"--secret-name=" + fullname + "-admission",
								"--patch-failure-policy=" + op.admissionWebhooks.failurePolicy,
							]
							if op.admissionWebhooks.patch.resources != _|_ {
								resources: op.admissionWebhooks.patch.resources
							}
							if op.admissionWebhooks.patch.securityContext != _|_ {
								securityContext: op.admissionWebhooks.patch.securityContext
							}
						}]
						restartPolicy:      "OnFailure"
						serviceAccountName: fullname + "-admission"
						nodeSelector:       op.admissionWebhooks.patch.nodeSelector
						affinity:           op.admissionWebhooks.patch.affinity
						tolerations:        op.admissionWebhooks.patch.tolerations
						if op.admissionWebhooks.patch.securityContext != _|_ {
							securityContext: op.admissionWebhooks.patch.securityContext
						}
					}
				}
			}
		}

		// 12. serviceaccount.yaml
		if op.admissionWebhooks.patch.serviceAccount.create {
			"#12-serviceaccount": corev1.#ServiceAccount & {
				apiVersion: "v1"
				kind:       "ServiceAccount"
				metadata: {
					name:      fullname + "-admission"
					namespace: opNamespace
					labels: webhookLabels & {app: chartName + "-admission"}
					if len(op.admissionWebhooks.patch.serviceAccount.annotations) > 0 {
						annotations: op.admissionWebhooks.patch.serviceAccount.annotations
					}
				}
				automountServiceAccountToken: op.admissionWebhooks.patch.serviceAccount.automountServiceAccountToken
				if len(mon.global.imagePullSecrets) > 0 {
					imagePullSecrets: mon.global.imagePullSecrets
				}
			}
		}
	}
}
