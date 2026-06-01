package templates

monitoringLokiRead: {
	#loki:     _
	#read:     _
	#metadata: _

	let ns = #metadata.namespace
	let _name = #metadata.name
	let fullname = "\(_name)-loki-read"
	let isSimpleScalable = #loki.deploymentMode == "SimpleScalable"

	let commonLabels = {
		for k, v in #metadata.labels if k != "app.kubernetes.io/name" && k != "app.kubernetes.io/instance" && k != "app.kubernetes.io/version" && k != "app.kubernetes.io/component" && k != "app.kubernetes.io/managed-by" {
			"\(k)": v
		}
		"helm.sh/chart":                "loki-5.36.2"
		"app.kubernetes.io/name":       "loki"
		"app.kubernetes.io/instance":   _name
		"app.kubernetes.io/version":    #loki.image.tag
		"app.kubernetes.io/component":  "read"
		"app.kubernetes.io/managed-by": "timoni"
	}

	let selectorLabels = {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  _name
		"app.kubernetes.io/component": "read"
	}

	let podAnnotations = {
		"checksum/config": "config-checksum-placeholder"
		for k, v in #loki.loki.podAnnotations {"\(k)": v}
		for k, v in #read.podAnnotations {"\(k)": v}
	}

	let podLabels = {
		for k, v in selectorLabels {"\(k)": v}
		"app.kubernetes.io/part-of": "memberlist"
		for k, v in #loki.loki.podLabels {"\(k)": v}
		for k, v in #read.podLabels {"\(k)": v}
	}

	if isSimpleScalable && !#read.legacyReadTarget {
		if !#read.persistence.enabled {
			// File 1: deployment-read.yaml
			"deployment": {
				apiVersion: "apps/v1"
				kind:       "Deployment"
				metadata: {
					name:      fullname
					namespace: ns
					labels: commonLabels & {"app.kubernetes.io/part-of": "memberlist"}
					if len(#loki.loki.annotations) > 0 || len(#read.annotations) > 0 {
						annotations: {
							for k, v in #loki.loki.annotations {"\(k)": v}
							for k, v in #read.annotations {"\(k)": v}
						}
					}
				}
				spec: {
					if !#read.autoscaling.enabled {
						replicas: #read.replicas
					}
					strategy: {
						rollingUpdate: {
							maxSurge:       0
							maxUnavailable: 1
						}
					}
					revisionHistoryLimit: #loki.loki.revisionHistoryLimit
					selector: matchLabels: selectorLabels
					template: {
						metadata: {
							annotations: podAnnotations
							labels:      podLabels
						}
						spec: {
							serviceAccountName:           "\(_name)-loki"
							automountServiceAccountToken: true
							if #read.priorityClassName != null {
								priorityClassName: #read.priorityClassName
							}
							securityContext:               #loki.loki.podSecurityContext
							terminationGracePeriodSeconds: #read.terminationGracePeriodSeconds
							containers: [
								{
									name:            "loki"
									image:           "\(#loki.image.repository):\(#loki.image.tag)"
									imagePullPolicy: #loki.image.pullPolicy
									args: [
										"-config.file=/etc/loki/config/config.yaml",
										"-target=\(#read.targetModule)",
										"-legacy-read-mode=false",
										for arg in #read.extraArgs {arg},
									]
									ports: [
										{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
										{name: "grpc", containerPort: 9095, protocol: "TCP"},
										{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
									]
									if len(#read.extraEnv) > 0 {
										env: #read.extraEnv
									}
									if len(#read.extraEnvFrom) > 0 {
										envFrom: #read.extraEnvFrom
									}
									securityContext: #loki.loki.containerSecurityContext
									readinessProbe:  #loki.loki.readinessProbe
									volumeMounts: [
										{name: "config", mountPath: "/etc/loki/config"},
										{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
										{name: "tmp", mountPath: "/tmp"},
										{name: "data", mountPath: "/var/loki"},
										for vm in #read.extraVolumeMounts {vm},
									]
									resources: #read.resources
								},
							]
							if len(#read.affinity) > 0 {
								affinity: #read.affinity
							}
							nodeSelector: #read.nodeSelector
							tolerations:  #read.tolerations
							volumes: [
								{name: "tmp", emptyDir: {}},
								{name: "data", emptyDir: {}},
								{name: "config", configMap: {name: "\(_name)-loki-config"}},
								{name: "runtime-config", configMap: {name: "\(_name)-loki-runtime"}},
								for v in #read.extraVolumes {v},
							]
						}
					}
				}
			}
		}

		if #read.persistence.enabled {
			// File 2: statefulset-read.yaml
			"statefulset": {
				apiVersion: "apps/v1"
				kind:       "StatefulSet"
				metadata: {
					name:      fullname
					namespace: ns
					labels: commonLabels & {"app.kubernetes.io/part-of": "memberlist"}
					if len(#loki.loki.annotations) > 0 || len(#read.annotations) > 0 {
						annotations: {
							for k, v in #loki.loki.annotations {"\(k)": v}
							for k, v in #read.annotations {"\(k)": v}
						}
					}
				}
				spec: {
					if !#read.autoscaling.enabled {
						replicas: #read.replicas
					}
					serviceName:          "\(fullname)-headless"
					revisionHistoryLimit: #loki.loki.revisionHistoryLimit
					selector: matchLabels: selectorLabels
					template: {
						metadata: {
							annotations: podAnnotations
							labels:      podLabels
						}
						spec: {
							serviceAccountName:           "\(_name)-loki"
							automountServiceAccountToken: true
							if #read.priorityClassName != null {
								priorityClassName: #read.priorityClassName
							}
							securityContext:               #loki.loki.podSecurityContext
							terminationGracePeriodSeconds: #read.terminationGracePeriodSeconds
							containers: [
								{
									name:            "loki"
									image:           "\(#loki.image.repository):\(#loki.image.tag)"
									imagePullPolicy: #loki.image.pullPolicy
									args: [
										"-config.file=/etc/loki/config/config.yaml",
										"-target=\(#read.targetModule)",
										"-legacy-read-mode=false",
										for arg in #read.extraArgs {arg},
									]
									ports: [
										{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
										{name: "grpc", containerPort: 9095, protocol: "TCP"},
										{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
									]
									if len(#read.extraEnv) > 0 {
										env: #read.extraEnv
									}
									if len(#read.extraEnvFrom) > 0 {
										envFrom: #read.extraEnvFrom
									}
									securityContext: #loki.loki.containerSecurityContext
									readinessProbe:  #loki.loki.readinessProbe
									volumeMounts: [
										{name: "config", mountPath: "/etc/loki/config"},
										{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
										{name: "tmp", mountPath: "/tmp"},
										{name: "data", mountPath: "/var/loki"},
										for vm in #read.extraVolumeMounts {vm},
									]
									resources: #read.resources
								},
							]
							if len(#read.affinity) > 0 {
								affinity: #read.affinity
							}
							nodeSelector: #read.nodeSelector
							tolerations:  #read.tolerations
							volumes: [
								{name: "tmp", emptyDir: {}},
								{name: "config", configMap: {name: "\(_name)-loki-config"}},
								{name: "runtime-config", configMap: {name: "\(_name)-loki-runtime"}},
								for v in #read.extraVolumes {v},
							]
						}
					}
					volumeClaimTemplates: [
						{
							metadata: name: "data"
							spec: {
								accessModes: ["ReadWriteOnce"]
								if #read.persistence.storageClass != null {
									storageClassName: #read.persistence.storageClass
								}
								resources: requests: storage: #read.persistence.size
							}
						},
					]
				}
			}
		}

		// File 3: hpa.yaml
		if #read.autoscaling.enabled {
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
						kind: [if #read.persistence.enabled {"StatefulSet"}, {"Deployment"}][0]
						name: fullname
					}
					minReplicas: #read.autoscaling.minReplicas
					maxReplicas: #read.autoscaling.maxReplicas
					metrics: [
						if #read.autoscaling.targetCPUUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "cpu"
									target: {type: "Utilization", averageUtilization: #read.autoscaling.targetCPUUtilizationPercentage}
								}
							}
						},
						if #read.autoscaling.targetMemoryUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "memory"
									target: {type: "Utilization", averageUtilization: #read.autoscaling.targetMemoryUtilizationPercentage}
								}
							}
						},
					]
				}
			}
		}

		// File 4: poddisruptionbudget-read.yaml
		if #read.replicas > 1 {
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

		// File 5: service-read.yaml
		"service": {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:        fullname
				namespace:   ns
				labels:      commonLabels & #read.serviceLabels
				annotations: #loki.loki.serviceAnnotations & #read.serviceAnnotations
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

		// File 6: service-read-headless.yaml
		"service-headless": {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(fullname)-headless"
				namespace: ns
				labels:    commonLabels
			}
			spec: {
				type:      "ClusterIP"
				clusterIP: "None"
				ports: [
					{name: "http-metrics", port: 3100, targetPort: "http-metrics", protocol: "TCP"},
					{name: "grpc", port: 9095, targetPort: "grpc", protocol: "TCP"},
				]
				selector: selectorLabels
			}
		}
	}
}
