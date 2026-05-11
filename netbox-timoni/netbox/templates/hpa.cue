package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#HPA: autoscalingv2.#HorizontalPodAutoscaler & {
	#config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	spec: autoscalingv2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       #config._fullname
		}
		minReplicas: #config.autoscaling.minReplicas
		maxReplicas: #config.autoscaling.maxReplicas
		if len(#config.autoscaling.behavior) > 0 {
			behavior: #config.autoscaling.behavior
		}
		metrics: [
			if #config.autoscaling.targetCPUUtilizationPercentage != null {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if #config.autoscaling.targetMemoryUtilizationPercentage != null {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
		]
	}
}



