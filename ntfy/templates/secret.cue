package templates

import (
	"strings"

	corev1 "k8s.io/api/core/v1"
)

// #DbSecret mirrors the database Secret in templates/secret.yaml.
#DbSecret: corev1.#Secret & {
	#config: #Config

	let _encUser = strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(#config._dbUser, "%", "%25", -1), " ", "+", -1), "+", "%2B", -1), "/", "%2F", -1), "?", "%3F", -1), "#", "%23", -1), "&", "%26", -1), "=", "%3D", -1), "@", "%40", -1), ":", "%3A", -1)
	let _encPass = strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(strings.Replace(#config._dbPass, "%", "%25", -1), " ", "+", -1), "+", "%2B", -1), "/", "%2F", -1), "?", "%3F", -1), "#", "%23", -1), "&", "%26", -1), "=", "%3D", -1), "@", "%40", -1), ":", "%3A", -1)

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._dbSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	type: "Opaque"
	stringData: {
		"database-url": "postgres://\(_encUser):\(_encPass)@\(#config._dbHost):\(#config._dbPort)/\(#config._dbName)?sslmode=disable"
	}
}

// #AdminSecret mirrors the admin Secret in templates/secret.yaml.
#AdminSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._adminSecretName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.commonAnnotations) > 0 || len(#config.ntfy.admin.annotations) > 0 {
			annotations: {
				for k, v in #config.commonAnnotations if #config.ntfy.admin.annotations[k] == _|_ {(k): v}
				#config.ntfy.admin.annotations
			}
		}
	}
	type: "Opaque"
	stringData: {
		username: #config.ntfy.admin.username
		password: #config.ntfy.admin.password
	}
}

// #OidcSecret mirrors the OIDC Secret in templates/secret.yaml.
#OidcSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._oidcSecretName
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "oidc"
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	type: "Opaque"
	stringData: {
		"client-secret": #config.oidc.clientSecret
	}
}

// #SmtpSecret mirrors the SMTP Secret in templates/secret.yaml.
#SmtpSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._smtpSecretName
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "smtp"
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	type: "Opaque"
	stringData: {
		"smtp-password": #config.smtp.senderPass
	}
}

// #BackupS3Secret mirrors templates/backup-secret.yaml.
#BackupS3Secret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config._backupSecretName
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "backup"
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	type: "Opaque"
	stringData: {
		"access-key": #config.backup.s3.accessKey
		"secret-key": #config.backup.s3.secretKey
	}
}
