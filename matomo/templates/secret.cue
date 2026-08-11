package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// Define the Secret template
#Secret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata:   #config.metadata & {
		name: [
			if #config.database.external.existingSecret != "" { #config.database.external.existingSecret },
			if #config.database.external.existingSecret == "" && #config.database.mode == "mysql" { "\(#config.metadata.name)-mysql-auth" },
			if #config.database.external.existingSecret == "" && #config.database.mode != "mysql" { "\(#config.fullname)-database" },
		][0]
	}
	type:       "Opaque"
	stringData: {
		"database-password": #config.database.external.password
	}
}
