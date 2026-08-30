package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Secret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-app"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"app-keys": [
			if #config.secrets.appKeys != "" {
				#config.secrets.appKeys
			},
			if #config.secrets.appKeys == "" {
				"generated-app-key-1,generated-app-key-2"
			},
		][0]
		"api-token-salt": [
			if #config.secrets.apiTokenSalt != "" {
				#config.secrets.apiTokenSalt
			},
			if #config.secrets.apiTokenSalt == "" {
				"generated-api-token-salt"
			},
		][0]
		"admin-jwt-secret": [
			if #config.secrets.adminJwtSecret != "" {
				#config.secrets.adminJwtSecret
			},
			if #config.secrets.adminJwtSecret == "" {
				"generated-admin-jwt-secret"
			},
		][0]
		"jwt-secret": [
			if #config.secrets.jwtSecret != "" {
				#config.secrets.jwtSecret
			},
			if #config.secrets.jwtSecret == "" {
				"generated-jwt-secret"
			},
		][0]
		"transfer-token-salt": [
			if #config.secrets.transferTokenSalt != "" {
				#config.secrets.transferTokenSalt
			},
			if #config.secrets.transferTokenSalt == "" {
				"generated-transfer-token-salt"
			},
		][0]
	}
}

// External Database Secret 
#DatabaseSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-database"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"database-password": [
			if #config.database.external.password != "" {#config.database.external.password},
			"generated-database-password",
		][0]
	}
}

// Backup S3 Secret
#BackupSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-backup"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"access-key": #config.backup.s3.accessKey
		"secret-key": #config.backup.s3.secretKey
	}
}

// Upload S3 Secret
#UploadS3Secret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-upload-s3"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"access-key": #config.strapi.upload.s3.accessKey
		"secret-key": #config.strapi.upload.s3.secretKey
	}
}

// Upload Cloudinary Secret
#UploadCloudinarySecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-upload-cloudinary"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"api-key":    #config.strapi.upload.cloudinary.apiKey
		"api-secret": #config.strapi.upload.cloudinary.apiSecret
	}
}

// SMTP Email Secret
#SMTPEmailSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-email"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"smtp-password": #config.strapi.email.smtp.password
	}
}

// SendGrid Email Secret
#SendGridEmailSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-email"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"sendgrid-api-key": #config.strapi.email.sendgrid.apiKey
	}
}
