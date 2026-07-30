package templates

#GranianServiceMonitor: {
	#config: #Config

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      "\(#config._fullname)-granian"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			for k, v in #config.metrics.granian.serviceMonitor.additionalLabels {
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
			if #config.metrics.granian.serviceMonitor.selector != _|_ {
				#config.metrics.granian.serviceMonitor.selector
			}
		}
		endpoints: [
			{
				port: "granian-metrics"
				path: "/"
				if #config.metrics.granian.serviceMonitor.interval != "" {
					interval: #config.metrics.granian.serviceMonitor.interval
				}
				if #config.metrics.granian.serviceMonitor.scrapeTimeout != "" {
					scrapeTimeout: #config.metrics.granian.serviceMonitor.scrapeTimeout
				}
				if #config.metrics.granian.serviceMonitor.honorLabels != _|_ {
					honorLabels: #config.metrics.granian.serviceMonitor.honorLabels
				}
				if #config.metrics.granian.serviceMonitor.metricRelabelings != _|_ {
					metricRelabelings: #config.metrics.granian.serviceMonitor.metricRelabelings
				}
				if #config.metrics.granian.serviceMonitor.relabelings != _|_ {
					relabelings: #config.metrics.granian.serviceMonitor.relabelings
				}
			},
		]
	}
}
