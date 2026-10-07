package templates

#ServiceMonitor: {
	#config: #Config

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			if #config.metrics.serviceMonitor.labels != _|_ {
				for k, v in #config.metrics.serviceMonitor.labels {
					"\(k)": v
				}
			}
		}
		if #config.metrics.serviceMonitor.annotations != _|_ && len(#config.metrics.serviceMonitor.annotations) > 0 {
			annotations: #config.metrics.serviceMonitor.annotations
		}
	}
	spec: {
		selector: matchLabels: #config.#selectorLabels & {
			"app.kubernetes.io/component": "metrics"
		}
		endpoints: [{
			port:          "metrics"
			path:          "/r.php/monitoringexporter_prometheus/metrics"
			interval:      #config.metrics.serviceMonitor.interval
			scrapeTimeout: #config.metrics.serviceMonitor.scrapeTimeout
			authorization: {
				type: "Bearer"
				credentials: {
					name: #config.#metricsSecret
					key:  #config.metrics.existingSecretTokenKey
				}
			}
			if len(#config.metrics.serviceMonitor.relabelings) > 0 {
				relabelings: #config.metrics.serviceMonitor.relabelings
			}
			if len(#config.metrics.serviceMonitor.metricRelabelings) > 0 {
				metricRelabelings: #config.metrics.serviceMonitor.metricRelabelings
			}
		}]
	}
}

