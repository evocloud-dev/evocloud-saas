package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#IngressMedia: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-media"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.ingressMedia.className != _|_ {
				"kubernetes.io/ingress.class": #config.ingressMedia.className
			}
			if #config.ingressMedia.annotations != _|_ {
				#config.ingressMedia.annotations
			}
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingressMedia.className != _|_ {
			ingressClassName: #config.ingressMedia.className
		}

		if #config.ingressMedia.tls.enabled {
			tls: [
				if #config.ingressMedia.host != _|_ {
					hosts: [#config.ingressMedia.host]
					secretName: #config.ingressMedia.tls.secretName | *"\(#config.metadata.name)-tls"
				},
				if #config.ingressMedia.tls.additional != _|_ for t in #config.ingressMedia.tls.additional {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}

		rules: [
			if #config.ingressMedia.host != _|_ {
				host: #config.ingressMedia.host
				http: paths: [{
					path:     #config.ingressMedia.path
					pathType: "ImplementationSpecific"
					backend: service: {
						name: "\(#config.metadata.name)-media"
						port: number: #config.serviceMedia.port
					}
				}]
			},
			if #config.ingressMedia.hosts != _|_ for h in #config.ingressMedia.hosts {
				host: h
				http: paths: [{
					path:     #config.ingressMedia.path
					pathType: "ImplementationSpecific"
					backend: service: {
						name: "\(#config.metadata.name)-media"
						port: number: #config.serviceMedia.port
					}
				}]
			},
		]
	}
}