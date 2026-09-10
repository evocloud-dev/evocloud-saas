package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#IngressBuilder: networkingv1.#Ingress & {
	_config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      _config.fullname
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
		if len(_config.ingress.annotations) > 0 {
			annotations: _config.ingress.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if _config.ingress.ingressClassName != "" {
			ingressClassName: _config.ingress.ingressClassName
		}
		if len(_config.ingress.tls) > 0 {
			tls: [
				for t in _config.ingress.tls {
					secretName: t.secretName
					hosts:      t.hosts
				},
			]
		}
		rules: [
			for h in _config.ingress.hosts {
				host: h.host
				http: paths: [
					for p in (h.paths & [...{path: string, pathType: string}]) | [{path: "/", pathType: "Prefix"}] {
						path:     p.path
						pathType: p.pathType
						backend: service: {
							name: _config.fullname
							port: name: "http"
						}
					},
				]
			},
		]
	}
}
