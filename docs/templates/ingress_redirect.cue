package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#IngressRedirect: networkingv1.#Ingress & {
	#config: #Config
	#rule:   _
	#index:  int
	
	let redirectHost = #rule.host | #config.ingressRedirects.host
	let redirectFrom = #rule.from
	let redirectTo = #rule.to
	let redirectCode = #rule.code | 301
	
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-redirect-\(#index)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if redirectCode == 301 || redirectCode == "301" {
				"nginx.ingress.kubernetes.io/permanent-redirect": redirectTo
			}
			if redirectCode != 301 && redirectCode != "301" {
				"nginx.ingress.kubernetes.io/temporal-redirect": redirectTo
				"nginx.ingress.kubernetes.io/temporal-redirect-code": "\(redirectCode)"
			}
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.ingressRedirects.className != null {
			ingressClassName: #config.ingressRedirects.className
		}
		if #config.ingressRedirects.tls.enabled {
			tls: [
				{
					hosts: [redirectHost]
					secretName: #config.ingressRedirects.tls.secretName | *"\(#config.metadata.name)-tls"
				},
				for t in #config.ingressRedirects.tls.additional {
					hosts:      t.hosts
					secretName: t.secretName
				}
			]
		}
		rules: [
			{
				host: redirectHost
				http: paths: [
					{
						path:     redirectFrom
						pathType: "Exact"
						backend: service: {
							name: "\(#config.metadata.name)-frontend"
							port: number: #config.frontend.service.port
						}
					},
					{
						path:     "\(redirectFrom)/"
						pathType: "Exact"
						backend: service: {
							name: "\(#config.metadata.name)-frontend"
							port: number: #config.frontend.service.port
						}
					}
				]
			}
		]
	}
}
