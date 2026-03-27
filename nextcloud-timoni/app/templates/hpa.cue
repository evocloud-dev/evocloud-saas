package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
	corev1 "k8s.io/api/core/v1"
)

#HorizontalPodAutoscaler: autoscalingv2.#HorizontalPodAutoscaler & {
	#in:    #Config
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata:   #in.metadata
	spec: {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       #in.metadata.name
		}
		
		minReplicas: #in.hpa.minPods
		maxReplicas: #in.hpa.maxPods

		metrics: [
			{
				type: autoscalingv2.#ResourceMetricSourceType
				resource: {
					name: corev1.#ResourceCPU
					target: {
						type: autoscalingv2.#UtilizationMetricType
						averageUtilization: #in.hpa.cputhreshold
					}
				}
			}
		]
	}
}
