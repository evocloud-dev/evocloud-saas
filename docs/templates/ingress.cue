package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.ingress.className != _|_ {
				"kubernetes.io/ingress.class": #config.ingress.className
			}
			if #config.ingress.annotations != _|_ {
				#config.ingress.annotations
			}
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.className != _|_ {
			ingressClassName: #config.ingress.className
		}

		if #config.ingress.tls.enabled {
			tls: [
				if #config.ingress.host != _|_ {
					hosts: [#config.ingress.host]
					secretName: #config.ingress.tls.secretName | *"\(#config.metadata.name)-tls"
				},
				if #config.ingress.tls.additional != _|_ for t in #config.ingress.tls.additional {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}

		rules: [
			if #config.ingress.host != _|_ {
				host: #config.ingress.host
				http: paths: [
					{
						path:     #config.ingress.path
						pathType: "Prefix"
						backend: service: {
							name: #config.frontendName
							port: number: #config.frontend.service.port
						}
					},
					{
						path:     "/api"
						pathType: "Prefix"
						backend: service: {
							name: #config.backendName
							port: number: #config.backend.service.port
						}
					},
					{
						path:     "/external_api"
						pathType: "Prefix"
						backend: service: {
							name: #config.backendName
							port: number: #config.backend.service.port
						}
					},
					if #config.ingress.customBackends != _|_ for cb in #config.ingress.customBackends {
						cb
					},
				]
			},
			if #config.ingress.hosts != _|_ for h in #config.ingress.hosts {
				host: h
				http: paths: [
					{
						path:     #config.ingress.path
						pathType: "Prefix"
						backend: service: {
							name: #config.frontendName
							port: number: #config.frontend.service.port
						}
					},
					{
						path:     "/api"
						pathType: "Prefix"
						backend: service: {
							name: #config.backendName
							port: number: #config.backend.service.port
						}
					},
					{
						path:     "/external_api"
						pathType: "Prefix"
						backend: service: {
							name: #config.backendName
							port: number: #config.backend.service.port
						}
					},
					if #config.ingress.customBackends != _|_ for cb in #config.ingress.customBackends {
						cb
					},
				]
			},
		]
	}
}