package templates

import (
	netv1 "k8s.io/api/networking/v1"
)

#ServerIngress: netv1.#Ingress & {
	#config: #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name: "\(#config.metadata.name)-server"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "server"
		}
		if #config.server.ingress.acme {
			annotations: {
				"kubernetes.io/ingress.class": #config.server.ingress.className
				"cert-manager.io/cluster-issuer": "letsencrypt-prod"
			}
		}
	}
	spec: netv1.#IngressSpec & {
		if #config.server.ingress.className != "" {
			ingressClassName: #config.server.ingress.className
		}
		if #config.server.ingress.tls != [] {
			tls: [
				for t in #config.server.ingress.tls {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}
		rules: [
			for h in #config.server.ingress.hosts {
				host: h.host
				http: paths: [
					for p in h.paths {
						path:     p.path
						pathType: p.pathType
						backend: service: {
							name: "\(#config.metadata.name)-server"
							port: number: #config.server.service.port
						}
					},
				]
			},
		]
	}
}
