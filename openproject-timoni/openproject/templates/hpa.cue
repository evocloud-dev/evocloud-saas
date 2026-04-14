package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#HPA: autoscalingv2.#HorizontalPodAutoscaler & {
	#config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(#config.metadata.name)-web-hpa"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"openproject/process":        "web"
			"app.kubernetes.io/component": "web"
		}
	}
	spec: autoscalingv2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       "\(#config.metadata.name)-web"
		}
		minReplicas: #config.autoscaling.minReplicas
		maxReplicas: #config.autoscaling.maxReplicas
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
			for m in #config.autoscaling.customMetrics {
				{
					type: m.type
					if m.type == "Pods" {
						pods: m.pods
					}
					if m.type == "Object" {
						object: m.object
					}
					if m.type == "External" {
						external: m.external
					}
					if m.type == "Resource" {
						resource: m.resource
					}
				}
			},
		]
		if #config.autoscaling.behavior != _|_ {
			behavior: #config.autoscaling.behavior
		}
	}
}
