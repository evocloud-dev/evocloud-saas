package templates

import (
	apps_v1 "k8s.io/api/apps/v1"
	core_v1 "k8s.io/api/core/v1"
	policy_v1 "k8s.io/api/policy/v1"
	autoscaling_v2 "k8s.io/api/autoscaling/v2"
)

monitoringLokiBloomBuilder: {
	#config: #Config
	let _loki_conf = #config."hyperswitch-monitoring".loki
	let ns = #config.metadata.namespace

	_isDistributed:         _loki_conf.deploymentMode == "Distributed"
	_isBloomBuilderEnabled: _isDistributed && (_loki_conf.bloomPlanner.replicas > 0)

	_labels: {
		"helm.sh/chart":              "loki-5.36.2"
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": #config.metadata.name
		"app.kubernetes.io/version": [if _loki_conf.image.tag != "" {_loki_conf.image.tag}, #config.moduleVersion][0]
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/component":  "bloom-builder"
	}

	_selectorLabels: {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  #config.metadata.name
		"app.kubernetes.io/component": "bloom-builder"
	}

	if _isBloomBuilderEnabled {
		// 1. deployment-bloom-builder.yaml
		"deployment": apps_v1.#Deployment & {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      "\(#config.metadata.name)-loki-bloom-builder"
				namespace: ns
				labels:    _labels & _loki_conf.bloomBuilder.labels
				if _loki_conf.loki.annotations != _|_ {
					annotations: _loki_conf.loki.annotations
				}
			}
			spec: {
				if !_loki_conf.bloomBuilder.autoscaling.enabled {
					replicas: _loki_conf.bloomBuilder.replicas
				}
				strategy: {
					rollingUpdate: {
						maxSurge:       0
						maxUnavailable: 1
					}
				}
				revisionHistoryLimit: _loki_conf.loki.revisionHistoryLimit
				selector: matchLabels: _selectorLabels
				template: {
					metadata: {
						annotations: {
							"checksum/config": "TODO_SHA256"
							for k, v in _loki_conf.loki.podAnnotations {
								"\(k)": v
							}
							for k, v in _loki_conf.bloomBuilder.podAnnotations {
								"\(k)": v
							}
						}
						labels: _selectorLabels & _loki_conf.loki.podLabels & _loki_conf.bloomBuilder.podLabels & {
							"app.kubernetes.io/part-of": "memberlist"
						}
					}
					spec: {
						serviceAccountName: [if _loki_conf.rbac.namespaced {"\(#config.metadata.name)-loki"}, "default"][0]
						if len(_loki_conf.imagePullSecrets) > 0 {
							imagePullSecrets: _loki_conf.imagePullSecrets
						}
						if len(_loki_conf.bloomBuilder.hostAliases) > 0 {
							hostAliases: _loki_conf.bloomBuilder.hostAliases
						}
						if _loki_conf.bloomBuilder.priorityClassName != "" {
							priorityClassName: _loki_conf.bloomBuilder.priorityClassName
						}
						securityContext:               _loki_conf.loki.podSecurityContext
						terminationGracePeriodSeconds: _loki_conf.bloomBuilder.terminationGracePeriodSeconds

						let loki_tag = [if _loki_conf.image.tag != "" {_loki_conf.image.tag}, #config.moduleVersion][0]
						containers: [
							{
								name:            "bloom-builder"
								image:           "\(_loki_conf.image.repository):\(loki_tag)"
								imagePullPolicy: _loki_conf.image.pullPolicy
								if _loki_conf.bloomBuilder.command != null {
									command: [_loki_conf.bloomBuilder.command]
								}
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-target=bloom-builder",
									for arg in _loki_conf.bloomBuilder.extraArgs {
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
								if len(_loki_conf.bloomBuilder.extraEnv) > 0 {
									env: _loki_conf.bloomBuilder.extraEnv
								}
								if len(_loki_conf.bloomBuilder.extraEnvFrom) > 0 {
									envFrom: _loki_conf.bloomBuilder.extraEnvFrom
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
									if _loki_conf.enterprise.enabled {
										{
											name:      "license"
											mountPath: "/etc/loki/license"
										}
									},
									{
										name:      "temp"
										mountPath: "/tmp"
									},
									{
										name:      "data"
										mountPath: "/var/loki"
									},
									for vm in _loki_conf.bloomBuilder.extraVolumeMounts {
										vm
									},
								]
								resources: _loki_conf.bloomBuilder.resources
							},
						]
						if len(_loki_conf.bloomBuilder.extraContainers) > 0 {
							for c in _loki_conf.bloomBuilder.extraContainers {
								containers: [c]
							}
						}
						affinity:     _loki_conf.bloomBuilder.affinity
						nodeSelector: _loki_conf.bloomBuilder.nodeSelector
						tolerations:  _loki_conf.bloomBuilder.tolerations
						volumes: [
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
							{
								name: "temp"
								emptyDir: {}
							},
							{
								name: "data"
								emptyDir: {}
							},
							for v in _loki_conf.bloomBuilder.extraVolumes {
								v
							},
						]
					}
				}
			}
		}

		// 2. service-bloom-builder.yaml
		"service": core_v1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:        "\(#config.metadata.name)-loki-bloom-builder"
				namespace:   ns
				labels:      _labels & _loki_conf.loki.serviceLabels & _loki_conf.bloomBuilder.service.labels
				annotations: _loki_conf.loki.serviceAnnotations & _loki_conf.bloomBuilder.service.annotations
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

		// 3. service-bloom-builder-headless.yaml
		"service-headless": core_v1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-loki-bloom-builder-headless"
				namespace: ns
				labels: _labels & _loki_conf.loki.serviceLabels & _loki_conf.bloomBuilder.service.labels & {
					variant:                         "headless"
					"prometheus.io/service-monitor": "false"
				}
				annotations: _loki_conf.loki.serviceAnnotations & _loki_conf.bloomBuilder.service.annotations
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

		// 4. hpa.yaml
		if _loki_conf.bloomBuilder.autoscaling.enabled {
			"hpa": autoscaling_v2.#HorizontalPodAutoscaler & {
				apiVersion: "autoscaling/v2"
				kind:       "HorizontalPodAutoscaler"
				metadata: {
					name:      "\(#config.metadata.name)-loki-bloom-builder"
					namespace: ns
					labels:    _labels
				}
				spec: {
					scaleTargetRef: {
						apiVersion: "apps/v1"
						kind:       "Deployment"
						name:       "\(#config.metadata.name)-loki-bloom-builder"
					}
					minReplicas: _loki_conf.bloomBuilder.autoscaling.minReplicas
					maxReplicas: _loki_conf.bloomBuilder.autoscaling.maxReplicas
					metrics: [
						if _loki_conf.bloomBuilder.autoscaling.targetCPUUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "cpu"
									target: {
										type:               "Utilization"
										averageUtilization: _loki_conf.bloomBuilder.autoscaling.targetCPUUtilizationPercentage
									}
								}
							}
						},
						if _loki_conf.bloomBuilder.autoscaling.targetMemoryUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "memory"
									target: {
										type:               "Utilization"
										averageUtilization: _loki_conf.bloomBuilder.autoscaling.targetMemoryUtilizationPercentage
									}
								}
							}
						},
					]
				}
			}
		}

		// 5. poddisruptionbudget-bloom-builder.yaml
		if _loki_conf.bloomBuilder.pdb.enabled {
			"pdb": policy_v1.#PodDisruptionBudget & {
				apiVersion: "policy/v1"
				kind:       "PodDisruptionBudget"
				metadata: {
					name:      "\(#config.metadata.name)-loki-bloom-builder"
					namespace: ns
					labels:    _labels
				}
				spec: {
					selector: matchLabels: _selectorLabels
					if _loki_conf.bloomBuilder.pdb.maxUnavailable != null {
						maxUnavailable: _loki_conf.bloomBuilder.pdb.maxUnavailable
					}
					if _loki_conf.bloomBuilder.pdb.minAvailable != null {
						minAvailable: _loki_conf.bloomBuilder.pdb.minAvailable
					}
				}
			}
		}
	}
}
