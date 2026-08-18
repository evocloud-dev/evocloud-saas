package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#IngressAdmin: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-admin"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		
		// Unifies legacy annotations fallback logic directly in the schema declaration
		annotations: {
			if #config.ingressAdmin.className != _|_ {
				"kubernetes.io/ingress.class": #config.ingressAdmin.className
			}
			if #config.ingressAdmin.annotations != _|_ {
				#config.ingressAdmin.annotations
			}
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingressAdmin.className != _|_ {
			ingressClassName: #config.ingressAdmin.className
		}

		if #config.ingressAdmin.tls.enabled {
			tls: [
				if #config.ingressAdmin.host != _|_ {
					hosts: [#config.ingressAdmin.host]
					secretName: #config.ingressAdmin.tls.secretName | *"\(#config.metadata.name)-tls"
				},
				if #config.ingressAdmin.tls.additional != _|_ for t in #config.ingressAdmin.tls.additional {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}

		rules: [
			if #config.ingressAdmin.host != _|_ {
				host: #config.ingressAdmin.host
				http: paths: [
					{
						path:     #config.ingressAdmin.path
						pathType: "Prefix"
						backend: service: {
							name: #config.backendName
							port: number: #config.backend.service.port
						}
					},
					{
						path:     "/static"
						pathType: "Prefix"
						backend: service: {
							name: #config.backendName
							port: number: #config.backend.service.port
						}
					},
				]
			},
			if #config.ingressAdmin.hosts != _|_ for h in #config.ingressAdmin.hosts {
				host: h
				http: paths: [
					{
						path:     #config.ingressAdmin.path
						pathType: "Prefix"
						backend: service: {
							name: #config.backendName
							port: number: #config.backend.service.port
						}
					},
				]
			},
		]
	}
}