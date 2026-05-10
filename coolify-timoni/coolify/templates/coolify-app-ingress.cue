package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#CoolifyAppIngress: {
	#config: #Config
	if #config.ingress.enabled {
		ingress: networkingv1.#Ingress & {
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				name:      "\(#config.metadata.name)-app-ingress"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels & {
					"app.kubernetes.io/component": "core"
				}
				if #config.metadata.annotations != _|_ {
					annotations: #config.metadata.annotations & #config.ingress.annotations
				}
				if #config.metadata.annotations == _|_ {
					annotations: #config.ingress.annotations
				}
			}
			spec: networkingv1.#IngressSpec & {
				if #config.ingress.className != "" {
					ingressClassName: #config.ingress.className
				}
				rules: [
					for h in #config.ingress.hosts {
						host: h.host
						http: paths: [
							for p in h.paths {
								path:     p.path
								pathType: p.pathType
								backend: service: {
									name: "\(#config.metadata.name)-app-svc"
									port: number: #config.coolifyApp.service.port
								}
							},
						]
					},
				]
				if #config.ingress.tls != [] {
					tls: [
						for t in #config.ingress.tls {
							hosts:      t.hosts
							secretName: t.secretName
						},
					]
				}
			}
		}
	}
}
