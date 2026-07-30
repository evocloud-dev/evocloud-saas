package templates

#ServiceMonitor: {
	#config: #Config

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			for k, v in #config.metrics.serviceMonitor.additionalLabels {
				"\(k)": v
			}
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	spec: {
		jobLabel: #config._fullname
		namespaceSelector: matchNames: [#config.metadata.namespace]
		selector: matchLabels: #config.selector.labels & {
			if #config.metrics.serviceMonitor.selector != _|_ {
				#config.metrics.serviceMonitor.selector
			}
		}
		endpoints: [
			{
				port: "http"
				path: "/metrics"
				if #config.metrics.serviceMonitor.interval != "" {
					interval: #config.metrics.serviceMonitor.interval
				}
				if #config.metrics.serviceMonitor.scrapeTimeout != "" {
					scrapeTimeout: #config.metrics.serviceMonitor.scrapeTimeout
				}
				if #config.metrics.serviceMonitor.honorLabels != _|_ {
					honorLabels: #config.metrics.serviceMonitor.honorLabels
				}
				if #config.metrics.serviceMonitor.metricRelabelings != _|_ {
					metricRelabelings: #config.metrics.serviceMonitor.metricRelabelings
				}
				if #config.metrics.serviceMonitor.relabelings != _|_ {
					relabelings: #config.metrics.serviceMonitor.relabelings
				}
			},
		]
	}
}
