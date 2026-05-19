package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceWs: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-ws"
		namespace: #config.metadata.namespace
		labels: {
			app:      #config.metadata.name
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
		if #config.supersetWebsockets.service.annotations != _|_ {
			annotations: #config.supersetWebsockets.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.supersetWebsockets.service.type
		ports: [{
			name:       "ws"
			port:       #config.supersetWebsockets.service.port
			targetPort: "ws"
			protocol:   "TCP"
			if #config.supersetWebsockets.service.type == "NodePort" || #config.supersetWebsockets.service.type == "LoadBalancer" {
				if #config.supersetWebsockets.service.nodePort.http != null {
					nodePort: #config.supersetWebsockets.service.nodePort.http
				}
			}
		}]
		selector: {
			app:     "\(#config.name)-ws"
			release: #config.metadata.name
		}
		if #config.supersetWebsockets.service.loadBalancerIP != null {
			loadBalancerIP: #config.supersetWebsockets.service.loadBalancerIP
		}
	}
}
