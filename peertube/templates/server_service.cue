package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServerService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      *"\((#config.metadata.name))-svc" | string
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.server.service.annotations != _|_ {
			annotations: #config.server.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.server.service.type
		ports: [
			{
				name:       "server"
				port:       #config.server.service.port
				protocol:   "TCP"
				targetPort: "server"
				#appProto:  *"" | string
				if (#config.server.service["appProtocol"] & string) != _|_ {
					#appProto: #config.server.service["appProtocol"]
				}
				if #appProto != "" {
					appProtocol: #appProto
				}
				if #config.server.service.type == "NodePort" && #config.server.service.nodePort != _|_ {
					nodePort: #config.server.service.nodePort
				}
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "server"
		}
		if (#config.server.service.trafficDistribution & string) != _|_ {
			trafficDistribution: #config.server.service.trafficDistribution
		}
	}
}
