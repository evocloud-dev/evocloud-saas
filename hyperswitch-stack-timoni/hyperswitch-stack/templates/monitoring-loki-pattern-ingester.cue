package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

monitoringLokiPatternIngester: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	let patternIngester = loki.patternIngester
	let ns = #config.metadata.namespace
	let _name = #config.metadata.name
	let modVersion = #config.moduleVersion
	let globalPriority = #config.global.priorityClassName
	let clusterVer = #config.clusterVersion.#Version

	let commonLabels = {
		"helm.sh/chart":              "loki-5.36.2"
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": _name
		"app.kubernetes.io/version": [if loki.image.tag != null {loki.image.tag}, modVersion][0]
		"app.kubernetes.io/component":  "pattern-ingester"
		"app.kubernetes.io/managed-by": "timoni"
	}

	let commonSelectorLabels = {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  _name
		"app.kubernetes.io/component": "pattern-ingester"
	}

	// File 1: statefulset-pattern-ingester.yaml
	if patternIngester.replicas > 0 {
		"statefulset": appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "\(_name)-loki-pattern-ingester"
				namespace: ns
				labels:    commonLabels
				if len(loki.loki.annotations) > 0 {
					annotations: loki.loki.annotations
				}
			}
			spec: {
				replicas:            patternIngester.replicas
				podManagementPolicy: "Parallel"
				updateStrategy: rollingUpdate: partition: 0
				serviceName:          "\(_name)-loki-pattern-ingester-headless"
				revisionHistoryLimit: loki.loki.revisionHistoryLimit

				if clusterVer >= "1.23.0" && patternIngester.persistence.enableStatefulSetAutoDeletePVC {
					persistentVolumeClaimRetentionPolicy: {
						whenDeleted: patternIngester.persistence.whenDeleted
						whenScaled:  patternIngester.persistence.whenScaled
					}
				}

				selector: matchLabels: commonSelectorLabels
				template: {
					metadata: {
						annotations: {
							"checksum/config": "fake-checksum"
							for k, v in loki.loki.podAnnotations {"\(k)": v}
							for k, v in patternIngester.podAnnotations {"\(k)": v}
						}
						labels: commonSelectorLabels & {
							"app.kubernetes.io/part-of": "memberlist"
							for k, v in loki.loki.podLabels {"\(k)": v}
							for k, v in patternIngester.podLabels {"\(k)": v}
						}
					}
					spec: {
						serviceAccountName: "\(_name)-loki"
						if len(loki.imagePullSecrets) > 0 {
							imagePullSecrets: loki.imagePullSecrets
						}
						if len(patternIngester.hostAliases) > 0 {
							hostAliases: patternIngester.hostAliases
						}

						// Priority Class Logic
						if patternIngester.priorityClassName != null {
							priorityClassName: patternIngester.priorityClassName
						}
						if globalPriority != "" {
							priorityClassName: globalPriority
						}

						securityContext:               loki.loki.podSecurityContext
						terminationGracePeriodSeconds: patternIngester.terminationGracePeriodSeconds

						if len(patternIngester.initContainers) > 0 {
							initContainers: patternIngester.initContainers
						}

						containers: [
							{
								name:            "pattern-ingester"
								image:           "\(loki.image.repository):\(loki.image.tag)"
								imagePullPolicy: loki.image.pullPolicy

								if patternIngester.command != null || loki.loki.command != null {
									command: [[if patternIngester.command != null {patternIngester.command}, loki.loki.command][0]]
								}

								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-target=pattern-ingester",
									for a in patternIngester.extraArgs {a},
								]
								ports: [
									{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
									{name: "grpc", containerPort: 9095, protocol: "TCP"},
									{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
								]
								if len(patternIngester.extraEnv) > 0 {
									env: patternIngester.extraEnv
								}
								if len(patternIngester.extraEnvFrom) > 0 {
									envFrom: patternIngester.extraEnvFrom
								}
								securityContext: loki.loki.containerSecurityContext

								if patternIngester.readinessProbe != null {
									readinessProbe: patternIngester.readinessProbe
								}
								if patternIngester.readinessProbe == null {
									readinessProbe: loki.loki.readinessProbe
								}

								volumeMounts: [
									{name: "temp", mountPath: "/tmp"},
									{name: "config", mountPath: "/etc/loki/config"},
									{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
									{name: "data", mountPath: "/var/loki"},
									for vm in patternIngester.extraVolumeMounts {vm},
								]
								if len(patternIngester.resources) > 0 {
									resources: patternIngester.resources
								}
							},
							for c in patternIngester.extraContainers {c},
						]
						if len(patternIngester.affinity) > 0 {
							affinity: patternIngester.affinity
						}
						if len(patternIngester.nodeSelector) > 0 {
							nodeSelector: patternIngester.nodeSelector
						}
						if len(patternIngester.tolerations) > 0 {
							tolerations: patternIngester.tolerations
						}
						volumes: [
							{name: "temp", emptyDir: {}},
							{
								name: "config"
								secret: secretName: "\(_name)-loki-config"
							},
							{
								name: "runtime-config"
								configMap: name: "\(_name)-loki-runtime"
							},
							if !patternIngester.persistence.enabled {
								{name: "data", emptyDir: {}}
							},
							for v in patternIngester.extraVolumes {v},
						]
					}
				}
				if patternIngester.persistence.enabled {
					volumeClaimTemplates: [
						for c in patternIngester.persistence.claims {
							metadata: {
								name: c.name
								if len(c.annotations) > 0 {
									annotations: c.annotations
								}
							}
							spec: {
								accessModes: ["ReadWriteOnce"]
								if c.storageClass != _|_ {
									storageClassName: [if c.storageClass == "-" {""}, c.storageClass][0]
								}
								resources: requests: storage: c.size
							}
						},
					]
				}
			}
		}
	}
}
