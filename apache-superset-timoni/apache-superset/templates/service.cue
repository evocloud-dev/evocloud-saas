package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels: {
			app:      #config.metadata.name
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
		if #config.service.annotations != _|_ {
			annotations: #config.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		ports: [{
			name:       "http"
			port:       #config.service.port
			targetPort: "http"
			protocol:   "TCP"
			if #config.service.type == "NodePort" || #config.service.type == "LoadBalancer" {
				if #config.service.nodePort.http != null {
					nodePort: #config.service.nodePort.http
				}
			}
		}]
		selector: {
			app:     #config.name
			release: #config.metadata.name
		}
		if #config.service.loadBalancerIP != null {
			loadBalancerIP: #config.service.loadBalancerIP
		}
	}
}
