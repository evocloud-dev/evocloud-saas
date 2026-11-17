package templates

// #ServiceMonitor mirrors templates/servicemonitor.yaml.
#ServiceMonitor: {
	#config: #Config

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & #config.metrics.serviceMonitor.labels
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	spec: {
		selector: matchLabels: #config.selector.labels
		endpoints: [{
			port: [
				if #config.ntfy.enableMetrics && #config.ntfy.metricsListenHttp != "" {"metrics"},
				"http",
			][0]
			path:     "/metrics"
			interval: #config.metrics.serviceMonitor.interval
		}]
	}
}
