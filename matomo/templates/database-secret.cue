package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DatabaseSecret: corev1.#Secret & {
	#config:    #Config
	if #config.database.mode == "external" && #config.database.external.existingSecret == "" && #config.externalSecrets.enabled == false {
		apiVersion: "v1"
		kind:       "Secret"
		metadata: {
			if #config.database.external.existingSecret != "" {
				name: #config.database.external.existingSecret
			}
			if #config.database.external.existingSecret == "" && #config.database.mode == "mysql" {
				name: #config.metadata.name + "-mysql-auth"
			}
			if #config.database.external.existingSecret == "" && #config.database.mode != "mysql" {
				name: #config.fullname + "-database"
			}
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
		}
		type: "Opaque"
		stringData: {
			"database-password": #config.database.external.password
		}
	}
}
