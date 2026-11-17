package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#ClientHPA: autoscalingv2.#HorizontalPodAutoscaler & {
	#config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-client"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: autoscalingv2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-client"
		}
		minReplicas: #config.client.autoscaling.minReplicas
		maxReplicas: #config.client.autoscaling.maxReplicas
		behavior: scaleDown: stabilizationWindowSeconds: 300
		metrics: [
			{
				type: "ContainerResource"
				containerResource: {
					name: "cpu"
					container: "client"
					target: {
						type:               "Utilization"
						averageUtilization: #config.client.autoscaling.targetCPUUtilizationPercentage
					}
				}
			},
		]
	}
}
