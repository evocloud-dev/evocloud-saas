package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ExternalPostgresqlSecret: corev1.#Secret & {
	#config: #Config
	let app = #config."hyperswitch-app"

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "ext-postgresql-\(#config.metadata.name)"
		namespace: #config.metadata.namespace
	}
	stringData: {
		if app.externalPostgresql.primary.auth.password != _|_ {
			primaryPassword: app.externalPostgresql.primary.auth.password
		}
		if app.externalPostgresql.primary.auth.plainpassword != _|_ {
			primaryPlainPassword: app.externalPostgresql.primary.auth.plainpassword
		}
		if app.externalPostgresql.readOnly.enabled {
			if app.externalPostgresql.readOnly.auth.password != _|_ {
				readOnlyPassword: app.externalPostgresql.readOnly.auth.password
			}
		}
	}
}
