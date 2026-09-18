package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
	#config: #Config
	apiVersion: "networking/v1"
	kind:       "Ingress"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.ingress.annotations != _|_ {
			annotations: #config.ingress.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.className != _|_ {
			ingressClassName: #config.ingress.className
		}
		if #config.ingress.tls != _|_ {
			tls: #config.ingress.tls
		}
		if #config.ingress.hosts != _|_ {
			rules: [
				for h in #config.ingress.hosts {
					host: h.host
					http: paths: [
						for p in h.paths {
							path:     p.path
							pathType: p.pathType
							backend: service: {
								name: #config.metadata.name
								port: number: #config.service.port
							}
						},
					]
				},
			]
		}
	}
}

