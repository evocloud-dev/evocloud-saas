package templates

#Secret: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#applicationSecretName
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		if len(#config.#applicationSecretAnnotations) > 0 {
			annotations: #config.#applicationSecretAnnotations
		}
	}
	type: "Opaque"
	data: {
		"\(#config.documenso.nextAuthSecretKey)":         #config.documenso.secrets.nextAuthSecret
		"\(#config.documenso.encryptionKeyKey)":          #config.documenso.secrets.encryptionKey
		"\(#config.documenso.encryptionSecondaryKeyKey)": #config.documenso.secrets.encryptionSecondaryKey
	}
}
