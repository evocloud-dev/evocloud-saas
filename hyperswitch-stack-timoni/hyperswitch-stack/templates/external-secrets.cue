package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ExternalSecretStore: {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "external-secrets.io/v1"
	kind:       "SecretStore"
	metadata: {
		name:      app.externalSecretsOperator.secretStore.name
		namespace: #config.metadata.namespace
	}
	spec: {
		provider: app.externalSecretsOperator.secretStore.provider
	}
}

#ExternalSecretServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	let app = #config."hyperswitch-app"

	let _saName = [if app.externalSecretsOperator.serviceAccount.name != "" {app.externalSecretsOperator.serviceAccount.name}, "hyperswitch-eso-sa"][0]

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:        _saName
		namespace:   #config.metadata.namespace
		labels:      #config.global.labels & app.externalSecretsOperator.serviceAccount.extraLabels
		annotations: app.externalSecretsOperator.serviceAccount.annotations
	}
}

#ExternalSecret: {
	#config: #Config
	#secret: {...}

	let app = #config."hyperswitch-app"

	apiVersion: "external-secrets.io/v1"
	kind:       "ExternalSecret"
	metadata: {
		name:      #secret.name
		namespace: #config.metadata.namespace
	}
	spec: {
		refreshInterval: (#secret.refreshInterval | *"1h")
		secretStoreRef: {
			name: app.externalSecretsOperator.secretStore.name
			kind: "SecretStore"
		}
		target: {
			name:           #secret.targetName
			creationPolicy: (#secret.creationPolicy | *"Owner")
		}
		if #secret.data != _|_ {
			data: #secret.data
		}
		if #secret.dataFrom != _|_ {
			dataFrom: [
				for d in #secret.dataFrom {
					extract: {
						key: d.extract.key
						if d.extract.version != _|_ {version: d.extract.version}
						if d.extract.property != _|_ {property: d.extract.property}
						conversionStrategy: (d.extract.conversionStrategy | *"Default")
						decodingStrategy:   (d.extract.decodingStrategy | *"None")
						metadataPolicy:     (d.extract.metadataPolicy | *"None")
					}
				},
			]
		}
	}
}
