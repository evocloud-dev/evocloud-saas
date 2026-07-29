package templates

#ServerCertificate: {
	#config:    #Config
	apiVersion: "cert-manager.io/v1"
	kind:       "Certificate"
	metadata: {
		name:      *"\((#config.metadata.name))-server" | string
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.server.certificate.annotations != _|_ {
			annotations: #config.server.certificate.annotations
		}
	}
	spec: {
		secretName: "peertube-server-tls"
		if #config.server.certificate.secretTemplateAnnotations != _|_ && len(#config.server.certificate.secretTemplateAnnotations) > 0 {
			secretTemplate: annotations: #config.server.certificate.secretTemplateAnnotations
		}
		#ingressHost: *"" | string
		if #config.server.ingress.enabled && len(#config.server.ingress.hosts) > 0 {
			#ingressHost: #config.server.ingress.hosts[0]
		}
		#certificateDomain: *#ingressHost | string
		if #config.server.certificate.domain != "" {
			#certificateDomain: #config.server.certificate.domain
		}
		if #certificateDomain != "" {
			commonName: #certificateDomain
			dnsNames: [
				#certificateDomain,
				for h in #config.server.certificate.additionalHosts {h},
			]
		}
		if #config.server.certificate.duration != "" {
			duration: #config.server.certificate.duration
		}
		if #config.server.certificate.renewBefore != "" {
			renewBefore: #config.server.certificate.renewBefore
		}
		issuerRef: {
			if #config.server.certificate.issuer.group != "" {
				group: #config.server.certificate.issuer.group
			}
			kind: #config.server.certificate.issuer.kind
			name: #config.server.certificate.issuer.name
		}
		if #config.server.certificate.privateKey != _|_ {
			privateKey: #config.server.certificate.privateKey
		}
		if len(#config.server.certificate.usages) > 0 {
			usages: #config.server.certificate.usages
		}
	}
}
