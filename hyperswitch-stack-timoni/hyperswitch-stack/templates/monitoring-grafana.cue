package templates

import (
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	appsv1 "k8s.io/api/apps/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#HyperswitchGrafanaName: {
	#config: #Config
	result:  string | *"grafana"
}

#HyperswitchGrafanaFullname: {
	#config: #Config
	let _stackName = #config.metadata.name
	result: "\(_stackName)-grafana"
}

#HyperswitchGrafanaLabels: {
	#config: #Config
	let _name = (#HyperswitchGrafanaName & {#config: #config}).result
	result: {
		"app.kubernetes.io/name":       _name
		"app.kubernetes.io/instance":   #config.metadata.name
		"app.kubernetes.io/version":    "11.2.1"
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "grafana-8.5.2"
	}
}

#HyperswitchGrafanaSelectorLabels: {
	#config: #Config
	let _name = (#HyperswitchGrafanaName & {#config: #config}).result
	result: {
		"app.kubernetes.io/name":     _name
		"app.kubernetes.io/instance": #config.metadata.name
	}
}

// monitoringGrafana registry for Instance._objects
monitoringGrafana: {
	#config: #Config
	let grafana = #config."hyperswitch-monitoring"."kube-prometheus-stack".grafana
	let _fullname = (#HyperswitchGrafanaFullname & {#config: #config}).result
	let _labels = (#HyperswitchGrafanaLabels & {#config: #config}).result
	let _selectorLabels = (#HyperswitchGrafanaSelectorLabels & {#config: #config}).result
	let _namespace = #config.metadata.namespace

	let _grafanaClusterRoleRules = [
		if grafana.sidecar.dashboards.enabled || grafana.sidecar.datasources.enabled {
			apiGroups: [""]
			resources: ["configmaps", "secrets"]
			verbs: ["get", "watch", "list"]
		},
		for r in (grafana.rbac.extraClusterRoleRules | []) {
			r
		},
	]

	// 1. clusterrolebinding.yaml
	if grafana.rbac.create && len(_grafanaClusterRoleRules) > 0 {
		"grafana-sub-clusterrolebinding": rbacv1.#ClusterRoleBinding & {
			kind:       "ClusterRoleBinding"
			apiVersion: "rbac.authorization.k8s.io/v1"
			metadata: {
				name:   "\(_fullname)-clusterrolebinding"
				labels: _labels
				if grafana.annotations != _|_ {
					annotations: grafana.annotations
				}
			}
			subjects: [{
				kind:      "ServiceAccount"
				name:      "\(_fullname)"
				namespace: _namespace
			}]
			roleRef: {
				kind:     "ClusterRole"
				name:     "\(_fullname)-clusterrole"
				apiGroup: "rbac.authorization.k8s.io"
			}
		}
	}

	// 2. clusterrole.yaml
	if grafana.rbac.create && len(_grafanaClusterRoleRules) > 0 {
		"grafana-sub-clusterrole": rbacv1.#ClusterRole & {
			kind:       "ClusterRole"
			apiVersion: "rbac.authorization.k8s.io/v1"
			metadata: {
				labels: _labels
				if grafana.annotations != _|_ {
					annotations: grafana.annotations
				}
				name: "\(_fullname)-clusterrole"
			}
			rules: _grafanaClusterRoleRules
		}
	}

	// 3. configmap-dashboard-provider.yaml
	if grafana.sidecar.dashboards.enabled && grafana.sidecar.dashboards.SCProvider {
		"grafana-sub-configmap-dashboard-provider": corev1.#ConfigMap & {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				labels: _labels
				if grafana.annotations != _|_ {
					annotations: grafana.annotations
				}
				name:      "\(_fullname)-config-dashboards"
				namespace: _namespace
			}
			data: {
				"dashboardproviders.yaml": """
					apiVersion: 1
					providers:
					- name: 'default'
					  orgId: 1
					  folder: ''
					  type: file
					  disableDeletion: false
					  editable: true
					  options:
					    path: /var/lib/grafana/dashboards/default
					"""
			}
		}
	}

	// 4. configmap.yaml
	if grafana.createConfigmap {
		"grafana-sub-configmap": corev1.#ConfigMap & {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
				if grafana.annotations != _|_ {
					annotations: grafana.annotations
				}
			}
			data: {
				"grafana.ini": """
					[paths]
					data = /var/lib/grafana/
					logs = /var/log/grafana
					plugins = /var/lib/grafana/plugins
					provisioning = /etc/grafana/provisioning
					[server]
					domain = localhost
					"""
			}
		}
	}

	// 5. configSecret.yaml
	if grafana.createConfigmap && (grafana.alerting != _|_ || grafana.datasources != _|_ || grafana.notifiers != _|_) {
		"grafana-sub-config-secret": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(_fullname)-config-secret"
				namespace: _namespace
				labels:    _labels
				if grafana.annotations != _|_ {
					annotations: grafana.annotations
				}
			}
			data: {
				if grafana.alerting != _|_ {
					for key, value in grafana.alerting {
						if (value & {secretFile: string}) != _|_ {
							"\(key)": '\(value.secretFile)'
						}
					}
				}
			}
			stringData: {
				if grafana.datasources != _|_ {
					for key, value in grafana.datasources {
						if value.secret != _|_ {
							"\(key)": value.secret
						}
					}
				}
				if grafana.notifiers != _|_ {
					for key, value in grafana.notifiers {
						if value.secret != _|_ {
							"\(key)": value.secret
						}
					}
				}
				if grafana.alerting != _|_ {
					for key, value in grafana.alerting {
						if (value & {secret: string}) != _|_ {
							"\(key)": value.secret
						}
					}
				}
			}
		}
	}

	// 6. dashboards-json-configmap.yaml
	if grafana.dashboards != _|_ {
		for provider, dashboards in grafana.dashboards {
			"grafana-sub-dashboards-\(provider)": corev1.#ConfigMap & {
				apiVersion: "v1"
				kind:       "ConfigMap"
				metadata: {
					name:      "\(_fullname)-dashboards-\(provider)"
					namespace: _namespace
					labels: _labels & {"dashboard-provider": provider}
				}
				data: {
					for key, value in dashboards {
						if value.json != _|_ {
							"\(key).json": value.json
						}
					}
				}
			}
		}
	}

	// 7. deployment.yaml
	if !grafana.useStatefulSet && (!grafana.persistence.enabled || grafana.persistence.type == "pvc") {
		"grafana-sub-deployment": appsv1.#Deployment & {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
				if grafana.annotations != _|_ {
					annotations: grafana.annotations
				}
			}
			spec: {
				if !grafana.autoscaling.enabled {
					replicas: grafana.replicas
				}
				revisionHistoryLimit: grafana.revisionHistoryLimit
				selector: matchLabels: _selectorLabels
				strategy: grafana.deploymentStrategy
				template: {
					metadata: {
						labels: _selectorLabels
						if grafana.podLabels != _|_ {
							for k, v in grafana.podLabels {"\(k)": v}
						}
						if grafana.podAnnotations != _|_ {
							annotations: grafana.podAnnotations
						}
					}
					spec: corev1.#PodSpec & {
						serviceAccountName: _fullname
						containers: [{
							name:  "grafana"
							image: "\(grafana.image.registry)/\(grafana.image.repository):\(grafana.image.tag)"
							ports: [{
								name:          "service"
								containerPort: 3000
								protocol:      "TCP"
							}]
							livenessProbe:  grafana.livenessProbe
							readinessProbe: grafana.readinessProbe
							resources:      grafana.resources
							volumeMounts: [
								{
									name:      "config"
									mountPath: "/etc/grafana/grafana.ini"
									subPath:   "grafana.ini"
								},
								{
									name:      "storage"
									mountPath: "/var/lib/grafana"
								},
							]
						}]
						volumes: [
							{
								name: "config"
								configMap: {name: _fullname}
							},
							{
								name: "storage"
								if grafana.persistence.enabled {
									persistentVolumeClaim: claimName: _fullname
								}
								if !grafana.persistence.enabled {
									emptyDir: {}
								}
							},
						]
					}
				}
			}
		}
	}

	// 8. extra-manifests.yaml
	if grafana.extraObjects != _|_ {
		for i, obj in grafana.extraObjects {
			"grafana-sub-extra-\(i)": obj
		}
	}

	// 9. headless-service.yaml
	if grafana.headlessService || (grafana.persistence.enabled && (grafana.persistence.type == "statefulset" || grafana.persistence.type == "sts")) {
		"grafana-sub-headless-service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(_fullname)-headless"
				namespace: _namespace
				labels:    _labels
			}
			spec: {
				clusterIP: "None"
				selector:  _selectorLabels
				ports: [{
					name: "gossip-tcp"
					port: 9094
				}]
			}
		}
	}

	// 10. hpa.yaml
	if grafana.autoscaling.enabled {
		"grafana-sub-hpa": {
			apiVersion: "autoscaling/v2"
			kind:       "HorizontalPodAutoscaler"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
			}
			spec: {
				scaleTargetRef: {
					apiVersion: "apps/v1"
					kind: [if grafana.useStatefulSet {"StatefulSet"}, "Deployment"][0]
					name: _fullname
				}
				minReplicas: grafana.autoscaling.minReplicas
				maxReplicas: grafana.autoscaling.maxReplicas
				metrics: [
					if grafana.autoscaling.targetCPU != "" {
						{
							type: "Resource"
							resource: {
								name: "cpu"
								target: {
									type:               "Utilization"
									averageUtilization: grafana.autoscaling.targetCPU
								}
							}
						}
					},
				]
			}
		}
	}

	// 11. image-renderer-deployment.yaml
	if grafana.imageRenderer.enabled {
		"grafana-sub-image-renderer-deployment": appsv1.#Deployment & {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      "\(_fullname)-image-renderer"
				namespace: _namespace
				labels: _labels & {"app.kubernetes.io/name": "\(_fullname)-image-renderer"}
			}
			spec: {
				replicas: 1
				selector: matchLabels: {
					"app.kubernetes.io/name": "\(_fullname)-image-renderer"
				}
				template: {
					metadata: {
						labels: _labels & {"app.kubernetes.io/name": "\(_fullname)-image-renderer"}
						if grafana.imageRenderer.podAnnotations != _|_ {
							annotations: grafana.imageRenderer.podAnnotations
						}
					}
					spec: corev1.#PodSpec & {
						containers: [{
							name: "image-renderer"
							image: [if grafana.imageRenderer.image.registry != "" {grafana.imageRenderer.image.registry + "/"}, ""][0] + grafana.imageRenderer.image.repository + ":" + grafana.imageRenderer.image.tag
							ports: [{
								name:          "http"
								containerPort: grafana.imageRenderer.service.targetPort
							}]
							resources: grafana.imageRenderer.resources
							volumeMounts: [
								{
									name:      "tmp"
									mountPath: "/tmp"
								},
							]
						}]
						volumes: [{
							name: "tmp"
							emptyDir: {}
						}]
					}
				}
			}
		}
	}

	// 12. image-renderer-hpa.yaml
	if grafana.imageRenderer.enabled && grafana.imageRenderer.autoscaling.enabled {
		"grafana-sub-image-renderer-hpa": {
			apiVersion: "autoscaling/v2"
			kind:       "HorizontalPodAutoscaler"
			metadata: {
				name:      "\(_fullname)-image-renderer"
				namespace: _namespace
			}
			spec: {
				scaleTargetRef: {
					apiVersion: "apps/v1"
					kind:       "Deployment"
					name:       "\(_fullname)-image-renderer"
				}
				minReplicas: grafana.imageRenderer.autoscaling.minReplicas
				maxReplicas: grafana.imageRenderer.autoscaling.maxReplicas
				metrics: [
					if grafana.imageRenderer.autoscaling.targetCPU > 0 {
						{
							type: "Resource"
							resource: {
								name: "cpu"
								target: {
									type:               "Utilization"
									averageUtilization: grafana.imageRenderer.autoscaling.targetCPU
								}
							}
						}
					},
				]
			}
		}
	}

	// 13. image-renderer-network-policy.yaml
	if grafana.imageRenderer.enabled && (grafana.imageRenderer.networkPolicy.limitIngress || grafana.imageRenderer.networkPolicy.limitEgress) {
		if grafana.imageRenderer.networkPolicy.limitIngress {
			"grafana-sub-image-renderer-ingress-np": networkingv1.#NetworkPolicy & {
				apiVersion: "networking.k8s.io/v1"
				kind:       "NetworkPolicy"
				metadata: {
					name:      "\(_fullname)-image-renderer-ingress"
					namespace: _namespace
				}
				spec: {
					podSelector: matchLabels: "app.kubernetes.io/name": "\(_fullname)-image-renderer"
					policyTypes: ["Ingress"]
					ingress: [{
						from: [{
							podSelector: matchLabels: _selectorLabels
						}]
						ports: [{
							port:     grafana.imageRenderer.service.targetPort
							protocol: "TCP"
						}]
					}]
				}
			}
		}
	}

	// 14. image-renderer-servicemonitor.yaml
	if grafana.imageRenderer.serviceMonitor.enabled {
		"grafana-sub-image-renderer-servicemonitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {
				name:      "\(_fullname)-image-renderer"
				namespace: _namespace
				labels:    _labels & grafana.imageRenderer.serviceMonitor.labels
			}
			spec: {
				endpoints: [{
					port:     grafana.imageRenderer.service.portName
					interval: grafana.imageRenderer.serviceMonitor.interval
					path:     grafana.imageRenderer.serviceMonitor.path
					scheme:   grafana.imageRenderer.serviceMonitor.scheme
				}]
				selector: matchLabels: "app.kubernetes.io/name": "\(_fullname)-image-renderer"
			}
		}
	}

	// 15. image-renderer-service.yaml
	if grafana.imageRenderer.enabled && grafana.imageRenderer.service.enabled {
		"grafana-sub-image-renderer-service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(_fullname)-image-renderer"
				namespace: _namespace
				labels: _labels & {"app.kubernetes.io/name": "\(_fullname)-image-renderer"}
			}
			spec: {
				ports: [{
					name:       grafana.imageRenderer.service.portName
					port:       grafana.imageRenderer.service.port
					targetPort: grafana.imageRenderer.service.targetPort
					protocol:   "TCP"
				}]
				selector: "app.kubernetes.io/name": "\(_fullname)-image-renderer"
			}
		}
	}

	// 16. ingress.yaml
	if grafana.ingress.enabled {
		"grafana-sub-ingress": networkingv1.#Ingress & {
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
				if grafana.ingress.annotations != _|_ {
					annotations: grafana.ingress.annotations
				}
			}
			spec: {
				if grafana.ingress.ingressClassName != "" {
					ingressClassName: grafana.ingress.ingressClassName
				}
				rules: [
					for h in grafana.ingress.hosts {
						host: h.host
						http: paths: [
							for p in h.paths {
								path:     p.path
								pathType: p.pathType
								backend: service: {
									name: _fullname
									port: number: grafana.service.port
								}
							},
						]
					},
				]
			}
		}
	}

	// 17. networkpolicy.yaml
	if grafana.networkPolicy.enabled {
		"grafana-sub-networkpolicy": networkingv1.#NetworkPolicy & {
			apiVersion: "networking.k8s.io/v1"
			kind:       "NetworkPolicy"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
			}
			spec: {
				podSelector: matchLabels: _selectorLabels
				policyTypes: ["Ingress"]
				ingress: [{
					from: [{
						podSelector: matchLabels: "\(_fullname)-client": "true"
					}]
					ports: [{
						port: grafana.service.targetPort
					}]
				}]
			}
		}
	}

	// 18. poddisruptionbudget.yaml
	if grafana.podDisruptionBudget != _|_ {
		"grafana-sub-poddisruptionbudget": policyv1.#PodDisruptionBudget & {
			apiVersion: "policy/v1"
			kind:       "PodDisruptionBudget"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
			}
			spec: {
				selector: matchLabels: _selectorLabels
				if grafana.podDisruptionBudget.minAvailable != _|_ {
					minAvailable: grafana.podDisruptionBudget.minAvailable
				}
				if grafana.podDisruptionBudget.maxUnavailable != _|_ {
					maxUnavailable: grafana.podDisruptionBudget.maxUnavailable
				}
			}
		}
	}

	// 19. podsecuritypolicy.yaml
	if grafana.rbac.pspEnabled {
		"grafana-sub-podsecuritypolicy": {
			apiVersion: "policy/v1beta1"
			kind:       "PodSecurityPolicy"
			metadata: {
				name:   _fullname
				labels: _labels
			}
			spec: {
				privileged:               false
				allowPrivilegeEscalation: false
				volumes: ["configMap", "emptyDir", "projected", "csi", "secret", "downwardAPI", "persistentVolumeClaim"]
				hostNetwork: false
				hostIPC:     false
				hostPID:     false
				runAsUser: rule: "RunAsAny"
				seLinux: rule:   "RunAsAny"
				supplementalGroups: {
					rule: "MustRunAs"
					ranges: [{min: 1, max: 65535}]
				}
				fsGroup: {
					rule: "MustRunAs"
					ranges: [{min: 1, max: 65535}]
				}
			}
		}
	}

	// 20. pvc.yaml
	if grafana.persistence.enabled && (grafana.persistence.type == "pvc" || grafana.persistence.type == "") {
		"grafana-sub-pvc": corev1.#PersistentVolumeClaim & {
			apiVersion: "v1"
			kind:       "PersistentVolumeClaim"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
			}
			spec: {
				accessModes: grafana.persistence.accessModes
				resources: requests: storage: grafana.persistence.size
				storageClassName: grafana.persistence.storageClassName
			}
		}
	}

	// 21. rolebinding.yaml
	if grafana.rbac.create && grafana.rbac.namespaced {
		"grafana-sub-rolebinding": rbacv1.#RoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "RoleBinding"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
			}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "Role"
				name:     _fullname
			}
			subjects: [{
				kind:      "ServiceAccount"
				name:      _fullname
				namespace: _namespace
			}]
		}
	}

	// 22. role.yaml
	if grafana.rbac.create && grafana.rbac.namespaced {
		"grafana-sub-role": rbacv1.#Role & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "Role"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
			}
			rules: [
				if grafana.rbac.pspEnabled {
					{
						apiGroups: ["extensions"]
						resources: ["podsecuritypolicies"]
						verbs: ["use"]
						resourceNames: [_fullname]
					}
				},
			]
		}
	}

	// 23. secret-env.yaml
	if grafana.envRenderSecret != _|_ {
		"grafana-sub-secret-env": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(_fullname)-env"
				namespace: _namespace
				labels:    _labels
			}
			type: "Opaque"
			data: {
				for k, v in grafana.envRenderSecret {
					"\(k)": '\(v)'
				}
			}
		}
	}

	// 24. secret.yaml
	if grafana.admin.existingSecret == "" {
		"grafana-sub-secret": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
			}
			type: "Opaque"
			data: {
				"admin-user":     'YWRtaW4='
				"admin-password": 'cHJvbWV0aGV1cy1vcGVyYXRvcg=='
			}
		}
	}

	// 25. serviceaccount.yaml
	if grafana.serviceAccount.create {
		"grafana-sub-serviceaccount": corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
			}
		}
	}

	// 26. servicemonitor.yaml
	if grafana.serviceMonitor.enabled {
		"grafana-sub-servicemonitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
			}
			spec: {
				endpoints: [{
					port: "service"
				}]
				selector: matchLabels: _selectorLabels
			}
		}
	}

	// 27. service.yaml
	if grafana.service.enabled {
		"grafana-sub-service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
			}
			spec: {
				type: grafana.service.type
				ports: [{
					name:       "service"
					port:       grafana.service.port
					targetPort: grafana.service.targetPort
				}]
				selector: _selectorLabels
			}
		}
	}

	// 28. statefulset.yaml
	if grafana.useStatefulSet || (grafana.persistence.enabled && (grafana.persistence.type == "statefulset" || grafana.persistence.type == "sts")) {
		"grafana-sub-statefulset": appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      _fullname
				namespace: _namespace
				labels:    _labels
			}
			spec: {
				replicas:    grafana.replicas
				serviceName: "\(_fullname)-headless"
				selector: matchLabels: _selectorLabels
				template: {
					metadata: {
						labels: _selectorLabels
					}
					spec: corev1.#PodSpec & {
						serviceAccountName: _fullname
						containers: [{
							name:  "grafana"
							image: "\(grafana.image.registry)/\(grafana.image.repository):\(grafana.image.tag)"
							ports: [{
								name:          "service"
								containerPort: 3000
							}]
							volumeMounts: [{
								name:      "storage"
								mountPath: "/var/lib/grafana"
							}]
						}]
						volumes: [{
							name: "storage"
							if grafana.persistence.enabled {
								persistentVolumeClaim: claimName: _fullname
							}
						}]
					}
				}
			}
		}
	}
}
