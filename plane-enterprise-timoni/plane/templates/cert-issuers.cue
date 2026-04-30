package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PlaneIssuerTokenSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-issuer-api-token-secret"
	}
	type: "Opaque"
	stringData: {
		"api-token": #config.ssl.token
	}
}

#PlaneCertIssuer: {
	#config: #Config

	apiVersion: "cert-manager.io/v1"
	kind:       "Issuer"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-cert-issuer"
	}
	spec: {
		acme: {
			email: #config.ssl.email
			server: #config.ssl.server
			privateKeySecretRef: name: "\(#config.metadata.name)-cert-issuer-key"
			solvers: [
				if #config.ssl.issuer == "cloudflare" {
					{
						dns01: cloudflare: {
							apiTokenSecretRef: {
								name: "\(#config.metadata.name)-issuer-api-token-secret"
								key:  "api-token"
							}
						}
					}
				},
				if #config.ssl.issuer == "digitalocean" {
					{
						dns01: digitalocean: {
							tokenSecretRef: {
								name: "\(#config.metadata.name)-issuer-api-token-secret"
								key:  "api-token"
							}
						}
					}
				},
				if #config.ssl.issuer == "http" {
					{
						http01: ingress: ingressClassName: #config.ingress.ingressClass
					}
				},
			]
		}
	}
}
