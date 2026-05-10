package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#CoolifyAppHPA: autoscalingv2.#HorizontalPodAutoscaler & {
	#config: #Config
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-app"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "core"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: autoscalingv2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-app"
		}
		minReplicas: #config.coolifyApp.autoscaling.minReplicas
		maxReplicas: #config.coolifyApp.autoscaling.maxReplicas
		metrics: [
			if #config.coolifyApp.autoscaling.targetCPUUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.coolifyApp.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.coolifyApp.autoscaling.targetMemoryUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.coolifyApp.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}
