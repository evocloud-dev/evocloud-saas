package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#DrupalHPA: autoscalingv2.#HorizontalPodAutoscaler & {
	#config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: autoscalingv2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       #config.metadata.name
		}
		
		minReplicas: #config.drupal.autoscaling.minReplicas
		maxReplicas: #config.drupal.autoscaling.maxReplicas
		metrics: [
			if #config.drupal.autoscaling.targetCPUUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.drupal.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.drupal.autoscaling.targetMemoryUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.drupal.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}
