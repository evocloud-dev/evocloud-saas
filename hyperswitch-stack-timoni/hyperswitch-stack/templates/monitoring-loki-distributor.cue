package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	autoscalingv2 "k8s.io/api/autoscaling/v2"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#LokiDistributorFullname: {
	#name:  string
	result: "\(#name)-loki-distributor"
}

#LokiDistributorLabels: {
	#name:    string
	#loki:    _
	#version: string
	result: {
		"helm.sh/chart":              "loki-5.36.2"
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": #name
		"app.kubernetes.io/version": [if #loki.image.tag != "" {#loki.image.tag}, #version][0]
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/component":  "distributor"
	}
}

#LokiDistributorSelectorLabels: {
	#name: string
	result: {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  #name
		"app.kubernetes.io/component": "distributor"
	}
}

#LokiDistributorPriorityClassName: {
	#loki: _
	result: [if #loki.global.distributorPriorityClassName != "" {#loki.global.priorityClassName}, #loki.distributor.priorityClassName][0]
}

monitoringLokiDistributor: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	let ns = #config.metadata.namespace
	let instanceName = #config.metadata.name
	let modVersion = #config.moduleVersion

	let fullname = (#LokiDistributorFullname & {#name: instanceName}).result
	let distributorLabels = (#LokiDistributorLabels & {
		#name:    instanceName
		#loki:    loki
		#version: modVersion
	}).result
	let selectorLabels = (#LokiDistributorSelectorLabels & {#name: instanceName}).result
	let distributorPriorityClassName = (#LokiDistributorPriorityClassName & {#loki: loki}).result

	let lokiTag = [if loki.image.tag != "" {loki.image.tag}, modVersion][0]
	let lokiImage = "\(loki.image.repository):\(lokiTag)"
	let configVolume = [if loki.loki.configStorageType == "Secret" {secret: secretName: loki.loki.generatedConfigObjectName}, {configMap: {name: loki.loki.generatedConfigObjectName}}][0]
	let serviceAnnotations = loki.loki.serviceAnnotations & loki.distributor.serviceAnnotations
	let serviceLabels = loki.distributor.serviceLabels
	let isDistributed = loki.deploymentMode == "Distributed"

	if isDistributed {
		// 1. deployment-distributor.yaml
		"deployment": appsv1.#Deployment & {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      fullname
				namespace: ns
				labels: distributorLabels & {
					"app.kubernetes.io/part-of": "memberlist"
				}
				if len(loki.loki.annotations) > 0 {
					annotations: loki.loki.annotations
				}
			}
			spec: {
				if !loki.distributor.autoscaling.enabled {
					replicas: loki.distributor.replicas
				}
				strategy: rollingUpdate: {
					maxSurge:       loki.distributor.maxSurge
					maxUnavailable: 1
				}
				revisionHistoryLimit: loki.loki.revisionHistoryLimit
				selector: matchLabels: selectorLabels
				template: {
					metadata: {
						annotations: {
							"checksum/config": "TODO_SHA256"
							for key, value in loki.loki.podAnnotations {
								"\(key)": value
							}
							for key, value in loki.distributor.podAnnotations {
								"\(key)": value
							}
						}
						labels: selectorLabels & loki.loki.podLabels & loki.distributor.podLabels & {
							"app.kubernetes.io/part-of": "memberlist"
						}
					}
					spec: {
						serviceAccountName: [if loki.serviceAccount.name != "" {loki.serviceAccount.name}, "loki"][0]
						if len(loki.imagePullSecrets) > 0 {
							imagePullSecrets: loki.imagePullSecrets
						}
						if len(loki.distributor.hostAliases) > 0 {
							hostAliases: loki.distributor.hostAliases
						}
						if distributorPriorityClassName != "" {
							priorityClassName: distributorPriorityClassName
						}
						securityContext:               loki.loki.podSecurityContext
						terminationGracePeriodSeconds: loki.distributor.terminationGracePeriodSeconds
						containers: [
							{
								name:            "distributor"
								image:           lokiImage
								imagePullPolicy: loki.image.pullPolicy
								if loki.command != "" || loki.distributor.command != "" {
									command: [[if loki.distributor.command != "" {loki.distributor.command}, loki.command][0]]
								}
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-target=distributor",
									if loki.ingester.zoneAwareReplication.enabled {
										[if loki.ingester.zoneAwareReplication.migration.enabled && !loki.ingester.zoneAwareReplication.migration.writePath {"-distributor.zone-awareness-enabled=false"}, "-distributor.zone-awareness-enabled=true"][0]
									},
									for arg in loki.distributor.extraArgs {arg},
								]
								ports: [
									{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
									{name: "grpc", containerPort: 9095, protocol: "TCP"},
									{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
								]
								if len(loki.distributor.extraEnv) > 0 {
									env: loki.distributor.extraEnv
								}
								if len(loki.distributor.extraEnvFrom) > 0 {
									envFrom: loki.distributor.extraEnvFrom
								}
								securityContext: loki.loki.containerSecurityContext
								readinessProbe:  loki.loki.readinessProbe
								livenessProbe:   loki.loki.livenessProbe
								volumeMounts: [
									{name: "config", mountPath: "/etc/loki/config"},
									{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
									if loki.enterprise.enabled {name: "license", mountPath: "/etc/loki/license"},
									...loki.distributor.extraVolumeMounts,
								]
								resources: loki.distributor.resources
							},
							...loki.distributor.extraContainers,
						]
						if len(loki.distributor.affinity) > 0 {
							affinity: loki.distributor.affinity
						}
						if len(loki.distributor.nodeSelector) > 0 {
							nodeSelector: loki.distributor.nodeSelector
						}
						if len(loki.distributor.tolerations) > 0 {
							tolerations: loki.distributor.tolerations
						}
						volumes: [
							{name: "config", configVolume},
							{name: "runtime-config", configMap: name: "loki-runtime"},
							if loki.enterprise.enabled {
								{
									name: "license"
									secret: secretName: [if loki.enterprise.useExternalLicense {loki.enterprise.externalLicenseName}, "enterprise-logs-license"][0]
								}
							},
							...loki.distributor.extraVolumes,
						]
					}
				}
			}
		}

		// 2. hpa.yaml
		if loki.distributor.autoscaling.enabled {
			"hpa": autoscalingv2.#HorizontalPodAutoscaler & {
				apiVersion: "autoscaling/v2"
				kind:       "HorizontalPodAutoscaler"
				metadata: {
					name:   fullname
					labels: distributorLabels
				}
				spec: {
					scaleTargetRef: {
						apiVersion: "apps/v1"
						kind:       "Deployment"
						name:       fullname
					}
					minReplicas: loki.distributor.autoscaling.minReplicas
					maxReplicas: loki.distributor.autoscaling.maxReplicas
					metrics: [
						if loki.distributor.autoscaling.targetMemoryUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "memory"
									target: {type: "Utilization", averageUtilization: loki.distributor.autoscaling.targetMemoryUtilizationPercentage}
								}
							}
						},
						if loki.distributor.autoscaling.targetCPUUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "cpu"
									target: {type: "Utilization", averageUtilization: loki.distributor.autoscaling.targetCPUUtilizationPercentage}
								}
							}
						},
						...loki.distributor.autoscaling.customMetrics,
					]
					if loki.distributor.autoscaling.behavior.enabled {
						behavior: {
							if len(loki.distributor.autoscaling.behavior.scaleDown) > 0 {scaleDown: loki.distributor.autoscaling.behavior.scaleDown}
							if len(loki.distributor.autoscaling.behavior.scaleUp) > 0 {scaleUp: loki.distributor.autoscaling.behavior.scaleUp}
						}
					}
				}
			}
		}

		// 3. poddisruptionbudget-distributor.yaml
		if loki.distributor.replicas > 1 && loki.distributor.maxUnavailable != null {
			"poddisruptionbudget": policyv1.#PodDisruptionBudget & {
				apiVersion: "policy/v1"
				kind:       "PodDisruptionBudget"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    distributorLabels
				}
				spec: {
					selector: matchLabels: selectorLabels
					maxUnavailable: loki.distributor.maxUnavailable
				}
			}
		}

		// 4. service-distributor-headless.yaml
		"service-headless": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(fullname)-headless"
				namespace: ns
				labels: selectorLabels & serviceLabels & {
					variant:                         "headless"
					"prometheus.io/service-monitor": "false"
				}
				annotations: serviceAnnotations
			}
			spec: {
				type:      "ClusterIP"
				clusterIP: "None"
				ports: [
					{name: "http-metrics", port: 3100, targetPort: "http-metrics", protocol: "TCP"},
					{
						name:       "grpc"
						port:       9095
						targetPort: "grpc"
						protocol:   "TCP"
						if loki.distributor.appProtocol.grpc != "" {appProtocol: loki.distributor.appProtocol.grpc}
					},
				]
				selector: selectorLabels
			}
		}

		// 5. service-distributor.yaml
		"service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:        fullname
				namespace:   ns
				labels:      distributorLabels & serviceLabels
				annotations: serviceAnnotations
			}
			spec: {
				type: "ClusterIP"
				ports: [
					{name: "http-metrics", port: 3100, targetPort: "http-metrics", protocol: "TCP"},
					{
						name:       "grpc"
						port:       9095
						targetPort: "grpc"
						protocol:   "TCP"
						if loki.distributor.appProtocol.grpc != "" {appProtocol: loki.distributor.appProtocol.grpc}
					},
				]
				selector: selectorLabels
			}
		}
	}
}
