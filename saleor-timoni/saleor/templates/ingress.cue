package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
	#config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "api"
		}
		annotations: #config.ingress.annotations & #config.ingress.api.annotations
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.className != "" {
			ingressClassName: #config.ingress.className
		}

		_tlsEnabled: bool | *false
		if #config.global.tls.enabled || #config.ingress.api.tls != [] {
			_tlsEnabled: true
		}

		if _tlsEnabled {
			tls: [
				if #config.global.tls.enabled && #config.global.tls.secretName != "" {
					{
						hosts: [
							for h in #config.ingress.api.hosts {
								h.host
							},
						]
						secretName: #config.global.tls.secretName
					}
				},
				if !(#config.global.tls.enabled && #config.global.tls.secretName != "") && #config.ingress.api.tls != [] {
					for t in #config.ingress.api.tls {
						hosts:      t.hosts
						secretName: t.secretName
					}
				},
				if #config.global.tls.enabled && #config.global.tls.secretName == "" && #config.ingress.api.tls == [] {
					{
						hosts: [
							for h in #config.ingress.api.hosts {
								h.host
							},
						]
					}
				},
			]
		}

		rules: [
			for h in #config.ingress.api.hosts {
				host: h.host
				http: paths: [
					for p in h.paths {
						path:     p.path
						pathType: p.pathType
						backend: service: {
							name: "\(#config.metadata.name)-api"
							port: name: "http"
						}
					},
					if #config.dashboard.enabled {
						{
							path:     "/dashboard/"
							pathType: "Prefix"
							backend: service: {
								name: "\(#config.metadata.name)-dashboard"
								port: name: "http"
							}
						}
					},
				]
			},
		]
	}
}
