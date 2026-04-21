package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.ingress.annotations != _|_ || #config.commonAnnotations != _|_ {
			annotations: {
				for k, v in #config.ingress.annotations {
					"\(k)": v
				}
				for k, v in #config.commonAnnotations {
					"\(k)": v
				}
			}
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.className != "" {
			ingressClassName: #config.ingress.className
		}
		if #config.ingress.tls != _|_ {
			tls: [
				for t in #config.ingress.tls {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}
		rules: [
			for h in #config.ingress.hosts {
				host: h.host
				http: paths: [
					for p in h.paths {
						if (p & string) != _|_ {
							path:     p
							pathType: "Prefix"
							backend: service: {
								name: #config._fullname
								port: name: "http"
							}
						}
						if (p & string) == _|_ {
							path:     p.path
							pathType: p.pathType
							backend: service: {
								name: #config._fullname
								port: name: "http"
							}
						}
					},
				]
			},
		]
	}
}
