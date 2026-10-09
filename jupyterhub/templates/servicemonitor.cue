package templates

#ServiceMonitor: {
	#config: #Config

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels {
				(k): v
			}
			if len(#config.metrics.serviceMonitor.labels) > 0 {
				for k, v in #config.metrics.serviceMonitor.labels {
					(k): v
				}
			}
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		endpoints: [
			{
				port:     "http"
				path:     #config.#hubMetricsPath
				interval: #config.metrics.serviceMonitor.interval
			},
		]
		selector: matchLabels: #config.#selectorLabels & {#component: "proxy"}
		namespaceSelector: matchNames: [
			#config.metadata.namespace,
		]
	}
}

