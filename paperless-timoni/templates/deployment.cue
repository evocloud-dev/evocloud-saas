package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		revisionHistoryLimit: 3
		replicas:             1
		strategy: type:        "Recreate"
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "paperless"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "paperless"
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				dnsPolicy:                    "ClusterFirst"
				enableServiceLinks:           true
				if #config.securityContext.fsGroup != _|_ {
					securityContext: {
						fsGroup: #config.securityContext.fsGroup
					}
				}
				containers: [
					{
						name:            #config.metadata.name
						image:           "\(#config.image.repository):\(#config.image.tag)"
						imagePullPolicy: #config.image.pullPolicy
						securityContext: {
							readOnlyRootFilesystem: #config.securityContext.readOnlyRootFilesystem
							if #config.securityContext.runAsUser != _|_ {
								runAsUser: #config.securityContext.runAsUser
							}
							if #config.securityContext.runAsGroup != _|_ {
								runAsGroup: #config.securityContext.runAsGroup
							}
							if #config.securityContext.runAsNonRoot != _|_ {
								runAsNonRoot: #config.securityContext.runAsNonRoot
							}
							if len(#config.securityContext.capabilities.drop) > 0 || len(#config.securityContext.capabilities.add) > 0 {
								capabilities: {
									if len(#config.securityContext.capabilities.drop) > 0 {
										drop: #config.securityContext.capabilities.drop
									}
									if len(#config.securityContext.capabilities.add) > 0 {
										add: #config.securityContext.capabilities.add
									}
								}
							}
						}
						resources: {
							requests: {
								cpu:    #config.resources.requests.cpu
								memory: #config.resources.requests.memory
							}
							limits: {
								cpu:    #config.resources.limits.cpu
								memory: #config.resources.limits.memory
							}
						}
						ports: [
							{
								name:          "http"
								containerPort: #config.service.main.ports.http.port
								protocol:      "TCP"
							},
						]
						livenessProbe: {
							tcpSocket: port: #config.service.main.ports.http.port
							initialDelaySeconds: 0
							failureThreshold:    3
							timeoutSeconds:      1
							periodSeconds:       10
						}
						readinessProbe: {
							tcpSocket: port: #config.service.main.ports.http.port
							initialDelaySeconds: 0
							failureThreshold:    3
							timeoutSeconds:      1
							periodSeconds:       10
						}
						startupProbe: {
							tcpSocket: port: #config.service.main.ports.http.port
							initialDelaySeconds: 0
							failureThreshold:    30
							timeoutSeconds:      1
							periodSeconds:       5
						}
						#urlScheme: "http"
						if len(#config.ingress.main.tls) > 0 {
							#urlScheme: "https"
						}
						#paperlessURL: "\(#urlScheme)://\(#config.ingress.main.hosts[0].host)"
						#redisSecretName: "\(#config.metadata.name)-redis"
						if #config.redis.auth.existingSecret != _|_ {
							#redisSecretName: #config.redis.auth.existingSecret
						}
						#redisPasswordKey: #config.redis.auth.existingSecretPasswordKey
						#redisAuthPrefix: ":"
						if #config.redis.auth.username != "" {
							#redisAuthPrefix: "\(#config.redis.auth.username):"
						}
						#postgresqlSecretName: "\(#config.metadata.name)-postgresql"
						if #config.postgresql.auth.existingSecret != _|_ {
							#postgresqlSecretName: #config.postgresql.auth.existingSecret
						}
						#postgresqlPasswordKey: "postgres-password"
						if #config.postgresql.auth.password != _|_ {
							#postgresqlPasswordKey: "password"
						}
						#env: [
							for key, val in #config.env if val != null {
								name:  key
								value: "\(val)"
							},
							if #config.env.PAPERLESS_TIME_ZONE == _|_ {
								{
									name:  "PAPERLESS_TIME_ZONE"
									value: "\(#config.env.TZ)"
								}
							},
							if #config.env.PAPERLESS_PORT == _|_ {
								{
									name:  "PAPERLESS_PORT"
									value: "\(#config.service.main.ports.http.port)"
								}
							},
							if #config.ingress.main.enabled && #config.env.PAPERLESS_URL == _|_ {
								{
									name:  "PAPERLESS_URL"
									value: #paperlessURL
								}
							},
							if #config.postgresql.enabled && #config.env.PAPERLESS_DBENGINE == _|_ {
								{
									name:  "PAPERLESS_DBENGINE"
									value: "postgresql"
								}
							},
							if #config.postgresql.enabled && #config.env.PAPERLESS_DBHOST == _|_ {
								{
									name:  "PAPERLESS_DBHOST"
									value: "\(#config.metadata.name)-postgresql"
								}
							},
							if #config.postgresql.enabled && #config.env.PAPERLESS_DBNAME == _|_ {
								{
									name:  "PAPERLESS_DBNAME"
									value: #config.postgresql.auth.database
								}
							},
							if #config.postgresql.enabled && #config.env.PAPERLESS_DBUSER == _|_ {
								{
									name:  "PAPERLESS_DBUSER"
									value: #config.postgresql.auth.username
								}
							},
							if #config.postgresql.enabled && #config.env.PAPERLESS_DBPASS == _|_ {
								{
									name: "PAPERLESS_DBPASS"
									valueFrom: secretKeyRef: {
										name: #postgresqlSecretName
										key:  #postgresqlPasswordKey
									}
								}
							},
							if #config.redis.enabled && #config.redis.auth.enabled {
								{
									name: "A_REDIS_PASSWORD"
									valueFrom: secretKeyRef: {
										name: #redisSecretName
										key:  #redisPasswordKey
									}
								}
							},
							if #config.redis.enabled && #config.redis.auth.enabled && #config.env.PAPERLESS_REDIS == _|_ {
								{
									name:  "PAPERLESS_REDIS"
									value: "redis://\(#redisAuthPrefix)$(A_REDIS_PASSWORD)@\(#config.metadata.name)-redis-master"
								}
							},
							if #config.redis.enabled && !#config.redis.auth.enabled && #config.env.PAPERLESS_REDIS == _|_ {
								{
									name:  "PAPERLESS_REDIS"
									value: "redis://\(#config.metadata.name)-redis-master"
								}
							},
						]
						if len(#env) > 0 {
							env: #env
						}
						#volumeMounts: [
							if #config.persistence.data.enabled {
								{name: "data", mountPath: #config.persistence.data.mountPath}
							},
							if #config.persistence.media.enabled {
								{name: "media", mountPath: #config.persistence.media.mountPath}
							},
							if #config.persistence.consume.enabled {
								{name: "consume", mountPath: #config.persistence.consume.mountPath}
							},
							if #config.persistence.export.enabled {
								{name: "export", mountPath: #config.persistence.export.mountPath}
							},
							if #config.securityContext.readOnlyRootFilesystem {
								{name: "tmp", mountPath: "/tmp"}
							},
							if #config.securityContext.readOnlyRootFilesystem {
								{name: "run", mountPath: "/run"}
							},
						]
						if len(#volumeMounts) > 0 {
							volumeMounts: #volumeMounts
						}
					},
				]
				#volumes: [
					if #config.persistence.data.enabled {
						#Volume & {#cfg: #config, #volumeName: "data"}
					},
					if #config.persistence.media.enabled {
						#Volume & {#cfg: #config, #volumeName: "media"}
					},
					if #config.persistence.consume.enabled {
						#Volume & {#cfg: #config, #volumeName: "consume"}
					},
					if #config.persistence.export.enabled {
						#Volume & {#cfg: #config, #volumeName: "export"}
					},
					if #config.securityContext.readOnlyRootFilesystem {
						{name: "tmp", emptyDir: {}}
					},
					if #config.securityContext.readOnlyRootFilesystem {
						{name: "run", emptyDir: {}}
					},
				]
				if len(#volumes) > 0 {
					volumes: #volumes
				}
			}
		}
	}
}