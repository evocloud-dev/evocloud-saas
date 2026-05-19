package templates

import (
	autoscalev2 "k8s.io/api/autoscaling/v2"
)

#HpaWorker: autoscalev2.#HorizontalPodAutoscaler & {
	#config:    #Config
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-hpa-worker"
		namespace: #config.metadata.namespace
		labels: {
			app:      #config.metadata.name
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
	}
	spec: autoscalev2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-worker"
		}
		minReplicas: #config.supersetWorker.autoscaling.minReplicas
		maxReplicas: #config.supersetWorker.autoscaling.maxReplicas
		metrics: [
			if #config.supersetWorker.autoscaling.targetCPUUtilizationPercentage != null {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.supersetWorker.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.supersetWorker.autoscaling.targetMemoryUtilizationPercentage != null {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.supersetWorker.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}
