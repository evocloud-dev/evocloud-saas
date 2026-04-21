package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#WebDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-web"
		labels: #config.metadata.labels & {
			#config.mastodon.web.labels
			"app.kubernetes.io/component": "web"
			"app.kubernetes.io/part-of":    "rails"
		}
		if #config.mastodon.web.annotations != _|_ {
			annotations: #config.deploymentAnnotations & #config.mastodon.web.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.mastodon.web.replicas
		if #config.mastodon.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: #config.mastodon.revisionHistoryLimit
		}
		if #config.mastodon.web.updateStrategy != _|_ {
			strategy: #config.mastodon.web.updateStrategy
		}
		selector: {
			matchLabels: {
				#config.selector.labels
				"app.kubernetes.io/component": "web"
				"app.kubernetes.io/part-of":    "rails"
			}
		}
		template: {
			metadata: {
				annotations: {
					#config.podAnnotations
					#config.mastodon.web.podAnnotations
					// roll the pods to pick up any db migrations or other changes
					if #config.revisionPodAnnotation {
						"rollme": "true"
					}
					// 1:1 parity checksum for smtp
					"checksum/config-secrets-smtp": "ignored-in-timoni"
				}
				labels: {
					#config.mastodon.labels
					#config.selector.labels
					#config.mastodon.podLabels
					#config.mastodon.web.podLabels
					(#StatsD & {#config: #config}).#labels
					"app.kubernetes.io/component": "web"
					"app.kubernetes.io/part-of":    "rails"
				}
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: {
					if #config.serviceAccount.name != "" {
						#config.serviceAccount.name
					}
					if #config.serviceAccount.name == "" {
						#config.metadata.name
					}
				}
				securityContext: #config.mastodon.web.podSecurityContext
				
				volumes: [
					if !#config.mastodon.s3.enabled {
						{
							name: "assets"
							persistentVolumeClaim: claimName: {
								if #config.mastodon.persistence.assets.existingClaim != "" {
									#config.mastodon.persistence.assets.existingClaim
								}
								if #config.mastodon.persistence.assets.existingClaim == "" {
									"\(#config.metadata.name)-assets"
								}
							}
						}
					},
					if !#config.mastodon.s3.enabled {
						{
							name: "system"
							persistentVolumeClaim: claimName: {
								if #config.mastodon.persistence.system.existingClaim != "" {
									#config.mastodon.persistence.system.existingClaim
								}
								if #config.mastodon.persistence.system.existingClaim == "" {
									"\(#config.metadata.name)-system"
								}
							}
						}
					},
					if #config.elasticsearch.caSecret.name != _|_ {
						{
							name: "elasticsearch-ca"
							secret: secretName: #config.elasticsearch.caSecret.name
						}
					},
					if #config.mastodon.web.customDatabaseConfigYml.configMapRef.name != "" {
						{
							name: "config-database-yml"
							configMap: {
								name: #config.mastodon.web.customDatabaseConfigYml.configMapRef.name
							}
						}
					},
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
					for v in (#StatsD & {#config: #config}).#volume {v},
					for v in #config.volumes {v},
				]

				containers: [
					{
						name: "mastodon"
						securityContext: #config.mastodon.web.securityContext
						image:           #config.mastodon.web.image.reference
						imagePullPolicy: #config.mastodon.web.image.pullPolicy
						command: ["bundle", "exec", "puma", "-C", "config/puma.rb"]
						
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
							if #config.mastodon.extraEnvFrom != "" {
								{configMapRef: name: #config.mastodon.extraEnvFrom}
							},
						]

						_env: {
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
							if #config.postgresql.readReplica.auth.existingSecret != "" {
								REPLICA_DB_PASS: valueFrom: secretKeyRef: {
									name: #config.postgresql.readReplica.auth.existingSecret
									key:  "password"
								}
							}
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
							if #config.redis.sidekiq.enabled && #config.redis.sidekiq.auth.existingSecret != "" {
								SIDEKIQ_REDIS_PASSWORD: valueFrom: secretKeyRef: {
									name: #config.redis.sidekiq.auth.existingSecret
									key:  "redis-password"
								}
							}
							if #config.redis.cache.enabled && #config.redis.cache.auth.existingSecret != "" {
								CACHE_REDIS_PASSWORD: valueFrom: secretKeyRef: {
									name: #config.redis.cache.auth.existingSecret
									key:  "redis-password"
								}
							}
							if (#config.elasticsearch.enabled || #config.elasticsearch.hostname != "") && #config.elasticsearch.existingSecret != "" {
								ES_PASS: valueFrom: secretKeyRef: {
									name: #config.elasticsearch.existingSecret
									key:  "password"
								}
							}
							SMTP_LOGIN: valueFrom: secretKeyRef: {
								name: {
									if #config.mastodon.smtp.existingSecret != "" {
										#config.mastodon.smtp.existingSecret
									}
									if #config.mastodon.smtp.existingSecret == "" {
										"\(#config.metadata.name)-smtp"
									}
								}
								key:      "login"
								optional: true
							}
							SMTP_PASSWORD: valueFrom: secretKeyRef: {
								name: {
									if #config.mastodon.smtp.existingSecret != "" {
										#config.mastodon.smtp.existingSecret
									}
									if #config.mastodon.smtp.existingSecret == "" {
										"\(#config.metadata.name)-smtp"
									}
								}
								key:      "password"
								optional: true
							}
							if #config.mastodon.smtp.bulk.enabled {
								BULK_SMTP_LOGIN: valueFrom: secretKeyRef: {
									name: {
										if #config.mastodon.smtp.bulk.existingSecret != "" {
											#config.mastodon.smtp.bulk.existingSecret
										}
										if #config.mastodon.smtp.bulk.existingSecret == "" {
											"\(#config.metadata.name)-smtp-bulk"
										}
									}
									key:      "login"
									optional: true
								}
								BULK_SMTP_PASSWORD: valueFrom: secretKeyRef: {
									name: {
										if #config.mastodon.smtp.bulk.existingSecret != "" {
											#config.mastodon.smtp.bulk.existingSecret
										}
										if #config.mastodon.smtp.bulk.existingSecret == "" {
											"\(#config.metadata.name)-smtp-bulk"
										}
									}
									key:      "password"
									optional: true
								}
							}
							if #config.mastodon.s3.enabled && #config.mastodon.s3.existingSecret != "" {
								AWS_SECRET_ACCESS_KEY: valueFrom: secretKeyRef: {
									name: #config.mastodon.s3.existingSecret
									key:  "AWS_SECRET_ACCESS_KEY"
								}
								AWS_ACCESS_KEY_ID: valueFrom: secretKeyRef: {
									name: #config.mastodon.s3.existingSecret
									key:  "AWS_ACCESS_KEY_ID"
								}
							}
							if #config.mastodon.deepl.enabled {
								DEEPL_API_KEY: valueFrom: secretKeyRef: {
									name: #config.mastodon.deepl.apiKeySecretRef.name
									key:  #config.mastodon.deepl.apiKeySecretRef.key
								}
							}
							if #config.mastodon.hcaptcha.enabled {
								HCAPTCHA_SECRET_KEY: valueFrom: secretKeyRef: {
									name: #config.mastodon.hcaptcha.secretKeySecretRef.name
									key:  #config.mastodon.hcaptcha.secretKeySecretRef.key
								}
							}
							if #config.mastodon.cacheBuster.enabled && #config.mastodon.cacheBuster.authToken.existingSecret != "" {
								CACHE_BUSTER_SECRET: valueFrom: secretKeyRef: {
									name: #config.mastodon.cacheBuster.authToken.existingSecret
									key:  "password"
								}
							}
							if #config.mastodon.web.otel.enabled || (#config.mastodon.otel.enabled && #config.mastodon.web.otel.enabled != false) {
								OTEL_EXPORTER_OTLP_ENDPOINT: value: #config.mastodon.web.otel.exporterUri | #config.mastodon.otel.exporterUri
								OTEL_SERVICE_NAME_PREFIX:    value: #config.mastodon.web.otel.namePrefix | #config.mastodon.otel.namePrefix
								OTEL_SERVICE_NAME_SEPARATOR: value: #config.mastodon.web.otel.nameSeparator | #config.mastodon.otel.nameSeparator
							}
							if #config.mastodon.metrics.prometheus.enabled {
								MASTODON_PROMETHEUS_EXPORTER_ENABLED: value: "true"
								PROMETHEUS_EXPORTER_HOST:             value: "127.0.0.1"
								PROMETHEUS_EXPORTER_PORT:             value: "\(#config.mastodon.metrics.prometheus.port)"
								if #config.mastodon.metrics.prometheus.web.detailed {
									MASTODON_PROMETHEUS_EXPORTER_WEB_DETAILED_METRICS: value: "true"
								}
							}
							if #config.externalAuth.ldap.enabled && #config.externalAuth.ldap.passwordSecretRef.name != "" {
								LDAP_PASSWORD: valueFrom: secretKeyRef: {
									name: #config.externalAuth.ldap.passwordSecretRef.name
									key:  #config.externalAuth.ldap.passwordSecretRef.key | "password"
								}
							}
							PORT:              value: "\(#config.mastodon.web.port)"
							MIN_THREADS:       value: "\(#config.mastodon.web.minThreads)"
							MAX_THREADS:       value: "\(#config.mastodon.web.maxThreads)"
							WEB_CONCURRENCY:   value: "\(#config.mastodon.web.workers)"
							PERSISTENT_TIMEOUT: value: "\(#config.mastodon.web.persistentTimeout)"
							if #config.mastodon.web.mallocArenaMax != _|_ {
								MALLOC_ARENA_MAX: value: "\(#config.mastodon.web.mallocArenaMax)"
							}
							if #config.mastodon.web.ldPreload != "" {
								LD_PRELOAD: value: #config.mastodon.web.ldPreload
							}
						}
						env: [ for k, v in _env { {name: k, v} }]

						volumeMounts: [
							if !#config.mastodon.s3.enabled {
								{
									name:      "assets"
									mountPath: "/opt/mastodon/public/assets"
								}
							},
							if !#config.mastodon.s3.enabled {
								{
									name:      "system"
									mountPath: "/opt/mastodon/public/system"
								}
							},
							if #config.elasticsearch.caSecret.name != _|_ {
								{
									name:      "elasticsearch-ca"
									mountPath: "/opt/opensearch/config/ca.certs"
									subPath:   #config.elasticsearch.caSecret.key
									readOnly:  true
								}
							},
							if #config.mastodon.web.customDatabaseConfigYml.configMapRef.name != "" {
								{
									name:      "config-database-yml"
									mountPath: "/opt/mastodon/config/database.yml"
									subPath:   #config.mastodon.web.customDatabaseConfigYml.configMapRef.key
								}
							},
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

						ports: [
							{
								name:          "http"
								containerPort: #config.mastodon.web.port
								protocol:      "TCP"
							},
						]

						livenessProbe: tcpSocket: port: "http"
						readinessProbe: httpGet: {
							path: "/health"
							port: "http"
						}
						startupProbe: {
							httpGet: {
								path: "/health"
								port: "http"
							}
							initialDelaySeconds: 15
							failureThreshold:    30
							periodSeconds:       5
						}
						resources: #config.mastodon.web.resources
					},
					if #config.mastodon.metrics.prometheus.enabled {
						{
							name: "prometheus-exporter"
							image:           #config.mastodon.web.image.reference
							command: ["./bin/prometheus_exporter"]
							args: ["--bind", "0.0.0.0", "--port", "\(#config.mastodon.metrics.prometheus.port)"]
							resources: {
								requests: {
									cpu:    "0.1"
									memory: "180M"
								}
								limits: {
									cpu:    "0.5"
									memory: "250M"
								}
							}
							ports: [
								{
									name:          "prometheus"
									containerPort: #config.mastodon.metrics.prometheus.port
								},
							]
						}
					},
					for c in (#StatsD & {#config: #config}).#container {c},
				]

				nodeSelector:              #config.mastodon.web.nodeSelector
				affinity:                  #config.mastodon.web.affinity
				topologySpreadConstraints: #config.mastodon.web.topologySpreadConstraints
				tolerations:               #config.tolerations
			}
		}
	}
}
