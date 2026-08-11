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
		if #config.ingress.tls != _|_ {
				tls: #config.ingress.tls
		}
		if #config.ingress.hosts != _|_ {
				rules: [ for host in #config.ingress.hosts {
					{ host: host.host, http: {
						paths: [ for p in host.paths {
							{ path: p.path, pathType: p.pathType, backend: {
								service: {
									name: p.backend.service.name
									port: { number: p.backend.service.portNumber }
								}
							} }
						} ]
					} }
			} ]
		}
	}
}
