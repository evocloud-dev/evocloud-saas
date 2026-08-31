package templates

#HPABuilder: {
	_config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      _config.fullname
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	spec: {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       _config.fullname
		}
		minReplicas: _config.autoscaling.minReplicas
		maxReplicas: _config.autoscaling.maxReplicas
		metrics: [
			{
				type: "Resource"
				resource: {
					name: "cpu"
					target: {
						type:               "Utilization"
						averageUtilization: _config.autoscaling.targetCPUUtilizationPercentage
					}
				}
			},
			{
				type: "Resource"
				resource: {
					name: "memory"
					target: {
						type:               "Utilization"
						averageUtilization: _config.autoscaling.targetMemoryUtilizationPercentage
					}
				}
			},
		]
	}
}
