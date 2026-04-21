package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#S3Secret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-s3"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "s3"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		OPENPROJECT_ATTACHMENTS__STORAGE:    "fog"
		OPENPROJECT_FOG_CREDENTIALS_PROVIDER: "AWS"
		if #config.s3.auth.existingSecret == "" {
			OPENPROJECT_FOG_CREDENTIALS_AWS__ACCESS__KEY__ID:     #config.s3.auth.accessKeyId
			OPENPROJECT_FOG_CREDENTIALS_AWS__SECRET__ACCESS__KEY: #config.s3.auth.secretAccessKey
		}
		if #config.s3.endpoint != "" {
			OPENPROJECT_FOG_CREDENTIALS_ENDPOINT: #config.s3.endpoint
		}
		if #config.s3.host != "" {
			OPENPROJECT_FOG_CREDENTIALS_HOST: #config.s3.host
		}
		if #config.s3.port != "" {
			OPENPROJECT_FOG_CREDENTIALS_PORT: #config.s3.port
		}
		OPENPROJECT_FOG_DIRECTORY:                               #config.s3.bucketName
		OPENPROJECT_FOG_CREDENTIALS_REGION:                      #config.s3.region
		OPENPROJECT_FOG_CREDENTIALS_PATH__STYLE:                "\(#config.s3.pathStyle)"
		OPENPROJECT_FOG_CREDENTIALS_AWS__SIGNATURE__VERSION:    "\(#config.s3.signatureVersion)"
		OPENPROJECT_FOG_CREDENTIALS_USE__IAM__PROFILE:           "\(#config.s3.useIamProfile)"
		OPENPROJECT_FOG_CREDENTIALS_ENABLE__SIGNATURE__V4__STREAMING: "\(#config.s3.enableSignatureV4Streaming)"
		OPENPROJECT_DIRECT__UPLOADS:                             "\(#config.s3.directUploads)"
	}
}
