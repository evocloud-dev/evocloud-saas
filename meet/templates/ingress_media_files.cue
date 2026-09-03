package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#IngressMediaFiles: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-media-files"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.ingressMediaFiles.className != _|_ {
				"kubernetes.io/ingress.class": #config.ingressMediaFiles.className
			}
			if #config.ingressMediaFiles.annotations != _|_ {
				#config.ingressMediaFiles.annotations
			}
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingressMediaFiles.className != _|_ {
			ingressClassName: #config.ingressMediaFiles.className
		}

		if #config.ingressMediaFiles.tls.enabled {
			tls: [
				if #config.ingressMediaFiles.host != _|_ {
					hosts: [#config.ingressMediaFiles.host]
					secretName: #config.ingressMediaFiles.tls.secretName | *"\(#config.metadata.name)-tls"
				},
				if #config.ingressMediaFiles.tls.additional != _|_ for t in #config.ingressMediaFiles.tls.additional {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}

		rules: [
			if #config.ingressMediaFiles.host != _|_ {
				host: #config.ingressMediaFiles.host
				http: paths: [{
					path:     #config.ingressMediaFiles.path
					pathType: "ImplementationSpecific"
					backend: service: {
						name: "\(#config.metadata.name)-media-files"
						port: number: #config.serviceMediaFiles.port
					}
				}]
			},
			if #config.ingressMediaFiles.hosts != _|_ for h in #config.ingressMediaFiles.hosts {
				host: h
				http: paths: [{
					path:     #config.ingressMediaFiles.path
					pathType: "ImplementationSpecific"
					backend: service: {
						name: "\(#config.metadata.name)-media-files"
						port: number: #config.serviceMediaFiles.port
					}
				}]
			},
		]
	}
}