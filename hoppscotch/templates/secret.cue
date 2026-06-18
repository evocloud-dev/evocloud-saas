package templates

import (
	"encoding/base64"
	corev1 "k8s.io/api/core/v1"
)

#Secret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.fullname
		namespace: #config.namespace
		labels:    #config.labels
	}
	type: "Opaque"
	data: {
		if #config.database.external.enabled {
			if !(#config.database.external.existingSecret != "" && #config.database.external.existingSecretUrlKey != "") {
				if #config.database.external.url != "" {
					"database-url": '\(base64.Encode(null, #config.database.external.url))'
				}
				if #config.database.external.url == "" && #config.database.external.existingSecret == "" {
					"database-url": '\(base64.Encode(null, "postgresql://\(#config.database.external.username):\(#config.database.external.password)@\(#config.databaseHost):\(#config.databasePort)/\(#config.databaseName)"))'
				}
			}
		}
		if #config.encryption.existingSecret == "" {
			"data-encryption-key": '\(base64.Encode(null, #config.encryption.key))'
		}
		if #config.signingKey.existingSecret == "" {
			"\(#config.signingSecretKey)": '\(base64.Encode(null, #config.signingKey.key))'
		}
		if #config.auth.github.enabled && #config.auth.github.existingSecret == "" {
			"github-client-id":     '\(base64.Encode(null, #config.auth.github.clientId))'
			"github-client-secret": '\(base64.Encode(null, #config.auth.github.clientSecret))'
		}
		if #config.auth.google.enabled && #config.auth.google.existingSecret == "" {
			"google-client-id":     '\(base64.Encode(null, #config.auth.google.clientId))'
			"google-client-secret": '\(base64.Encode(null, #config.auth.google.clientSecret))'
		}
		if #config.auth.microsoft.enabled && #config.auth.microsoft.existingSecret == "" {
			"microsoft-client-id":     '\(base64.Encode(null, #config.auth.microsoft.clientId))'
			"microsoft-client-secret": '\(base64.Encode(null, #config.auth.microsoft.clientSecret))'
		}
		if #config.mailer.enabled && #config.mailer.existingSecret == "" {
			if #config.mailer.useCustomConfigs {
				"smtp-password": '\(base64.Encode(null, #config.mailer.password))'
			}
			if !#config.mailer.useCustomConfigs {
				"smtp-url": '\(base64.Encode(null, #config.mailer.smtpUrl))'
			}
		}
	}
}
