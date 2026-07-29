package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServerMetricsService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      *"\((#config.metadata.name))-metrics" | string
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.server.metricsService.annotations != _|_ {
			annotations: #config.server.metricsService.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.server.metricsService.type
		ports: [
			{
				name:       "metrics"
				port:       #config.server.metricsService.port
				protocol:   "TCP"
				targetPort: "metrics"
				#appProto:  *"" | string
				if (#config.server.metricsService["appProtocol"] & string) != _|_ {
					#appProto: #config.server.metricsService["appProtocol"]
				}
				if #appProto != "" && #appProto != null {
					appProtocol: #appProto
				}
				if #config.server.metricsService.type == "NodePort" && #config.server.metricsService.nodePort != _|_ {
					nodePort: #config.server.metricsService.nodePort
				}
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "server"
		}
		if (#config.server.metricsService.trafficDistribution & string) != _|_ {
			trafficDistribution: #config.server.metricsService.trafficDistribution
		}
	}
}
