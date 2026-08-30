package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
	#config: #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.ingress.annotations != _|_ {
			annotations: #config.ingress.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.className != "" {
			ingressClassName: #config.ingress.className
		}
		rules: [for h in #config.ingress.hosts {
			host: h.host
			http: paths: [for p in h.paths {
				path:     p.path
				pathType: p.pathType
				backend: service: {
					name: #config.#nginxServiceName
					port: number: #config.nginx.service.port
				}
			}]
		}]
		if #config.ingress.tls != _|_ && len(#config.ingress.tls) > 0 {
			tls: [for t in #config.ingress.tls {
				if t.hosts != _|_ {
					hosts: t.hosts
				}
				if t.secretName != _|_ {
					secretName: t.secretName
				}
			}]
		}
	}
}
