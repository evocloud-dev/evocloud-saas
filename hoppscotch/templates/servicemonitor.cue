package templates

#ServiceMonitor: {
	#config: #Config
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      #config.fullname
		namespace: #config.namespace
		labels: {
			#config.labels
			if #config.metrics.serviceMonitor.labels != _|_ && len(#config.metrics.serviceMonitor.labels) > 0 {
				for k, v in #config.metrics.serviceMonitor.labels {
					"\(k)": v
				}
			}
		}
	}
	spec: {
		selector: matchLabels: #config.selectorLabels
		endpoints: [
			{
				port:     "http"
				path:     "/backend/health"
				interval: #config.metrics.serviceMonitor.interval
			},
		]
	}
}
