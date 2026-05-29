package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SecretEnv: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-\(#config.secretEnv.name)"
		namespace: #config.metadata.namespace
		labels: {
			app:      #config.name
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
	}
	type: "Opaque"
	stringData: {
		REDIS_HOST: {
			if #config.redis.enabled {
				"\(#config.metadata.name)-redis-master"
			}
			if !#config.redis.enabled {
				#config.supersetNode.connections.redis_host
			}
		}
		REDIS_USER: #config.supersetNode.connections.redis_user
		if #config.supersetNode.connections.redis_password != null {
			REDIS_PASSWORD: #config.supersetNode.connections.redis_password
		}
		REDIS_PORT: #config.supersetNode.connections.redis_port
		REDIS_PROTO: {
			if #config.supersetNode.connections.redis_ssl.enabled {
				"rediss"
			}
			if !#config.supersetNode.connections.redis_ssl.enabled {
				"redis"
			}
		}
		REDIS_DB:        #config.supersetNode.connections.redis_cache_db
		REDIS_CELERY_DB: #config.supersetNode.connections.redis_celery_db
		if #config.supersetNode.connections.redis_ssl.enabled {
			REDIS_SSL_CERT_REQS: #config.supersetNode.connections.redis_ssl.ssl_cert_reqs | *"CERT_NONE"
		}
		DB_HOST: {
			if #config.postgresql.enabled {
				"\(#config.metadata.name)-postgresql"
			}
			if !#config.postgresql.enabled {
				#config.supersetNode.connections.db_host
			}
		}
		DB_PORT: #config.supersetNode.connections.db_port
		DB_USER: #config.supersetNode.connections.db_user
		DB_PASS: #config.supersetNode.connections.db_pass
		DB_NAME: #config.supersetNode.connections.db_name
	} & #config.extraSecretEnv
}
