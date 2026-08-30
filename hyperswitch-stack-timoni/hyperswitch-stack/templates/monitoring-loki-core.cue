package templates

import (
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	netv1 "k8s.io/api/networking/v1"
	"encoding/yaml"
)

monitoringLokiCore: {
	#config: #Config
	let loki_conf = #config."hyperswitch-monitoring".loki

	_labels: {
		"helm.sh/chart":              "loki-5.36.2"
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": #config.metadata.name
		"app.kubernetes.io/version": [if loki_conf.image.tag != "" {loki_conf.image.tag}, #config.moduleVersion][0]
		"app.kubernetes.io/managed-by": "timoni"
	}

	_selectorLabels: {
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": #config.metadata.name
	}

	_backendSelectorLabels: _selectorLabels & {
		"app.kubernetes.io/component": "backend"
	}

	// Helper for loki.calculatedConfig
	_calculatedConfig: [if loki_conf.loki.config != "" {loki_conf.loki.config}, yaml.Marshal(loki_conf.loki.structuredConfig)][0]

	// 1. serviceaccount.yaml
	if loki_conf.serviceAccount.create {
		"service-account": corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name: [if loki_conf.serviceAccount.name != "" {loki_conf.serviceAccount.name}, "loki"][0]
				namespace: #config.metadata.namespace
				labels:    _labels & loki_conf.serviceAccount.labels
				if len(loki_conf.serviceAccount.annotations) > 0 {
					annotations: loki_conf.serviceAccount.annotations
				}
			}
			automountServiceAccountToken: loki_conf.serviceAccount.automountServiceAccountToken
			if len(loki_conf.serviceAccount.imagePullSecrets) > 0 {
				imagePullSecrets: loki_conf.serviceAccount.imagePullSecrets
			}
		}
	}

	// 2. role.yaml
	if loki_conf.rbac.pspEnabled || loki_conf.rbac.sccEnabled {
		"role": rbacv1.#Role & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "Role"
			metadata: {
				name:      "loki"
				namespace: #config.metadata.namespace
				labels:    _labels
			}
			rules: [
				if loki_conf.rbac.pspEnabled {
					{
						apiGroups: ["policy"]
						resources: ["podsecuritypolicies"]
						verbs: ["use"]
						resourceNames: ["loki"]
					}
				},
				if loki_conf.rbac.sccEnabled {
					{
						apiGroups: ["security.openshift.io"]
						resources: ["securitycontextconstraints"]
						verbs: ["use"]
						resourceNames: ["loki"]
					}
				},
				if loki_conf.rbac.sccEnabled && loki_conf.rbac.namespaced && loki_conf.sidecar.rules.enabled {
					{
						apiGroups: [""]
						resources: ["configmaps", "secrets"]
						verbs: ["get", "watch", "list"]
					}
				},
			]
		}
	}

	// 3. rolebinding.yaml
	if loki_conf.rbac.pspEnabled || loki_conf.rbac.sccEnabled {
		"role-binding": rbacv1.#RoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "RoleBinding"
			metadata: {
				name:      "loki"
				namespace: #config.metadata.namespace
				labels:    _labels
			}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "Role"
				name:     "loki"
			}
			subjects: [
				{
					kind: "ServiceAccount"
					name: [if loki_conf.serviceAccount.name != "" {loki_conf.serviceAccount.name}, "loki"][0]
					namespace: #config.metadata.namespace
				},
			]
		}
	}

	// 4. secret-license.yaml
	if !loki_conf.enterprise.useExternalLicense && loki_conf.enterprise.enabled {
		"secret-license": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "enterprise-logs-license"
				namespace: #config.metadata.namespace
				labels:    _labels
			}
			stringData: "license.jwt": loki_conf.enterprise.license.contents
		}
	}

	// 5. config.yaml
	if loki_conf.loki.generatedConfigObjectName != "" {
		"config": {
			if loki_conf.loki.configStorageType == "Secret" {
				corev1.#Secret & {
					apiVersion: "v1"
					kind:       "Secret"
					metadata: {
						name:      loki_conf.loki.generatedConfigObjectName
						namespace: #config.metadata.namespace
						labels:    _labels
					}
					stringData: "config.yaml": _calculatedConfig
				}
			}
			if loki_conf.loki.configStorageType == "ConfigMap" {
				corev1.#ConfigMap & {
					apiVersion: "v1"
					kind:       "ConfigMap"
					metadata: {
						name:      loki_conf.loki.generatedConfigObjectName
						namespace: #config.metadata.namespace
						labels:    _labels
					}
					data: "config.yaml": _calculatedConfig
				}
			}
		}
	}

	// 6. ciliumnetworkpolicy.yaml
	if loki_conf.networkPolicy.enabled && loki_conf.networkPolicy.flavor == "cilium" {
		"cilium-namespace-only": {
			apiVersion: "cilium.io/v2"
			kind:       "CiliumNetworkPolicy"
			metadata: {
				name:      "loki-namespace-only"
				namespace: #config.metadata.namespace
				labels:    _labels
			}
			spec: {
				endpointSelector: {}
				ingress: [{fromEndpoints: [{matchLabels: "io.kubernetes.pod.namespace": #config.metadata.namespace}]}]
				egress: [{toEndpoints: [{matchLabels: "io.kubernetes.pod.namespace": #config.metadata.namespace}]}]
			}
		}
	}

	// 7. extra-manifests.yaml
	if len(loki_conf.extraObjects) > 0 {
		for i, obj in loki_conf.extraObjects {
			"extra-manifest-\(i)": obj
		}
	}

	// 8. ingress.yaml
	if loki_conf.ingress.enabled {
		"ingress": netv1.#Ingress & {
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				name:      "loki"
				namespace: #config.metadata.namespace
				labels:    _labels & loki_conf.ingress.labels
				if len(loki_conf.ingress.annotations) > 0 {
					annotations: loki_conf.ingress.annotations
				}
			}
			spec: {
				if loki_conf.ingress.ingressClassName != "" {
					ingressClassName: loki_conf.ingress.ingressClassName
				}
				if len(loki_conf.ingress.tls) > 0 {
					tls: [for t in loki_conf.ingress.tls {hosts: t.hosts, if t.secretName != _|_ {secretName: t.secretName}}]
				}
				rules: [for h in loki_conf.ingress.hosts {host: h, http: paths: [{path: "/", pathType: "Prefix", backend: service: {name: "loki-gateway", port: name: "http"}}]}]
			}
		}
	}

	// 9. networkpolicy.yaml
	if loki_conf.networkPolicy.enabled && loki_conf.networkPolicy.flavor == "kubernetes" {
		"network-policy-namespace-only": netv1.#NetworkPolicy & {
			apiVersion: "networking.k8s.io/v1"
			kind:       "NetworkPolicy"
			metadata: {name: "loki-namespace-only", namespace: #config.metadata.namespace, labels: _labels}
			spec: {
				policyTypes: ["Ingress", "Egress"]
				podSelector: {}
				ingress: [{from: [{podSelector: {}}]}]
				egress: [{to: [{podSelector: {}}]}]
			}
		}
		"network-policy-egress-dns": netv1.#NetworkPolicy & {
			apiVersion: "networking.k8s.io/v1"
			kind:       "NetworkPolicy"
			metadata: {name: "loki-egress-dns", namespace: #config.metadata.namespace, labels: _labels}
			spec: {
				policyTypes: ["Egress"]
				podSelector: matchLabels: _selectorLabels
				egress: [{ports: [{port: "dns", protocol: "UDP"}], to: [{namespaceSelector: {}}]}]
			}
		}
		"network-policy-ingress": netv1.#NetworkPolicy & {
			apiVersion: "networking.k8s.io/v1"
			kind:       "NetworkPolicy"
			metadata: {name: "loki-ingress", namespace: #config.metadata.namespace, labels: _labels}
			spec: {
				policyTypes: ["Ingress"]
				podSelector: {
					matchExpressions: [{key: "app.kubernetes.io/component", operator: "In", values: [if loki_conf.gateway.enabled {"gateway"}, "read", "write"]}]
					matchLabels: _selectorLabels
				}
				ingress: [{
					ports: [{port: "http", protocol: "TCP"}]
					if loki_conf.networkPolicy.ingress.namespaceSelector != _|_ {
						from: [{
							namespaceSelector: loki_conf.networkPolicy.ingress.namespaceSelector
							if loki_conf.networkPolicy.ingress.podSelector != _|_ {
								podSelector: loki_conf.networkPolicy.ingress.podSelector
							}
						}]
					}
				}]
			}
		}
	}

	// 10. podsecuritypolicy.yaml
	if loki_conf.rbac.pspEnabled {
		"pod-security-policy": {
			apiVersion: "policy/v1beta1"
			kind:       "PodSecurityPolicy"
			metadata: {
				name:   "loki"
				labels: _labels
				if len(loki_conf.rbac.pspAnnotations) > 0 {
					annotations: loki_conf.rbac.pspAnnotations
				}
			}
			spec: {
				privileged:               false
				allowPrivilegeEscalation: false
				volumes: ["configMap", "emptyDir", "persistentVolumeClaim", "secret", "projected"]
				hostNetwork: false
				hostIPC:     false
				hostPID:     false
				runAsUser: rule:          "MustRunAsNonRoot"
				seLinux: rule:            "RunAsAny"
				supplementalGroups: rule: "MustRunAs", ranges: [{min: 1, max: 65535}]
				fsGroup: rule: "MustRunAs", ranges: [{min: 1, max: 65535}]
				readOnlyRootFilesystem: true
				requiredDropCapabilities: ["ALL"]
			}
		}
	}

	// 11. runtime-configmap.yaml
	if len(loki_conf.loki.runtimeConfig) > 0 {
		"runtime-config": corev1.#ConfigMap & {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {name: "loki-runtime", namespace: #config.metadata.namespace, labels: _labels}
			data: "runtime-config.yaml": yaml.Marshal(loki_conf.loki.runtimeConfig)
		}
	}

	// 12. securitycontextconstraints.yaml
	if loki_conf.rbac.sccEnabled {
		"security-context-constraints": {
			apiVersion: "security.openshift.io/v1"
			kind:       "SecurityContextConstraints"
			metadata: {name: "loki", labels: _labels}
			allowHostDirVolumePlugin: false
			allowHostIPC:             false
			allowHostNetwork:         false
			allowHostPID:             false
			allowHostPorts:           false
			allowPrivilegeEscalation: true
			allowPrivilegedContainer: false
			allowedCapabilities: []
			fsGroup: type: "RunAsAny"
			readOnlyRootFilesystem: false
			requiredDropCapabilities: ["ALL"]
			runAsUser: type:      "RunAsAny"
			seLinuxContext: type: "MustRunAs"
			seccompProfiles: ["*"]
			supplementalGroups: type: "RunAsAny"
			volumes: ["configMap", "downwardAPI", "emptyDir", "hostPath", "persistentVolumeClaim", "projected", "secret"]
		}
	}

	// 13. service-memberlist.yaml
	"service-memberlist": corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "loki-memberlist"
			namespace: #config.metadata.namespace
			labels:    _labels
			if len(loki_conf.loki.serviceAnnotations) > 0 {annotations: loki_conf.loki.serviceAnnotations}
		}
		spec: {
			type:      "ClusterIP"
			clusterIP: "None"
			ports: [{name: "tcp", port: 7946, targetPort: "http-memberlist", protocol: "TCP"}]
			if loki_conf.memberlist.service.publishNotReadyAddresses {publishNotReadyAddresses: true}
			selector: _selectorLabels & {"app.kubernetes.io/part-of": "memberlist"}
		}
	}

	// 14. validate.yaml
}
