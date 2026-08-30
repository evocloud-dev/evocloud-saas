package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#IngressPosthogAssets: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-posthog-assets"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.posthog.ingressAssets.className != _|_ {
				"kubernetes.io/ingress.class": #config.posthog.ingressAssets.className
			}
			if #config.posthog.ingressAssets.annotations != _|_ {
				#config.posthog.ingressAssets.annotations
			}
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.posthog.ingressAssets.className != _|_ {
			ingressClassName: #config.posthog.ingressAssets.className
		}

		if #config.posthog.ingressAssets.tls.enabled {
			tls: [
				if #config.posthog.ingressAssets.host != _|_ {
					hosts: [#config.posthog.ingressAssets.host]
					secretName: #config.posthog.ingressAssets.tls.secretName | *"\(#config.metadata.name)-posthog-tls"
				},
				if #config.posthog.ingressAssets.tls.additional != _|_ for t in #config.posthog.ingressAssets.tls.additional {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}

		rules: [
			if #config.posthog.ingressAssets.host != _|_ {
				host: #config.posthog.ingressAssets.host
				http: paths: [
					for p in #config.posthog.ingressAssets.paths {
						path:     p
						pathType: "Prefix"
						backend: service: {
							name: "\(#config.posthog.fullname)-assets-proxy"
							port: number: #config.posthog.assetsService.port
						}
					}
				]
			}
		]
	}
}