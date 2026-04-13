package templates

import (
	autoscalev2 "k8s.io/api/autoscaling/v2"
)

#WorkerHPA: {
	#config: #Config
	if #config.worker.hpa.enabled {
		apiVersion: "autoscaling/v2"
		kind:       "HorizontalPodAutoscaler"
		metadata: {
			name:      "\(#config.metadata.name)-worker"
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
			if #config.metadata.annotations != _|_ {
				annotations: #config.metadata.annotations
			}
		}
		spec: autoscalev2.#HorizontalPodAutoscalerSpec & {
			scaleTargetRef: {
				apiVersion: "apps/v1"
				kind:       "Deployment"
				name:       "\(#config.metadata.name)-worker"
			}
			minReplicas: #config.worker.hpa.minpods
			maxReplicas: #config.worker.hpa.maxpods
			metrics: [
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.worker.hpa.cputhreshold
						}
					}
				},
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.worker.hpa.memorythreshold
						}
					}
				},
			]
		}
	}
}
