package templates

import (
	autoscalev2 "k8s.io/api/autoscaling/v2"
)

#WebHPA: {
	#config: #Config
	if #config.web.hpa.enabled {
		apiVersion: "autoscaling/v2"
		kind:       "HorizontalPodAutoscaler"
		metadata: {
			name:      "\(#config.metadata.name)-web"
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
			if #config.metadata.annotations != _|_ {
				annotations: #config.metadata.annotations
			}
		}
		spec: autoscalev2.#HorizontalPodAutoscalerSpec & {
			scaleTargetRef: {
				apiVersion: "apps/v1"
				kind:       "Deployment"
				name:       "\(#config.metadata.name)-web"
			}
			minReplicas: #config.web.hpa.minpods
			maxReplicas: #config.web.hpa.maxpods
			metrics: [
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: #config.web.hpa.cputhreshold
						}
					}
				},
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: #config.web.hpa.memorythreshold
						}
					}
				},
			]
		}
	}
}
