package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PIApiSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-pi-api-secrets"
	}
	type: "Opaque"
	stringData: {
		PLANE_PI_DATABASE_URL: "postgresql://\(#config.env.pgdb_username):\(#config.env.pgdb_password)@\(#config.metadata.name)-pgdb.\(#config.#namespace).svc.cluster.local/\(#config.env.pg_pi_db_name)"
		FOLLOWER_POSTGRES_URI: "postgresql://\(#config.env.pgdb_username):\(#config.env.pgdb_password)@\(#config.metadata.name)-pgdb.\(#config.#namespace).svc.cluster.local/\(#config.env.pgdb_name)"
		AMQP_URL:              "amqp://plane:plane@\(#config.metadata.name)-rabbitmq.\(#config.#namespace).svc.cluster.local/"

		OPENAI_API_KEY:     #config.services.pi.ai_providers.openai.api_key
		CLAUDE_API_KEY:     #config.services.pi.ai_providers.claude.api_key
		GROQ_API_KEY:       #config.services.pi.ai_providers.groq.api_key
		COHERE_API_KEY:     #config.services.pi.ai_providers.cohere.api_key
		CUSTOM_LLM_API_KEY: #config.services.pi.ai_providers.custom_llm.api_key
		AES_SECRET_KEY:     #config.env.silo_envs.aes_secret_key
	}
}

#PIApiConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-pi-api-vars"
	}
	data: {
		DEBUG:               "0"
		LOG_LEVEL:           "DEBUG"
		FASTAPI_APP_HOST:    "0.0.0.0"
		FASTAPI_APP_WORKERS: "1"
		PLANE_FRONTEND_URL:  "http://\(#config.license.licenseDomain)"
		PLANE_API_HOST:      "http://\(#config.license.licenseDomain)"
		PI_INTERNAL_SECRET:  "tyfvfqvBJAgpm9bzvf3r4urJer0Ehfdubk"
		
		FEATURE_FLAG_SERVER_BASE_URL: "http://\(#config.metadata.name)-monitor.\(#config.#namespace).svc.cluster.local:8080"
		PI_BASE_PATH:                 "/pi"
		CORS_ALLOWED_ORIGINS:         "http://\(#config.license.licenseDomain),https://\(#config.license.licenseDomain)"
		PLANE_OAUTH_REDIRECT_URI:     "http://\(#config.license.licenseDomain)/pi/api/v1/oauth/callback/"
		
		CUSTOM_LLM_ENABLED:     "false"
		CUSTOM_LLM_MAX_TOKENS:  "128000"
		EMBEDDING_MODEL:        "openai/text-embedding-3-small"
		OPENSEARCH_ML_MODEL_ID: #config.services.pi.ai_providers.embedding_model.model_id
		
		CELERY_VECTOR_SYNC_ENABLED:         "1"
		CELERY_VECTOR_SYNC_INTERVAL:        "3"
		CELERY_WORKSPACE_PLAN_SYNC_ENABLED:  "1"
		CELERY_WORKSPACE_PLAN_SYNC_INTERVAL: "86400"
		CELERY_DOCS_SYNC_ENABLED:           "1"
		CELERY_DOCS_SYNC_INTERVAL:           "86400"
	}
}
