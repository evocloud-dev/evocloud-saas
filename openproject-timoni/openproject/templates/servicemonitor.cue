package templates

#ServiceMonitor: {
	#config: #Config
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      "\(#config.metadata.name)-metrics"
		namespace: #config.metrics.serviceMonitor.namespace | #config.metadata.namespace
		labels: #config.metadata.labels & #config.metrics.serviceMonitor.labels & {
			"app.kubernetes.io/component": "openproject"
		}
		if #config.metrics.serviceMonitor.annotations != _|_ {
			annotations: #config.metrics.serviceMonitor.annotations
		}
	}
	spec: {
		endpoints: [{
			port:          "metrics"
			path:          #config.metrics.path
			interval:      #config.metrics.serviceMonitor.interval
			scrapeTimeout: #config.metrics.serviceMonitor.scrapeTimeout
			honorLabels:   #config.metrics.serviceMonitor.honorLabels
			if #config.metrics.serviceMonitor.metricRelabelings != _|_ {
				metricRelabelings: #config.metrics.serviceMonitor.metricRelabelings
			}
			if #config.metrics.serviceMonitor.relabelings != _|_ {
				relabelings: #config.metrics.serviceMonitor.relabelings
			}
		}]
		jobLabel: #config.metadata.name
		namespaceSelector: matchNames: [#config.metadata.namespace]
		selector: matchLabels: #config.selector.labels
	}
}
