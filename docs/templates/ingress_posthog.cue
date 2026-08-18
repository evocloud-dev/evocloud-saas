package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#IngressPosthog: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-posthog"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.posthog.ingress.className != _|_ {
				"kubernetes.io/ingress.class": #config.posthog.ingress.className
			}
			if #config.posthog.ingress.annotations != _|_ {
				#config.posthog.ingress.annotations
			}
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.posthog.ingress.className != _|_ {
			ingressClassName: #config.posthog.ingress.className
		}

		if #config.posthog.ingress.tls.enabled {
			tls: [
				if #config.posthog.ingress.host != _|_ {
					hosts: [#config.posthog.ingress.host]
					secretName: #config.posthog.ingress.tls.secretName | *"\(#config.metadata.name)-posthog-tls"
				},
				if #config.posthog.ingress.tls.additional != _|_ for t in #config.posthog.ingress.tls.additional {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}

		rules: [
			if #config.posthog.ingress.host != _|_ {
				host: #config.posthog.ingress.host
				http: paths: [{
					path:     #config.posthog.ingress.path
					pathType: "Prefix"
					backend: service: {
						name: "\(#config.posthog.fullname)-proxy"
						port: number: #config.posthog.service.port
					}
				}]
			},
			if #config.posthog.ingress.hosts != _|_ for h in #config.posthog.ingress.hosts {
				host: h
				http: paths: [
					{
						path:     #config.posthog.ingress.path
						pathType: "Prefix"
						backend: service: {
							name: "\(#config.posthog.fullname)-proxy"
							port: number: #config.posthog.service.port
						}
					},
					if #config.posthog.assetsService.customBackends != _|_ for cb in #config.posthog.assetsService.customBackends {
						cb
					},
				]
			},
		]
	}
}
