package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

monitoringLokiIndexGateway: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	let indexGateway = loki.indexGateway
	let ns = #config.metadata.namespace
	let _name = #config.metadata.name
	let clusterVer = #config.clusterVersion.#Version
	let metadataLabels = #config.metadata.labels

	if loki.enabled && loki.deploymentMode == "Distributed" {
		let indexGatewayLabels = {
			"helm.sh/chart":                "loki-5.36.2"
			"app.kubernetes.io/name":       "loki"
			"app.kubernetes.io/instance":   _name
			"app.kubernetes.io/version":    loki.image.tag
			"app.kubernetes.io/component":  "index-gateway"
			"app.kubernetes.io/managed-by": "timoni"
			for k, v in metadataLabels {
				"\(k)": v
			}
			for k, v in loki.commonLabels {
				"\(k)": v
			}
		}

		let indexGatewaySelectorLabels = {
			"app.kubernetes.io/name":      "loki"
			"app.kubernetes.io/instance":  _name
			"app.kubernetes.io/component": "index-gateway"
			"app.kubernetes.io/part-of":   "loki"
		}

		// File 1: statefulset-index-gateway.yaml
		"statefulset-index-gateway": appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "\(_name)-loki-index-gateway"
				namespace: ns
				labels:    indexGatewayLabels
				if len(loki.loki.annotations) > 0 {
					annotations: loki.loki.annotations
				}
			}
			spec: {
				replicas: indexGateway.replicas
				updateStrategy: {
					rollingUpdate: partition: 0
				}
				serviceName:          "\(_name)-loki-index-gateway-headless"
				revisionHistoryLimit: loki.loki.revisionHistoryLimit
				if clusterVer >= "1.23.0" && indexGateway.persistence.enableStatefulSetAutoDeletePVC {
					persistentVolumeClaimRetentionPolicy: {
						whenDeleted: indexGateway.persistence.whenDeleted
						whenScaled:  indexGateway.persistence.whenScaled
					}
				}
				selector: matchLabels: indexGatewaySelectorLabels
				template: {
					metadata: {
						annotations: {
							"checksum/config": "config-checksum-placeholder"
							for k, v in loki.loki.podAnnotations {
								"\(k)": v
							}
							for k, v in indexGateway.podAnnotations {
								"\(k)": v
							}
						}
						labels: indexGatewaySelectorLabels & {
							for k, v in loki.loki.podLabels {
								"\(k)": v
							}
							for k, v in indexGateway.podLabels {
								"\(k)": v
							}
							if indexGateway.joinMemberlist {
								"app.kubernetes.io/part-of": "memberlist"
							}
						}
					}
					spec: {
						serviceAccountName: "\(_name)-loki"
						if len(loki.imagePullSecrets) > 0 {
							imagePullSecrets: loki.imagePullSecrets
						}
						if len(indexGateway.hostAliases) > 0 {
							hostAliases: indexGateway.hostAliases
						}
						if indexGateway.priorityClassName != "" {
							priorityClassName: indexGateway.priorityClassName
						}
						securityContext:               loki.loki.podSecurityContext
						terminationGracePeriodSeconds: indexGateway.terminationGracePeriodSeconds
						if len(indexGateway.initContainers) > 0 {
							initContainers: indexGateway.initContainers
						}
						containers: [
							{
								name:            "index-gateway"
								image:           "\(loki.image.registry)/\(loki.image.repository):\(loki.image.tag)"
								imagePullPolicy: loki.image.pullPolicy
								if loki.command != "" || indexGateway.command != "" {
									command: [[if indexGateway.command != "" {indexGateway.command}, loki.command][0]]
								}
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-target=index-gateway",
								] + indexGateway.extraArgs
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
									if indexGateway.joinMemberlist {
										{
											name:          "http-memberlist"
											containerPort: 7946
											protocol:      "TCP"
										}
									},
								]
								if len(indexGateway.extraEnv) > 0 {
									env: indexGateway.extraEnv
								}
								if len(indexGateway.extraEnvFrom) > 0 {
									envFrom: indexGateway.extraEnvFrom
								}
								securityContext: loki.loki.containerSecurityContext
								readinessProbe:  indexGateway.readinessProbe
								livenessProbe:   indexGateway.livenessProbe
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
										name:      "data"
										mountPath: "/var/loki"
									},
									if loki.enterprise.enabled {
										{
											name:      "license"
											mountPath: "/etc/loki/license"
										}
									},
									...indexGateway.extraVolumeMounts,
								]
								resources: indexGateway.resources
								if len(indexGateway.lifecycle) > 0 {
									lifecycle: indexGateway.lifecycle
								}
							},
						]
						if len(indexGateway.extraContainers) > 0 {
							containers: indexGateway.extraContainers
						}
						affinity:     indexGateway.affinity
						nodeSelector: indexGateway.nodeSelector
						tolerations:  indexGateway.tolerations
						if len(indexGateway.topologySpreadConstraints) > 0 {
							topologySpreadConstraints: indexGateway.topologySpreadConstraints
						}
						volumes: [
							{
								name: "config"
								configMap: name: "\(_name)-loki-config"
							},
							{
								name: "runtime-config"
								configMap: name: "\(_name)-loki-runtime"
							},
							if loki.enterprise.enabled {
								{
									name: "license"
									secret: secretName: [if loki.enterprise.useExternalLicense {loki.enterprise.externalLicenseName}, "enterprise-logs-license"][0]
								}
							},
						] + indexGateway.extraVolumes + [
							if !indexGateway.persistence.enabled {
								{
									name: "data"
									emptyDir: {}
								}
							},
							if indexGateway.persistence.inMemory {
								{
									name: "data"
									emptyDir: {
										medium: "Memory"
										if indexGateway.persistence.size != "" {
											sizeLimit: indexGateway.persistence.size
										}
									}
								}
							},
						]
					}
				}
				if indexGateway.persistence.enabled && !indexGateway.persistence.inMemory {
					volumeClaimTemplates: [
						{
							metadata: {
								name: "data"
								if len(indexGateway.persistence.annotations) > 0 {
									annotations: indexGateway.persistence.annotations
								}
								if len(indexGateway.persistence.labels) > 0 {
									labels: indexGateway.persistence.labels
								}
							}
							spec: {
								accessModes: indexGateway.persistence.accessModes
								if indexGateway.persistence.storageClass != "" {
									storageClassName: indexGateway.persistence.storageClass
								}
								resources: requests: storage: indexGateway.persistence.size
							}
						},
					]
				}
			}
		}

		// File 2: service-index-gateway-headless.yaml
		"service-index-gateway-headless": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(_name)-loki-index-gateway-headless"
				namespace: ns
				labels: indexGatewaySelectorLabels & {
					variant:                         "headless"
					"prometheus.io/service-monitor": "false"
				}
				annotations: loki.loki.serviceAnnotations & indexGateway.serviceAnnotations
			}
			spec: {
				type:      "ClusterIP"
				clusterIP: "None"
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
						if indexGateway.appProtocol.grpc != "" {
							appProtocol: indexGateway.appProtocol.grpc
						}
					},
				]
				selector: indexGatewaySelectorLabels
			}
		}

		// File 3: service-index-gateway.yaml
		"service-index-gateway": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:        "\(_name)-loki-index-gateway"
				namespace:   ns
				labels:      indexGatewayLabels & indexGateway.serviceLabels
				annotations: loki.loki.serviceAnnotations & indexGateway.serviceAnnotations
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
						if indexGateway.appProtocol.grpc != "" {
							appProtocol: indexGateway.appProtocol.grpc
						}
					},
				]
				selector: indexGatewaySelectorLabels
			}
		}

		// File 4: poddisruptionbudget-index-gateway.yaml
		if indexGateway.replicas > 1 && indexGateway.maxUnavailable != null {
			"poddisruptionbudget-index-gateway": policyv1.#PodDisruptionBudget & {
				if clusterVer >= "1.21.0" {
					apiVersion: "policy/v1"
				}
				if clusterVer < "1.21.0" {
					apiVersion: "policy/v1beta1"
				}
				kind: "PodDisruptionBudget"
				metadata: {
					name:      "\(_name)-loki-index-gateway"
					namespace: ns
					labels:    indexGatewayLabels
				}
				spec: {
					selector: matchLabels: indexGatewaySelectorLabels
					maxUnavailable: indexGateway.maxUnavailable
				}
			}
		}
	}
}
