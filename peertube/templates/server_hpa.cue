package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#ServerHPA: autoscalingv2.#HorizontalPodAutoscaler & {
	#config:    #Config
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      *"\((#config.metadata.name))-server" | string
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: autoscalingv2.#HorizontalPodAutoscalerSpec & {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       *"\((#config.metadata.name))-server" | string
		}
		minReplicas: #config.server.autoscaling.minReplicas
		maxReplicas: #config.server.autoscaling.maxReplicas
		if #config.server.autoscaling.metrics != _|_ {
			metrics: [
				for m in #config.server.autoscaling.metrics {m},
			]
		}
		if #config.server.autoscaling.behavior != _|_ {
			behavior: #config.server.autoscaling.behavior
		}
	}
}
