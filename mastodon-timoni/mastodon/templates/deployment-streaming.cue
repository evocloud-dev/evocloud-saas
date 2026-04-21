package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#StreamingDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-streaming"
		labels: #config.metadata.labels & {
			#config.mastodon.streaming.labels
			"app.kubernetes.io/component": "streaming"
		}
		if #config.mastodon.streaming.annotations != _|_ {
			annotations: #config.deploymentAnnotations & #config.mastodon.streaming.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.mastodon.streaming.replicas
		if #config.mastodon.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: #config.mastodon.revisionHistoryLimit
		}
		if #config.mastodon.streaming.updateStrategy != _|_ {
			strategy: #config.mastodon.streaming.updateStrategy
		}
		selector: {
			matchLabels: {
				#config.selector.labels
				"app.kubernetes.io/component": "streaming"
			}
		}
		template: {
			metadata: {
				annotations: {
					#config.podAnnotations
					#config.mastodon.streaming.podAnnotations
					// roll the pods to pick up any db migrations or other changes
					if #config.revisionPodAnnotation {
						"rollme": "true"
					}
				}
				labels: {
					#config.mastodon.labels
					#config.selector.labels
					#config.mastodon.podLabels
					#config.mastodon.streaming.podLabels
					"app.kubernetes.io/component": "streaming"
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
				securityContext: #config.mastodon.streaming.podSecurityContext
				
				if #config.mastodon.streaming.extraCerts.existingSecret != "" {
					volumes: [{
						name: #config.mastodon.streaming.extraCerts.name | "extra-certs"
						secret: {
							secretName: #config.mastodon.streaming.extraCerts.existingSecret
							items: [{
								key:  "ca.crt"
								path: "trusted-ca.crt"
							}]
						}
					}]
				}

				containers: [
					{
						name: "mastodon-streaming"
						securityContext: #config.mastodon.streaming.securityContext
						image:           #config.mastodon.streaming.image.reference
						imagePullPolicy: #config.mastodon.streaming.image.pullPolicy
						command: ["node", "./streaming"]
						
						if #config.mastodon.streaming.extraCerts.existingSecret != "" {
							volumeMounts: [{
								name:      #config.mastodon.streaming.extraCerts.name | "extra-certs"
								mountPath: "/usr/local/share/ca-certificates"
							}]
						}

						envFrom: [
							{configMapRef: name: "\(#config.metadata.name)-env"},
							if #config.mastodon.extraEnvFrom != "" {
								{configMapRef: name: #config.mastodon.extraEnvFrom}
							},
						]
						_env: {
							if #config.mastodon.streaming.extraCerts.existingSecret != "" {
								NODE_EXTRA_CA_CERTS: value: "/usr/local/share/ca-certificates/trusted-ca.crt"
								DB_SSLMODE:          value: "verify-full"
							}
							if #config.postgresql.readReplica.hostname != "" {
								DB_HOST: value: #config.postgresql.readReplica.hostname
							}
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
							PORT: value: "\(#config.mastodon.streaming.port)"
							if #config.externalAuth.ldap.enabled && #config.externalAuth.ldap.passwordSecretRef.name != "" {
								LDAP_PASSWORD: valueFrom: secretKeyRef: {
									name: #config.externalAuth.ldap.passwordSecretRef.name
									key:  #config.externalAuth.ldap.passwordSecretRef.key | "password"
								}
							}
							for k, v in #config.mastodon.streaming.extraEnvVars {
								"\(k)": value: v
							}
						}
						env: [ for k, v in _env { {name: k, v} }]

						ports: [{
							name:          "streaming"
							containerPort: #config.mastodon.streaming.port
							protocol:      "TCP"
						}]

						livenessProbe: httpGet: {
							path: "/api/v1/streaming/health"
							port: "streaming"
						}
						readinessProbe: httpGet: {
							path: "/api/v1/streaming/health"
							port: "streaming"
						}
						startupProbe: httpGet: {
							path: "/api/v1/streaming/health"
							port: "streaming"
						}
						resources: #config.mastodon.streaming.resources
					},
				]

				nodeSelector:              #config.mastodon.streaming.nodeSelector
				affinity:                  #config.mastodon.streaming.affinity
				topologySpreadConstraints: #config.mastodon.streaming.topologySpreadConstraints
				tolerations:               #config.tolerations
			}
		}
	}
}
