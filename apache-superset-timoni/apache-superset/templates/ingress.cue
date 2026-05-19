package templates

import (
	netv1 "k8s.io/api/networking/v1"
)

#Ingress: netv1.#Ingress & {
	#config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels: {
			app:      #config.metadata.name
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
		if #config.ingress.annotations != _|_ {
			annotations: #config.ingress.annotations
		}
	}
	spec: netv1.#IngressSpec & {
		if #config.ingress.ingressClassName != null {
			ingressClassName: #config.ingress.ingressClassName
		}
		if #config.ingress.tls != [] {
			tls: #config.ingress.tls
		}
		rules: [
			for h in #config.ingress.hosts {
				host: h
				http: paths: [
					{
						path:     #config.ingress.path
						pathType: #config.ingress.pathType
						backend: service: {
							name: #config.metadata.name
							port: name: "http"
						}
					},
					if #config.supersetWebsockets.enabled {
						{
							path:     #config.supersetWebsockets.ingress.path
							pathType: #config.supersetWebsockets.ingress.pathType
							backend: service: {
								name: "\(#config.metadata.name)-ws"
								port: name: "ws"
							}
						}
					},
				]
			},
		]
	}
}
