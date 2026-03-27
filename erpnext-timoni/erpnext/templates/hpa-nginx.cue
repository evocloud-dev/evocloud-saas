package templates

import (
	autov2 "k8s.io/api/autoscaling/v2"
)

#NginxHPA: autov2.#HorizontalPodAutoscaler & {
	#config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-nginx"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name": "\(#config.metadata.name)-nginx"
		}
	}
	spec: autov2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-nginx"
		}
		minReplicas: #config.nginx.autoscaling.minReplicas
		maxReplicas: #config.nginx.autoscaling.maxReplicas
		metrics: [
			if #config.nginx.autoscaling.targetCPU != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.nginx.autoscaling.targetCPU
						}
					}
				}
			},
			if #config.nginx.autoscaling.targetMemory != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.nginx.autoscaling.targetMemory
						}
					}
				}
			},
		]
	}
}
