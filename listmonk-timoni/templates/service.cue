package templates

#Service: {
	#config: #Config
	#helpers: #Helpers

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #helpers.fullname
		namespace: #config.metadata.namespace
		labels:    #helpers.labels
	}
	spec: {
		type: #config.service.type
		ports: [{
			port:       #config.service.port
			targetPort: "http"
			protocol:   "TCP"
			name:       "http"
		}]
		selector: #helpers.selectorLabels
	}
}
