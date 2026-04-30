package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#AppSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-app-secrets"
	}
	type: "Opaque"
	stringData: {
		SECRET_KEY:             #config.env.secret_key
		AES_SECRET_KEY:         *"dsOdt7YrvxsTIFJ37pOaEVvLxN8KGBCr" | string
		LIVE_SERVER_SECRET_KEY: *"htbqvBJAgpm9bzvf3r4urJer0ENReatceh" | string
		PI_INTERNAL_SECRET:    *"tyfvfqvBJAgpm9bzvf3r4urJer0Ehfdubk" | string

		REDIS_URL: "redis://\(#config.metadata.name)-redis.\(#config.#namespace).svc.cluster.local:6379/"
		DATABASE_URL: "postgresql://\(#config.env.pgdb_username):\(#config.env.pgdb_password)@\(#config.metadata.name)-pgdb.\(#config.#namespace).svc.cluster.local/\(#config.env.pgdb_name)"
		AMQP_URL: "amqp://plane:plane@\(#config.metadata.name)-rabbitmq.\(#config.#namespace).svc.cluster.local/"
	}
}

#AppConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-app-vars"
	}
	data: {
		PRIME_HOST:                  #config.license.licenseServer
		MACHINE_SIGNATURE:           *"ignored-in-timoni" | string
		APP_DOMAIN:                  #config.license.licenseDomain
		APP_VERSION:                 #config.planeVersion
		PAYMENT_SERVER_BASE_URL:     "http://\(#config.metadata.name)-monitor.\(#config.#namespace).svc.cluster.local:8080/"
		FEATURE_FLAG_SERVER_BASE_URL: "http://\(#config.metadata.name)-monitor.\(#config.#namespace).svc.cluster.local:8080/"
		
		API_KEY_RATE_LIMIT:          #config.env.api_key_rate_limit
		MINIO_ENDPOINT_SSL:          [if #config.services.minio.env.minio_endpoint_ssl {"1"}, {"0"}][0]
		USE_STORAGE_PROXY:           [if #config.env.use_storage_proxy {"1"}, {"0"}][0]
		ALLOW_ALL_ATTACHMENT_TYPES:  [if #config.env.allow_all_attachment_types {"1"}, {"0"}][0]
		ENABLE_DRF_SPECTACULAR:      [if #config.env.enable_drf_spectacular {"1"}, {"0"}][0]
		
		DEBUG:             "0"
		DOCKERIZED:        "1"
		GUNICORN_WORKERS:  "1"
		
		if #config.env.web_url != "" {
			WEB_URL: #config.env.web_url
		}
		if #config.env.web_url == "" {
			WEB_URL: "http://\(#config.license.licenseDomain)"
		}

		LIVE_BASE_URL: "http://\(#config.metadata.name)-live.\(#config.#namespace).svc.cluster.local:3000/"
		LIVE_BASE_PATH: "/live"
		PI_BASE_URL:    "http://\(#config.license.licenseDomain)/pi"
		PI_BASE_PATH:   "/pi"
		
		if #config.env.cors_allowed_origins == "*" {
			CORS_ALLOWED_ORIGINS: "*"
		}
		if #config.env.cors_allowed_origins != "*" {
			CORS_ALLOWED_ORIGINS: [
				if #config.env.cors_allowed_origins != "" {"http://\(#config.license.licenseDomain),https://\(#config.license.licenseDomain),\(#config.env.cors_allowed_origins)"},
				{"http://\(#config.license.licenseDomain),https://\(#config.license.licenseDomain)"}
			][0]
		}
	}
}
