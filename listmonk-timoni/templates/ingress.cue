package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: {
	#config: #Config
	#helpers: #Helpers

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      #helpers.fullname
		namespace: #config.metadata.namespace
		labels:    #helpers.labels
		if #config.ingress.annotations != _|_ {
			annotations: #config.ingress.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.className != "" {
			ingressClassName: #config.ingress.className
		}
		if #config.ingress.tls != _|_ {
			tls: [
				for t in #config.ingress.tls {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}
		rules: [
			for h in #config.ingress.hosts {
				host: h.host
				http: paths: [
					for p in h.paths {
						path:     p.path
						pathType: p.pathType
						backend: service: {
							name: #helpers.fullname
							port: number: #config.service.port
						}
					},
				]
			},
		]
	}
}
