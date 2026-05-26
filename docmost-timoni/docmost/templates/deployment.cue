package templates

import (
	"list"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicaCount
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if #config.podLabels != _|_ {
					labels: #config.podLabels
				}
				annotations: {
					"checksum/secret": "dynamic-checksum-recomputed-by-k8s"
					if #config.podAnnotations != _|_ {
						for k, v in #config.podAnnotations {
							"\(k)": v
						}
					}
				}
			}
			spec: corev1.#PodSpec & {
				if #config.serviceAccount.name != "" {
					serviceAccountName: #config.serviceAccount.name
				}
				if #config.serviceAccount.name == "" {
					if #config.serviceAccount.create {
						serviceAccountName: #config.metadata.name
					}
					if !#config.serviceAccount.create {
						serviceAccountName: "default"
					}
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}

				let _dbMode = {
					if #config.database.mode == "external" { "external" }
					if #config.database.mode == "postgresql" { "postgresql" }
					if #config.database.mode == "auto" {
						if #config.database.external.host != "" || #config.database.external.existingSecret != "" { "external" }
						if #config.database.external.host == "" && #config.database.external.existingSecret == "" { "postgresql" }
					}
				}
				let _dbHost = {
					if _dbMode == "external" { #config.database.external.host }
					if _dbMode == "postgresql" { "\(#config.metadata.name)-postgresql" }
				}
				let _dbPort = {
					if _dbMode == "external" { "\(#config.database.external.port)" }
					if _dbMode == "postgresql" { "5432" }
				}
				let _dbName = {
					if _dbMode == "external" { #config.database.external.name }
					if _dbMode == "postgresql" { #config.postgresql.auth.database }
				}
				let _dbUsername = {
					if _dbMode == "external" { #config.database.external.username }
					if _dbMode == "postgresql" { #config.postgresql.auth.username }
				}
				let _dbSecretName = {
					if _dbMode == "external" && #config.database.external.existingSecret != "" { #config.database.external.existingSecret }
					if _dbMode == "external" && #config.database.external.existingSecret == "" { "\(#config.metadata.name)-database" }
					if _dbMode == "postgresql" { "" }
				}
				let _dbSecretKey = {
					if _dbMode == "external" && #config.database.external.existingSecret != "" { #config.database.external.existingSecretPasswordKey }
					if _dbMode == "external" && #config.database.external.existingSecret == "" { "database-password" }
					if _dbMode == "postgresql" { "" }
				}

				let _redisMode = {
					if #config.redis.external.host != "" || #config.redis.external.existingSecret != "" { "external" }
					if #config.redis.external.host == "" && #config.redis.external.existingSecret == "" { "internal" }
				}
				let _redisHost = {
					if _redisMode == "external" { #config.redis.external.host }
					if _redisMode == "internal" { "\(#config.metadata.name)-redis-client" }
				}
				let _redisPort = {
					if _redisMode == "external" { "\(#config.redis.external.port)" }
					if _redisMode == "internal" { "6379" }
				}
				let _hasRedisPassword = {
					if _redisMode == "external" {
						if #config.redis.external.password != "" || #config.redis.external.existingSecret != "" { true }
						if #config.redis.external.password == "" && #config.redis.external.existingSecret == "" { false }
					}
					if _redisMode == "internal" { #config.redis.auth.enabled }
				}
				let _redisSecretName = {
					if _redisMode == "external" && #config.redis.external.existingSecret != "" { #config.redis.external.existingSecret }
					if _redisMode == "external" && #config.redis.external.existingSecret == "" { "\(#config.metadata.name)-redis" }
					if _redisMode == "internal" { "" }
				}
				let _redisSecretKey = {
					if _redisMode == "external" && #config.redis.external.existingSecret != "" { #config.redis.external.existingSecretPasswordKey }
					if _redisMode == "external" && #config.redis.external.existingSecret == "" { "redis-password" }
					if _redisMode == "internal" { "" }
				}

				let _storageSecretName = {
					if #config.storage.s3.existingSecret != "" { #config.storage.s3.existingSecret }
					if #config.storage.s3.existingSecret == "" { "\(#config.metadata.name)-storage" }
				}

				initContainers: [
					{
						name:  "wait-for-postgresql"
						image: "docker.io/library/busybox:1.37"
						command: [
							"sh",
							"-c",
							"echo \"Waiting for \(_dbHost):\(_dbPort) ...\"; until nc -z -w2 \(_dbHost) \(_dbPort); do sleep 2; done; echo \"PostgreSQL is reachable.\"",
						]
					},
					{
						name:  "wait-for-redis"
						image: "docker.io/library/busybox:1.37"
						command: [
							"sh",
							"-c",
							"echo \"Waiting for \(_redisHost):\(_redisPort) ...\"; until nc -z -w2 \(_redisHost) \(_redisPort); do sleep 2; done; echo \"Redis is reachable.\"",
						]
					},
				]
				containers: [{
					name:            "docmost"
					image:           #config.image.reference
					imagePullPolicy: #config.image.pullPolicy
					if #config.securityContext != _|_ {
						securityContext: #config.securityContext
					}
					ports: [{
						name:          "http"
						containerPort: 3000
						protocol:      "TCP"
					}]
					env: list.Concat([[
						{
							name:  "PORT"
							value: "3000"
						},
						{
							name: "APP_SECRET"
							valueFrom: secretKeyRef: {
								name: "\(#config.metadata.name)-app"
								key:  "app-secret"
							}
						},
						if _dbMode != "postgresql" {
							{
								name: "DATABASE_PASSWORD"
								valueFrom: secretKeyRef: {
									name: _dbSecretName
									key:  _dbSecretKey
								}
							}
						},
						if _dbMode == "postgresql" {
							{
								name: "DATABASE_PASSWORD"
								value: {
									if #config.postgresql.auth.password != "" { #config.postgresql.auth.password }
									if #config.postgresql.auth.password == "" { "postgres-default-pass-change-me" }
								}
							}
						},
						{
							name:  "DATABASE_URL"
							value: "postgresql://\(_dbUsername):$(DATABASE_PASSWORD)@\(_dbHost):\(_dbPort)/\(_dbName)"
						},
						if _hasRedisPassword && _redisMode != "internal" {
							{
								name: "REDIS_PASSWORD"
								valueFrom: secretKeyRef: {
									name: _redisSecretName
									key:  _redisSecretKey
								}
							}
						},
						if _hasRedisPassword && _redisMode == "internal" {
							{
								name: "REDIS_PASSWORD"
								value: {
									if #config.redis.auth.password != "" { #config.redis.auth.password }
									if #config.redis.auth.password == "" { "redis-default-pass-change-me" }
								}
							}
						},
						if _hasRedisPassword {
							{
								name:  "REDIS_URL"
								value: "redis://:$(REDIS_PASSWORD)@\(_redisHost):\(_redisPort)"
							}
						},
						if !_hasRedisPassword {
							{
								name:  "REDIS_URL"
								value: "redis://\(_redisHost):\(_redisPort)"
							}
						},
						{
							name:  "JWT_TOKEN_EXPIRES_IN"
							value: #config.docmost.jwtTokenExpiresIn
						},
						if #config.docmost.appUrl != "" {
							{
								name:  "APP_URL"
								value: #config.docmost.appUrl
							}
						},
						{
							name:  "STORAGE_DRIVER"
							value: #config.storage.mode
						},
						if #config.storage.mode == "s3" {
							{
								name:  "AWS_S3_REGION"
								value: #config.storage.s3.region
							}
						},
						if #config.storage.mode == "s3" {
							{
								name:  "AWS_S3_BUCKET"
								value: #config.storage.s3.bucket
							}
						},
						if #config.storage.mode == "s3" && #config.storage.s3.endpoint != "" {
							{
								name:  "AWS_S3_ENDPOINT"
								value: #config.storage.s3.endpoint
							}
						},
						if #config.storage.mode == "s3" {
							{
								name: "AWS_S3_FORCE_PATH_STYLE"
								value: {
									if #config.storage.s3.forcePathStyle { "true" }
									if !#config.storage.s3.forcePathStyle { "false" }
								}
							}
						},
						if #config.storage.mode == "s3" {
							{
								name: "AWS_S3_ACCESS_KEY_ID"
								valueFrom: secretKeyRef: {
									name: _storageSecretName
									key:  #config.storage.s3.existingSecretAccessKeyKey
								}
							}
						},
						if #config.storage.mode == "s3" {
							{
								name: "AWS_S3_SECRET_ACCESS_KEY"
								valueFrom: secretKeyRef: {
									name: _storageSecretName
									key:  #config.storage.s3.existingSecretSecretKeyKey
								}
							}
						},
					], #config.docmost.extraEnv])

					if #config.startupProbe.enabled {
						startupProbe: {
							httpGet: {
								path: #config.startupProbe.path
								port: "http"
							}
							initialDelaySeconds: #config.startupProbe.initialDelaySeconds
							periodSeconds:       #config.startupProbe.periodSeconds
							timeoutSeconds:      #config.startupProbe.timeoutSeconds
							failureThreshold:    #config.startupProbe.failureThreshold
						}
					}
					if #config.livenessProbe.enabled {
						livenessProbe: {
							httpGet: {
								path: #config.livenessProbe.path
								port: "http"
							}
							initialDelaySeconds: #config.livenessProbe.initialDelaySeconds
							periodSeconds:       #config.livenessProbe.periodSeconds
							timeoutSeconds:      #config.livenessProbe.timeoutSeconds
							failureThreshold:    #config.livenessProbe.failureThreshold
						}
					}
					if #config.readinessProbe.enabled {
						readinessProbe: {
							httpGet: {
								path: #config.readinessProbe.path
								port: "http"
							}
							initialDelaySeconds: #config.readinessProbe.initialDelaySeconds
							periodSeconds:       #config.readinessProbe.periodSeconds
							timeoutSeconds:      #config.readinessProbe.timeoutSeconds
							failureThreshold:    #config.readinessProbe.failureThreshold
						}
					}
					if #config.resources != _|_ {
						resources: #config.resources
					}
					volumeMounts: list.Concat([[
						if #config.storage.mode == "local" {
							{
								name:      "storage"
								mountPath: "/app/data/storage"
							}
						},
					], #config.extraVolumeMounts])
				}]
				volumes: list.Concat([[
					if #config.storage.mode == "local" {
						{
							name: "storage"
							if #config.storage.local.existingClaim != "" {
								persistentVolumeClaim: claimName: #config.storage.local.existingClaim
							}
							if #config.storage.local.existingClaim == "" {
								if #config.storage.local.enabled {
									persistentVolumeClaim: claimName: "\(#config.metadata.name)-storage"
								}
								if !#config.storage.local.enabled {
									emptyDir: {}
								}
							}
						}
					},
				], #config.extraVolumes])

				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
			}
		}
	}
}
