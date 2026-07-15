package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#ServerIngress: networkingv1.#Ingress & {
	#config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      *"\((#config.metadata.name))-server" | string
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.server.ingress.annotations != _|_ {
			annotations: #config.server.ingress.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.server.ingress.ingressClassName != "" {
			ingressClassName: #config.server.ingress.ingressClassName
		}
		if #config.server.ingress.tls || (#config.server.ingress.extraTls != _|_ && len(#config.server.ingress.extraTls) > 0) {
			tls: [
				if #config.server.ingress.tls == true || #config.server.ingress.tls != false {
					{
						hosts: [
							for h in #config.server.ingress.hosts {h},
							for eh in #config.server.ingress.extraHosts if eh.name != _|_ {eh.name},
						]
						secretName: "peertube-server-tls"
					}
				},
				if #config.server.ingress.extraTls != _|_ {
					for t in #config.server.ingress.extraTls {t}
				},
			]
		}
		rules: [
			if len(#config.server.ingress.hosts) > 0 {
				for h in #config.server.ingress.hosts {
					host: h
					http: paths: [
						if #config.server.ingress.extraPaths != _|_ {
							for ep in #config.server.ingress.extraPaths {ep}
						},
						{
							path:     #config.server.ingress.path
							pathType: #config.server.ingress.pathType
							backend: service: {
								name: *"\((#config.metadata.name))-svc" | string
								port: number: #config.server.service.port
							}
						},
					]
				}
			},
			if len(#config.server.ingress.hosts) == 0 {
				{
					http: paths: [
						if #config.server.ingress.extraPaths != _|_ {
							for ep in #config.server.ingress.extraPaths {ep}
						},
						{
							path:     #config.server.ingress.path
							pathType: #config.server.ingress.pathType
							backend: service: {
								name: *"\((#config.metadata.name))-svc" | string
								port: number: #config.server.service.port
							}
						},
					]
				}
			},
			if #config.server.ingress.extraHosts != _|_ {
				for eh in #config.server.ingress.extraHosts {
					host: eh.name
					http: paths: [
						{
							path: *#config.server.ingress.path | string
							if eh.path != _|_ {
								path: eh.path
							}
							pathType: *#config.server.ingress.pathType | string
							if eh.pathType != _|_ {
								pathType: eh.pathType
							}
							backend: service: {
								name: *"\((#config.metadata.name))-svc" | string
								port: number: #config.server.service.port
							}
						},
					]
				}
			},
			if #config.server.ingress.extraRules != _|_ {
				for er in #config.server.ingress.extraRules {er}
			},
		]
	}
}
