package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#ServerDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name: "\(#config.metadata.name)-server"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "server"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		strategy: {
			if #config.server.persistence.enabled || #config.server.dockerDataPersistence.enabled {
				type: "Recreate"
			}
			if !#config.server.persistence.enabled && !#config.server.dockerDataPersistence.enabled {
				type: "RollingUpdate"
				rollingUpdate: {
					maxSurge:       1
					maxUnavailable: 1
				}
			}
		}
		replicas: #config.server.replicaCount
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "server"
		}
		template: {
			metadata: labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "server"
			}
			spec: corev1.#PodSpec & {
				securityContext: {
					runAsUser: #config.securityContext.runAsUser
					fsGroup:   #config.securityContext.fsGroup
				}
				initContainers: [
					{
						name:  "wait-for-db"
						image: #config.utilityImages.postgres
						command: [
							"sh",
							"-c",
							"""
							until pg_isready -h \(#config.metadata.name)-db -p 5432 -U postgres; do
							  echo \"Waiting for database socket...\"
							  sleep 2
							done
							echo \"Database socket is ready!\"
							""",
						]
					},
					{
						name:  "ensure-database-exists"
						image: #config.utilityImages.postgres
						env: [
							{
								name: "PGPASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-db-superuser"
									key:  "password"
								}
							},
							{
								name: "APP_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-db-url"
									key:  "appPassword"
								}
							},
						]
						command: [
							"sh",
							"-c",
							"""
							DBNAME=\(#config.db.internal.database)
							APP_USER=\(#config.db.internal.appUser)
							export PGPASSWORD
							export APP_PASSWORD
							echo "Creating database ${DBNAME} if it doesn't exist..."
							psql -h \(#config.metadata.name)-db -p 5432 -U postgres -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname = '${DBNAME}'" | grep -q 1 || psql -h \(#config.metadata.name)-db -p 5432 -U postgres -d postgres -c "CREATE DATABASE ${DBNAME};"
							echo "Creating app user ${APP_USER} if it doesn't exist..."
							psql -h \(#config.metadata.name)-db -p 5432 -U postgres -d postgres -c "DO \\$do$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${APP_USER}') THEN EXECUTE format('CREATE USER %I WITH PASSWORD %L', '${APP_USER}', '${APP_PASSWORD}'); ELSE EXECUTE format('ALTER USER %I WITH PASSWORD %L', '${APP_USER}', '${APP_PASSWORD}'); END IF; END \\$do$;"
							echo "Creating core schema and granting permissions..."
							psql -h \(#config.metadata.name)-db -p 5432 -U postgres -d "${DBNAME}" -c "CREATE SCHEMA IF NOT EXISTS core"
							psql -h \(#config.metadata.name)-db -p 5432 -U postgres -d "${DBNAME}" -c "GRANT ALL PRIVILEGES ON DATABASE ${DBNAME} TO ${APP_USER};"
							psql -h \(#config.metadata.name)-db -p 5432 -U postgres -d "${DBNAME}" -c "GRANT ALL PRIVILEGES ON SCHEMA core TO ${APP_USER};"
							psql -h \(#config.metadata.name)-db -p 5432 -U postgres -d "${DBNAME}" -c "GRANT ALL PRIVILEGES ON SCHEMA public TO ${APP_USER};"
							psql -h \(#config.metadata.name)-db -p 5432 -U postgres -d "${DBNAME}" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO ${APP_USER};"
							psql -h \(#config.metadata.name)-db -p 5432 -U postgres -d "${DBNAME}" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${APP_USER};"
							psql -h \(#config.metadata.name)-db -p 5432 -U postgres -d "${DBNAME}" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT ALL ON TABLES TO ${APP_USER};"
							psql -h \(#config.metadata.name)-db -p 5432 -U postgres -d "${DBNAME}" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT ALL ON SEQUENCES TO ${APP_USER};"
							psql -h \(#config.metadata.name)-db -p 5432 -U postgres -d "${DBNAME}" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${APP_USER};"
							psql -h \(#config.metadata.name)-db -p 5432 -U postgres -d "${DBNAME}" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${APP_USER};"
							echo "Database ${DBNAME} is ready."
							""",
						]
					},
					{
						name:            "run-migrations"
						image:           #config.server.image.reference
						imagePullPolicy: #config.server.image.pullPolicy
						command: [
							"sh",
							"-c",
							"npx -y typeorm migration:run -d dist/database/typeorm/core/core.datasource",
						]
						env: [
							if #config.db.internal.enabled {
								{
									name: "PG_DATABASE_URL"
									valueFrom: secretKeyRef: {
										name: "\(#config.metadata.name)-db-url"
										key:  "url"
									}
								}
							},
							if !#config.db.internal.enabled && #config.db.external != _|_ && #config.db.external.secretName != "" {
								{
									name: "DB_PASSWORD"
									valueFrom: secretKeyRef: {
										name: #config.db.external.secretName
										key:  #config.db.external.passwordKey
									}
								}
							},
							if !#config.db.internal.enabled && #config.db.external != _|_ && #config.db.external.secretName != "" {
								{
									name: "PG_DATABASE_URL"
									_ssl: *"" | string
									if #config.db.external.ssl {
										_ssl: "?sslmode=require"
									}
									value: "postgres://\(#config.db.external.user):$(DB_PASSWORD)@\(#config.db.external.host):\(#config.db.external.port)/\(#config.db.external.database)\(_ssl)"
								}
							},
						]
					},
				]
				containers: [
					{
						name:            "server"
						image:           #config.server.image.reference
						imagePullPolicy: #config.server.image.pullPolicy
						stdin:           #config.server.stdin
						tty:             #config.server.tty
						ports: [
							{
								containerPort: #config.server.service.port
								name:          "http-tcp"
								protocol:      "TCP"
							},
						]
						livenessProbe: {
							httpGet: {
								path: "/"
								port: #config.server.service.port
							}
							initialDelaySeconds: 180
							periodSeconds:       10
							timeoutSeconds:      5
							failureThreshold:    5
						}
						readinessProbe: {
							httpGet: {
								path: "/"
								port: #config.server.service.port
							}
							initialDelaySeconds: 60
							periodSeconds:       5
							timeoutSeconds:      5
							failureThreshold:    5
						}
						env: [
							{
								name:  "SERVER_URL"
								value: #config.server.env.SERVER_URL
							},
							{
								name:  "FRONTEND_URL"
								value: #config.server.env.FRONTEND_URL
							},
							{
								name:  "REDIS_URL"
								value: "redis://\(#config.metadata.name)-redis:\(#config.redis.internal.service.port)"
							},
							{
								name: "PG_DATABASE_URL"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-db-url"
									key:  "url"
								}
							},
							{
								name:  "STORAGE_TYPE"
								value: #config.storage.type
							},
							{
								name:  "SIGN_IN_PREFILLED"
								value: #config.server.env.SIGN_IN_PREFILLED
							},
							{
								name:  "ACCESS_TOKEN_EXPIRES_IN"
								value: #config.server.env.ACCESS_TOKEN_EXPIRES_IN
							},
							{
								name:  "LOGIN_TOKEN_EXPIRES_IN"
								value: #config.server.env.LOGIN_TOKEN_EXPIRES_IN
							},
							{
								name:  "API_RATE_LIMITING_SHORT_LIMIT"
								value: "\(#config.server.env.API_RATE_LIMITING_SHORT_LIMIT)"
							},
							{
								name:  "API_RATE_LIMITING_SHORT_TTL_IN_MS"
								value: "\(#config.server.env.API_RATE_LIMITING_SHORT_TTL_IN_MS)"
							},
							{
								name:  "IS_MULTIWORKSPACE_ENABLED"
								value: #config.server.env.IS_MULTIWORKSPACE_ENABLED
							},
							{
								name:  "DEFAULT_SUBDOMAIN"
								value: #config.server.env.DEFAULT_SUBDOMAIN
							},
							{
								name:  "IS_WORKSPACE_CREATION_LIMITED_TO_SERVER_ADMINS"
								value: #config.server.env.IS_WORKSPACE_CREATION_LIMITED_TO_SERVER_ADMINS
							},
							{
								name: "APP_SECRET"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-tokens"
									key:  "accessToken"
								}
							},
							if #config.storage.type == "s3" {
								{
									name:  "STORAGE_S3_NAME"
									value: #config.storage.s3.bucket
								}
							},
							if #config.storage.type == "s3" {
								{
									name:  "STORAGE_S3_REGION"
									value: #config.storage.s3.region
								}
							},
							if #config.storage.type == "s3" {
								{
									name:  "STORAGE_S3_ENDPOINT"
									value: #config.storage.s3.endpoint
								}
							},
							if #config.storage.type == "s3" {
								{
									name:  "STORAGE_S3_ACCESS_KEY_ID"
									value: #config.storage.s3.accessKeyId
								}
							},
							if #config.storage.type == "s3" {
								{
									name:  "STORAGE_S3_SECRET_ACCESS_KEY"
									value: #config.storage.s3.secretAccessKey
								}
							},
						]
						resources: #config.server.resources
						volumeMounts: [
							if #config.server.persistence.enabled {
								{
									name:      "server-data"
									mountPath: "/app/packages/twenty-server/.local-storage"
								}
							},
							if #config.server.dockerDataPersistence.enabled {
								{
									name:      "docker-data"
									mountPath: "/app/docker-data"
								}
							},
						]
					},
				]
				volumes: [
					if #config.server.persistence.enabled {
						{
							name: "server-data"
							persistentVolumeClaim: claimName: {
								if #config.server.persistence.existingClaim != "" {
									#config.server.persistence.existingClaim
								}
								if #config.server.persistence.existingClaim == "" {
									"\(#config.metadata.name)-server"
								}
							}
						}
					},
					if #config.server.dockerDataPersistence.enabled {
						{
							name: "docker-data"
							persistentVolumeClaim: claimName: {
								if #config.server.dockerDataPersistence.existingClaim != "" {
									#config.server.dockerDataPersistence.existingClaim
								}
								if #config.server.dockerDataPersistence.existingClaim == "" {
									"\(#config.metadata.name)-docker-data"
								}
							}
						}
					},
				]
			}
		}
	}
}
