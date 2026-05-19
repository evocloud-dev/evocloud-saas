package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceFlower: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-flower"
		namespace: #config.metadata.namespace
		labels: {
			app:      #config.metadata.name
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
		if #config.supersetCeleryFlower.service.annotations != _|_ {
			annotations: #config.supersetCeleryFlower.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.supersetCeleryFlower.service.type
		ports: [{
			name:       "flower"
			port:       #config.supersetCeleryFlower.service.port
			targetPort: "flower"
			protocol:   "TCP"
			if #config.supersetCeleryFlower.service.type == "NodePort" || #config.supersetCeleryFlower.service.type == "LoadBalancer" {
				if #config.supersetCeleryFlower.service.nodePort.http != null {
					nodePort: #config.supersetCeleryFlower.service.nodePort.http
				}
			}
		}]
		selector: {
			app:     "\(#config.metadata.name)-flower"
			release: #config.metadata.name
		}
		if #config.supersetCeleryFlower.service.loadBalancerIP != null {
			loadBalancerIP: #config.supersetCeleryFlower.service.loadBalancerIP
		}
	}
}
