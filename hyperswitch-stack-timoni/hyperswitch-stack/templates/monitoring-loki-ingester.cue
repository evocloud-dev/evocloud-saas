package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

monitoringLokiIngester: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	let ingester = #config."hyperswitch-monitoring".loki.ingester
	let ns = #config.metadata.namespace
	let _name = #config.metadata.name
	let isDistributed = loki.deploymentMode == "Distributed"
	let zoneAware = ingester.zoneAwareReplication

	if loki.enabled && isDistributed {
		let ingesterLabels = {
			"helm.sh/chart":                "loki-5.36.2"
			"app.kubernetes.io/name":       "loki"
			"app.kubernetes.io/instance":   _name
			"app.kubernetes.io/version":    loki.image.tag
			"app.kubernetes.io/component":  "ingester"
			"app.kubernetes.io/managed-by": "timoni"
			for k, v in #config.metadata.labels {
				"\(k)": v
			}
			for k, v in loki.commonLabels {
				"\(k)": v
			}
		}

		let ingesterSelectorLabels = {
			"app.kubernetes.io/name":      "loki"
			"app.kubernetes.io/instance":  _name
			"app.kubernetes.io/component": "ingester"
		}

		let lokiImage = "\(loki.image.registry)/\(loki.image.repository):\(loki.image.tag)"
		let zoneReplicas = [if ingester.replicas > 0 {int(ingester.replicas / 3)}, 1][0]

		// File 1: hpa.yaml
		if ingester.autoscaling.enabled {
			"hpa": autoscalingv2.#HorizontalPodAutoscaler & {
				apiVersion: "autoscaling/v2"
				kind:       "HorizontalPodAutoscaler"
				metadata: {
					name:      "\(_name)-loki-ingester"
					namespace: ns
					labels:    ingesterLabels
				}
				spec: {
					scaleTargetRef: {
						apiVersion: "apps/v1"
						kind:       "StatefulSet"
						name:       "\(_name)-loki-ingester"
					}
					minReplicas: ingester.autoscaling.minReplicas
					maxReplicas: ingester.autoscaling.maxReplicas
					metrics: [
						if ingester.autoscaling.targetCPUUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "cpu"
									target: {type: "Utilization", averageUtilization: ingester.autoscaling.targetCPUUtilizationPercentage}
								}
							}
						},
						if ingester.autoscaling.targetMemoryUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "memory"
									target: {type: "Utilization", averageUtilization: ingester.autoscaling.targetMemoryUtilizationPercentage}
								}
							}
						},
					]
				}
			}
		}

		// File 2: poddisruptionbudget-ingester-rollout.yaml
		if zoneAware.enabled && !zoneAware.migration.enabled {
			"poddisruptionbudget-ingester-rollout": policyv1.#PodDisruptionBudget & {
				if #config.clusterVersion.#Version >= "1.21.0" {
					apiVersion: "policy/v1"
				}
				if #config.clusterVersion.#Version < "1.21.0" {
					apiVersion: "policy/v1beta1"
				}
				kind: "PodDisruptionBudget"
				metadata: {
					name:      "\(_name)-loki-ingester-rollout"
					namespace: ns
					labels:    ingesterLabels
				}
				spec: {
					selector: matchLabels: {
						for k, v in ingesterSelectorLabels {"\(k)": v}
						"rollout-group": "ingester"
					}
					maxUnavailable: [if (int(ingester.replicas * zoneAware.maxUnavailablePct / 100)) > 0 {int(ingester.replicas * zoneAware.maxUnavailablePct / 100)}, 1][0]
				}
			}
		}

		// File 3: poddisruptionbudget-ingester.yaml
		if (!zoneAware.enabled || zoneAware.migration.enabled) && ingester.replicas > 1 {
			"poddisruptionbudget-ingester": policyv1.#PodDisruptionBudget & {
				if #config.clusterVersion.#Version >= "1.21.0" {
					apiVersion: "policy/v1"
				}
				if #config.clusterVersion.#Version < "1.21.0" {
					apiVersion: "policy/v1beta1"
				}
				kind: "PodDisruptionBudget"
				metadata: {
					name:      "\(_name)-loki-ingester"
					namespace: ns
					labels:    ingesterLabels
				}
				spec: {
					selector: matchLabels: ingesterSelectorLabels
					if ingester.maxUnavailable != null {
						maxUnavailable: ingester.maxUnavailable
					}
				}
			}
		}

		// File 4: service-ingester-headless.yaml
		if !zoneAware.enabled || zoneAware.migration.enabled {
			"service-ingester-headless": corev1.#Service & {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      "\(_name)-loki-ingester-headless"
					namespace: ns
					labels: ingesterSelectorLabels & {
						variant:                         "headless"
						"prometheus.io/service-monitor": "false"
					}
					annotations: loki.loki.serviceAnnotations & ingester.serviceAnnotations
				}
				spec: {
					type:      "ClusterIP"
					clusterIP: "None"
					ports: [
						{name: "http-metrics", port: 3100, targetPort: "http-metrics", protocol: "TCP"},
						{name: "grpc", port: 9095, targetPort: "grpc", protocol: "TCP", if ingester.appProtocol.grpc != "" {appProtocol: ingester.appProtocol.grpc}},
					]
					selector: ingesterSelectorLabels
				}
			}
		}

		// File 5: service-ingester.yaml
		if !zoneAware.enabled || zoneAware.migration.enabled {
			"service-ingester": corev1.#Service & {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:        "\(_name)-loki-ingester"
					namespace:   ns
					labels:      ingesterLabels & ingester.serviceLabels
					annotations: loki.loki.serviceAnnotations & ingester.serviceAnnotations
				}
				spec: {
					type: "ClusterIP"
					ports: [
						{name: "http-metrics", port: 3100, targetPort: "http-metrics", protocol: "TCP"},
						{name: "grpc", port: 9095, targetPort: "grpc", protocol: "TCP", if ingester.appProtocol.grpc != "" {appProtocol: ingester.appProtocol.grpc}},
					]
					selector: ingesterSelectorLabels
				}
			}
		}

		// File 6: service-ingester-zone-a-headless.yaml
		if zoneAware.enabled && !zoneAware.migration.enabled {
			"service-ingester-zone-a-headless": corev1.#Service & {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      "\(_name)-loki-ingester-zone-a-headless"
					namespace: ns
					labels: ingesterSelectorLabels & {
						name:                            "ingester-zone-a"
						"rollout-group":                 "ingester"
						variant:                         "headless"
						"prometheus.io/service-monitor": "false"
					}
					annotations: loki.loki.serviceAnnotations & ingester.serviceAnnotations
				}
				spec: {
					type:      "ClusterIP"
					clusterIP: "None"
					ports: [
						{name: "http-metrics", port: 3100, targetPort: "http-metrics", protocol: "TCP"},
						{name: "grpc", port: 9095, targetPort: "grpc", protocol: "TCP", if ingester.appProtocol.grpc != "" {appProtocol: ingester.appProtocol.grpc}},
					]
					selector: ingesterSelectorLabels & {
						name:            "ingester-zone-a"
						"rollout-group": "ingester"
					}
				}
			}
		}

		// File 7: service-ingester-zone-b-headless.yaml
		if zoneAware.enabled && !zoneAware.migration.enabled {
			"service-ingester-zone-b-headless": corev1.#Service & {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      "\(_name)-loki-ingester-zone-b-headless"
					namespace: ns
					labels: ingesterSelectorLabels & {
						name:                            "ingester-zone-b"
						"rollout-group":                 "ingester"
						variant:                         "headless"
						"prometheus.io/service-monitor": "false"
					}
					annotations: loki.loki.serviceAnnotations & ingester.serviceAnnotations
				}
				spec: {
					type:      "ClusterIP"
					clusterIP: "None"
					ports: [
						{name: "http-metrics", port: 3100, targetPort: "http-metrics", protocol: "TCP"},
						{name: "grpc", port: 9095, targetPort: "grpc", protocol: "TCP", if ingester.appProtocol.grpc != "" {appProtocol: ingester.appProtocol.grpc}},
					]
					selector: ingesterSelectorLabels & {
						name:            "ingester-zone-b"
						"rollout-group": "ingester"
					}
				}
			}
		}

		// File 8: service-ingester-zone-c-headless.yaml
		if zoneAware.enabled && !zoneAware.migration.enabled {
			"service-ingester-zone-c-headless": corev1.#Service & {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      "\(_name)-loki-ingester-zone-c-headless"
					namespace: ns
					labels: ingesterSelectorLabels & {
						name:                            "ingester-zone-c"
						"rollout-group":                 "ingester"
						variant:                         "headless"
						"prometheus.io/service-monitor": "false"
					}
					annotations: loki.loki.serviceAnnotations & ingester.serviceAnnotations
				}
				spec: {
					type:      "ClusterIP"
					clusterIP: "None"
					ports: [
						{name: "http-metrics", port: 3100, targetPort: "http-metrics", protocol: "TCP"},
						{name: "grpc", port: 9095, targetPort: "grpc", protocol: "TCP", if ingester.appProtocol.grpc != "" {appProtocol: ingester.appProtocol.grpc}},
					]
					selector: ingesterSelectorLabels & {
						name:            "ingester-zone-c"
						"rollout-group": "ingester"
					}
				}
			}
		}

		// File 9: statefulset-ingester.yaml
		if !zoneAware.enabled || zoneAware.migration.enabled {
			"statefulset-ingester": appsv1.#StatefulSet & {
				apiVersion: "apps/v1"
				kind:       "StatefulSet"
				metadata: {
					name:      "\(_name)-loki-ingester"
					namespace: ns
					labels: ingesterLabels & {"app.kubernetes.io/part-of": "memberlist"}
					if len(loki.loki.annotations) > 0 {
						annotations: loki.loki.annotations
					}
				}
				spec: {
					if !ingester.autoscaling.enabled {
						replicas: ingester.replicas
					}
					podManagementPolicy: "Parallel"
					updateStrategy: rollingUpdate: partition: 0
					serviceName:          "\(_name)-loki-ingester-headless"
					revisionHistoryLimit: loki.loki.revisionHistoryLimit
					if #config.clusterVersion.#Version >= "1.23.0" && ingester.persistence.enableStatefulSetAutoDeletePVC {
						persistentVolumeClaimRetentionPolicy: {
							whenDeleted: ingester.persistence.whenDeleted
							whenScaled:  ingester.persistence.whenScaled
						}
					}
					selector: matchLabels: ingesterSelectorLabels
					template: {
						metadata: {
							annotations: {
								"checksum/config": "config-checksum-placeholder"
								for k, v in loki.loki.podAnnotations {"\(k)": v}
								for k, v in ingester.podAnnotations {"\(k)": v}
							}
							labels: ingesterSelectorLabels & {
								"app.kubernetes.io/part-of": "memberlist"
								for k, v in loki.loki.podLabels {"\(k)": v}
								for k, v in ingester.podLabels {"\(k)": v}
							}
						}
						spec: {
							if #config.clusterVersion.#Version >= "1.19.0" {
								if len(ingester.topologySpreadConstraints) > 0 {
									topologySpreadConstraints: ingester.topologySpreadConstraints
								}
							}
							serviceAccountName: "\(_name)-loki"
							if len(loki.imagePullSecrets) > 0 {
								imagePullSecrets: loki.imagePullSecrets
							}
							if len(ingester.hostAliases) > 0 {
								hostAliases: ingester.hostAliases
							}
							if ingester.priorityClassName != "" {
								priorityClassName: ingester.priorityClassName
							}
							securityContext:               loki.loki.podSecurityContext
							terminationGracePeriodSeconds: ingester.terminationGracePeriodSeconds
							if len(ingester.initContainers) > 0 {
								initContainers: ingester.initContainers
							}
							containers: [{
								name:            "ingester"
								image:           lokiImage
								imagePullPolicy: loki.image.pullPolicy
								if loki.command != "" || ingester.command != "" {
									command: [[if ingester.command != "" {ingester.command}, loki.command][0]]
								}
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-ingester.availability-zone=zone-default",
									"-target=ingester",
								] + ingester.extraArgs
								ports: [
									{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
									{name: "grpc", containerPort: 9095, protocol: "TCP"},
									{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
								]
								if len(ingester.extraEnv) > 0 {
									env: ingester.extraEnv
								}
								if len(ingester.extraEnvFrom) > 0 {
									envFrom: ingester.extraEnvFrom
								}
								securityContext: loki.loki.containerSecurityContext
								readinessProbe:  loki.loki.readinessProbe
								livenessProbe:   loki.loki.livenessProbe
								volumeMounts: [
									{name: "config", mountPath: "/etc/loki/config"},
									{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
									{name: "data", mountPath: "/var/loki"},
									if loki.enterprise.enabled {
										{name: "license", mountPath: "/etc/loki/license"}
									},
									...ingester.extraVolumeMounts,
								]
								resources: ingester.resources
								if len(ingester.lifecycle) > 0 {
									lifecycle: ingester.lifecycle
								}
							}, ...ingester.extraContainers]
							if len(ingester.affinity) > 0 {
								affinity: ingester.affinity
							}
							nodeSelector: ingester.nodeSelector
							tolerations:  ingester.tolerations
							volumes: [
								{
									name: "config"
									configMap: {name: "\(_name)-loki-config"}
								},
								{
									name: "runtime-config"
									configMap: {name: "\(_name)-loki-runtime"}
								},
								if loki.enterprise.enabled {
									{
										name: "license"
										secret: secretName: [if loki.enterprise.useExternalLicense {loki.enterprise.externalLicenseName}, "enterprise-logs-license"][0]
									}
								},
							] + ingester.extraVolumes + [
								if !ingester.persistence.enabled {
									{name: "data", emptyDir: {}}
								},
								if ingester.persistence.inMemory {
									{
										name: "data"
										emptyDir: {
											medium: "Memory"
											if ingester.persistence.size != "" {
												sizeLimit: ingester.persistence.size
											}
										}
									}
								},
							]
						}
					}
					if ingester.persistence.enabled && !ingester.persistence.inMemory {
						volumeClaimTemplates: [
							for claim in ingester.persistence.claims {
								metadata: {
									name: claim.name
									if len(claim.annotations) > 0 {
										annotations: claim.annotations
									}
								}
								spec: {
									accessModes: ["ReadWriteOnce"]
									if claim.storageClass == "-" {
										storageClassName: ""
									}
									if claim.storageClass != "-" && claim.storageClass != null {
										storageClassName: claim.storageClass
									}
									resources: requests: storage: claim.size
								}
							},
						]
					}
				}
			}
		}

		// File 10: statefulset-ingester-zone-a.yaml
		if zoneAware.enabled && !zoneAware.migration.enabled {
			"statefulset-ingester-zone-a": appsv1.#StatefulSet & {
				apiVersion: "apps/v1"
				kind:       "StatefulSet"
				metadata: {
					name:      "\(_name)-loki-ingester-zone-a"
					namespace: ns
					labels: ingesterLabels & {
						"app.kubernetes.io/part-of": "memberlist"
						name:                        "ingester-zone-a"
						"rollout-group":             "ingester"
					}
					annotations: {
						"rollout-max-unavailable": "\([if (int(zoneReplicas * zoneAware.maxUnavailablePct / 100)) > 0 {int(zoneReplicas * zoneAware.maxUnavailablePct / 100)}, 1][0])"
						for k, v in loki.loki.annotations {"\(k)": v}
						for k, v in zoneAware.zoneA.annotations {"\(k)": v}
					}
				}
				spec: {
					if !ingester.autoscaling.enabled {
						replicas: zoneReplicas
					}
					podManagementPolicy: "Parallel"
					updateStrategy: type: "OnDelete"
					serviceName:          "\(_name)-loki-ingester-zone-a-headless"
					revisionHistoryLimit: loki.loki.revisionHistoryLimit
					if #config.clusterVersion.#Version >= "1.23.0" && ingester.persistence.enableStatefulSetAutoDeletePVC {
						persistentVolumeClaimRetentionPolicy: {
							whenDeleted: ingester.persistence.whenDeleted
							whenScaled:  ingester.persistence.whenScaled
						}
					}
					selector: matchLabels: ingesterSelectorLabels & {
						name:            "ingester-zone-a"
						"rollout-group": "ingester"
					}
					template: {
						metadata: {
							annotations: {
								"checksum/config": "config-checksum-placeholder"
								for k, v in loki.loki.podAnnotations {"\(k)": v}
								for k, v in ingester.podAnnotations {"\(k)": v}
								for k, v in zoneAware.zoneA.podAnnotations {"\(k)": v}
							}
							labels: ingesterSelectorLabels & {
								"app.kubernetes.io/part-of": "memberlist"
								name:                        "ingester-zone-a"
								"rollout-group":             "ingester"
								for k, v in loki.loki.podLabels {"\(k)": v}
								for k, v in ingester.podLabels {"\(k)": v}
							}
						}
						spec: {
							if #config.clusterVersion.#Version >= "1.19.0" {
								if len(ingester.topologySpreadConstraints) > 0 {
									topologySpreadConstraints: ingester.topologySpreadConstraints
								}
							}
							serviceAccountName: "\(_name)-loki"
							if len(loki.imagePullSecrets) > 0 {
								imagePullSecrets: loki.imagePullSecrets
							}
							if len(ingester.hostAliases) > 0 {
								hostAliases: ingester.hostAliases
							}
							if ingester.priorityClassName != "" {
								priorityClassName: ingester.priorityClassName
							}
							securityContext:               loki.loki.podSecurityContext
							terminationGracePeriodSeconds: ingester.terminationGracePeriodSeconds
							if len(ingester.initContainers) > 0 {
								initContainers: ingester.initContainers
							}
							containers: [{
								name:            "ingester"
								image:           lokiImage
								imagePullPolicy: loki.image.pullPolicy
								if loki.command != "" || ingester.command != "" {
									command: [[if ingester.command != "" {ingester.command}, loki.command][0]]
								}
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-ingester.availability-zone=zone-a",
									"-ingester.unregister-on-shutdown=false",
									"-ingester.tokens-file-path=/var/loki/ring-tokens",
									"-target=ingester",
								] + ingester.extraArgs
								ports: [
									{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
									{name: "grpc", containerPort: 9095, protocol: "TCP"},
									{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
								]
								if len(ingester.extraEnv) > 0 {
									env: ingester.extraEnv
								}
								if len(ingester.extraEnvFrom) > 0 {
									envFrom: ingester.extraEnvFrom
								}
								securityContext: loki.loki.containerSecurityContext
								readinessProbe:  loki.loki.readinessProbe
								livenessProbe:   loki.loki.livenessProbe
								volumeMounts: [
									{name: "config", mountPath: "/etc/loki/config"},
									{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
									{name: "data", mountPath: "/var/loki"},
									if loki.enterprise.enabled {
										{name: "license", mountPath: "/etc/loki/license"}
									},
									...ingester.extraVolumeMounts,
								]
								resources: ingester.resources
								if len(ingester.lifecycle) > 0 {
									lifecycle: ingester.lifecycle
								}
							}, ...ingester.extraContainers]
							affinity: {
								podAntiAffinity: requiredDuringSchedulingIgnoredDuringExecution: [{
									labelSelector: matchExpressions: [
										{key: "rollout-group", operator: "In", values: ["ingester"]},
										{key: "name", operator: "NotIn", values: ["ingester-zone-a"]},
									]
									topologyKey: "kubernetes.io/hostname"
								}]
								for k, v in zoneAware.zoneA.extraAffinity {
									"\(k)": v
								}
							}
							nodeSelector: zoneAware.zoneA.nodeSelector & ingester.nodeSelector
							tolerations:  zoneAware.zoneA.tolerations & ingester.tolerations
							volumes: [
								{
									name: "config"
									configMap: {name: "\(_name)-loki-config"}
								},
								{
									name: "runtime-config"
									configMap: {name: "\(_name)-loki-runtime"}
								},
								if loki.enterprise.enabled {
									{
										name: "license"
										secret: secretName: [if loki.enterprise.useExternalLicense {loki.enterprise.externalLicenseName}, "enterprise-logs-license"][0]
									}
								},
							] + ingester.extraVolumes + [
								if !ingester.persistence.enabled {
									{name: "data", emptyDir: {}}
								},
								if ingester.persistence.inMemory {
									{
										name: "data"
										emptyDir: {
											medium: "Memory"
											if ingester.persistence.size != "" {
												sizeLimit: ingester.persistence.size
											}
										}
									}
								},
							]
						}
					}
					if ingester.persistence.enabled && !ingester.persistence.inMemory {
						volumeClaimTemplates: [
							for claim in ingester.persistence.claims {
								metadata: {
									name: claim.name
									if len(claim.annotations) > 0 {
										annotations: claim.annotations
									}
								}
								spec: {
									accessModes: ["ReadWriteOnce"]
									if claim.storageClass == "-" {
										storageClassName: ""
									}
									if claim.storageClass != "-" && claim.storageClass != null {
										storageClassName: claim.storageClass
									}
									resources: requests: storage: claim.size
								}
							},
						]
					}
				}
			}
		}

		// File 11: statefulset-ingester-zone-b.yaml
		if zoneAware.enabled && !zoneAware.migration.enabled {
			"statefulset-ingester-zone-b": appsv1.#StatefulSet & {
				apiVersion: "apps/v1"
				kind:       "StatefulSet"
				metadata: {
					name:      "\(_name)-loki-ingester-zone-b"
					namespace: ns
					labels: ingesterLabels & {
						"app.kubernetes.io/part-of": "memberlist"
						name:                        "ingester-zone-b"
						"rollout-group":             "ingester"
					}
					annotations: {
						"rollout-max-unavailable": "\([if (int(zoneReplicas * zoneAware.maxUnavailablePct / 100)) > 0 {int(zoneReplicas * zoneAware.maxUnavailablePct / 100)}, 1][0])"
						for k, v in loki.loki.annotations {"\(k)": v}
						for k, v in zoneAware.zoneB.annotations {"\(k)": v}
					}
				}
				spec: {
					if !ingester.autoscaling.enabled {
						replicas: zoneReplicas
					}
					podManagementPolicy: "Parallel"
					updateStrategy: type: "OnDelete"
					serviceName:          "\(_name)-loki-ingester-zone-b-headless"
					revisionHistoryLimit: loki.loki.revisionHistoryLimit
					if #config.clusterVersion.#Version >= "1.23.0" && ingester.persistence.enableStatefulSetAutoDeletePVC {
						persistentVolumeClaimRetentionPolicy: {
							whenDeleted: ingester.persistence.whenDeleted
							whenScaled:  ingester.persistence.whenScaled
						}
					}
					selector: matchLabels: ingesterSelectorLabels & {
						name:            "ingester-zone-b"
						"rollout-group": "ingester"
					}
					template: {
						metadata: {
							annotations: {
								"checksum/config": "config-checksum-placeholder"
								for k, v in loki.loki.podAnnotations {"\(k)": v}
								for k, v in ingester.podAnnotations {"\(k)": v}
								for k, v in zoneAware.zoneB.podAnnotations {"\(k)": v}
							}
							labels: ingesterSelectorLabels & {
								"app.kubernetes.io/part-of": "memberlist"
								name:                        "ingester-zone-b"
								"rollout-group":             "ingester"
								for k, v in loki.loki.podLabels {"\(k)": v}
								for k, v in ingester.podLabels {"\(k)": v}
							}
						}
						spec: {
							if #config.clusterVersion.#Version >= "1.19.0" {
								if len(ingester.topologySpreadConstraints) > 0 {
									topologySpreadConstraints: ingester.topologySpreadConstraints
								}
							}
							serviceAccountName: "\(_name)-loki"
							if len(loki.imagePullSecrets) > 0 {
								imagePullSecrets: loki.imagePullSecrets
							}
							if len(ingester.hostAliases) > 0 {
								hostAliases: ingester.hostAliases
							}
							if ingester.priorityClassName != "" {
								priorityClassName: ingester.priorityClassName
							}
							securityContext:               loki.loki.podSecurityContext
							terminationGracePeriodSeconds: ingester.terminationGracePeriodSeconds
							if len(ingester.initContainers) > 0 {
								initContainers: ingester.initContainers
							}
							containers: [{
								name:            "ingester"
								image:           lokiImage
								imagePullPolicy: loki.image.pullPolicy
								if loki.command != "" || ingester.command != "" {
									command: [[if ingester.command != "" {ingester.command}, loki.command][0]]
								}
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-ingester.availability-zone=zone-b",
									"-ingester.unregister-on-shutdown=false",
									"-ingester.tokens-file-path=/var/loki/ring-tokens",
									"-target=ingester",
								] + ingester.extraArgs
								ports: [
									{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
									{name: "grpc", containerPort: 9095, protocol: "TCP"},
									{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
								]
								if len(ingester.extraEnv) > 0 {
									env: ingester.extraEnv
								}
								if len(ingester.extraEnvFrom) > 0 {
									envFrom: ingester.extraEnvFrom
								}
								securityContext: loki.loki.containerSecurityContext
								readinessProbe:  loki.loki.readinessProbe
								livenessProbe:   loki.loki.livenessProbe
								volumeMounts: [
									{name: "config", mountPath: "/etc/loki/config"},
									{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
									{name: "data", mountPath: "/var/loki"},
									if loki.enterprise.enabled {
										{name: "license", mountPath: "/etc/loki/license"}
									},
									...ingester.extraVolumeMounts,
								]
								resources: ingester.resources
								if len(ingester.lifecycle) > 0 {
									lifecycle: ingester.lifecycle
								}
							}, ...ingester.extraContainers]
							affinity: {
								podAntiAffinity: requiredDuringSchedulingIgnoredDuringExecution: [{
									labelSelector: matchExpressions: [
										{key: "rollout-group", operator: "In", values: ["ingester"]},
										{key: "name", operator: "NotIn", values: ["ingester-zone-b"]},
									]
									topologyKey: "kubernetes.io/hostname"
								}]
								for k, v in zoneAware.zoneB.extraAffinity {
									"\(k)": v
								}
							}
							nodeSelector: zoneAware.zoneB.nodeSelector & ingester.nodeSelector
							tolerations:  zoneAware.zoneB.tolerations & ingester.tolerations
							volumes: [
								{
									name: "config"
									configMap: {name: "\(_name)-loki-config"}
								},
								{
									name: "runtime-config"
									configMap: {name: "\(_name)-loki-runtime"}
								},
								if loki.enterprise.enabled {
									{
										name: "license"
										secret: secretName: [if loki.enterprise.useExternalLicense {loki.enterprise.externalLicenseName}, "enterprise-logs-license"][0]
									}
								},
							] + ingester.extraVolumes + [
								if !ingester.persistence.enabled {
									{name: "data", emptyDir: {}}
								},
								if ingester.persistence.inMemory {
									{
										name: "data"
										emptyDir: {
											medium: "Memory"
											if ingester.persistence.size != "" {
												sizeLimit: ingester.persistence.size
											}
										}
									}
								},
							]
						}
					}
					if ingester.persistence.enabled && !ingester.persistence.inMemory {
						volumeClaimTemplates: [
							for claim in ingester.persistence.claims {
								metadata: {
									name: claim.name
									if len(claim.annotations) > 0 {
										annotations: claim.annotations
									}
								}
								spec: {
									accessModes: ["ReadWriteOnce"]
									if claim.storageClass == "-" {
										storageClassName: ""
									}
									if claim.storageClass != "-" && claim.storageClass != null {
										storageClassName: claim.storageClass
									}
									resources: requests: storage: claim.size
								}
							},
						]
					}
				}
			}
		}

		// File 12: statefulset-ingester-zone-c.yaml
		if zoneAware.enabled && !zoneAware.migration.enabled {
			"statefulset-ingester-zone-c": appsv1.#StatefulSet & {
				apiVersion: "apps/v1"
				kind:       "StatefulSet"
				metadata: {
					name:      "\(_name)-loki-ingester-zone-c"
					namespace: ns
					labels: ingesterLabels & {
						"app.kubernetes.io/part-of": "memberlist"
						name:                        "ingester-zone-c"
						"rollout-group":             "ingester"
					}
					annotations: {
						"rollout-max-unavailable": "\([if (int(zoneReplicas * zoneAware.maxUnavailablePct / 100)) > 0 {int(zoneReplicas * zoneAware.maxUnavailablePct / 100)}, 1][0])"
						for k, v in loki.loki.annotations {"\(k)": v}
						for k, v in zoneAware.zoneC.annotations {"\(k)": v}
					}
				}
				spec: {
					if !ingester.autoscaling.enabled {
						replicas: zoneReplicas
					}
					podManagementPolicy: "Parallel"
					updateStrategy: type: "OnDelete"
					serviceName:          "\(_name)-loki-ingester-zone-c-headless"
					revisionHistoryLimit: loki.loki.revisionHistoryLimit
					if #config.clusterVersion.#Version >= "1.23.0" && ingester.persistence.enableStatefulSetAutoDeletePVC {
						persistentVolumeClaimRetentionPolicy: {
							whenDeleted: ingester.persistence.whenDeleted
							whenScaled:  ingester.persistence.whenScaled
						}
					}
					selector: matchLabels: ingesterSelectorLabels & {
						name:            "ingester-zone-c"
						"rollout-group": "ingester"
					}
					template: {
						metadata: {
							annotations: {
								"checksum/config": "config-checksum-placeholder"
								for k, v in loki.loki.podAnnotations {"\(k)": v}
								for k, v in ingester.podAnnotations {"\(k)": v}
								for k, v in zoneAware.zoneC.podAnnotations {"\(k)": v}
							}
							labels: ingesterSelectorLabels & {
								"app.kubernetes.io/part-of": "memberlist"
								name:                        "ingester-zone-c"
								"rollout-group":             "ingester"
								for k, v in loki.loki.podLabels {"\(k)": v}
								for k, v in ingester.podLabels {"\(k)": v}
							}
						}
						spec: {
							if #config.clusterVersion.#Version >= "1.19.0" {
								if len(ingester.topologySpreadConstraints) > 0 {
									topologySpreadConstraints: ingester.topologySpreadConstraints
								}
							}
							serviceAccountName: "\(_name)-loki"
							if len(loki.imagePullSecrets) > 0 {
								imagePullSecrets: loki.imagePullSecrets
							}
							if len(ingester.hostAliases) > 0 {
								hostAliases: ingester.hostAliases
							}
							if ingester.priorityClassName != "" {
								priorityClassName: ingester.priorityClassName
							}
							securityContext:               loki.loki.podSecurityContext
							terminationGracePeriodSeconds: ingester.terminationGracePeriodSeconds
							if len(ingester.initContainers) > 0 {
								initContainers: ingester.initContainers
							}
							containers: [{
								name:            "ingester"
								image:           lokiImage
								imagePullPolicy: loki.image.pullPolicy
								if loki.command != "" || ingester.command != "" {
									command: [[if ingester.command != "" {ingester.command}, loki.command][0]]
								}
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-ingester.availability-zone=zone-c",
									"-ingester.unregister-on-shutdown=false",
									"-ingester.tokens-file-path=/var/loki/ring-tokens",
									"-target=ingester",
								] + ingester.extraArgs
								ports: [
									{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
									{name: "grpc", containerPort: 9095, protocol: "TCP"},
									{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
								]
								if len(ingester.extraEnv) > 0 {
									env: ingester.extraEnv
								}
								if len(ingester.extraEnvFrom) > 0 {
									envFrom: ingester.extraEnvFrom
								}
								securityContext: loki.loki.containerSecurityContext
								readinessProbe:  loki.loki.readinessProbe
								livenessProbe:   loki.loki.livenessProbe
								volumeMounts: [
									{name: "config", mountPath: "/etc/loki/config"},
									{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
									{name: "data", mountPath: "/var/loki"},
									if loki.enterprise.enabled {
										{name: "license", mountPath: "/etc/loki/license"}
									},
									...ingester.extraVolumeMounts,
								]
								resources: ingester.resources
								if len(ingester.lifecycle) > 0 {
									lifecycle: ingester.lifecycle
								}
							}, ...ingester.extraContainers]
							affinity: {
								podAntiAffinity: requiredDuringSchedulingIgnoredDuringExecution: [{
									labelSelector: matchExpressions: [
										{key: "rollout-group", operator: "In", values: ["ingester"]},
										{key: "name", operator: "NotIn", values: ["ingester-zone-c"]},
									]
									topologyKey: "kubernetes.io/hostname"
								}]
								for k, v in zoneAware.zoneC.extraAffinity {
									"\(k)": v
								}
							}
							nodeSelector: zoneAware.zoneC.nodeSelector & ingester.nodeSelector
							tolerations:  zoneAware.zoneC.tolerations & ingester.tolerations
							volumes: [
								{
									name: "config"
									configMap: {name: "\(_name)-loki-config"}
								},
								{
									name: "runtime-config"
									configMap: {name: "\(_name)-loki-runtime"}
								},
								if loki.enterprise.enabled {
									{
										name: "license"
										secret: secretName: [if loki.enterprise.useExternalLicense {loki.enterprise.externalLicenseName}, "enterprise-logs-license"][0]
									}
								},
							] + ingester.extraVolumes + [
								if !ingester.persistence.enabled {
									{name: "data", emptyDir: {}}
								},
								if ingester.persistence.inMemory {
									{
										name: "data"
										emptyDir: {
											medium: "Memory"
											if ingester.persistence.size != "" {
												sizeLimit: ingester.persistence.size
											}
										}
									}
								},
							]
						}
					}
					if ingester.persistence.enabled && !ingester.persistence.inMemory {
						volumeClaimTemplates: [
							for claim in ingester.persistence.claims {
								metadata: {
									name: claim.name
									if len(claim.annotations) > 0 {
										annotations: claim.annotations
									}
								}
								spec: {
									accessModes: ["ReadWriteOnce"]
									if claim.storageClass == "-" {
										storageClassName: ""
									}
									if claim.storageClass != "-" && claim.storageClass != null {
										storageClassName: claim.storageClass
									}
									resources: requests: storage: claim.size
								}
							},
						]
					}
				}
			}
		}
	}
}
