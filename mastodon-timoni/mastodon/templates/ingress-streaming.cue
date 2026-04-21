package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#IngressStreaming: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		namespace: #config.#namespace
		name:   "\(#config.metadata.name)-streaming"
		labels: #config.metadata.labels
		if #config.ingress.streaming.annotations != _|_ {
			annotations: #config.ingress.streaming.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.streaming.ingressClassName != "" {
			ingressClassName: #config.ingress.streaming.ingressClassName
		}
		if len(#config.ingress.streaming.tls) > 0 {
			tls: [
				for t in #config.ingress.streaming.tls {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}
		rules: [
			for h in #config.ingress.streaming.hosts {
				host: h.host
				http: paths: [
					for p in h.paths {
						path:     "\(p.path)api/v1/streaming"
						pathType: p.pathType
						backend: service: {
							name: "\(#config.metadata.name)-streaming"
							port: number: #config.mastodon.streaming.port
						}
					},
				]
			},
		]
	}
}
