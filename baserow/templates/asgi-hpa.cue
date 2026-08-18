package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#HpaAsgi: autoscalingv2.#HorizontalPodAutoscaler & {
	#config:    #Config
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-asgi"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-asgi"
		}
		minReplicas: #config.backend.asgi.autoscaling.minReplicas
		maxReplicas: #config.backend.asgi.autoscaling.maxReplicas
		metrics: [
			if #config.backend.asgi.autoscaling.targetCPUUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.backend.asgi.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.backend.asgi.autoscaling.targetMemoryUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.backend.asgi.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}
