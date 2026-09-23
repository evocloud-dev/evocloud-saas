package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#HorizontalPodAutoscaler: autoscalingv2.#HorizontalPodAutoscaler & {
	#config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata:   #config.metadata
	spec: autoscalingv2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       #config.metadata.name
		}
		minReplicas: #config.autoscaling.minReplicas
		maxReplicas: #config.autoscaling.maxReplicas
		behavior: scaleDown: stabilizationWindowSeconds: 300
		metrics: [
			{
				type: "ContainerResource"
				containerResource: {
					name: "cpu"
					container: "bentopdf"
					target: {
						type:               "Utilization"
						averageUtilization: #config.autoscaling.targetCPUUtilizationPercentage
					}
				}
			},
		]
	}
}

