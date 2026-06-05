package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
	#config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata:   #config.metadata
	if #config.ingress.annotations != _|_ {
		metadata: annotations: #config.ingress.annotations
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.className != "" {
			ingressClassName: #config.ingress.className
		}
		if len(#config.ingress.tls) > 0 {
			tls: [
				for t in #config.ingress.tls {
					hosts:      t.hosts
					secretName: t.secretName
				}
			]
		}
		rules: [
			for h in #config.ingress.hosts {
				host: h
				http: {
					paths: [
						{
							path:     #config.ingress.path
							pathType: #config.ingress.pathType
							backend: service: {
								name: #config.metadata.name
								port: number: 80
							}
						}
					]
				}
			}
		]
	}
}
