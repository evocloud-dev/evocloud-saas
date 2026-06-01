package templates

monitoringLokiResultsCache: {
	#loki:         _
	#resultsCache: _
	#metadata:     _

	let ns = #metadata.namespace
	let _name = #metadata.name
	let fullname = "\(_name)-loki-results-cache"

	let commonLabels = {
		for k, v in #metadata.labels if k != "app.kubernetes.io/name" && k != "app.kubernetes.io/instance" && k != "app.kubernetes.io/version" && k != "app.kubernetes.io/component" && k != "app.kubernetes.io/managed-by" {
			"\(k)": v
		}
		"helm.sh/chart":                "loki-5.36.2"
		"app.kubernetes.io/name":       "loki"
		"app.kubernetes.io/instance":   _name
		"app.kubernetes.io/version":    #loki.image.tag
		"app.kubernetes.io/component":  "results-cache"
		"app.kubernetes.io/managed-by": "timoni"
	}

	let selectorLabels = {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  _name
		"app.kubernetes.io/component": "results-cache"
	}

	if #resultsCache.enabled {
		// File 1: statefulset-results-cache.yaml
		"statefulset": {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      fullname
				namespace: ns
				labels: commonLabels & {name: "results-cache"}
				if len(#resultsCache.annotations) > 0 {
					annotations: #resultsCache.annotations
				}
			}
			spec: {
				replicas:            #resultsCache.replicas
				podManagementPolicy: #resultsCache.podManagementPolicy
				serviceName:         fullname
				updateStrategy:      #resultsCache.statefulStrategy
				selector: matchLabels: selectorLabels & {name: "results-cache"}
				template: {
					metadata: {
						labels: selectorLabels & {
							name: "results-cache"
							for k, v in #loki.loki.podLabels {"\(k)": v}
							for k, v in #resultsCache.podLabels {"\(k)": v}
						}
						annotations: {
							for k, v in #resultsCache.podAnnotations {"\(k)": v}
						}
					}
					spec: {
						serviceAccountName: "\(_name)-loki"
						if #resultsCache.priorityClassName != "" {
							priorityClassName: #resultsCache.priorityClassName
						}
						securityContext:               #loki.loki.podSecurityContext
						terminationGracePeriodSeconds: #resultsCache.terminationGracePeriodSeconds
						containers: [
							{
								name:            "memcached"
								image:           "\(#loki.memcached.image.repository):\(#loki.memcached.image.tag)"
								imagePullPolicy: #loki.memcached.image.pullPolicy
								ports: [
									{name: "memcached-client", containerPort: #resultsCache.port},
								]
								args: [
									"-m \(#resultsCache.allocatedMemory)",
									"--extended=modern,track_sizes",
									"-I \(#resultsCache.maxItemMemory)m",
									"-c \(#resultsCache.connectionLimit)",
									"-v",
									"-u \(#resultsCache.port)",
									for k, v in #resultsCache.extraArgs {
										"-\(k)\([if v != "" {" \(v)"}, ""][0])"
									},
								]
								securityContext: #loki.memcached.containerSecurityContext
								resources:       #resultsCache.resources
							},
							if #loki.memcachedExporter.enabled {
								{
									name:            "exporter"
									image:           "\(#loki.memcachedExporter.image.repository):\(#loki.memcachedExporter.image.tag)"
									imagePullPolicy: #loki.memcachedExporter.image.pullPolicy
									ports: [
										{name: "http-metrics", containerPort: 9150},
									]
									args: [
										"--memcached.address=localhost:\(#resultsCache.port)",
										"--web.listen-address=0.0.0.0:9150",
									]
									securityContext: #loki.memcachedExporter.containerSecurityContext
									resources:       #loki.memcachedExporter.resources
								}
							},
						]
						nodeSelector: #resultsCache.nodeSelector
						tolerations:  #resultsCache.tolerations
						if len(#resultsCache.affinity) > 0 {
							affinity: #resultsCache.affinity
						}
					}
				}
			}
		}

		// File 2: service-results-cache.yaml
		"service": {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:        fullname
				namespace:   ns
				labels:      commonLabels & #resultsCache.serviceLabels
				annotations: #resultsCache.serviceAnnotations
			}
			spec: {
				type:      "ClusterIP"
				clusterIP: "None"
				ports: [
					{name: "memcached-client", port: #resultsCache.port, targetPort: "memcached-client"},
					if #loki.memcachedExporter.enabled {
						{name: "http-metrics", port: 9150, targetPort: "http-metrics"}
					},
				]
				selector: selectorLabels & {name: "results-cache"}
			}
		}

		// File 3: poddisruptionbudget-results-cache.yaml
		if #resultsCache.podDisruptionBudget.enabled {
			"poddisruptionbudget": {
				apiVersion: "policy/v1"
				kind:       "PodDisruptionBudget"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					selector: matchLabels: selectorLabels & {name: "results-cache"}
					if #resultsCache.podDisruptionBudget.maxUnavailable != null {
						maxUnavailable: #resultsCache.podDisruptionBudget.maxUnavailable
					}
					if #resultsCache.podDisruptionBudget.minAvailable != null {
						minAvailable: #resultsCache.podDisruptionBudget.minAvailable
					}
				}
			}
		}
	}
}
