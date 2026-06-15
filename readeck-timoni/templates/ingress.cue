package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
	#config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & #config.ingress.main.labels
		annotations: #config.ingress.main.annotations
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.main.ingressClassName != "" {
			ingressClassName: #config.ingress.main.ingressClassName
		}
		if len(#config.ingress.main.tls) > 0 {
			tls: [
				for item in #config.ingress.main.tls {
					{
						hosts: item.hosts
						if item.secretName != _|_ {
							secretName: item.secretName
						}
					}
				},
			]
		}
		rules: [
			for ingressHost in #config.ingress.main.hosts {
				{
					host: ingressHost.host
					http: paths: [
						for item in ingressHost.paths {
							{
								path:     item.path
								pathType: item.pathType
								backend: service: {
									#serviceName: #config.metadata.name
									if item.service.name != "" {
										#serviceName: item.service.name
									}
									name: #serviceName
									#servicePort: #config.service.main.ports.http.port
									if item.service.port != 0 {
										#servicePort: item.service.port
									}
									port: number: #servicePort
								}
							}
						},
					]
				}
			},
		]
	}
}