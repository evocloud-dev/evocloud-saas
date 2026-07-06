package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#WebHorizontalPodAutoscaler: autoscalingv2.#HorizontalPodAutoscaler & {
	#config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-web"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: autoscalingv2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-web"
		}
		minReplicas: #config.web.autoscaling.minReplicas
		maxReplicas: #config.web.autoscaling.maxReplicas
		metrics: [
			if #config.web.autoscaling.targetCPUUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.web.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.web.autoscaling.targetMemoryUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.web.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}
