package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#HorizontalPodAutoscaler: autoscalingv2.#HorizontalPodAutoscaler & {
	#config:    #Config
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels:    #config.#allLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: autoscalingv2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       #config.#fullname
		}
		minReplicas: #config.autoscaling.minReplicas
		maxReplicas: #config.autoscaling.maxReplicas
		metrics: [
			{
				type: "Resource"
				resource: {
					name: "cpu"
					target: {
						type:               "Utilization"
						averageUtilization: #config.autoscaling.targetCPUUtilizationPercentage
					}
				}
			},
			{
				type: "Resource"
				resource: {
					name: "memory"
					target: {
						type:               "Utilization"
						averageUtilization: #config.autoscaling.targetMemoryUtilizationPercentage
					}
				}
			},
		]
	}
}
