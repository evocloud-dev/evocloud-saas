package templates

monitoringLokiTableManager: {
	#loki:         _
	#tableManager: _
	#metadata:     _

	let ns = #metadata.namespace
	let _name = #metadata.name
	let fullname = "\(_name)-loki-table-manager"

	let commonLabels = {
		for k, v in #metadata.labels if k != "app.kubernetes.io/name" && k != "app.kubernetes.io/instance" && k != "app.kubernetes.io/version" && k != "app.kubernetes.io/component" && k != "app.kubernetes.io/managed-by" {
			"\(k)": v
		}
		"helm.sh/chart":                "loki-5.36.2"
		"app.kubernetes.io/name":       "loki"
		"app.kubernetes.io/instance":   _name
		"app.kubernetes.io/version":    #loki.image.tag
		"app.kubernetes.io/component":  "table-manager"
		"app.kubernetes.io/managed-by": "timoni"
	}

	let selectorLabels = {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  _name
		"app.kubernetes.io/component": "table-manager"
	}

	if #tableManager.enabled {
		// File 1: deployment-table-manager.yaml
		"deployment": {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      fullname
				namespace: ns
				labels:    commonLabels
				if len(#loki.loki.annotations) > 0 || len(#tableManager.annotations) > 0 {
					annotations: {
						for k, v in #loki.loki.annotations {"\(k)": v}
						for k, v in #tableManager.annotations {"\(k)": v}
					}
				}
			}
			spec: {
				replicas:             1
				revisionHistoryLimit: #loki.loki.revisionHistoryLimit
				selector: matchLabels: selectorLabels
				template: {
					metadata: {
						annotations: {
							"checksum/config": "config-checksum-placeholder"
							for k, v in #loki.loki.podAnnotations {"\(k)": v}
							for k, v in #tableManager.podAnnotations {"\(k)": v}
						}
						labels: selectorLabels & {
							for k, v in #loki.loki.podLabels {"\(k)": v}
							for k, v in #tableManager.podLabels {"\(k)": v}
						}
					}
					spec: {
						serviceAccountName: "\(_name)-loki"
						if #tableManager.priorityClassName != null {
							priorityClassName: #tableManager.priorityClassName
						}
						securityContext:               #loki.loki.podSecurityContext
						terminationGracePeriodSeconds: #tableManager.terminationGracePeriodSeconds
						containers: [
							{
								name:            "table-manager"
								image:           "\(#loki.image.repository):\(#loki.image.tag)"
								imagePullPolicy: #loki.image.pullPolicy
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-target=table-manager",
									for arg in #tableManager.extraArgs {arg},
								]
								ports: [
									{name: "http-metrics", containerPort: 3100, protocol: "TCP"},
									{name: "grpc", containerPort: 9095, protocol: "TCP"},
								]
								if len(#tableManager.extraEnv) > 0 {
									env: #tableManager.extraEnv
								}
								if len(#tableManager.extraEnvFrom) > 0 {
									envFrom: #tableManager.extraEnvFrom
								}
								securityContext: #loki.loki.containerSecurityContext
								readinessProbe:  #loki.loki.readinessProbe
								livenessProbe:   #loki.loki.livenessProbe
								volumeMounts: [
									{name: "config", mountPath: "/etc/loki/config"},
									for vm in #tableManager.extraVolumeMounts {vm},
								]
								resources: #tableManager.resources
							},
						]
						if len(#tableManager.extraContainers) > 0 {
							containers: containers + #tableManager.extraContainers
						}
						if len(#tableManager.affinity) > 0 {
							affinity: #tableManager.affinity
						}
						nodeSelector: #tableManager.nodeSelector
						tolerations:  #tableManager.tolerations
						volumes: [
							{name: "config", configMap: {name: "\(_name)-loki-config"}},
							for v in #tableManager.extraVolumes {v},
						]
					}
				}
			}
		}

		// File 2: service-table-manager.yaml
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

		// File 3: servicemonitor-table-manager.yaml
		if #tableManager.serviceMonitor.enabled {
			"servicemonitor": {
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "ServiceMonitor"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					selector: matchLabels: selectorLabels
					endpoints: [
						{
							port:     "http-metrics"
							interval: #tableManager.serviceMonitor.interval
							if #tableManager.serviceMonitor.scrapeTimeout != null {
								scrapeTimeout: #tableManager.serviceMonitor.scrapeTimeout
							}
							if len(#tableManager.serviceMonitor.relabelings) > 0 {
								relabelings: #tableManager.serviceMonitor.relabelings
							}
							if len(#tableManager.serviceMonitor.metricRelabelings) > 0 {
								metricRelabelings: #tableManager.serviceMonitor.metricRelabelings
							}
						},
					]
				}
			}
		}
	}
}
