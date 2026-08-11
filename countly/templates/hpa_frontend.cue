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
		labels: {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-frontend"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/version":    #config.moduleVersion
			"app.kubernetes.io/managed-by": "timoni"
		}
	}
	spec: autoscalingv2.#HorizontalPodAutoscalerSpec & {
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
