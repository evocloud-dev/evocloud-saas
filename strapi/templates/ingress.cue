package templates

import (
	netv1 "k8s.io/api/networking/v1"
)

#Ingress: netv1.#Ingress & {
	#config: #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:        #config.fullname
		namespace:   #config.metadata.namespace
		labels:      #config.metadata.labels
		annotations: #config.ingress.annotations
	}
	spec: netv1.#IngressSpec & {
		if #config.ingress.ingressClassName != "" {
			ingressClassName: #config.ingress.ingressClassName
		}
		if len(#config.ingress.tls) > 0 {
			tls: [
				for item in #config.ingress.tls {
					secretName: item.secretName
					hosts:      item.hosts
				},
			]
		}
		if len(#config.ingress.hosts) > 0 {
			rules: [
				for item in #config.ingress.hosts {
					host: item.host
					http: paths: [
						for p in item.paths {
							path:     p.path
							pathType: p.pathType
							backend: service: {
								name: #config.fullname
								port: name: "http"
							}
						},
					]
				},
			]
		}
	}
}
