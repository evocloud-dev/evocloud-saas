package templates

import (
	autov2 "k8s.io/api/autoscaling/v2"
)

#HorizontalPodAutoscaler: {
	#config: #Config

	autov2.#HorizontalPodAutoscaler & {
		apiVersion: "autoscaling/v2"
		kind:       "HorizontalPodAutoscaler"
		metadata:   #config.metadata
		spec: {
			scaleTargetRef: {
				apiVersion: "apps/v1"
				kind:       "Deployment"
				name:       #config.metadata.name
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
}