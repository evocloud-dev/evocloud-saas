package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata:   #config.metadata
	if #config.service.annotations != _|_ {
		metadata: annotations: #config.service.annotations
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		if #config.service.type == "ClusterIP" && #config.service.clusterIP != _|_ {
			clusterIP: #config.service.clusterIP
		}
		if #config.service.type == "LoadBalancer" {
			if #config.service.loadBalancerIP != _|_ {
				loadBalancerIP: #config.service.loadBalancerIP
			}
			if #config.service.loadBalancerSourceRanges != _|_ {
				loadBalancerSourceRanges: #config.service.loadBalancerSourceRanges
			}
		}
		if #config.service.externalIPs != _|_ {
			externalIPs: #config.service.externalIPs
		}
		ports: [
			{
				name:       "http"
				port:       #config.service.port
				protocol:   "TCP"
				targetPort: 80
			},
		]
		selector: {
			"app.kubernetes.io/name":     "snipeit"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}
