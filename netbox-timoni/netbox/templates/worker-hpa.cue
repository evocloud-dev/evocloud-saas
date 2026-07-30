package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#WorkerHPA: autoscalingv2.#HorizontalPodAutoscaler & {
	#config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config._fullname)-worker"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "worker"
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	spec: autoscalingv2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config._fullname)-worker"
		}
		minReplicas: #config.worker.autoscaling.minReplicas
		maxReplicas: #config.worker.autoscaling.maxReplicas
		if len(#config.worker.autoscaling.behavior) > 0 {
			behavior: #config.worker.autoscaling.behavior
		}
		metrics: [
			if #config.worker.autoscaling.targetCPUUtilizationPercentage != null {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.worker.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.worker.autoscaling.targetMemoryUtilizationPercentage != null {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.worker.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}
