package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: {
	#config: #Config
	if #config.ingress.enabled {
		apiVersion: "networking.k8s.io/v1"
		kind:       "Ingress"
		metadata: {
			name:      #config.metadata.name
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
			if #config.ingress.annotations != _|_ {
				annotations: #config.ingress.annotations
			}
		}
		spec: networkingv1.#IngressSpec & {
			if #config.ingress.ingressClassName != _|_ {
				ingressClassName: #config.ingress.ingressClassName
			}
			if #config.ingress.tls != _|_ {
				tls: [for t in #config.ingress.tls {
					hosts:      t.hosts
					secretName: t.secretName
				}]
			}
			rules: [for h in #config.ingress.hosts {
				host: h.host
				http: paths: [for p in h.paths {
					path:     p.path
					pathType: p.pathType
					backend: service: {
						if p.backend != _|_ {
							name: p.backend.service.name
							port: number: p.backend.service.port.number
						}
						if p.backend == _|_ {
							name: #config.metadata.name
							port: number: #config.services.internalPort
						}
					}
				}]
			}]
		}
	}
}
