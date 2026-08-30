package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#IngressCollaborationWS: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-ws"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.ingressCollaborationWS.className != _|_ {
				"kubernetes.io/ingress.class": #config.ingressCollaborationWS.className
			}
			if #config.ingressCollaborationWS.annotations != _|_ {
				#config.ingressCollaborationWS.annotations
			}
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingressCollaborationWS.className != _|_ {
			ingressClassName: #config.ingressCollaborationWS.className
		}

		if #config.ingressCollaborationWS.tls.enabled {
			tls: [
				if #config.ingressCollaborationWS.host != _|_ {
					hosts: [#config.ingressCollaborationWS.host]
					secretName: #config.ingressCollaborationWS.tls.secretName | *"\(#config.metadata.name)-tls"
				},
				if #config.ingressCollaborationWS.tls.additional != _|_ for t in #config.ingressCollaborationWS.tls.additional {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}

		rules: [
			if #config.ingressCollaborationWS.host != _|_ {
				host: #config.ingressCollaborationWS.host
				http: paths: [
					{
						path:     #config.ingressCollaborationWS.path
						pathType: "ImplementationSpecific"
						backend: service: {
							name: "\(#config.metadata.name)-y-provider"
							port: number: #config.yProvider.service.port
						}
					},
					if #config.ingressCollaborationWS.customBackends != _|_ for cb in #config.ingressCollaborationWS.customBackends {
						cb
					},
				]
			},
			if #config.ingressCollaborationWS.hosts != _|_ for h in #config.ingressCollaborationWS.hosts {
				host: h
				http: paths: [
					{
						path:     #config.ingressCollaborationWS.path
						pathType: "ImplementationSpecific"
						backend: service: {
							name: "\(#config.metadata.name)-y-provider"
							port: number: #config.yProvider.service.port
						}
					},
					if #config.ingressCollaborationWS.customBackends != _|_ for cb in #config.ingressCollaborationWS.customBackends {
						cb
					},
				]
			},
		]
	}
}
