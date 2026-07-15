package templates

import networkingv1 "k8s.io/api/networking/v1"

#Ingress: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      #config.#serviceName
		namespace: #config.metadata.namespace
		labels:    #config.labels
		if len(#config.ingress.annotations) > 0 {
			annotations: #config.ingress.annotations
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingress.ingressClassName != "" {
			ingressClassName: #config.ingress.ingressClassName
		}
		if len(#config.ingress.tls) > 0 {
			tls: [for item in #config.ingress.tls {
				hosts:      item.hosts
				secretName: item.secretName
			}]
		}
		rules: [for item in #config.ingress.hosts {
			host: item.host
			http: paths: [for ingressPath in item.paths {
				path:     ingressPath.path
				pathType: ingressPath.pathType
				backend: service: {
					name: #config.#serviceName
					port: name: "http"
				}
			}]
		}]
	}
}