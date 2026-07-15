package templates

#ServerServiceMonitor: {
	#config:    #Config
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      *"\((#config.metadata.name))-server" | string
		namespace: *#config.metadata.namespace | string
		if (#config.server.serviceMonitor.namespace & string) != _|_ {
			namespace: #config.server.serviceMonitor.namespace
		}
		labels: #config.metadata.labels & {
			if #config.server.serviceMonitor.additionalLabels != _|_ {
				#config.server.serviceMonitor.additionalLabels
			}
		}
		if #config.server.serviceMonitor.additionalAnnotations != _|_ {
			annotations: #config.server.serviceMonitor.additionalAnnotations
		}
	}
	spec: {
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "server"
		}
		namespaceSelector: matchNames: [#config.metadata.namespace]
		endpoints: [
			{
				port: "metrics"
				if #config.server.serviceMonitor.interval != "" {
					interval: #config.server.serviceMonitor.interval
				}
				if #config.server.serviceMonitor.scrapeTimeout != "" {
					scrapeTimeout: #config.server.serviceMonitor.scrapeTimeout
				}
				path:    "/metrics"
				#scheme: *"http" | string
				if #config.server.serviceMonitor.secure {
					#scheme: "https"
				}
				scheme: #scheme
				if #config.server.serviceMonitor.tlsConfig != _|_ && len(#config.server.serviceMonitor.tlsConfig) > 0 {
					tlsConfig: #config.server.serviceMonitor.tlsConfig
				}
				if len(#config.server.serviceMonitor.relabelings) > 0 {
					relabelings: #config.server.serviceMonitor.relabelings
				}
				if len(#config.server.serviceMonitor.metricRelabelings) > 0 {
					metricRelabelings: #config.server.serviceMonitor.metricRelabelings
				}
			},
		]
	}
}
