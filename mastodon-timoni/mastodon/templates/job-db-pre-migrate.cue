package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#JobDbPreMigrate: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-db-pre-migrate"
		labels: #config.metadata.labels
		annotations: {
			"helm.sh/hook":                "pre-upgrade"
			"helm.sh/hook-delete-policy": "before-hook-creation,hook-succeeded"
			"helm.sh/hook-weight":         "-2"
		}
	}
	spec: batchv1.#JobSpec & {
		template: {
			metadata: {
				name: "\(#config.metadata.name)-db-migrate"
				if #config.mastodon.jobLabels != _|_ {
					labels: #config.mastodon.jobLabels
				}
				if #config.mastodon.jobAnnotations != _|_ {
					annotations: #config.mastodon.jobAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				restartPolicy: "Never"
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				securityContext: #config.podSecurityContext
				containers: [{
					name:            "\(#config.metadata.name)-db-migrate"
					securityContext: #config.securityContext
					image:           #config.image.reference
					imagePullPolicy: #config.image.pullPolicy
					command: ["bundle", "exec", "rails", "db:migrate"]
					envFrom: [
						{configMapRef: name: "\(#config.metadata.name)-env"},
						{
							secretRef: name: {
								if #config.mastodon.secrets.existingSecret != "" {
									#config.mastodon.secrets.existingSecret
								}
								if #config.mastodon.secrets.existingSecret == "" {
									#config.metadata.name
								}
							}
						},
					]
					_env: {
						DB_HOST: value: {
							if #config.postgresql.direct.hostname != null && #config.postgresql.direct.hostname != "" {
								#config.postgresql.direct.hostname
							}
							if #config.postgresql.direct.hostname == null || #config.postgresql.direct.hostname == "" {
								if #config.postgresql.enabled {
									"\(#config.metadata.name)-postgresql"
								}
								if !#config.postgresql.enabled {
									#config.postgresql.postgresqlHostname
								}
							}
						}
						DB_PORT: value: {
							if #config.postgresql.direct.port != null && #config.postgresql.direct.port != "" {
								"\(#config.postgresql.direct.port)"
							}
							if #config.postgresql.direct.port == null || #config.postgresql.direct.port == "" {
								if #config.postgresql.enabled {
									"5432"
								}
								if !#config.postgresql.enabled {
									"\(#config.postgresql.postgresqlPort)"
								}
							}
						}
						DB_NAME: value: {
							if #config.postgresql.direct.database != null && #config.postgresql.direct.database != "" {
								#config.postgresql.direct.database
							}
							if #config.postgresql.direct.database == null || #config.postgresql.direct.database == "" {
								#config.postgresql.auth.database
							}
						}
						DB_USER: value: #config.postgresql.auth.username
						DB_PASS: valueFrom: secretKeyRef: {
							name: {
								if #config.postgresql.auth.existingSecret != "" {
									#config.postgresql.auth.existingSecret
								}
								if #config.postgresql.auth.existingSecret == "" {
									"\(#config.metadata.name)-postgresql"
								}
							}
							key: "password"
						}
						REDIS_HOST: value: {
							if #config.redis.enabled {
								"\(#config.metadata.name)-redis-master"
							}
							if !#config.redis.enabled {
								#config.redis.hostname
							}
						}
						REDIS_PORT: value: "\(#config.redis.port)"
						if #config.redis.sidekiq.enabled {
							SIDEKIQ_REDIS_HOST: value: {
								if #config.redis.sidekiq.hostname != "" {
									#config.redis.sidekiq.hostname
								}
								if #config.redis.sidekiq.hostname == "" {
									#config.redis.hostname
								}
							}
							SIDEKIQ_REDIS_PORT: value: {
								if #config.redis.sidekiq.port != 0 {
									"\(#config.redis.sidekiq.port)"
								}
								if #config.redis.sidekiq.port == 0 {
									"\(#config.redis.port)"
								}
							}
						}
						if #config.redis.cache.enabled {
							CACHE_REDIS_HOST: value: {
								if #config.redis.cache.hostname != "" {
									#config.redis.cache.hostname
								}
								if #config.redis.cache.hostname == "" {
									#config.redis.hostname
								}
							}
							CACHE_REDIS_PORT: value: {
								if #config.redis.cache.port != 0 {
									"\(#config.redis.cache.port)"
								}
								if #config.redis.cache.port == 0 {
									"\(#config.redis.port)"
								}
							}
						}
						REDIS_DRIVER: value: "ruby"
						REDIS_PASSWORD: valueFrom: secretKeyRef: {
							name: {
								if #config.redis.auth.existingSecret != "" {
									#config.redis.auth.existingSecret
								}
								if #config.redis.auth.existingSecret == "" {
									"\(#config.metadata.name)-redis"
								}
							}
							key: #config.redis.auth.existingSecretKey
						}
						SKIP_POST_DEPLOYMENT_MIGRATIONS: value: "true"
					}
					env: [ for k, v in _env { {name: k, v} }]
				}]
				nodeSelector: #config.mastodon.hooks.dbMigrate.nodeSelector
			}
		}
	}
}
