package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#HorizontalPodAutoscaler: autoscalingv2.#HorizontalPodAutoscaler & {
	#config:      #Config
	#component:   string
	#targetName:  string
	#autoscaling: #Autoscaling

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: #component
	}

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata:   #meta
	spec: autoscalingv2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       #targetName
		}
		minReplicas: #autoscaling.minReplicas
		maxReplicas: #autoscaling.maxReplicas
		metrics: [
			if #autoscaling.targetCPUUtilizationPercentage != _|_ {
				type: "Resource"
				resource: {
					name: "cpu"
					target: {
						type:               "Utilization"
						averageUtilization: #autoscaling.targetCPUUtilizationPercentage
					}
				}
			},
			if #autoscaling.targetMemoryUtilizationPercentage != _|_ {
				type: "Resource"
				resource: {
					name: "memory"
					target: {
						type:               "Utilization"
						averageUtilization: #autoscaling.targetMemoryUtilizationPercentage
					}
				}
			},
		]
	}
}

