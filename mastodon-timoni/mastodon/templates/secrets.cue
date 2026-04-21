package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SecretMain: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name: #config.metadata.name
		labels: #config.metadata.labels
	}
	type: "Opaque"
	stringData: (#secretData & {#config: #config, prepare: false}).data
}

#secretData: {
	#config: #Config
	prepare: bool
	data: {
		if #config.mastodon.s3.enabled && #config.mastodon.s3.existingSecret == "" {
			AWS_ACCESS_KEY_ID:     #config.mastodon.s3.access_key
			AWS_SECRET_ACCESS_KEY: #config.mastodon.s3.access_secret
		}
		if #config.mastodon.secrets.existingSecret == "" {
			SECRET_KEY_BASE: #config.mastodon.secrets.secret_key_base
			OTP_SECRET:      #config.mastodon.secrets.otp_secret
			VAPID_PRIVATE_KEY: #config.mastodon.secrets.vapid.private_key
			VAPID_PUBLIC_KEY:  #config.mastodon.secrets.vapid.public_key
			ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY: #config.mastodon.secrets.activeRecordEncryption.primaryKey
			ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY: #config.mastodon.secrets.activeRecordEncryption.deterministicKey
			ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT: #config.mastodon.secrets.activeRecordEncryption.keyDerivationSalt
		}
		if !#config.postgresql.enabled && #config.postgresql.auth.existingSecret == "" {
			password: #config.postgresql.auth.password
		}
	}
}
