package templates

#ServerVPA: {
	#config:    #Config
	apiVersion: "autoscaling.k8s.io/v1"
	kind:       "VerticalPodAutoscaler"
	metadata: {
		name:      *"\((#config.metadata.name))-server" | string
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.server.vpa.annotations != _|_ {
			annotations: #config.server.vpa.annotations
		}
	}
	spec: {
		targetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       *"\((#config.metadata.name))-server" | string
		}
		updatePolicy: updateMode: #config.server.vpa.updateMode
		resourcePolicy: {
			containerPolicies: [
				{
					containerName: *"\((#config.metadata.name))-server" | string
					if #config.server.vpa.resourcePolicy.containerPolicies != _|_ {
						for cp in #config.server.vpa.resourcePolicy.containerPolicies {
							if cp.containerName == containerName {
								cp
							}
						}
					}
				},
			]
		}
	}
}
