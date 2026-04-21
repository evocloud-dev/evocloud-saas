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
		labels: #config.metadata.labels & #config.ingress.labels & {
			"app.kubernetes.io/component": "openproject"
		}
		if #config.ingress.annotations != _|_ {
			annotations: #config.ingress.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.ingressClassName != "" {
			ingressClassName: #config.ingress.ingressClassName
		}
		if #config.ingress.tls.enabled {
			tls: [
				if #config.ingress.tls.secretName != "" {
					{
						hosts: [#config.ingress.host]
						secretName: #config.ingress.tls.secretName
					}
				},
				for t in #config.ingress.tls.extraTls {
					t
				},
			]
		}
		rules: [{
			host: #config.ingress.host
			http: paths: [
				if #config.hocuspocus.enabled {
					{
						path:     #config.hocuspocus.ingress.path
						pathType: #config.hocuspocus.ingress.pathType
						backend: service: {
							name: "\(#config.metadata.name)-hocuspocus"
							port: name: "http"
						}
					}
				},
				{
					path:     #config.ingress.path
					pathType: #config.ingress.pathType
					backend: service: {
						name: #config.metadata.name
						port: name: "http"
					}
				},
			]
		}]
	}
}
