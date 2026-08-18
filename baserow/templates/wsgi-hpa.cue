package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#HpaWsgi: autoscalingv2.#HorizontalPodAutoscaler & {
	#config:    #Config
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-wsgi"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-wsgi"
		}
		minReplicas: #config.backend.wsgi.autoscaling.minReplicas
		maxReplicas: #config.backend.wsgi.autoscaling.maxReplicas
		metrics: [
			if #config.backend.wsgi.autoscaling.targetCPUUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.backend.wsgi.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.backend.wsgi.autoscaling.targetMemoryUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.backend.wsgi.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}
