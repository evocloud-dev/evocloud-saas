package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#IngressWebhook: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-webhook"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.ingressWebhook.className != _|_ {
				"kubernetes.io/ingress.class": #config.ingressWebhook.className
			}
			if #config.ingressWebhook.annotations != _|_ {
				#config.ingressWebhook.annotations
			}
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingressWebhook.className != _|_ {
			ingressClassName: #config.ingressWebhook.className
		}

		if #config.ingressWebhook.tls.enabled {
			tls: [
				if #config.ingressWebhook.host != _|_ {
					hosts: [#config.ingressWebhook.host]
					secretName: #config.ingressWebhook.tls.secretName | *"\(#config.metadata.name)-tls"
				},
				if #config.ingressWebhook.tls.additional != _|_ for t in #config.ingressWebhook.tls.additional {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}

		rules: [
			if #config.ingressWebhook.host != _|_ {
				host: #config.ingressWebhook.host
				http: paths: [
					{
						path:     #config.ingressWebhook.path
						pathType: "Exact"
						backend: service: {
							name: #config.backendName
							port: number: #config.backend.service.port
						}
					},
					if #config.ingressWebhook.customBackends != _|_ for cb in #config.ingressWebhook.customBackends {
						cb
					},
				]
			},
			if #config.ingressWebhook.hosts != _|_ for h in #config.ingressWebhook.hosts {
				host: h
				http: paths: [
					{
						path:     #config.ingressWebhook.path
						pathType: "Exact"
						backend: service: {
							name: #config.backendName
							port: number: #config.backend.service.port
						}
					},
					if #config.ingressWebhook.customBackends != _|_ for cb in #config.ingressWebhook.customBackends {
						cb
					},
				]
			},
		]
	}
}