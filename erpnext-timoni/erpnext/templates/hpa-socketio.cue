package templates

import (
	autov2 "k8s.io/api/autoscaling/v2"
)

#SocketioHPA: autov2.#HorizontalPodAutoscaler & {
	#config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-socketio"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name": "\(#config.metadata.name)-socketio"
		}
	}
	spec: autov2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-socketio"
		}
		minReplicas: #config.socketio.autoscaling.minReplicas
		maxReplicas: #config.socketio.autoscaling.maxReplicas
		metrics: [
			if #config.socketio.autoscaling.targetCPU != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.socketio.autoscaling.targetCPU
						}
					}
				}
			},
			if #config.socketio.autoscaling.targetMemory != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.socketio.autoscaling.targetMemory
						}
					}
				}
			},
		]
	}
}
