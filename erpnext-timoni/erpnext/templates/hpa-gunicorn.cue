package templates

import (
	autov2 "k8s.io/api/autoscaling/v2"
)

#GunicornHPA: autov2.#HorizontalPodAutoscaler & {
	#config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-gunicorn"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name": "\(#config.metadata.name)-gunicorn"
		}
	}
	spec: autov2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-gunicorn"
		}
		minReplicas: #config.worker.gunicorn.autoscaling.minReplicas
		maxReplicas: #config.worker.gunicorn.autoscaling.maxReplicas
		metrics: [
			if #config.worker.gunicorn.autoscaling.targetCPU != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.worker.gunicorn.autoscaling.targetCPU
						}
					}
				}
			},
			if #config.worker.gunicorn.autoscaling.targetMemory != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.worker.gunicorn.autoscaling.targetMemory
						}
					}
				}
			},
		]
	}
}
