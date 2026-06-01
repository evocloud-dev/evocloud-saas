package templates

monitoringLokiWrite: {
	#loki:     _
	#write:    _
	#metadata: _

	let ns = #metadata.namespace
	let _name = #metadata.name
	let fullname = "\(_name)-loki-write"
	let isSimpleScalable = #loki.deploymentMode == "SimpleScalable"

	let commonLabels = {
		for k, v in #metadata.labels if k != "app.kubernetes.io/name" && k != "app.kubernetes.io/instance" && k != "app.kubernetes.io/version" && k != "app.kubernetes.io/component" && k != "app.kubernetes.io/managed-by" {
			"\(k)": v
		}
		"helm.sh/chart":                "loki-5.36.2"
		"app.kubernetes.io/name":       "loki"
		"app.kubernetes.io/instance":   _name
		"app.kubernetes.io/version":    #loki.image.tag
		"app.kubernetes.io/component":  "write"
		"app.kubernetes.io/managed-by": "timoni"
	}

	let selectorLabels = {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  _name
		"app.kubernetes.io/component": "write"
	}

	if isSimpleScalable {
		// File 1: statefulset-write.yaml
		"statefulset": {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      fullname
				namespace: ns
				labels: commonLabels & {"app.kubernetes.io/part-of": "memberlist"}
				if len(#loki.loki.annotations) > 0 || len(#write.annotations) > 0 {
					annotations: {
						for k, v in #loki.loki.annotations {"\(k)": v}
						for k, v in #write.annotations {"\(k)": v}
					}
				}
			}
			spec: {
				if !#write.autoscaling.enabled {
					replicas: #write.replicas
				}
				podManagementPolicy: #write.podManagementPolicy
				updateStrategy: rollingUpdate: partition: 0
				serviceName:          "\(fullname)-headless"
				revisionHistoryLimit: #loki.loki.revisionHistoryLimit
				selector: matchLabels: selectorLabels
				template: {
					metadata: {
						annotations: {
							"checksum/config": "config-checksum-placeholder"
							for k, v in #loki.loki.podAnnotations {"\(k)": v}
							for k, v in #write.podAnnotations {"\(k)": v}
						}
						labels: selectorLabels & {
							"app.kubernetes.io/part-of": "memberlist"
							for k, v in #loki.loki.podLabels {"\(k)": v}
							for k, v in #write.podLabels {"\(k)": v}
						}
					}
					spec: {
						serviceAccountName: "\(_name)-loki"
						if #write.priorityClassName != "" {
							priorityClassName: #write.priorityClassName
						}
						securityContext:               #loki.loki.podSecurityContext
						terminationGracePeriodSeconds: #write.terminationGracePeriodSeconds
						if len(#write.initContainers) > 0 {
							initContainers: #write.initContainers
						}
						containers: [
							{
								name:            "loki"
								image:           "\(#loki.image.repository):\(#loki.image.tag)"
								imagePullPolicy: #loki.image.pullPolicy
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-target=\(#write.targetModule)",
									for arg in #write.extraArgs {arg},
								]
								ports: [
									{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
									{name: "grpc", containerPort: 9095, protocol: "TCP"},
									{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
								]
								if len(#write.extraEnv) > 0 {
									env: #write.extraEnv
								}
								if len(#write.extraEnvFrom) > 0 {
									envFrom: #write.extraEnvFrom
								}
								securityContext: #loki.loki.containerSecurityContext
								readinessProbe:  #loki.loki.readinessProbe
								if len(#write.lifecycle) > 0 {
									lifecycle: #write.lifecycle
								}
								if len(#write.lifecycle) == 0 && #write.autoscaling.enabled {
									lifecycle: preStop: httpGet: {
										path: "/ingester/shutdown?terminate=false"
										port: "http-metrics"
									}
								}
								volumeMounts: [
									{name: "config", mountPath: "/etc/loki/config"},
									{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
									{name: "data", mountPath: "/var/loki"},
									for vm in #write.extraVolumeMounts {vm},
								]
								resources: #write.resources
							},
						]
						if len(#write.extraContainers) > 0 {
							containers: containers + #write.extraContainers
						}
						if len(#write.affinity) > 0 {
							affinity: #write.affinity
						}
						nodeSelector: #write.nodeSelector
						if len(#write.topologySpreadConstraints) > 0 {
							topologySpreadConstraints: #write.topologySpreadConstraints
						}
						tolerations: #write.tolerations
						volumes: [
							{name: "config", configMap: {name: "\(_name)-loki-config"}},
							{name: "runtime-config", configMap: {name: "\(_name)-loki-runtime"}},
							if !#write.persistence.volumeClaimsEnabled {
								{
									name: "data"
									for k, v in #write.persistence.dataVolumeParameters {"\(k)": v}
								}
							},
							for v in #write.extraVolumes {v},
						]
					}
				}
				if #write.persistence.volumeClaimsEnabled {
					volumeClaimTemplates: [
						{
							apiVersion: "v1"
							kind:       "PersistentVolumeClaim"
							metadata: {
								name: "data"
								if len(#write.persistence.annotations) > 0 {
									annotations: #write.persistence.annotations
								}
							}
							spec: {
								accessModes: ["ReadWriteOnce"]
								if #write.persistence.storageClass != null {
									storageClassName: [if #write.persistence.storageClass == "-" {""}, #write.persistence.storageClass][0]
								}
								resources: requests: storage: #write.persistence.size
								if len(#write.persistence.selector) > 0 {
									selector: #write.persistence.selector
								}
							}
						},
						for vct in #write.extraVolumeClaimTemplates {vct},
					]
				}
			}
		}

		// File 2: service-write.yaml
		"service": {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      fullname
				namespace: ns
				labels:    commonLabels
			}
			spec: {
				type: "ClusterIP"
				ports: [
					{name: "http-metrics", port: 3100, targetPort: "http-metrics", protocol: "TCP"},
					{name: "grpc", port: 9095, targetPort: "grpc", protocol: "TCP"},
				]
				selector: selectorLabels
			}
		}

		// File 3: service-write-headless.yaml
		"service-headless": {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(fullname)-headless"
				namespace: ns
				labels: commonLabels & {"service.kausal.co/type": "nodes"}
			}
			spec: {
				type:                     "ClusterIP"
				clusterIP:                "None"
				publishNotReadyAddresses: true
				ports: [
					{name: "http-metrics", port: 3100, targetPort: "http-metrics", protocol: "TCP"},
					{name: "grpc", port: 9095, targetPort: "grpc", protocol: "TCP"},
				]
				selector: selectorLabels
			}
		}

		// File 4: poddisruptionbudget-write.yaml
		if !#write.autoscaling.enabled && #write.replicas > 1 {
			"poddisruptionbudget": {
				apiVersion: "policy/v1"
				kind:       "PodDisruptionBudget"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					selector: matchLabels: selectorLabels
					maxUnavailable: 1
				}
			}
		}

		// File 5: hpa.yaml
		if #write.autoscaling.enabled {
			"hpa": {
				apiVersion: "autoscaling/v2"
				kind:       "HorizontalPodAutoscaler"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					scaleTargetRef: {
						apiVersion: "apps/v1"
						kind:       "StatefulSet"
						name:       fullname
					}
					minReplicas: #write.autoscaling.minReplicas
					maxReplicas: #write.autoscaling.maxReplicas
					metrics: [
						if #write.autoscaling.targetMemoryUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "memory"
									target: {type: "Utilization", averageUtilization: #write.autoscaling.targetMemoryUtilizationPercentage}
								}
							}
						},
						if #write.autoscaling.targetCPUUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "cpu"
									target: {type: "Utilization", averageUtilization: #write.autoscaling.targetCPUUtilizationPercentage}
								}
							}
						},
					]
				}
			}
		}
	}
}
