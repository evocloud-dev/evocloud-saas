package templates

monitoringLokiQueryFrontend: {
	#loki:          _
	#queryFrontend: _
	#metadata:      _

	let ns = #metadata.namespace
	let _name = #metadata.name
	let fullname = "\(_name)-loki-query-frontend"
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
		"app.kubernetes.io/component":  "query-frontend"
		"app.kubernetes.io/managed-by": "timoni"
	}

	let selectorLabels = {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  _name
		"app.kubernetes.io/component": "query-frontend"
	}

	let podAnnotations = {
		"checksum/config": "config-checksum-placeholder"
		for k, v in #loki.loki.podAnnotations {"\(k)": v}
		for k, v in #queryFrontend.podAnnotations {"\(k)": v}
	}

	let podLabels = {
		for k, v in selectorLabels {"\(k)": v}
		"app.kubernetes.io/part-of": "memberlist"
		for k, v in #loki.loki.podLabels {"\(k)": v}
		for k, v in #queryFrontend.podLabels {"\(k)": v}
	}

	// File 1: deployment-query-frontend.yaml
	"deployment": {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      fullname
			namespace: ns
			labels:    commonLabels
			if len(#loki.loki.annotations) > 0 {
				annotations: #loki.loki.annotations
			}
		}
		spec: {
			if !#queryFrontend.autoscaling.enabled {
				replicas: #queryFrontend.replicas
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
					serviceAccountName: "\(_name)-loki"
					if #queryFrontend.priorityClassName != null {
						priorityClassName: #queryFrontend.priorityClassName
					}
					securityContext:               #loki.loki.podSecurityContext
					terminationGracePeriodSeconds: #queryFrontend.terminationGracePeriodSeconds
					containers: [
						{
							name:            "query-frontend"
							image:           "\(imageRepo):\(imageTag)"
							imagePullPolicy: pullPolicy
							args: [
								"-config.file=/etc/loki/config/config.yaml",
								"-target=query-frontend",
								for arg in #queryFrontend.extraArgs {arg},
							]
							ports: [
								{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
								{name: "grpc", containerPort: 9095, protocol: "TCP"},
								{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
							]
							if len(#queryFrontend.extraEnv) > 0 {
								env: #queryFrontend.extraEnv
							}
							if len(#queryFrontend.extraEnvFrom) > 0 {
								envFrom: #queryFrontend.extraEnvFrom
							}
							securityContext: #loki.loki.containerSecurityContext
							readinessProbe:  #loki.loki.readinessProbe
							volumeMounts: [
								{name: "config", mountPath: "/etc/loki/config"},
								{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
								for vm in #queryFrontend.extraVolumeMounts {vm},
							]
							resources: #queryFrontend.resources
						},
					]
					if len(#queryFrontend.affinity) > 0 {
						affinity: #queryFrontend.affinity
					}
					nodeSelector: #queryFrontend.nodeSelector
					tolerations:  #queryFrontend.tolerations
					volumes: [
						{name: "config", configMap: name: "\(_name)-loki-config"},
						{name: "runtime-config", configMap: name: "\(_name)-loki-runtime"},
						for v in #queryFrontend.extraVolumes {v},
					]
				}
			}
		}
	}

	// File 2: hpa.yaml
	if #queryFrontend.autoscaling.enabled {
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
					kind:       "Deployment"
					name:       fullname
				}
				minReplicas: #queryFrontend.autoscaling.minReplicas
				maxReplicas: #queryFrontend.autoscaling.maxReplicas
				metrics: [
					if #queryFrontend.autoscaling.targetCPUUtilizationPercentage != null {
						{
							type: "Resource"
							resource: {
								name: "cpu"
								target: {type: "Utilization", averageUtilization: #queryFrontend.autoscaling.targetCPUUtilizationPercentage}
							}
						}
					},
					if #queryFrontend.autoscaling.targetMemoryUtilizationPercentage != null {
						{
							type: "Resource"
							resource: {
								name: "memory"
								target: {type: "Utilization", averageUtilization: #queryFrontend.autoscaling.targetMemoryUtilizationPercentage}
							}
						}
					},
				]
			}
		}
	}

	// File 3: poddisruptionbudget-query-frontend.yaml
	if #queryFrontend.replicas > 1 {
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
				maxUnavailable: #queryFrontend.maxUnavailable
			}
		}
	}

	// File 4: service-query-frontend.yaml
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

	// File 5: service-query-frontend-headless.yaml
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
