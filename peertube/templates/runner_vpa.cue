package templates

#RunnerVPA: {
	#config:    #Config
	apiVersion: "autoscaling.k8s.io/v1"
	kind:       "VerticalPodAutoscaler"
	metadata: {
		name:      *"\((#config.metadata.name))-runner" | string
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "runner"
		}
	}
	spec: {
		targetRef: {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			name:       *"\((#config.metadata.name))-runner" | string
		}
		updatePolicy: updateMode: #config.runner.vpa.updateMode
		resourcePolicy: {
			containerPolicies: [
				{
					containerName: "runner"
					if #config.runner.vpa.resourcePolicy.containerPolicies != _|_ {
						for cp in #config.runner.vpa.resourcePolicy.containerPolicies {
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
