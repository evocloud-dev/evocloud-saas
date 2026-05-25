package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
)

monitoringLokiRolloutOperator: {
	#config: #Config
	let rollout = #config."hyperswitch-monitoring"."rollout-operator"

	_labels: {
		"app.kubernetes.io/name":       "rollout-operator"
		"app.kubernetes.io/instance":   #config.metadata.name
		"app.kubernetes.io/managed-by": "timoni"
	}

	_selectorLabels: {
		"app.kubernetes.io/name":     "rollout-operator"
		"app.kubernetes.io/instance": #config.metadata.name
	}

	// 1. serviceaccount.yaml
	if rollout.serviceAccount.create {
		"service-account": corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name: [if rollout.serviceAccount.name != "" {rollout.serviceAccount.name}, #config.metadata.name + "-rollout-operator"][0]
				namespace: #config.metadata.namespace
				labels:    _labels
				if len(rollout.serviceAccount.annotations) > 0 {
					annotations: rollout.serviceAccount.annotations
				}
			}
		}
	}

	// 2. role.yaml
	"role": rbacv1.#Role & {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "Role"
		metadata: {
			name:      #config.metadata.name + "-rollout-operator"
			namespace: #config.metadata.namespace
		}
		rules: [
			{
				apiGroups: [""]
				resources: ["pods"]
				verbs: ["list", "get", "watch", "delete"]
			},
			{
				apiGroups: ["apps"]
				resources: ["statefulsets"]
				verbs: ["list", "get", "watch"]
			},
			{
				apiGroups: ["apps"]
				resources: ["statefulsets/status"]
				verbs: ["update"]
			},
		]
	}

	// 3. rolebinding.yaml
	"role-binding": rbacv1.#RoleBinding & {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "RoleBinding"
		metadata: {
			name:      #config.metadata.name + "-rollout-operator"
			namespace: #config.metadata.namespace
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "Role"
			name:     #config.metadata.name + "-rollout-operator"
		}
		subjects: [
			{
				kind: "ServiceAccount"
				name: [if rollout.serviceAccount.name != "" {rollout.serviceAccount.name}, #config.metadata.name + "-rollout-operator"][0]
				namespace: #config.metadata.namespace
			},
		]
	}

	// 4. service.yaml
	if rollout.serviceMonitor.enabled {
		"service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      #config.metadata.name + "-rollout-operator"
				namespace: #config.metadata.namespace
				labels:    _labels
			}
			spec: {
				type:      "ClusterIP"
				clusterIP: "None"
				ports: [
					{
						port:       8001
						targetPort: "http-metrics"
						protocol:   "TCP"
						name:       "http-metrics"
					},
				]
				selector: _selectorLabels
			}
		}
	}

	// 5. deployment.yaml
	"deployment": appsv1.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      #config.metadata.name + "-rollout-operator"
			namespace: #config.metadata.namespace
			labels:    _labels
		}
		spec: {
			replicas:        1
			minReadySeconds: rollout.minReadySeconds
			selector: matchLabels: _selectorLabels
			strategy: rollingUpdate: {
				maxSurge:       0
				maxUnavailable: 1
			}
			template: {
				metadata: {
					if len(rollout.podAnnotations) > 0 {
						annotations: rollout.podAnnotations
					}
					labels: _selectorLabels & rollout.podLabels
				}
				spec: {
					if rollout.priorityClassName != "" {
						priorityClassName: rollout.priorityClassName
					}
					if len(rollout.imagePullSecrets) > 0 {
						imagePullSecrets: rollout.imagePullSecrets
					}
					if len(rollout.hostAliases) > 0 {
						hostAliases: rollout.hostAliases
					}
					serviceAccountName: [if rollout.serviceAccount.name != "" {rollout.serviceAccount.name}, #config.metadata.name + "-rollout-operator"][0]
					securityContext: rollout.podSecurityContext
					containers: [
						{
							name:            "rollout-operator"
							securityContext: rollout.securityContext
							image:           "\(rollout.image.repository):\(rollout.image.tag)"
							imagePullPolicy: rollout.image.pullPolicy
							args: [
								"-kubernetes.namespace=\(#config.metadata.namespace)",
							]
							ports: [
								{
									name:          "http-metrics"
									containerPort: 8001
									protocol:      "TCP"
								},
							]
							readinessProbe: {
								httpGet: {
									path: "/ready"
									port: "http-metrics"
								}
								initialDelaySeconds: 5
								timeoutSeconds:      1
							}
							resources: rollout.resources
						},
					]
					if len(rollout.nodeSelector) > 0 {
						nodeSelector: rollout.nodeSelector
					}
					if len(rollout.affinity) > 0 {
						affinity: rollout.affinity
					}
					if len(rollout.tolerations) > 0 {
						tolerations: rollout.tolerations
					}
				}
			}
		}
	}

	// 6. servicemonitor.yaml
	if rollout.serviceMonitor.enabled {
		"service-monitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {
				name: #config.metadata.name + "-rollout-operator"
				if rollout.serviceMonitor.namespace != null {
					namespace: rollout.serviceMonitor.namespace
				}
				if rollout.serviceMonitor.namespace == null {
					namespace: #config.metadata.namespace
				}
				labels: _labels & rollout.serviceMonitor.labels
				if len(rollout.serviceMonitor.annotations) > 0 {
					annotations: rollout.serviceMonitor.annotations
				}
			}
			spec: {
				if len(rollout.serviceMonitor.namespaceSelector) > 0 {
					namespaceSelector: rollout.serviceMonitor.namespaceSelector
				}
				selector: matchLabels: _selectorLabels
				endpoints: [
					{
						port: "http-metrics"
						if rollout.serviceMonitor.interval != null {
							interval: rollout.serviceMonitor.interval
						}
						if rollout.serviceMonitor.scrapeTimeout != null {
							scrapeTimeout: rollout.serviceMonitor.scrapeTimeout
						}
						if len(rollout.serviceMonitor.relabelings) > 0 {
							relabelings: rollout.serviceMonitor.relabelings
						}
						scheme: "http"
					},
				]
			}
		}
	}
}
