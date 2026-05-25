package templates

monitoringLokiSingleBinary: {
	#loki:         _
	#singleBinary: _
	#metadata:     _

	let ns = #metadata.namespace
	let _name = #metadata.name
	let fullname = "\(_name)-loki"
	let isSingleBinary = #loki.deploymentMode == "SingleBinary"
	let imageTag = #loki.image.tag
	let imageRepo = #loki.image.repository
	let pullPolicy = #loki.image.pullPolicy

	let commonLabels = {
		for k, v in #metadata.labels if k != "app.kubernetes.io/name" && k != "app.kubernetes.io/instance" && k != "app.kubernetes.io/version" && k != "app.kubernetes.io/component" && k != "app.kubernetes.io/managed-by" {
			"\(k)": v
		}
		"helm.sh/chart":                "loki-5.36.2"
		"app.kubernetes.io/name":       "loki"
		"app.kubernetes.io/instance":   _name
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/component":  "single-binary"
		"app.kubernetes.io/managed-by": "timoni"
	}

	let selectorLabels = {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  _name
		"app.kubernetes.io/component": "single-binary"
	}

	if isSingleBinary {
		// File 1: statefulset.yaml
		"statefulset": {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      fullname
				namespace: ns
				labels: commonLabels & {"app.kubernetes.io/part-of": "memberlist"}
				if len(#loki.loki.annotations) > 0 || len(#singleBinary.annotations) > 0 {
					annotations: {
						for k, v in #loki.loki.annotations {"\(k)": v}
						for k, v in #singleBinary.annotations {"\(k)": v}
					}
				}
			}
			spec: {
				replicas:            #singleBinary.replicas
				podManagementPolicy: "Parallel"
				updateStrategy: rollingUpdate: partition: 0
				serviceName:          "\(fullname)-headless"
				revisionHistoryLimit: #loki.loki.revisionHistoryLimit
				selector: matchLabels: selectorLabels
				template: {
					metadata: {
						annotations: {
							"checksum/config": "config-checksum-placeholder"
							for k, v in #loki.loki.podAnnotations {"\(k)": v}
							for k, v in #singleBinary.podAnnotations {"\(k)": v}
						}
						labels: selectorLabels & {
							"app.kubernetes.io/part-of": "memberlist"
							for k, v in #loki.loki.podLabels {"\(k)": v}
							for k, v in #singleBinary.podLabels {"\(k)": v}
						}
					}
					spec: {
						serviceAccountName:           "\(_name)-loki"
						automountServiceAccountToken: true
						if #singleBinary.priorityClassName != "" {
							priorityClassName: #singleBinary.priorityClassName
						}
						securityContext:               #loki.loki.podSecurityContext
						terminationGracePeriodSeconds: #singleBinary.terminationGracePeriodSeconds
						if len(#singleBinary.initContainers) > 0 {
							initContainers: #singleBinary.initContainers
						}
						containers: [
							{
								name:            "loki"
								image:           "\(imageRepo):\(imageTag)"
								imagePullPolicy: pullPolicy
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-target=\(#singleBinary.targetModule)",
									for arg in #singleBinary.extraArgs {arg},
								]
								ports: [
									{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
									{name: "grpc", containerPort: 9095, protocol: "TCP"},
									{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
								]
								if len(#singleBinary.extraEnv) > 0 {
									env: #singleBinary.extraEnv
								}
								if len(#singleBinary.extraEnvFrom) > 0 {
									envFrom: #singleBinary.extraEnvFrom
								}
								securityContext: #loki.loki.containerSecurityContext
								readinessProbe:  #loki.loki.readinessProbe
								volumeMounts: [
									{name: "tmp", mountPath: "/tmp"},
									{name: "config", mountPath: "/etc/loki/config"},
									{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
									if #singleBinary.persistence.enabled {
										{name: "storage", mountPath: "/var/loki"}
									},
									for vm in #singleBinary.extraVolumeMounts {vm},
								]
								resources: #singleBinary.resources
							},
						]
						if len(#singleBinary.affinity) > 0 {
							affinity: #singleBinary.affinity
						}
						nodeSelector: #singleBinary.nodeSelector
						tolerations:  #singleBinary.tolerations
						volumes: [
							{name: "tmp", emptyDir: {}},
							{name: "config", configMap: name: "\(_name)-loki-config"},
							{name: "runtime-config", configMap: name: "\(_name)-loki-runtime"},
							for v in #singleBinary.extraVolumes {v},
						]
					}
				}
				if #singleBinary.persistence.enabled {
					volumeClaimTemplates: [
						{
							apiVersion: "v1"
							kind:       "PersistentVolumeClaim"
							metadata: {
								name: "storage"
								if len(#singleBinary.persistence.annotations) > 0 {
									annotations: #singleBinary.persistence.annotations
								}
							}
							spec: {
								accessModes: ["ReadWriteOnce"]
								if #singleBinary.persistence.storageClass != null {
									storageClassName: [if #singleBinary.persistence.storageClass == "-" {""}, #singleBinary.persistence.storageClass][0]
								}
								resources: requests: storage: #singleBinary.persistence.size
								if len(#singleBinary.persistence.selector) > 0 {
									selector: #singleBinary.persistence.selector
								}
							}
						},
					]
				}
			}
		}

		// File 2: service.yaml
		"service": {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      fullname
				namespace: ns
				labels:    commonLabels
				if len(#singleBinary.serviceAnnotations) > 0 {
					annotations: #singleBinary.serviceAnnotations
				}
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

		// File 3: service-headless.yaml
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

		// File 4: pdb.yaml
		if #singleBinary.replicas > 1 {
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
		if #singleBinary.autoscaling.enabled {
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
					minReplicas: #singleBinary.autoscaling.minReplicas
					maxReplicas: #singleBinary.autoscaling.maxReplicas
					metrics: [
						if #singleBinary.autoscaling.targetMemoryUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "memory"
									target: {type: "Utilization", averageUtilization: #singleBinary.autoscaling.targetMemoryUtilizationPercentage}
								}
							}
						},
						if #singleBinary.autoscaling.targetCPUUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "cpu"
									target: {type: "Utilization", averageUtilization: #singleBinary.autoscaling.targetCPUUtilizationPercentage}
								}
							}
						},
					]
				}
			}
		}
	}
}
