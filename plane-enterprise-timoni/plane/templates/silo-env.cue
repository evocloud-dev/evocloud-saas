package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SiloSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-silo-secrets"
	}
	type: "Opaque"
	stringData: {
		SILO_HMAC_SECRET_KEY: #config.env.silo_envs.hmac_secret_key
		AES_SECRET_KEY:       #config.env.silo_envs.aes_secret_key

		if #config.services.postgres.local_setup {
			DATABASE_URL: "postgresql://\(#config.env.pgdb_username):\(#config.env.pgdb_password)@\(#config.metadata.name)-pgdb.\(#config.#namespace).svc.cluster.local:5432/\(#config.env.pgdb_name)"
		}
		if !#config.services.postgres.local_setup && #config.env.pgdb_remote_url != "" {
			DATABASE_URL: #config.env.pgdb_remote_url
		}
		if !#config.services.postgres.local_setup && #config.env.pgdb_remote_url == "" {
			DATABASE_URL: ""
		}

		if #config.services.redis.local_setup {
			REDIS_URL: "redis://\(#config.metadata.name)-redis.\(#config.#namespace).svc.cluster.local:6379/"
		}
		if !#config.services.redis.local_setup && #config.env.remote_redis_url != "" {
			REDIS_URL: #config.env.remote_redis_url
		}

		if #config.services.rabbitmq.local_setup {
			AMQP_URL: "amqp://\(#config.services.rabbitmq.default_user):\(#config.services.rabbitmq.default_password)@\(#config.metadata.name)-rabbitmq.\(#config.#namespace).svc.cluster.local:5672/"
		}
		if !#config.services.rabbitmq.local_setup && #config.services.rabbitmq.external_rabbitmq_url != "" {
			AMQP_URL: #config.services.rabbitmq.external_rabbitmq_url
		}
		if !#config.services.rabbitmq.local_setup && #config.services.rabbitmq.external_rabbitmq_url == "" {
			AMQP_URL: ""
		}

		if #config.services.silo.connectors.slack.enabled {
			SLACK_CLIENT_SECRET: #config.services.silo.connectors.slack.client_secret
			SLACK_CLIENT_ID:     #config.services.silo.connectors.slack.client_id
		}
		if #config.services.silo.connectors.github.enabled {
			GITHUB_CLIENT_SECRET: #config.services.silo.connectors.github.client_secret
			GITHUB_PRIVATE_KEY:   #config.services.silo.connectors.github.private_key
			GITHUB_CLIENT_ID:     #config.services.silo.connectors.github.client_id
			GITHUB_APP_NAME:      #config.services.silo.connectors.github.app_name
			GITHUB_APP_ID:        #config.services.silo.connectors.github.app_id
		}
		if #config.services.silo.connectors.gitlab.enabled {
			GITLAB_CLIENT_SECRET: #config.services.silo.connectors.gitlab.client_secret
			GITLAB_CLIENT_ID:     #config.services.silo.connectors.gitlab.client_id
		}
	}
}

#SiloConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-silo-vars"
	}
	data: {
		PORT:              "3000"
		BATCH_SIZE:        "\(#config.env.silo_envs.batch_size)"
		MQ_PREFETCH_COUNT: "\(#config.env.silo_envs.mq_prefetch_count)"
		REQUEST_INTERVAL:  "\(#config.env.silo_envs.request_interval)"
		SILO_BASE_PATH:    "/silo"

		if #config.env.silo_envs.cors_allowed_origins == "*" {
			CORS_ALLOWED_ORIGINS: "*"
		}
		if #config.env.silo_envs.cors_allowed_origins != "*" && #config.env.silo_envs.cors_allowed_origins != "" {
			CORS_ALLOWED_ORIGINS: "http://\(#config.license.licenseDomain),https://\(#config.license.licenseDomain),\(#config.env.silo_envs.cors_allowed_origins)"
		}
		if #config.env.silo_envs.cors_allowed_origins == "" {
			CORS_ALLOWED_ORIGINS: "http://\(#config.license.licenseDomain),https://\(#config.license.licenseDomain)"
		}

		if #config.ssl.tls_secret_name != "" || (#config.ssl.createIssuer && #config.ssl.generateCerts) {
			APP_BASE_URL:      "https://\(#config.license.licenseDomain)"
			SILO_API_BASE_URL: "https://\(#config.license.licenseDomain)"
		}
		if #config.ssl.tls_secret_name == "" && !(#config.ssl.createIssuer && #config.ssl.generateCerts) {
			APP_BASE_URL:      "http://\(#config.license.licenseDomain)"
			SILO_API_BASE_URL: "http://\(#config.license.licenseDomain)"
		}

		API_BASE_URL:                 "http://\(#config.metadata.name)-api.\(#config.#namespace).svc.cluster.local:8000/"
		PAYMENT_SERVER_BASE_URL:      "http://\(#config.metadata.name)-monitor.\(#config.#namespace).svc.cluster.local:8080/"
		FEATURE_FLAG_SERVER_BASE_URL: "http://\(#config.metadata.name)-monitor.\(#config.#namespace).svc.cluster.local:8080/"

		SENTRY_DSN:                #config.env.silo_envs.sentry_dsn
		SENTRY_ENVIRONMENT:        #config.env.silo_envs.sentry_environment
		SENTRY_TRACES_SAMPLE_RATE: "\(#config.env.silo_envs.sentry_traces_sample_rate)"
	}
}
