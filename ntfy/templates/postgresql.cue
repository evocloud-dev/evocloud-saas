package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

// #PostgresqlSecret mirrors the PostgreSQL auth Secret in charts/postgresql/templates/secret.yaml.
#PostgresqlSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-auth"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	type: "Opaque"
	stringData: {
		"postgres-password": [
			if #config.postgresql.auth.password != "" {#config.postgresql.auth.password},
			"change-me-postgres-password!",
		][0]
		"user-password": [
			if #config.postgresql.auth.password != "" {#config.postgresql.auth.password},
			"change-me-user-password!",
		][0]
	}
}

// #PostgresqlConfigMap mirrors charts/postgresql/templates/configmap.yaml (config).
#PostgresqlConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-config"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	data: {
		"postgres_exporter.yml": "{}\n"
		"postgresql.conf": """
			listen_addresses = '*'
			port = 5432
			wal_level = replica
			hot_standby = on
			max_wal_senders = 10
			max_replication_slots = 10
			wal_keep_size = '512MB'
			password_encryption = scram-sha-256
			max_connections = 200
			shared_buffers = '256MB'
			ssl = off
			"""
		"pg_hba.conf": """
			local   all             all                                     scram-sha-256
			host    all             all             127.0.0.1/32            scram-sha-256
			host    all             all             ::1/128                 scram-sha-256

			host all             all             0.0.0.0/0            scram-sha-256
			host all             all             ::/0            scram-sha-256
			"""
	}
}

// #PostgresqlInitDbConfigMap mirrors charts/postgresql/templates/configmap.yaml (initdb).
#PostgresqlInitDbConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-initdb"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	data: {
		"01-init-users.sh": """
			#!/bin/bash
			set -euo pipefail
			export PGPASSWORD="${POSTGRES_PASSWORD}"
			psql --username "${POSTGRES_USER}" --dbname postgres \\
			  --set=app_username="${APP_USERNAME}" \\
			  --set=app_password="${APP_PASSWORD}" \\
			  --set=app_database="${APP_DATABASE}" \\
			  --set=replication_username="${REPLICATION_USERNAME:-}" \\
			  --set=replication_password="${REPLICATION_PASSWORD:-}" <<'SQL'
			SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'app_username', :'app_password')
			WHERE :'app_username' <> ''
			  AND :'app_password' <> ''
			  AND NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'app_username') \\gexec

			SELECT format('CREATE DATABASE %I OWNER %I', :'app_database', :'app_username')
			WHERE :'app_database' <> ''
			  AND :'app_username' <> ''
			  AND NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'app_database') \\gexec

			SELECT format('CREATE ROLE %I REPLICATION LOGIN PASSWORD %L', :'replication_username', :'replication_password')
			WHERE :'replication_username' <> ''
			  AND :'replication_password' <> ''
			  AND NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'replication_username') \\gexec
			SQL

			# PostgreSQL 15+ revokes CREATE on the public schema for non-superusers.
			# Grant schema privileges so the application user can run migrations.
			if [ -n "${APP_DATABASE}" ] && [ -n "${APP_USERNAME}" ]; then
			  psql --username "${POSTGRES_USER}" --dbname "${APP_DATABASE}" \\
			    -c "GRANT ALL ON SCHEMA public TO \\"${APP_USERNAME}\\";"
			fi
			"""
	}
}

// #PostgresqlHeadlessService mirrors charts/postgresql/templates/service-headless.yaml.
#PostgresqlHeadlessService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-primary-headless"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	spec: corev1.#ServiceSpec & {
		clusterIP:                "None"
		publishNotReadyAddresses: true
		ports: [{
			name:       "postgres"
			port:       5432
			targetPort: "postgres"
		}]
		selector: {
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "postgresql"
			"app.kubernetes.io/part-of":   "postgresql"
			"app.kubernetes.io/role":      "standalone"
		}
	}
}

// #PostgresqlService mirrors charts/postgresql/templates/service.yaml.
#PostgresqlService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [{
			name:       "postgres"
			port:       5432
			targetPort: "postgres"
		}]
		selector: {
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "postgresql"
			"app.kubernetes.io/part-of":   "postgresql"
			"app.kubernetes.io/role":      "standalone"
		}
	}
}

// #PostgresqlStatefulSet mirrors charts/postgresql/templates/statefulset-primary.yaml.
#PostgresqlStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config.metadata.name)-postgresql-primary-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "postgresql"
			"app.kubernetes.io/part-of":   "postgresql"
			"app.kubernetes.io/role":      "standalone"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":      "postgresql"
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/component": "postgresql"
				"app.kubernetes.io/part-of":   "postgresql"
				"app.kubernetes.io/role":      "standalone"
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            "default"
				automountServiceAccountToken:  false
				securityContext:               #config.postgresql.podSecurityContext
				terminationGracePeriodSeconds: 120
				containers: [{
					name:            "postgresql"
					image:           #config.postgresql.image.reference
					imagePullPolicy: #config.postgresql.image.pullPolicy
					args: [
						"-c",
						"config_file=/etc/postgresql/generated/postgresql.conf",
						"-c",
						"hba_file=/etc/postgresql/generated/pg_hba.conf",
					]
					ports: [{
						name:          "postgres"
						containerPort: 5432
					}]
					env: [
						{name: "PGDATA", value: "/var/lib/postgresql/data/pgdata"},
						{name: "POSTGRES_USER", value: "postgres"},
						{name: "POSTGRES_DB", value: #config.postgresql.auth.database},
						{
							name: "POSTGRES_PASSWORD"
							valueFrom: secretKeyRef: {
								name: [
									if #config.postgresql.auth.existingSecret != "" {#config.postgresql.auth.existingSecret},
									"\(#config.metadata.name)-postgresql-auth",
								][0]
								key: "postgres-password"
							}
						},
						{name: "APP_DATABASE", value: #config.postgresql.auth.database},
						{name: "APP_USERNAME", value: #config.postgresql.auth.username},
						{
							name: "APP_PASSWORD"
							valueFrom: secretKeyRef: {
								name: [
									if #config.postgresql.auth.existingSecret != "" {#config.postgresql.auth.existingSecret},
									"\(#config.metadata.name)-postgresql-auth",
								][0]
								key: #config.postgresql.auth.existingSecretUserPasswordKey
							}
						},
					]
					livenessProbe: {
						exec: command: [
							"sh",
							"-ec",
							"PGPASSWORD=\"${POSTGRES_PASSWORD}\" pg_isready -U postgres -h 127.0.0.1 -p 5432 -d postgres",
						]
						initialDelaySeconds: 60
						periodSeconds:       20
						timeoutSeconds:      5
						failureThreshold:    6
					}
					readinessProbe: {
						exec: command: [
							"sh",
							"-ec",
							"""
							DATA_DIR="${PGDATA:-/var/lib/postgresql/data/pgdata}"
							if [ ! -s "${DATA_DIR}/PG_VERSION" ]; then
							  exit 1
							fi
							export PGPASSWORD="${POSTGRES_PASSWORD}"
							if psql -U postgres -h 127.0.0.1 -p 5432 -d template1 -tAc "SELECT 1" >/dev/null 2>&1; then
							  if ! psql -U postgres -h 127.0.0.1 -p 5432 -d template1 -tAc "SELECT 1 FROM pg_database WHERE datname = 'postgres'" | grep -qx 1; then
							    createdb -U postgres -h 127.0.0.1 -p 5432 postgres
							  fi
							else
							  echo "Unable to verify or repair the postgres database on this PostgreSQL data directory." >&2
							  exit 1
							fi
							PGPASSWORD="${POSTGRES_PASSWORD}" pg_isready -U postgres -h 127.0.0.1 -p 5432 -d postgres
							""",
						]
						initialDelaySeconds: 20
						periodSeconds:       10
						timeoutSeconds:      5
						failureThreshold:    6
					}
					startupProbe: {
						exec: command: [
							"sh",
							"-ec",
							"""
							DATA_DIR="${PGDATA:-/var/lib/postgresql/data/pgdata}"
							if [ ! -s "${DATA_DIR}/PG_VERSION" ]; then
							  exit 1
							fi
							export PGPASSWORD="${POSTGRES_PASSWORD}"
							if psql -U postgres -h 127.0.0.1 -p 5432 -d template1 -tAc "SELECT 1" >/dev/null 2>&1; then
							  if ! psql -U postgres -h 127.0.0.1 -p 5432 -d template1 -tAc "SELECT 1 FROM pg_database WHERE datname = 'postgres'" | grep -qx 1; then
							    createdb -U postgres -h 127.0.0.1 -p 5432 postgres
							  fi
							else
							  echo "Unable to verify or repair the postgres database on this PostgreSQL data directory." >&2
							  exit 1
							fi
							""",
						]
						initialDelaySeconds: 10
						periodSeconds:       10
						timeoutSeconds:      5
						failureThreshold:    60
					}
					securityContext: #config.postgresql.securityContext
					resources:       #config.postgresql.resources
					volumeMounts: [
						{name: "data", mountPath: "/var/lib/postgresql/data"},
						{name: "config", mountPath: "/etc/postgresql/generated"},
						{name: "initdb", mountPath: "/docker-entrypoint-initdb.d"},
					]
				}]
				volumes: [
					{
						name: "config"
						configMap: name: "\(#config.metadata.name)-postgresql-config"
					},
					{
						name: "initdb"
						projected: {
							defaultMode: 0o755
							sources: [{
								configMap: name: "\(#config.metadata.name)-postgresql-initdb"
							}]
						}
					},
					if !#config.postgresql.persistence.enabled {
						name: "data"
						emptyDir: {}
					},
				]
			}
		}
		if #config.postgresql.persistence.enabled {
			volumeClaimTemplates: [
				corev1.#PersistentVolumeClaim & {
					metadata: {
						name: "data"
						labels: {
							"app.kubernetes.io/name":     "postgresql"
							"app.kubernetes.io/instance": #config.metadata.name
						}
					}
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: ["ReadWriteOnce"]
						if #config.postgresql.persistence.storageClass != "" {
							storageClassName: #config.postgresql.persistence.storageClass
						}
						resources: requests: storage: #config.postgresql.persistence.size
					}
				},
			]
		}
	}
}
