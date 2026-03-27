package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Secret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		if #config["postgresql-sts"].enabled && #config["postgresql-sts"].postgresPassword != _|_ {
			"postgres-password": #config["postgresql-sts"].postgresPassword
		}
		if #config["mariadb-sts"].enabled && #config["mariadb-sts"].rootPassword != _|_ {
			"mariadb-root-password": #config["mariadb-sts"].rootPassword
		}
		if #config["mariadb-subchart"].enabled && #config["mariadb-subchart"].password != _|_ {
			"mariadb-password": #config["mariadb-subchart"].password
		}
		if #config["mariadb-subchart"].enabled && #config["mariadb-subchart"].rootPassword != _|_ {
			"mariadb-root-password": #config["mariadb-subchart"].rootPassword
		}
		if #config.dbRootPassword != _|_ && #config.dbExistingSecret == "" {
			"db-root-password": #config.dbRootPassword
		}
		"redis-password": "" // Default to empty if not configured
	}
}

