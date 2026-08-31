package templates

#IngressBuilder: {
	_config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      _config.fullname
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
		if _config.ingress.annotations != _|_ {
			annotations: _config.ingress.annotations
		}
	}
	spec: {
		if _config.ingress.ingressClassName != "" {
			ingressClassName: _config.ingress.ingressClassName
		}
		rules: [
			for h in _config.ingress.hosts {
				host: h.host
				http: paths: [
					for p in h.paths {
						path:     p.path
						pathType: p.pathType
						backend: service: {
							name: _config.fullname
							port: number: _config.service.port
						}
					},
				]
			},
		]
		if len(_config.ingress.tls) > 0 {
			tls: _config.ingress.tls
		}
	}
}
