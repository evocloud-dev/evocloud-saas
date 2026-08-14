package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#HpaCelery: autoscalingv2.#HorizontalPodAutoscaler & {
	#config:    #Config
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-celery"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-celery-worker"
		}
		minReplicas: #config.backend.celery.worker.autoscaling.minReplicas
		maxReplicas: #config.backend.celery.worker.autoscaling.maxReplicas
		metrics: [
			if #config.backend.celery.worker.autoscaling.targetCPUUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.backend.celery.worker.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.backend.celery.worker.autoscaling.targetMemoryUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.backend.celery.worker.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}
