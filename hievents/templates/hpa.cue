package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#BackendHPA: autoscalingv2.HorizontalPodAutoscaler & {
	#config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      #config._backendName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "backend"
		}
	}
	spec: {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       #config._backendName
		}
		minReplicas: #config.backend.autoscaling.minReplicas
		maxReplicas: #config.backend.autoscaling.maxReplicas
		metrics: [{
			type: "Resource"
			resource: {
				name: "cpu"
				target: {
					type:               "Utilization"
					averageUtilization: #config.backend.autoscaling.targetCPUUtilizationPercentage
				}
			}
		}]
	}
}

#FrontendHPA: autoscalingv2.HorizontalPodAutoscaler & {
	#config: #Config

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      #config._frontendName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "frontend"
		}
	}
	spec: {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       #config._frontendName
		}
		minReplicas: #config.frontend.autoscaling.minReplicas
		maxReplicas: #config.frontend.autoscaling.maxReplicas
		metrics: [{
			type: "Resource"
			resource: {
				name: "cpu"
				target: {
					type:               "Utilization"
					averageUtilization: #config.frontend.autoscaling.targetCPUUtilizationPercentage
				}
			}
		}]
	}
}
