package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata:   #config.metadata
	if #config.ingress.annotations != _|_ {
		metadata: annotations: #config.ingress.annotations
	}
	spec: networkingv1.#IngressSpec & {
		rules: [
			{
				host: #config.ingress.host
				http: paths: [
					{
						path:     "/"
						pathType: "Prefix"
						backend: service: {
							name: #config.metadata.name
							port: number: #config.service.main.port
						}
					},
				]
			},
		]
		if #config.ingress.tls {
			tls: [
				{
					hosts: [#config.ingress.host]
					secretName: "\(#config.metadata.name)-tls"
				},
			]
		}
	}
}

