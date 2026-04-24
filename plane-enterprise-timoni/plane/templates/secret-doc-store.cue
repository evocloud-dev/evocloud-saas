package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DocStoreSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-doc-store-secrets"
	}
	type: "Opaque"
	stringData: {
		FILE_SIZE_LIMIT:    *"5242880" | string
		AWS_S3_BUCKET_NAME: #config.env.docstore_bucket
		if #config.services.minio.local_setup {
			USE_MINIO:             "1"
			MINIO_ROOT_USER:       #config.services.minio.root_user
			MINIO_ROOT_PASSWORD:   #config.services.minio.root_password
			AWS_ACCESS_KEY_ID:     #config.services.minio.root_user
			AWS_SECRET_ACCESS_KEY: #config.services.minio.root_password
			AWS_S3_ENDPOINT_URL:   "http://\(#config.metadata.name)-minio.\(#config.#namespace).svc.cluster.local:9000"
		}
		if !#config.services.minio.local_setup {
			USE_MINIO:             "0"
			AWS_ACCESS_KEY_ID:     #config.env.aws_access_key
			AWS_SECRET_ACCESS_KEY: #config.env.aws_secret_access_key
			AWS_REGION:            #config.env.aws_region
			AWS_S3_ENDPOINT_URL:   #config.env.aws_s3_endpoint_url
		}
	}
}
