package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#NginxHPA: autoscalingv2.#HorizontalPodAutoscaler & {
	#config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-nginx"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: autoscalingv2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-nginx"
		}
		
		minReplicas: #config.nginx.autoscaling.minReplicas
		maxReplicas: #config.nginx.autoscaling.maxReplicas
		metrics: [
			if #config.nginx.autoscaling.targetCPUUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.nginx.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.nginx.autoscaling.targetMemoryUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.nginx.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}
