package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#SidekiqDeployment: appsv1.#Deployment & {
	#config: #Config
	#worker: #config.mastodon.sidekiq.workers[0] // Type hint for the loop item

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-sidekiq"
		labels: #config.metadata.labels & #config.mastodon.sidekiq.labels & {
			"app.kubernetes.io/part-of":    "rails"
		}
		if #config.mastodon.sidekiq.annotations != _|_ {
			annotations: #config.deploymentAnnotations & #config.mastodon.sidekiq.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #worker.replicas
		if #config.mastodon.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: #config.mastodon.revisionHistoryLimit
		}
		if #config.mastodon.sidekiq.updateStrategy != _|_ {
			strategy: #config.mastodon.sidekiq.updateStrategy
		}
		selector: {
			matchLabels: {
				#config.selector.labels
				"app.kubernetes.io/component": "sidekiq-\(#worker.name)"
				"app.kubernetes.io/part-of":    "rails"
			}
		}
		template: {
			metadata: {
				annotations: {
					#config.podAnnotations
					#config.mastodon.sidekiq.podAnnotations
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
					#config.mastodon.sidekiq.podLabels
					(#StatsD & {#config: #config}).#labels
					"app.kubernetes.io/component": "sidekiq-\(#worker.name)"
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
				securityContext: #config.mastodon.sidekiq.podSecurityContext
				
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
					if #worker.customDatabaseConfigYml.configMapRef.name != "" {
						{
							name: "config-database-yml"
							configMap: {
								name: #worker.customDatabaseConfigYml.configMapRef.name
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
						securityContext: #config.mastodon.sidekiq.securityContext
						image:           #worker.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: [
							"bundle", "exec", "sidekiq", "-c", "\(#worker.concurrency)",
							for q in #worker.queues for v in ["-q", q] {v},
						]
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
							if #config.mastodon.cacheBuster.enabled && #config.mastodon.cacheBuster.authToken.existingSecret != "" {
								CACHE_BUSTER_SECRET: valueFrom: secretKeyRef: {
									name: #config.mastodon.cacheBuster.authToken.existingSecret
									key:  "password"
								}
							}
							if #config.mastodon.sidekiq.otel.enabled || (#config.mastodon.otel.enabled && #config.mastodon.sidekiq.otel.enabled != false) {
								OTEL_EXPORTER_OTLP_ENDPOINT: value: #config.mastodon.sidekiq.otel.exporterUri | #config.mastodon.otel.exporterUri
								OTEL_SERVICE_NAME_PREFIX:    value: #config.mastodon.sidekiq.otel.namePrefix | #config.mastodon.otel.namePrefix
								OTEL_SERVICE_NAME_SEPARATOR: value: #config.mastodon.sidekiq.otel.nameSeparator | #config.mastodon.otel.nameSeparator
							}
							if #config.mastodon.metrics.prometheus.enabled {
								MASTODON_PROMETHEUS_EXPORTER_ENABLED: value: "true"
								MASTODON_PROMETHEUS_EXPORTER_LOCAL:   value: "true"
								MASTODON_PROMETHEUS_EXPORTER_HOST:    value: "0.0.0.0"
								MASTODON_PROMETHEUS_EXPORTER_PORT:    value: "\(#config.mastodon.metrics.prometheus.port)"
								if #config.mastodon.metrics.prometheus.sidekiq.detailed {
									MASTODON_PROMETHEUS_EXPORTER_SIDEKIQ_DETAILED_METRICS: value: "true"
								}
							}
							if #config.externalAuth.ldap.enabled && #config.externalAuth.ldap.passwordSecretRef.name != "" {
								LDAP_PASSWORD: valueFrom: secretKeyRef: {
									name: #config.externalAuth.ldap.passwordSecretRef.name
									key:  #config.externalAuth.ldap.passwordSecretRef.key | "password"
								}
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
									name: "elasticsearch-ca"
									mountPath: "/opt/opensearch/config/ca.certs"
									subPath: #config.elasticsearch.caSecret.key
									readOnly: true
								}
							},
							if #worker.customDatabaseConfigYml.configMapRef.name != "" {
								{
									name: "config-database-yml"
									mountPath: "/opt/mastodon/config/database.yml"
									subPath: #worker.customDatabaseConfigYml.configMapRef.key
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

						if #config.mastodon.metrics.prometheus.enabled {
							ports: [{
								name:          "prometheus"
								containerPort: #config.mastodon.metrics.prometheus.port
							}]
						}

						if #config.mastodon.sidekiq.readinessProbe.enabled {
							readinessProbe: {
								exec: command: ["cat", #config.mastodon.sidekiq.readinessProbe.path]
								if #config.mastodon.sidekiq.readinessProbe.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.mastodon.sidekiq.readinessProbe.initialDelaySeconds
								}
								if #config.mastodon.sidekiq.readinessProbe.periodSeconds != _|_ {
									periodSeconds:       #config.mastodon.sidekiq.readinessProbe.periodSeconds
								}
								if #config.mastodon.sidekiq.readinessProbe.successThreshold != _|_ {
									successThreshold:    #config.mastodon.sidekiq.readinessProbe.successThreshold
								}
								if #config.mastodon.sidekiq.readinessProbe.timeoutSeconds != _|_ {
									timeoutSeconds:      #config.mastodon.sidekiq.readinessProbe.timeoutSeconds
								}
								if #config.mastodon.sidekiq.readinessProbe.failureThreshold != _|_ {
									failureThreshold:    #config.mastodon.sidekiq.readinessProbe.failureThreshold
								}
							}
						}
						resources: #worker.resources | #config.mastodon.sidekiq.resources
					},
					for c in (#StatsD & {#config: #config}).#container {c},
				]

				nodeSelector:              #worker.nodeSelector | #config.mastodon.sidekiq.nodeSelector
				affinity:                  #worker.affinity | #config.mastodon.sidekiq.affinity
				topologySpreadConstraints: #worker.topologySpreadConstraints | #config.mastodon.sidekiq.topologySpreadConstraints
				tolerations:               #config.tolerations
			}
		}
	}
}
