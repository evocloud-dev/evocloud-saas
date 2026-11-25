package templates

#ExternalSecret: {
	#config: #Config
	#item:   #ExternalSecretItem

	let secretName = [
		if #item.fullnameOverride != "" { #item.fullnameOverride },
		if #item.name != "" { "\(#config.#fullname)-\(#item.name)" },
		"\(#config.#fullname)-externalsecret",
	][0]

	let targetName = [
		if #item.spec.target != _|_ && #item.spec.target.name != _|_ && #item.spec.target.name != "" { #item.spec.target.name },
		secretName,
	][0]

	let effectiveRefreshInterval = [
		if #item.spec.refreshInterval != _|_ && #item.spec.refreshInterval != "" { #item.spec.refreshInterval },
		#config.externalSecrets.refreshInterval,
	][0]

	let secretAnnotations = {
		for k, v in #config.commonAnnotations { "\(k)": v }
		for k, v in #item.annotations { "\(k)": v }
	}

	apiVersion: "external-secrets.io/v1"
	kind:       "ExternalSecret"
	metadata: {
		name:      secretName
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.#labels { "\(k)": v }
			for k, v in #item.labels { "\(k)": v }
		}
		if len(secretAnnotations) > 0 {
			annotations: secretAnnotations
		}
	}
	spec: {
		for k, v in #item.spec if k != "refreshInterval" && k != "target" {
			"\(k)": v
		}
		refreshInterval: effectiveRefreshInterval
		target: {
			if #item.spec.target != _|_ {
				for k, v in #item.spec.target if k != "name" {
					"\(k)": v
				}
			}
			name: targetName
		}
	}
}
