package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
	#config: #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      #config.fullname
		namespace: #config.namespace
		labels:    #config.labels
		if #config.ingress.annotations != _|_ && len(#config.ingress.annotations) > 0 {
			annotations: #config.ingress.annotations
		}
	}
	spec: {
		if #config.ingress.ingressClassName != "" {
			ingressClassName: #config.ingress.ingressClassName
		}
		if #config.ingress.tls != _|_ && len(#config.ingress.tls) > 0 {
			tls: #config.ingress.tls
		}
		rules: [
			{
				if #config.ingress.host != "" {
					host: #config.ingress.host
				}
				http: paths: [
					{
						path:     "/"
						pathType: "Prefix"
						backend: service: {
							name: #config.fullname
							port: number: #config.service.port
						}
					},
				]
			},
		]
	}
}
