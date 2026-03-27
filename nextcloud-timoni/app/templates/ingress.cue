package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
	#in:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata:   #in.metadata & {
		if len([for k, v in #in.ingress.annotations {k}]) > 0 {
			annotations: #in.ingress.annotations
		}
		if len([for k, v in #in.ingress.labels {k}]) > 0 {
			labels: #in.ingress.labels
		}
	}
	spec: {
		if #in.ingress.className != "" {
			ingressClassName: #in.ingress.className
		}
		rules: [
			{
				host: #in.nextcloud.host
				http: paths: [
					{
						path:     #in.ingress.path
						pathType: networkingv1.#PathType & #in.ingress.pathType
						backend: service: {
							name: #in.metadata.name
							port: number: #in.service.port
						}
					},
				]
			},
		]
		if len(#in.ingress.tls) > 0 {
			tls: #in.ingress.tls
		}
	}
}
