package templates

#ServiceMonitor: {
	#config: #Config
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
			if #config.prometheus.servicemonitor.labels != _|_ {
				#config.prometheus.servicemonitor.labels
			}
		}
	}
	spec: {
		endpoints: [
			{
				port: "http"
				path: "/cool/getMetrics"
				basicAuth: {
					username: {
						name: [if #config.collabora.existingSecret.enabled {#config.collabora.existingSecret.secretName}, #config.metadata.name][0]
						key:  [if #config.collabora.existingSecret.enabled {#config.collabora.existingSecret.usernameKey}, "username"][0]
					}
					password: {
						name: [if #config.collabora.existingSecret.enabled {#config.collabora.existingSecret.secretName}, #config.metadata.name][0]
						key:  [if #config.collabora.existingSecret.enabled {#config.collabora.existingSecret.passwordKey}, "password"][0]
					}
				}
			},
		]
		selector: matchLabels: #config.selector.labels & {
			type: "main"
		}
	}
}
