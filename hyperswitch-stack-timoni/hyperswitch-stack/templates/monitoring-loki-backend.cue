package templates

import (
	apps_v1 "k8s.io/api/apps/v1"
	core_v1 "k8s.io/api/core/v1"
	rbac_v1 "k8s.io/api/rbac/v1"
	policy_v1 "k8s.io/api/policy/v1"
	autoscaling_v2 "k8s.io/api/autoscaling/v2"
)

monitoringLokiBackend: {
	#config: #Config
	let _loki_conf = #config."hyperswitch-monitoring".loki
	let ns = #config.metadata.namespace

	_isScalable:       _loki_conf.deploymentMode != "SingleBinary"
	_isBackendEnabled: _isScalable && (_loki_conf.backend.replicas > 0 || _loki_conf.backend.autoscaling.enabled)

	_labels: {
		"helm.sh/chart":              "loki-5.36.2"
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": #config.metadata.name
		"app.kubernetes.io/version": [if _loki_conf.image.tag != "" {_loki_conf.image.tag}, #config.moduleVersion][0]
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/component":  "backend"
	}

	_selectorLabels: {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  #config.metadata.name
		"app.kubernetes.io/component": "backend"
	}

	if _isBackendEnabled {
		// 1. statefulset-backend.yaml
		"statefulset": apps_v1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "\(#config.metadata.name)-loki-backend"
				namespace: ns
				labels: _labels & _loki_conf.backend.labels & {
					"app.kubernetes.io/part-of": "memberlist"
				}
				annotations: _loki_conf.loki.serviceAnnotations & _loki_conf.backend.annotations
			}
			spec: {
				if !_loki_conf.backend.autoscaling.enabled {
					replicas: _loki_conf.backend.replicas
				}
				podManagementPolicy: _loki_conf.backend.podManagementPolicy
				updateStrategy: rollingUpdate: partition: 0
				serviceName:          "\(#config.metadata.name)-loki-backend-headless"
				revisionHistoryLimit: _loki_conf.loki.revisionHistoryLimit

				selector: matchLabels: _selectorLabels
				template: {
					metadata: {
						labels: _selectorLabels & _loki_conf.loki.podLabels & _loki_conf.backend.podLabels & {
							"app.kubernetes.io/part-of": "memberlist"
						}
						if _loki_conf.backend.selectorLabels != _|_ {
							for k, v in _loki_conf.backend.selectorLabels {
								labels: "\(k)": v
							}
						}
						annotations: {
							"checksum/config": "TODO_SHA256"
							for k, v in _loki_conf.loki.podAnnotations {
								"\(k)": v
							}
							for k, v in _loki_conf.backend.podAnnotations {
								"\(k)": v
							}
						}
					}
					spec: {
						serviceAccountName: [if _loki_conf.rbac.namespaced {"\(#config.metadata.name)-loki"}, "default"][0]
						automountServiceAccountToken: _loki_conf.serviceAccount.automountServiceAccountToken

						if _loki_conf.backend.priorityClassName != "" {
							priorityClassName: _loki_conf.backend.priorityClassName
						}
						securityContext:               _loki_conf.loki.podSecurityContext
						terminationGracePeriodSeconds: _loki_conf.backend.terminationGracePeriodSeconds

						if len(_loki_conf.backend.initContainers) > 0 {
							initContainers: _loki_conf.backend.initContainers
						}

						let loki_tag = [if _loki_conf.image.tag != "" {_loki_conf.image.tag}, #config.moduleVersion][0]
						containers: [
							{
								name:            "loki"
								image:           "\(_loki_conf.image.repository):\(loki_tag)"
								imagePullPolicy: _loki_conf.image.pullPolicy
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-target=\(_loki_conf.backend.targetModule)",
									"-legacy-read-mode=false",
									for arg in _loki_conf.backend.extraArgs {
										arg
									},
								]
								ports: [
									{
										name:          "http-metrics"
										containerPort: 3100
										protocol:      "TCP"
									},
									{
										name:          "grpc"
										containerPort: 9095
										protocol:      "TCP"
									},
									{
										name:          "http-memberlist"
										containerPort: 7946
										protocol:      "TCP"
									},
								]
								if len(_loki_conf.backend.extraEnv) > 0 {
									env: _loki_conf.backend.extraEnv
								}
								if len(_loki_conf.backend.extraEnvFrom) > 0 {
									envFrom: _loki_conf.backend.extraEnvFrom
								}
								securityContext: _loki_conf.loki.containerSecurityContext
								readinessProbe:  _loki_conf.loki.readinessProbe
								volumeMounts: [
									{
										name:      "config"
										mountPath: "/etc/loki/config"
									},
									{
										name:      "runtime-config"
										mountPath: "/etc/loki/runtime-config"
									},
									{
										name:      "tmp"
										mountPath: "/tmp"
									},
									{
										name:      "data"
										mountPath: "/var/loki"
									},
									if _loki_conf.enterprise.enabled {
										{
											name:      "license"
											mountPath: "/etc/loki/license"
										}
									},
									for vm in _loki_conf.backend.extraVolumeMounts {
										vm
									},
								]
								resources: _loki_conf.backend.resources
							},
						]
						affinity:     _loki_conf.backend.affinity
						nodeSelector: _loki_conf.backend.nodeSelector
						tolerations:  _loki_conf.backend.tolerations
						if _loki_conf.backend.dnsConfig != null {
							dnsConfig: _loki_conf.backend.dnsConfig
						}
						if len(_loki_conf.backend.topologySpreadConstraints) > 0 {
							topologySpreadConstraints: _loki_conf.backend.topologySpreadConstraints
						}

						volumes: [
							{
								name: "tmp"
								emptyDir: {}
							},
							if !_loki_conf.backend.persistence.volumeClaimsEnabled {
								{
									name: "data"
									_loki_conf.backend.persistence.dataVolumeParameters
								}
							},
							{
								name: "config"
								configMap: {name: _loki_conf.loki.generatedConfigObjectName}
							},
							{
								name: "runtime-config"
								configMap: {name: "\(#config.metadata.name)-loki-runtime"}
							},
							if _loki_conf.enterprise.enabled {
								{
									name: "license"
									secret: secretName: [if _loki_conf.enterprise.useExternalLicense {_loki_conf.enterprise.externalLicenseName}, "enterprise-logs-license"][0]
								}
							},
							for v in _loki_conf.backend.extraVolumes {
								v
							},
						]
					}
				}
				if _loki_conf.backend.persistence.volumeClaimsEnabled {
					volumeClaimTemplates: [
						{
							metadata: {
								name: "data"
								if _loki_conf.backend.persistence.annotations != _|_ {
									annotations: _loki_conf.backend.persistence.annotations
								}
							}
							spec: {
								accessModes: ["ReadWriteOnce"]
								if _loki_conf.backend.persistence.storageClass != null {
									storageClassName: _loki_conf.backend.persistence.storageClass
								}
								resources: requests: storage: _loki_conf.backend.persistence.size
								if _loki_conf.backend.persistence.selector != _|_ {
									selector: _loki_conf.backend.persistence.selector
								}
							}
						},
					]
				}
			}
		}

		// 2. service-backend.yaml
		"service": core_v1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:        "\(#config.metadata.name)-loki-backend"
				namespace:   ns
				labels:      _labels & _loki_conf.loki.serviceLabels & _loki_conf.backend.service.labels
				annotations: _loki_conf.loki.serviceAnnotations & _loki_conf.backend.service.annotations
			}
			spec: {
				type: "ClusterIP"
				ports: [
					{
						name:       "http-metrics"
						port:       3100
						protocol:   "TCP"
						targetPort: "http-metrics"
					},
					{
						name:       "grpc"
						port:       9095
						protocol:   "TCP"
						targetPort: "grpc"
					},
				]
				selector: _selectorLabels
			}
		}

		// 3. service-backend-headless.yaml
		"service-headless": core_v1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-loki-backend-headless"
				namespace: ns
				labels: _selectorLabels & _loki_conf.loki.serviceLabels & _loki_conf.backend.service.labels & {
					variant:                         "headless"
					"prometheus.io/service-monitor": "false"
				}
				annotations: _loki_conf.loki.serviceAnnotations & _loki_conf.backend.service.annotations
			}
			spec: {
				clusterIP: "None"
				ports: [
					{
						name:       "http-metrics"
						port:       3100
						protocol:   "TCP"
						targetPort: "http-metrics"
					},
					{
						name:       "grpc"
						port:       9095
						protocol:   "TCP"
						targetPort: "grpc"
					},
				]
				selector: _selectorLabels
			}
		}

		// 4. query-scheduler-discovery.yaml
		"service-discovery": core_v1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-loki-backend-discovery"
				namespace: ns
				labels: _selectorLabels & {
					"prometheus.io/service-monitor": "false"
				}
				annotations: _loki_conf.loki.serviceAnnotations & _loki_conf.backend.service.annotations
			}
			spec: {
				clusterIP:                "None"
				publishNotReadyAddresses: true
				ports: [
					{
						name:       "http-metrics"
						port:       3100
						protocol:   "TCP"
						targetPort: "http-metrics"
					},
					{
						name:       "grpc"
						port:       9095
						protocol:   "TCP"
						targetPort: "grpc"
					},
				]
				selector: _selectorLabels
			}
		}

		// 5. hpa.yaml
		if _loki_conf.backend.autoscaling.enabled {
			"hpa": autoscaling_v2.#HorizontalPodAutoscaler & {
				apiVersion: "autoscaling/v2"
				kind:       "HorizontalPodAutoscaler"
				metadata: {
					name:      "\(#config.metadata.name)-loki-backend"
					namespace: ns
					labels:    _labels
				}
				spec: {
					scaleTargetRef: {
						apiVersion: "apps/v1"
						kind:       "StatefulSet"
						name:       "\(#config.metadata.name)-loki-backend"
					}
					minReplicas: _loki_conf.backend.autoscaling.minReplicas
					maxReplicas: _loki_conf.backend.autoscaling.maxReplicas
					metrics: [
						if _loki_conf.backend.autoscaling.targetCPUUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "cpu"
									target: {
										type:               "Utilization"
										averageUtilization: _loki_conf.backend.autoscaling.targetCPUUtilizationPercentage
									}
								}
							}
						},
						if _loki_conf.backend.autoscaling.targetMemoryUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "memory"
									target: {
										type:               "Utilization"
										averageUtilization: _loki_conf.backend.autoscaling.targetMemoryUtilizationPercentage
									}
								}
							}
						},
					]
				}
			}
		}

		// 6. poddisruptionbudget-backend.yaml
		if _loki_conf.backend.pdb.enabled {
			"pdb": policy_v1.#PodDisruptionBudget & {
				apiVersion: "policy/v1"
				kind:       "PodDisruptionBudget"
				metadata: {
					name:      "\(#config.metadata.name)-loki-backend"
					namespace: ns
					labels:    _labels
				}
				spec: {
					selector: matchLabels: _selectorLabels
					if _loki_conf.backend.pdb.maxUnavailable != null {
						maxUnavailable: _loki_conf.backend.pdb.maxUnavailable
					}
					if _loki_conf.backend.pdb.minAvailable != null {
						minAvailable: _loki_conf.backend.pdb.minAvailable
					}
				}
			}
		}

		// 7. clusterrole.yaml
		if !_loki_conf.rbac.namespaced && !_loki_conf.rbac.useExistingRole {
			"clusterrole": rbac_v1.#ClusterRole & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRole"
				metadata: {
					name:   "\(#config.metadata.name)-loki-clusterrole"
					labels: _labels
					if _loki_conf.annotations != _|_ {
						annotations: _loki_conf.annotations
					}
				}
				if _loki_conf.sidecar.rules.enabled {
					rules: [
						{
							apiGroups: [""]
							resources: ["configmaps", "secrets"]
							verbs: ["get", "watch", "list"]
						},
					]
				}
				if !_loki_conf.sidecar.rules.enabled {
					rules: []
				}
			}
		}

		// 8. clusterrolebinding.yaml
		if !_loki_conf.rbac.namespaced {
			"clusterrolebinding": rbac_v1.#ClusterRoleBinding & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRoleBinding"
				metadata: {
					name:   "\(#config.metadata.name)-loki-clusterrolebinding"
					labels: _labels
					if _loki_conf.annotations != _|_ {
						annotations: _loki_conf.annotations
					}
				}
				subjects: [
					{
						kind: "ServiceAccount"
						name: [if _loki_conf.rbac.namespaced {"\(#config.metadata.name)-loki"}, "default"][0]
						namespace: ns
					},
				]
				roleRef: {
					kind: "ClusterRole"
					if _loki_conf.rbac.useExistingRole != "" {
						name: _loki_conf.rbac.useExistingRole
					}
					if _loki_conf.rbac.useExistingRole == "" {
						name: "\(#config.metadata.name)-loki-clusterrole"
					}
					apiGroup: "rbac.authorization.k8s.io"
				}
			}
		}
	}
}
