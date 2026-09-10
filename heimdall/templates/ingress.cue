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
		labels:    _config.standardLabels
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
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}
		if len(_config.ingress.hosts) > 0 {
			rules: [
				for h in _config.ingress.hosts {
					host: h.host
					http: paths: [
						for p in h.paths {
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
}

