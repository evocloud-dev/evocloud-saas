package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#WebIngress: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-web"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.web.ingress.annotations) > 0 {
			annotations: #config.web.ingress.annotations
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.web.ingress.className != "" {
			ingressClassName: #config.web.ingress.className
		}
		rules: [
			for _, h in #config.web.ingress.hosts {
				host: h.host
				http: paths: [
					for _, p in h.paths {
						path:     p.path
						pathType: p.pathType
						backend: service: {
							name: "\(#config.metadata.name)-web"
							port: number: #config.web.service.port
						}
					},
				]
			},
		]
		if len(#config.web.ingress.tls) > 0 {
			tls: [
				for _, t in #config.web.ingress.tls {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}
	}
}
