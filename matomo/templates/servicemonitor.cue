package templates

// Generate the ServiceMonitor resource if metrics monitoring is enabled
#ServiceMonitor: {
	#config: #Config
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata:   #config.metadata & {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		
		// Merges standard global labels with serviceMonitor-specific custom labels
		labels: #config.metadata.labels & {
			if #config.metrics.serviceMonitor.labels != _|_ {
				#config.metrics.serviceMonitor.labels
			}
		}
	}
	spec: {
		selector: matchLabels: #config.selector.labels
		endpoints: [{
			port:          "http"
			path:          "/matomo.php"
			interval:      #config.metrics.serviceMonitor.interval
			scrapeTimeout: #config.metrics.serviceMonitor.scrapeTimeout
		}]
		
		// Conditionally map the namespaceSelector if it is provided by the user
		if #config.metrics.serviceMonitor.namespaceSelector != _|_ && #config.metrics.serviceMonitor.namespaceSelector != {} {
			namespaceSelector: #config.metrics.serviceMonitor.namespaceSelector
		}
	}
}
