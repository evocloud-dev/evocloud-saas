package templates

monitoringLokiQuerier: {
	// Use _ to allow any input, but extract values into local scope to prevent recursion
	#loki:     _
	#querier:  _
	#metadata: _

	let ns = #metadata.namespace
	let _name = #metadata.name
	let fullname = "\(_name)-loki-querier"
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
		"app.kubernetes.io/component":  "querier"
		"app.kubernetes.io/managed-by": "timoni"
	}

	let selectorLabels = {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  _name
		"app.kubernetes.io/component": "querier"
	}

	let podAnnotations = {
		"checksum/config": "config-checksum-placeholder"
		for k, v in #loki.loki.podAnnotations {"\(k)": v}
		for k, v in #querier.podAnnotations {"\(k)": v}
	}

	let podLabels = {
		for k, v in selectorLabels {"\(k)": v}
		"app.kubernetes.io/part-of": "memberlist"
		for k, v in #loki.loki.podLabels {"\(k)": v}
		for k, v in #querier.podLabels {"\(k)": v}
	}

	// File 1: deployment-querier.yaml
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
			if !#querier.autoscaling.enabled {
				replicas: #querier.replicas
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
					if #querier.priorityClassName != null {
						priorityClassName: #querier.priorityClassName
					}
					securityContext:               #loki.loki.podSecurityContext
					terminationGracePeriodSeconds: #querier.terminationGracePeriodSeconds
					containers: [
						{
							name:            "querier"
							image:           "\(imageRepo):\(imageTag)"
							imagePullPolicy: pullPolicy
							args: [
								"-config.file=/etc/loki/config/config.yaml",
								"-target=querier",
								for arg in #querier.extraArgs {arg},
							]
							ports: [
								{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
								{name: "grpc", containerPort: 9095, protocol: "TCP"},
								{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
							]
							if len(#querier.extraEnv) > 0 {
								env: #querier.extraEnv
							}
							if len(#querier.extraEnvFrom) > 0 {
								envFrom: #querier.extraEnvFrom
							}
							securityContext: #loki.loki.containerSecurityContext
							readinessProbe:  #loki.loki.readinessProbe
							livenessProbe:   #loki.loki.livenessProbe
							volumeMounts: [
								{name: "config", mountPath: "/etc/loki/config"},
								{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
								{name: "data", mountPath: "/var/loki"},
								for vm in #querier.extraVolumeMounts {vm},
							]
							resources: #querier.resources
						},
					]
					if len(#querier.affinity) > 0 {
						affinity: #querier.affinity
					}
					nodeSelector: #querier.nodeSelector
					tolerations:  #querier.tolerations
					volumes: [
						{name: "config", configMap: name: "\(_name)-loki-config"},
						{name: "runtime-config", configMap: name: "\(_name)-loki-runtime"},
						{name: "data", emptyDir: {}},
						for v in #querier.extraVolumes {v},
					]
				}
			}
		}
	}

	// File 2: hpa.yaml
	if #querier.autoscaling.enabled {
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
				minReplicas: #querier.autoscaling.minReplicas
				maxReplicas: #querier.autoscaling.maxReplicas
				metrics: [
					if #querier.autoscaling.targetCPUUtilizationPercentage != null {
						{
							type: "Resource"
							resource: {
								name: "cpu"
								target: {type: "Utilization", averageUtilization: #querier.autoscaling.targetCPUUtilizationPercentage}
							}
						}
					},
					if #querier.autoscaling.targetMemoryUtilizationPercentage != null {
						{
							type: "Resource"
							resource: {
								name: "memory"
								target: {type: "Utilization", averageUtilization: #querier.autoscaling.targetMemoryUtilizationPercentage}
							}
						}
					},
				]
			}
		}
	}

	// File 4: service-querier.yaml
	"service": {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      fullname
			namespace: ns
			labels: {
				for k, v in commonLabels {"\(k)": v}
				for k, v in #querier.serviceLabels {"\(k)": v}
			}
			annotations: {
				for k, v in #loki.loki.serviceAnnotations {"\(k)": v}
				for k, v in #querier.serviceAnnotations {"\(k)": v}
			}
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
				},
			]
			selector: selectorLabels
		}
	}
}
