package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	strconv "strconv"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicaCount
		selector: matchLabels: #config.metadata.labels
		template: {
			metadata: {
				labels: #config.metadata.labels
				if len(#config.podLabels) > 0 {
					labels: #config.podLabels
				}
				annotations: {
					"checksum/secrets":         "strapi-secret-checksum"
					"checksum/database-config": "database-config-checksum"
					if len(#config.podAnnotations) > 0 {
						#config.podAnnotations
					}
				}
			}
			spec: corev1.#PodSpec & {
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: [
					if #config.serviceAccount.name != "" {#config.serviceAccount.name},
					#config.fullname,
				][0]
				automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				securityContext:               #config.podSecurityContext
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds

				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 {
					affinity: #config.affinity
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				if len(#config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}

				if #config.resolvedDbMode != "sqlite" {
					initContainers: [
						{
							name:  "wait-for-db"
							image: "docker.io/library/busybox:1.37"
							command: [
								"sh",
								"-c",
								"""
								echo "Waiting for \(#config.databaseHost):\(#config.databasePort) ..."
								until nc -z -w2 \(#config.databaseHost) \(#config.databasePort); do
								  sleep 2
								done
								echo "Database is reachable."
								""",
							]
						},
					]
				}

				containers: [
					{
						name:            "strapi"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						securityContext: #config.securityContext
						if len(#config.strapi.command) > 0 {
							command: #config.strapi.command
						}
						if len(#config.strapi.args) > 0 {
							args: #config.strapi.args
						}
						ports: [
							{
								name:          "http"
								containerPort: #config.strapi.port
								protocol:      "TCP"
							},
						]
						env: [
							{name: "NODE_ENV", value: #config.strapi.nodeEnv},
							{name: "HOME", value: "/tmp"},
							{name: "XDG_CONFIG_HOME", value: "/tmp/.config"},
							{name: "HOST", value: #config.strapi.host},
							{name: "PORT", value: strconv.FormatInt(#config.strapi.port, 10)},
							if #config.strapi.url != "" {
								name:  "URL"
								value: #config.strapi.url
							},
							if #config.strapi.url == "" && #config.ingress.enabled && len(#config.ingress.hosts) > 0 {
								name:  "URL"
								value: "https://\(#config.ingress.hosts[0].host)"
							},
							{name: "STRAPI_TELEMETRY_DISABLED", value: [if #config.strapi.telemetryDisabled {"true"}, "false"][0]},
							{
								name: "APP_KEYS"
								valueFrom: secretKeyRef: {
									name: #config.appSecretName
									key:  #config.secrets.existingSecretAppKeysKey
								}
							},
							{
								name: "API_TOKEN_SALT"
								valueFrom: secretKeyRef: {
									name: #config.appSecretName
									key:  #config.secrets.existingSecretApiTokenSaltKey
								}
							},
							{
								name: "ADMIN_JWT_SECRET"
								valueFrom: secretKeyRef: {
									name: #config.appSecretName
									key:  #config.secrets.existingSecretAdminJwtSecretKey
								}
							},
							{
								name: "JWT_SECRET"
								valueFrom: secretKeyRef: {
									name: #config.appSecretName
									key:  #config.secrets.existingSecretJwtSecretKey
								}
							},
							{
								name: "TRANSFER_TOKEN_SALT"
								valueFrom: secretKeyRef: {
									name: #config.appSecretName
									key:  #config.secrets.existingSecretTransferTokenSaltKey
								}
							},
							{
								name: "DATABASE_CLIENT"
								value: [
									if #config.resolvedDbMode == "sqlite" {"sqlite"},
									if #config.resolvedDbMode == "postgresql" {"postgres"},
									if #config.resolvedDbMode == "mysql" {"mysql"},
									if #config.resolvedDbMode == "external" {
										if #config.database.external.vendor == "postgres" {"postgres"}
										if #config.database.external.vendor != "postgres" {"mysql"}
									},
								][0]
							},
							if #config.resolvedDbMode == "sqlite" {
								name:  "DATABASE_FILENAME"
								value: "\(#config.database.sqlite.directory)/\(#config.database.sqlite.filename)"
							},
							if #config.resolvedDbMode != "sqlite" {
								name:  "DATABASE_HOST"
								value: [
									if #config.resolvedDbMode == "postgresql" {"\(#config.fullname)-postgresql"},
									if #config.resolvedDbMode == "mysql" {"\(#config.fullname)-mysql"},
									if #config.resolvedDbMode == "external" {#config.database.external.host},
								][0]
							},
							if #config.resolvedDbMode != "sqlite" {
								name:  "DATABASE_PORT"
								value: [
									if #config.resolvedDbMode == "postgresql" {"5432"},
									if #config.resolvedDbMode == "mysql" {"3306"},
									if #config.resolvedDbMode == "external" {
										if #config.database.external.port != "" {#config.database.external.port}
										if #config.database.external.port == "" {
											if #config.database.external.vendor == "postgres" {"5432"}
											if #config.database.external.vendor != "postgres" {"3306"}
										}
									},
								][0]
							},
							if #config.resolvedDbMode != "sqlite" {
								name:  "DATABASE_NAME"
								value: [
									if #config.resolvedDbMode == "postgresql" {#config.postgresql.auth.database},
									if #config.resolvedDbMode == "mysql" {#config.mysql.auth.database},
									if #config.resolvedDbMode == "external" {#config.database.external.name},
								][0]
							},
							if #config.resolvedDbMode != "sqlite" {
								name:  "DATABASE_USERNAME"
								value: [
									if #config.resolvedDbMode == "postgresql" {#config.postgresql.auth.username},
									if #config.resolvedDbMode == "mysql" {#config.mysql.auth.username},
									if #config.resolvedDbMode == "external" {#config.database.external.username},
								][0]
							},
							if #config.resolvedDbMode != "sqlite" {
								name: "DATABASE_PASSWORD"
								valueFrom: secretKeyRef: {
									name: [
										if #config.resolvedDbMode == "postgresql" {"\(#config.fullname)-postgresql-auth"},
										if #config.resolvedDbMode == "mysql" {"\(#config.fullname)-mysql-auth"},
										if #config.resolvedDbMode == "external" {
											if #config.database.external.existingSecret != "" {#config.database.external.existingSecret}
											if #config.database.external.existingSecret == "" {"\(#config.fullname)-database"}
										},
									][0]
									key: [
										if #config.resolvedDbMode == "postgresql" {"database-password"},
										if #config.resolvedDbMode == "mysql" {"database-password"},
										if #config.resolvedDbMode == "external" {#config.database.external.existingSecretPasswordKey},
									][0]
								}
							},
							if #config.resolvedDbMode != "sqlite" {
								name:  "DATABASE_SSL"
								value: [if #config.resolvedDbMode == "external" && #config.database.external.ssl.enabled {"true"}, "false"][0]
							},
							if #config.resolvedDbMode != "sqlite" {
								name:  "DATABASE_POOL_MIN"
								value: strconv.FormatInt(#config.database.pool.min, 10)
							},
							if #config.resolvedDbMode != "sqlite" {
								name:  "DATABASE_POOL_MAX"
								value: strconv.FormatInt(#config.database.pool.max, 10)
							},
							if #config.resolvedDbMode != "sqlite" && #config.database.pool.acquireTimeoutMillis > 0 {
								name:  "DATABASE_POOL_ACQUIRE_TIMEOUT"
								value: strconv.FormatInt(#config.database.pool.acquireTimeoutMillis, 10)
							},
							if #config.resolvedDbMode != "sqlite" && #config.database.pool.idleTimeoutMillis > 0 {
								name:  "DATABASE_POOL_IDLE_TIMEOUT"
								value: strconv.FormatInt(#config.database.pool.idleTimeoutMillis, 10)
							},
							if #config.strapi.performance.nodeOptions != "" {
								name:  "NODE_OPTIONS"
								value: #config.strapi.performance.nodeOptions
							},
							{name: "STRAPI_LOG_LEVEL", value: #config.strapi.performance.logLevel},
							if #config.strapi.performance.forceJsonLogs {
								name:  "STRAPI_LOG_FORCE_JSON"
								value: "true"
							},
							if #config.strapi.performance.prettyPrint {
								name:  "STRAPI_LOG_PRETTY_PRINT"
								value: "true"
							},
							if #config.strapi.admin.path != "" {
								name:  "ADMIN_PATH"
								value: #config.strapi.admin.path
							},
							if #config.strapi.admin.jwtExpiration != "" {
								name:  "ADMIN_JWT_EXPIRATION"
								value: #config.strapi.admin.jwtExpiration
							},
							if #config.strapi.admin.rateLimit.enabled {
								name:  "ADMIN_RATE_LIMIT_ENABLED"
								value: "true"
							},
							if #config.strapi.admin.rateLimit.enabled {
								name:  "ADMIN_RATE_LIMIT_MAX"
								value: strconv.FormatInt(#config.strapi.admin.rateLimit.max, 10)
							},
							if #config.strapi.admin.rateLimit.enabled {
								name:  "ADMIN_RATE_LIMIT_TIME_WINDOW"
								value: strconv.FormatInt(#config.strapi.admin.rateLimit.timeWindow, 10)
							},
							if #config.strapi.email.provider != "none" {
								name:  "EMAIL_PROVIDER"
								value: #config.strapi.email.provider
							},
							if #config.strapi.email.provider != "none" {
								name:  "EMAIL_DEFAULT_FROM"
								value: #config.strapi.email.defaultFrom
							},
							if #config.strapi.email.provider != "none" && #config.strapi.email.defaultReplyTo != "" {
								name:  "EMAIL_DEFAULT_REPLY_TO"
								value: #config.strapi.email.defaultReplyTo
							},
							if #config.strapi.email.provider == "smtp" {
								name:  "EMAIL_SMTP_HOST"
								value: #config.strapi.email.smtp.host
							},
							if #config.strapi.email.provider == "smtp" {
								name:  "EMAIL_SMTP_PORT"
								value: strconv.FormatInt(#config.strapi.email.smtp.port, 10)
							},
							if #config.strapi.email.provider == "smtp" && #config.strapi.email.smtp.username != "" {
								name:  "EMAIL_SMTP_USERNAME"
								value: #config.strapi.email.smtp.username
							},
							if #config.strapi.email.provider == "smtp" && (#config.strapi.email.smtp.password != "" || #config.strapi.email.smtp.existingSecret != "") {
								name: "EMAIL_SMTP_PASSWORD"
								valueFrom: secretKeyRef: {
									name: [
										if #config.strapi.email.smtp.existingSecret != "" {#config.strapi.email.smtp.existingSecret},
										"\(#config.fullname)-email",
									][0]
									key: #config.strapi.email.smtp.existingSecretPasswordKey
								}
							},
							if #config.strapi.email.provider == "smtp" {
								name:  "EMAIL_SMTP_SECURE"
								value: [if #config.strapi.email.smtp.secure {"true"}, "false"][0]
							},
							if #config.strapi.email.provider == "smtp" {
								name:  "EMAIL_SMTP_REQUIRE_TLS"
								value: [if #config.strapi.email.smtp.requireTLS {"true"}, "false"][0]
							},
							if #config.strapi.email.provider == "smtp" && #config.strapi.email.smtp.ignoreTLS {
								name:  "EMAIL_SMTP_IGNORE_TLS"
								value: "true"
							},
							if #config.strapi.email.provider == "sendgrid" && (#config.strapi.email.sendgrid.apiKey != "" || #config.strapi.email.sendgrid.existingSecret != "") {
								name: "SENDGRID_API_KEY"
								valueFrom: secretKeyRef: {
									name: [
										if #config.strapi.email.sendgrid.existingSecret != "" {#config.strapi.email.sendgrid.existingSecret},
										"\(#config.fullname)-email",
									][0]
									key: #config.strapi.email.sendgrid.existingSecretApiKeyKey
								}
							},
							if #config.strapi.upload.provider == "aws-s3" && #config.strapi.upload.s3.enabled {
								name: "AWS_ACCESS_KEY_ID"
								valueFrom: secretKeyRef: {
									name: [
										if #config.strapi.upload.s3.existingSecret != "" {#config.strapi.upload.s3.existingSecret},
										"\(#config.fullname)-upload-s3",
									][0]
									key: #config.strapi.upload.s3.existingSecretAccessKeyKey
								}
							},
							if #config.strapi.upload.provider == "aws-s3" && #config.strapi.upload.s3.enabled {
								name: "AWS_ACCESS_SECRET"
								valueFrom: secretKeyRef: {
									name: [
										if #config.strapi.upload.s3.existingSecret != "" {#config.strapi.upload.s3.existingSecret},
										"\(#config.fullname)-upload-s3",
									][0]
									key: #config.strapi.upload.s3.existingSecretSecretKeyKey
								}
							},
							if #config.strapi.upload.provider == "aws-s3" && #config.strapi.upload.s3.enabled && #config.strapi.upload.s3.region != "" {
								name:  "AWS_REGION"
								value: #config.strapi.upload.s3.region
							},
							if #config.strapi.upload.provider == "aws-s3" && #config.strapi.upload.s3.enabled && #config.strapi.upload.s3.endpoint != "" {
								name:  "AWS_ENDPOINT"
								value: #config.strapi.upload.s3.endpoint
							},
							if #config.strapi.upload.provider == "aws-s3" && #config.strapi.upload.s3.enabled {
								name:  "AWS_BUCKET"
								value: #config.strapi.upload.s3.bucket
							},
							if #config.strapi.upload.provider == "aws-s3" && #config.strapi.upload.s3.enabled && #config.strapi.upload.s3.prefix != "" {
								name:  "AWS_PREFIX"
								value: #config.strapi.upload.s3.prefix
							},
							if #config.strapi.upload.provider == "aws-s3" && #config.strapi.upload.s3.enabled && #config.strapi.upload.s3.baseUrl != "" {
								name:  "AWS_BASE_URL"
								value: #config.strapi.upload.s3.baseUrl
							},
							if #config.strapi.upload.provider == "cloudinary" && #config.strapi.upload.cloudinary.enabled {
								name:  "CLOUDINARY_CLOUD_NAME"
								value: #config.strapi.upload.cloudinary.cloudName
							},
							if #config.strapi.upload.provider == "cloudinary" && #config.strapi.upload.cloudinary.enabled && (#config.strapi.upload.cloudinary.apiKey != "" || #config.strapi.upload.cloudinary.existingSecret != "") {
								name: "CLOUDINARY_API_KEY"
								valueFrom: secretKeyRef: {
									name: [
										if #config.strapi.upload.cloudinary.existingSecret != "" {#config.strapi.upload.cloudinary.existingSecret},
										"\(#config.fullname)-upload-cloudinary",
									][0]
									key: #config.strapi.upload.cloudinary.existingSecretApiKeyKey
								}
							},
							if #config.strapi.upload.provider == "cloudinary" && #config.strapi.upload.cloudinary.enabled && (#config.strapi.upload.cloudinary.apiKey != "" || #config.strapi.upload.cloudinary.existingSecret != "") {
								name: "CLOUDINARY_API_SECRET"
								valueFrom: secretKeyRef: {
									name: [
										if #config.strapi.upload.cloudinary.existingSecret != "" {#config.strapi.upload.cloudinary.existingSecret},
										"\(#config.fullname)-upload-cloudinary",
									][0]
									key: #config.strapi.upload.cloudinary.existingSecretApiSecretKey
								}
							},
							if #config.strapi.graphql.playgroundEnabled {
								name:  "GRAPHQL_PLAYGROUND_ENABLED"
								value: "true"
							},
							if #config.strapi.graphql.endpoint != "" {
								name:  "GRAPHQL_ENDPOINT"
								value: #config.strapi.graphql.endpoint
							},
							if !#config.strapi.graphql.introspection {
								name:  "GRAPHQL_INTROSPECTION"
								value: "false"
							},
							if #config.strapi.graphql.maxDepth > 0 {
								name:  "GRAPHQL_MAX_DEPTH"
								value: strconv.FormatInt(#config.strapi.graphql.maxDepth, 10)
							},
							if #config.strapi.graphql.maxComplexity > 0 {
								name:  "GRAPHQL_MAX_COMPLEXITY"
								value: strconv.FormatInt(#config.strapi.graphql.maxComplexity, 10)
							},
							if #config.strapi.api.rest.defaultLimit > 0 {
								name:  "API_REST_DEFAULT_LIMIT"
								value: strconv.FormatInt(#config.strapi.api.rest.defaultLimit, 10)
							},
							if #config.strapi.api.rest.maxLimit > 0 {
								name:  "API_REST_MAX_LIMIT"
								value: strconv.FormatInt(#config.strapi.api.rest.maxLimit, 10)
							},
							if len(#config.strapi.extraEnv) > 0 {
								#config.strapi.extraEnv
							},
						]

						if #config.startupProbe.enabled {
							startupProbe: {
								httpGet: {
									path:   "/_health"
									port:   "http"
									scheme: "HTTP"
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
									path:   "/_health"
									port:   "http"
									scheme: "HTTP"
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
									path:   "/_health"
									port:   "http"
									scheme: "HTTP"
								}
								initialDelaySeconds: #config.readinessProbe.initialDelaySeconds
								periodSeconds:       #config.readinessProbe.periodSeconds
								timeoutSeconds:      #config.readinessProbe.timeoutSeconds
								failureThreshold:    #config.readinessProbe.failureThreshold
							}
						}

						if len(#config.resources) > 0 {
							resources: #config.resources
						}

						volumeMounts: [
							{
								name:      "database-config"
								mountPath: "/opt/app/dist/config/env/production/database.js"
								subPath:   "database.js"
								readOnly:  true
							},
							{
								name:      "data"
								mountPath: #config.persistence.uploads.mountPath
								if #config.persistence.enabled {
									subPath: #config.persistence.uploads.subPath
								}
							},
							if #config.resolvedDbMode == "sqlite" {
								name:      "data"
								mountPath: #config.database.sqlite.directory
								if #config.persistence.enabled {
									subPath: #config.persistence.sqlite.subPath
								}
							},
							if len(#config.extraVolumeMounts) > 0 {
								#config.extraVolumeMounts
							},
						]
					},
				]

				volumes: [
					{
						name: "database-config"
						configMap: name: "\(#config.fullname)-database-config"
					},
					{
						name: "data"
						if #config.persistence.enabled {
							persistentVolumeClaim: claimName: [
								if #config.persistence.existingClaim != "" {#config.persistence.existingClaim},
								if #config.persistence.existingClaim == "" {"\(#config.fullname)-data"},
							][0]
						}
						if !#config.persistence.enabled {
							emptyDir: {}
						}
					},
					if len(#config.extraVolumes) > 0 {
						#config.extraVolumes
					},
				]
			}
		}
	}
}
