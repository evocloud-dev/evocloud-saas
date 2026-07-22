package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#IngressCollaborationApi: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-collaboration-api"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.ingressCollaborationApi.className != _|_ {
				"kubernetes.io/ingress.class": #config.ingressCollaborationApi.className
			}
			if #config.ingressCollaborationApi.annotations != _|_ {
				#config.ingressCollaborationApi.annotations
			}
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingressCollaborationApi.className != _|_ {
			ingressClassName: #config.ingressCollaborationApi.className
		}

		if #config.ingressCollaborationApi.tls.enabled {
			tls: [
				if #config.ingressCollaborationApi.host != _|_ {
					hosts: [#config.ingressCollaborationApi.host]
					secretName: #config.ingressCollaborationApi.tls.secretName | *"\(#config.metadata.name)-tls"
				},
				if #config.ingressCollaborationApi.tls.additional != _|_ for t in #config.ingressCollaborationApi.tls.additional {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}

		rules: [
			if #config.ingressCollaborationApi.host != _|_ {
				host: #config.ingressCollaborationApi.host
				http: paths: [
					{
						path:     #config.ingressCollaborationApi.path
						pathType: "ImplementationSpecific"
						backend: service: {
							name: "\(#config.metadata.name)-y-provider"
							port: number: #config.yProvider.service.port
						}
					},
					if #config.ingressCollaborationApi.customBackends != _|_ for cb in #config.ingressCollaborationApi.customBackends {
						cb
					},
				]
			},
			if #config.ingressCollaborationApi.hosts != _|_ for h in #config.ingressCollaborationApi.hosts {
				host: h
				http: paths: [
					{
						path:     #config.ingressCollaborationApi.path
						pathType: "ImplementationSpecific"
						backend: service: {
							name: "\(#config.metadata.name)-y-provider"
							port: number: #config.yProvider.service.port
						}
					},
					if #config.ingressCollaborationApi.customBackends != _|_ for cb in #config.ingressCollaborationApi.customBackends {
						cb
					},
				]
			},
		]
	}
}
