package templates

#PlaneCertificates: {
	#config: #Config

	apiVersion: "cert-manager.io/v1"
	kind:       "Certificate"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-ssl-cert"
	}
	spec: {
		dnsNames: [
			#config.license.licenseDomain,
			if #config.services.minio.local_setup && #config.ingress.minioHost != "" {
				#config.ingress.minioHost
			},
			if #config.services.rabbitmq.local_setup && #config.ingress.rabbitmqHost != "" {
				#config.ingress.rabbitmqHost
			},
		]
		issuerRef: name: "\(#config.metadata.name)-cert-issuer"
		secretName: "\(#config.metadata.name)-ssl-cert"
	}
}
