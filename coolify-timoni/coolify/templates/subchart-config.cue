package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SubchartConfig: {
	#config: #Config
	if #config.postgresql.enabled {
		postgresqlConfig: corev1.#ConfigMap & {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      "\(#config.metadata.name)-postgresql-config"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels & {
					"app.kubernetes.io/component": "postgresql"
				}
				if #config.metadata.annotations != _|_ {
					annotations: #config.metadata.annotations
				}
			}
			data: "values.yaml": """
				auth:
				  existingSecret: \(#config.metadata.name)-postgresql
				  secretKeys:
				    adminPasswordKey: postgres-password
				    userPasswordKey: password
				  username: \(#config.postgresql.auth.username)
				  database: \(#config.postgresql.auth.database)
				"""
		}
	}

	if #config.redis.enabled {
		redisConfig: corev1.#ConfigMap & {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      "\(#config.metadata.name)-redis-config"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels & {
					"app.kubernetes.io/component": "redis"
				}
				if #config.metadata.annotations != _|_ {
					annotations: #config.metadata.annotations
				}
			}
			data: "values.yaml": """
				auth:
				  enabled: true
				  existingSecret: \(#config.metadata.name)-redis
				  existingSecretPasswordKey: redis-password
				"""
		}
	}
}
