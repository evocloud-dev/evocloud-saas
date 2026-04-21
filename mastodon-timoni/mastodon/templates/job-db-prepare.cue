package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#JobDbPrepare: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-db-prepare"
		labels: #config.metadata.labels
		annotations: {
			"helm.sh/hook":                "pre-install"
			"helm.sh/hook-delete-policy": "before-hook-creation,hook-succeeded"
			"helm.sh/hook-weight":         "-3"
		}
	}
	spec: batchv1.#JobSpec & {
		template: {
			metadata: {
				name: "\(#config.metadata.name)-db-prepare"
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
					command: ["bundle", "exec", "rails", "db:prepare"]
					envFrom: [
						{configMapRef: name: "\(#config.metadata.name)-env"},
						{
							secretRef: name: {
								if #config.mastodon.secrets.existingSecret != "" {
									#config.mastodon.secrets.existingSecret
								}
								if #config.mastodon.secrets.existingSecret == "" {
									"\(#config.metadata.name)-prepare"
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
								if !#config.redis.enabled && #config.redis.auth.existingSecret == "" && #config.redis.auth.password != "" {
									"\(#config.metadata.name)-redis-pre-install"
								}
								if #config.redis.enabled || #config.redis.auth.existingSecret != "" || #config.redis.auth.password == "" {
									if #config.redis.auth.existingSecret != "" {
										#config.redis.auth.existingSecret
									}
									if #config.redis.auth.existingSecret == "" {
										"\(#config.metadata.name)-redis"
									}
								}
							}
							key: #config.redis.auth.existingSecretKey
						}
					}
					env: [ for k, v in _env { {name: k, v} }]
					volumeMounts: [
						// Link the zzz_disable_ssl.rb script to Rails initializers.
						if #config.mastodon.disableSslPatch.enabled {
							{
								name:      "mastodon-patch"
								mountPath: "/opt/mastodon/config/initializers/zzz_disable_ssl.rb"
								subPath:   "zzz_disable_ssl.rb"
							}
						},
						for v in #config.volumeMounts {v},
					]
				}]
				volumes: [
					// Mount the custom Ruby initializer to disable the "force_ssl" setting in Rails.
					// This ensures internal pod-to-pod traffic can use HTTP while the external 
					// load balancer/ingress handles SSL termination.
					if #config.mastodon.disableSslPatch.enabled {
						{
							name: "mastodon-patch"
							configMap: {
								name: "\(#config.metadata.name)-patch"
							}
						}
					},
					for v in #config.volumes {v},
				]
				nodeSelector: #config.mastodon.hooks.dbPrepare.nodeSelector
			}
		}
	}
}
