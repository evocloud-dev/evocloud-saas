package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#IngressWeb: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		namespace: #config.#namespace
		name:   #config.metadata.name
		labels: #config.metadata.labels
		if #config.ingress.annotations != _|_ {
			annotations: #config.ingress.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.ingressClassName != "" {
			ingressClassName: #config.ingress.ingressClassName
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
							name: "\(#config.metadata.name)-web"
							port: number: #config.mastodon.web.port
						}
					},
					if !#config.ingress.streaming.enabled {
						for p in h.paths {
							path:     "\(p.path)api/v1/streaming"
							pathType: p.pathType
							backend: service: {
								name: "\(#config.metadata.name)-streaming"
								port: number: #config.mastodon.streaming.port
							}
						}
					},
				]
			},
		]
	}
}
