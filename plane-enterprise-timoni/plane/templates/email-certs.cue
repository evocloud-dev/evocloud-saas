package templates

#PlaneEmailCert: {
	#config: #Config

	apiVersion: "cert-manager.io/v1"
	kind:       "Certificate"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-mail-tls-cert"
	}
	spec: {
		dnsNames: [#config.services.email_service.smtp_domain]
		issuerRef: name: "\(#config.metadata.name)-cert-issuer"
		secretName: "\(#config.metadata.name)-mail-tls-secret"
	}
}
