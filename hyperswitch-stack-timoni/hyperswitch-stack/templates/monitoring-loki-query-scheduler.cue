package templates

monitoringLokiQueryScheduler: {
	#loki:           _
	#queryScheduler: _
	#metadata:       _

	let ns = #metadata.namespace
	let _name = #metadata.name
	let fullname = "\(_name)-loki-query-scheduler"
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
		"app.kubernetes.io/component":  "query-scheduler"
		"app.kubernetes.io/managed-by": "timoni"
	}

	let selectorLabels = {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  _name
		"app.kubernetes.io/component": "query-scheduler"
	}

	let podAnnotations = {
		"checksum/config": "config-checksum-placeholder"
		for k, v in #loki.loki.podAnnotations {"\(k)": v}
		for k, v in #queryScheduler.podAnnotations {"\(k)": v}
	}

	let podLabels = {
		for k, v in selectorLabels {"\(k)": v}
		"app.kubernetes.io/part-of": "memberlist"
		for k, v in #loki.loki.podLabels {"\(k)": v}
		for k, v in #queryScheduler.podLabels {"\(k)": v}
	}

	// File 1: deployment-query-scheduler.yaml
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
			replicas: #queryScheduler.replicas
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
					if #queryScheduler.priorityClassName != null {
						priorityClassName: #queryScheduler.priorityClassName
					}
					securityContext:               #loki.loki.podSecurityContext
					terminationGracePeriodSeconds: #queryScheduler.terminationGracePeriodSeconds
					containers: [
						{
							name:            "query-scheduler"
							image:           "\(imageRepo):\(imageTag)"
							imagePullPolicy: pullPolicy
							args: [
								"-config.file=/etc/loki/config/config.yaml",
								"-target=query-scheduler",
								for arg in #queryScheduler.extraArgs {arg},
							]
							ports: [
								{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
								{name: "grpc", containerPort: 9095, protocol: "TCP"},
								{name: "http-memberlist", containerPort: 7946, protocol: "TCP"},
							]
							if len(#queryScheduler.extraEnv) > 0 {
								env: #queryScheduler.extraEnv
							}
							if len(#queryScheduler.extraEnvFrom) > 0 {
								envFrom: #queryScheduler.extraEnvFrom
							}
							securityContext: #loki.loki.containerSecurityContext
							readinessProbe:  #loki.loki.readinessProbe
							livenessProbe:   #loki.loki.livenessProbe
							volumeMounts: [
								{name: "config", mountPath: "/etc/loki/config"},
								{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
								for vm in #queryScheduler.extraVolumeMounts {vm},
							]
							resources: #queryScheduler.resources
						},
					]
					if len(#queryScheduler.affinity) > 0 {
						affinity: #queryScheduler.affinity
					}
					nodeSelector: #queryScheduler.nodeSelector
					tolerations:  #queryScheduler.tolerations
					volumes: [
						{name: "config", configMap: name: "\(_name)-loki-config"},
						{name: "runtime-config", configMap: name: "\(_name)-loki-runtime"},
						for v in #queryScheduler.extraVolumes {v},
					]
				}
			}
		}
	}

	// File 2: poddisruptionbudget-query-scheduler.yaml
	if #queryScheduler.replicas > 1 {
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
				maxUnavailable: #queryScheduler.maxUnavailable
			}
		}
	}

	// File 3: service-query-scheduler.yaml
	"service": {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:        fullname
			namespace:   ns
			labels:      commonLabels & #queryScheduler.serviceLabels
			annotations: #loki.loki.serviceAnnotations & #queryScheduler.serviceAnnotations
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
}
