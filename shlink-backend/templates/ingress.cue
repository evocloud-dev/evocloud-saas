package templates

import networkingv1 "k8s.io/api/networking/v1"

#Ingress: networkingv1.#Ingress & {
	#config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:        #config.#serviceName
		namespace:   #config.metadata.namespace
		labels:      #config.metadata.labels
		annotations: #config.ingress.annotations
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.className != "" {
			ingressClassName: #config.ingress.className
		}
		if len(#config.ingress.tls) > 0 {
			tls: [
				for item in #config.ingress.tls {
					{
						hosts:      item.hosts
						secretName: item.secretName
					}
				},
			]
		}
		rules: [
			for ingressHost in #config.ingress.hosts {
				{
					host: ingressHost.host
					http: paths: [
						for ingressPath in ingressHost.paths {
							{
								path:     ingressPath.path
								pathType: ingressPath.pathType
								backend: service: {
									name: #config.#serviceName
									port: number: #config.service.port
								}
							}
						},
					]
				}
			},
		]
	}
}