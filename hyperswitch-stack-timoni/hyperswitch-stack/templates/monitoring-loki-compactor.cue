package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#LokiCompactorFullname: {
	#config: #Config
	result:  "\(#config.metadata.name)-loki-compactor"
}

#LokiCompactorLabels: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	result: loki.compactor.serviceLabels & {
		"helm.sh/chart":              "loki-5.36.2"
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": #config.metadata.name
		"app.kubernetes.io/version": [if loki.image.tag != "" {loki.image.tag}, #config.moduleVersion][0]
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/component":  "compactor"
	}
}

#LokiCompactorSelectorLabels: {
	#config: #Config
	result: {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  #config.metadata.name
		"app.kubernetes.io/component": "compactor"
	}
}

#LokiCompactorReadinessProbe: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	result: [if len(loki.compactor.readinessProbe) > 0 {loki.compactor.readinessProbe}, loki.loki.readinessProbe][0]
}

#LokiCompactorLivenessProbe: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	result: [if len(loki.compactor.livenessProbe) > 0 {loki.compactor.livenessProbe}, loki.loki.livenessProbe][0]
}

#LokiCompactorPriorityClassName: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	result: [if loki.global.priorityClassName != "" {loki.global.priorityClassName}, loki.compactor.priorityClassName][0]
}

#LokiCompactorServiceAccountName: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	let baseServiceAccountName = [if loki.serviceAccount.name != "" {loki.serviceAccount.name}, "loki"][0]
	result: string
	if loki.compactor.serviceAccount.create && loki.compactor.serviceAccount.name != "" {result: loki.compactor.serviceAccount.name}
	if loki.compactor.serviceAccount.create && loki.compactor.serviceAccount.name == "" {result: "\(baseServiceAccountName)-compactor"}
	if !loki.compactor.serviceAccount.create && loki.compactor.serviceAccount.name != "" {result: loki.compactor.serviceAccount.name}
	if !loki.compactor.serviceAccount.create && loki.compactor.serviceAccount.name == "" {result: baseServiceAccountName}
}

monitoringLokiCompactor: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	let ns = #config.metadata.namespace
	let compactorFullname = (#LokiCompactorFullname & {#config: #config}).result
	let compactorLabels = (#LokiCompactorLabels & {#config: #config}).result
	let compactorSelectorLabels = (#LokiCompactorSelectorLabels & {#config: #config}).result
	let compactorPriorityClassName = (#LokiCompactorPriorityClassName & {#config: #config}).result
	let lokiTag = [if loki.image.tag != "" {loki.image.tag}, #config.moduleVersion][0]
	let lokiImage = "\(loki.image.repository):\(lokiTag)"
	let configVolume = [if loki.loki.configStorageType == "Secret" {secret: secretName: loki.loki.generatedConfigObjectName}, {configMap: {name: loki.loki.generatedConfigObjectName}}][0]
	let isDistributed = loki.deploymentMode == "Distributed"

	if isDistributed {
		// 1. service-compactor.yaml
		"service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:        compactorFullname
				namespace:   ns
				labels:      compactorLabels
				annotations: loki.loki.serviceAnnotations & loki.compactor.serviceAnnotations
			}
			spec: {
				type: "ClusterIP"
				ports: [
					{
						name:       "http-metrics"
						port:       3100
						targetPort: "http-metrics"
						protocol:   "TCP"
					},
					{
						name:       "grpc"
						port:       9095
						targetPort: "grpc"
						protocol:   "TCP"
						if loki.compactor.appProtocol.grpc != "" {
							appProtocol: loki.compactor.appProtocol.grpc
						}
					},
				]
				selector: compactorSelectorLabels
			}
		}

		// 2. statefulset-compactor.yaml
		"statefulset": appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      compactorFullname
				namespace: ns
				labels: compactorLabels & {
					"app.kubernetes.io/part-of": "memberlist"
				}
				if len(loki.loki.annotations) > 0 {
					annotations: loki.loki.annotations
				}
			}
			spec: {
				replicas:            loki.compactor.replicas
				podManagementPolicy: "Parallel"
				updateStrategy: rollingUpdate: partition: 0
				serviceName:          "\(compactorFullname)-headless"
				revisionHistoryLimit: loki.loki.revisionHistoryLimit
				if loki.compactor.persistence.enableStatefulSetAutoDeletePVC {
					persistentVolumeClaimRetentionPolicy: {
						whenDeleted: loki.compactor.persistence.whenDeleted
						whenScaled:  loki.compactor.persistence.whenScaled
					}
				}
				selector: matchLabels: compactorSelectorLabels
				template: {
					metadata: {
						annotations: {
							"checksum/config": "TODO_SHA256"
							for key, value in loki.loki.podAnnotations {
								"\(key)": value
							}
							for key, value in loki.compactor.podAnnotations {
								"\(key)": value
							}
						}
						labels: compactorSelectorLabels & loki.loki.podLabels & loki.compactor.podLabels & {
							"app.kubernetes.io/part-of": "memberlist"
						}
					}
					spec: {
						if len(loki.compactor.topologySpreadConstraints) > 0 {
							topologySpreadConstraints: loki.compactor.topologySpreadConstraints
						}
						serviceAccountName: [if loki.compactor.serviceAccount.create {(#LokiCompactorServiceAccountName & {#config: #config}).result}, [if loki.serviceAccount.name != "" {loki.serviceAccount.name}, "loki"][0]][0]
						if len(loki.imagePullSecrets) > 0 {
							imagePullSecrets: loki.imagePullSecrets
						}
						if len(loki.compactor.hostAliases) > 0 {
							hostAliases: loki.compactor.hostAliases
						}
						if compactorPriorityClassName != "" {
							priorityClassName: compactorPriorityClassName
						}
						securityContext:               loki.loki.podSecurityContext
						terminationGracePeriodSeconds: loki.compactor.terminationGracePeriodSeconds
						if len(loki.compactor.initContainers) > 0 {
							initContainers: loki.compactor.initContainers
						}
						containers: [
							{
								name:            "compactor"
								image:           lokiImage
								imagePullPolicy: loki.image.pullPolicy
								if loki.command != "" || loki.compactor.command != "" {
									command: [[if loki.compactor.command != "" {loki.compactor.command}, loki.command][0]]
								}
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-target=compactor",
									for arg in loki.compactor.extraArgs {arg},
								]
								ports: [
									{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
									{name: "grpc", containerPort: 9095, protocol: "TCP"},
									{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
								]
								if len(loki.compactor.extraEnv) > 0 {
									env: loki.compactor.extraEnv
								}
								if len(loki.compactor.extraEnvFrom) > 0 {
									envFrom: loki.compactor.extraEnvFrom
								}
								securityContext: loki.loki.containerSecurityContext
								readinessProbe: (#LokiCompactorReadinessProbe & {#config: #config}).result
								livenessProbe: (#LokiCompactorLivenessProbe & {#config: #config}).result
								volumeMounts: [
									{name: "temp", mountPath: "/tmp"},
									{name: "config", mountPath: "/etc/loki/config"},
									{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
									{name: "data", mountPath: "/var/loki"},
									if loki.enterprise.enabled {name: "license", mountPath: "/etc/loki/license"},
									for volumeMount in loki.compactor.extraVolumeMounts {volumeMount},
								]
								if len(loki.compactor.resources) > 0 {
									resources: loki.compactor.resources
								}
								if len(loki.compactor.lifecycle) > 0 {
									lifecycle: loki.compactor.lifecycle
								}
							},
							for container in loki.compactor.extraContainers {container},
						]
						if len(loki.compactor.affinity) > 0 {
							affinity: loki.compactor.affinity
						}
						if len(loki.compactor.nodeSelector) > 0 {
							nodeSelector: loki.compactor.nodeSelector
						}
						if len(loki.compactor.tolerations) > 0 {
							tolerations: loki.compactor.tolerations
						}
						volumes: [
							{name: "temp", emptyDir: {}},
							{name: "config", configVolume},
							{name: "runtime-config", configMap: {name: "loki-runtime"}},
							if loki.enterprise.enabled {
								name: "license"
								secret: secretName: [if loki.enterprise.useExternalLicense {loki.enterprise.externalLicenseName}, "enterprise-logs-license"][0]
							},
							if !loki.compactor.persistence.enabled {name: "data", emptyDir: {}},
							for volume in loki.compactor.extraVolumes {volume},
						]
					}
				}
				if loki.compactor.persistence.enabled {
					volumeClaimTemplates: [
						for claim in loki.compactor.persistence.claims {
							{
								metadata: {
									name: claim.name
									if len(claim.annotations) > 0 {
										annotations: claim.annotations
									}
								}
								spec: {
									accessModes: ["ReadWriteOnce"]
									if claim.storageClass != null {
										storageClassName: [if claim.storageClass == "-" {""}, claim.storageClass][0]
									}
									resources: requests: storage: claim.size
								}
							}
						},
					]
				}
			}
		}
	}
}
