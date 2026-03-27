package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

// #Ingress defines a template for Kubernetes Ingress.
#Ingress: networkingv1.#Ingress & {
	#config: #Config
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
		if #config.ingress.className != "" {
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
				host: h
				http: paths: [{
					path:     #config.ingress.path
					pathType: "Prefix"
					backend: service: {
						name: [
							if #config.varnish.enabled {
								"\(#config.metadata.name)-varnish"
							},
							"\(#config.metadata.name)-nginx",
						][0]
						port: number: 8080
					}
				}]
			},
		]
	}
}
