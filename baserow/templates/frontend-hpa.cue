package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#HpaFrontend: autoscalingv2.#HorizontalPodAutoscaler & {
	#config:    #Config
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-frontend"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-frontend"
		}
		minReplicas: #config.frontend.autoscaling.minReplicas
		maxReplicas: #config.frontend.autoscaling.maxReplicas
		metrics: [
			if #config.frontend.autoscaling.targetCPUUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.frontend.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.frontend.autoscaling.targetMemoryUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.frontend.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}
