package templates

import (
)

#Secret: {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-env"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		POSTGRES_HOST:     #config.#postgresql.host
		POSTGRES_PORT:     "\(#config.#postgresql.port)"
		POSTGRES_USERNAME: #config.#postgresql.user
		POSTGRES_DATABASE: #config.#postgresql.database
		REDIS_HOST: #config.#redis.host
		REDIS_PORT: "\(#config.#redis.port)"
		REDIS_URL: #config.#redis.url
		if #config.redis.enabled && #config.redis.sentinel.enabled {
			REDIS_SENTINELS:            #config.#redis.sentinels
			REDIS_SENTINEL_MASTER_NAME: #config.#redis.sentinelMasterName
		}
		for k, v in #config.env if v != "" {
			if #config.redis.enabled && #config.redis.sentinel.enabled {
				if k != "REDIS_SENTINELS" && k != "REDIS_SENTINEL_MASTER_NAME" {
					"\(k)": v
				}
			}
			if !#config.redis.enabled || !#config.redis.sentinel.enabled {
				"\(k)": v
			}
		}
		if #config.postgresql.auth.existingSecret == _|_ {
			POSTGRES_PASSWORD: #config.#postgresql.password
		}
		if #config.redis.auth.existingSecret == _|_ {
			REDIS_PASSWORD: #config.#redis.password
		}
	}
}
