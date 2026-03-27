package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		if #config.ingress.ingressName != _|_ {
			name: #config.ingress.ingressName
		}
		if #config.ingress.ingressName == _|_ {
			name: #config.metadata.name
		}
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.ingress.annotations != _|_ {
			annotations: #config.ingress.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.className != _|_ {
			ingressClassName: #config.ingress.className
		}
		if len(#config.ingress.tls) > 0 {
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
							name: #config.metadata.name
							port: number: #config.nginx.service.port
						}
					},
				]
			},
		]
	}
}
