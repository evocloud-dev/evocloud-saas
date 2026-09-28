package templates

import (
	"crypto/sha256"
	"encoding/hex"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgresSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.#postgresqlFullname)-auth"
		namespace: #config.metadata.namespace
		labels:    #config.#postgresqlLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		"postgres-password": #config.#databaseAdminPassword
		"user-password":     #config.#databaseUserPassword
	}
}

#PostgresConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.#postgresqlFullname)-config"
		namespace: #config.metadata.namespace
		labels:    #config.#postgresqlLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
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

#PostgresInitdbConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.#postgresqlFullname)-initdb"
		namespace: #config.metadata.namespace
		labels:    #config.#postgresqlLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
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

#PostgresHeadlessService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.#postgresqlFullname)-primary-headless"
		namespace: #config.metadata.namespace
		labels:    #config.#postgresqlLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		clusterIP:                "None"
		publishNotReadyAddresses: true
		ports: [
			{
				name:       "postgres"
				port:       5432
				targetPort: "postgres"
			},
		]
		selector: #config.#postgresqlSelectorLabels
	}
}

#PostgresService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#postgresqlServiceName
		namespace: #config.metadata.namespace
		labels:    #config.#postgresqlLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [
			{
				name:       "postgres"
				port:       5432
				targetPort: "postgres"
			},
		]
		selector: #config.#postgresqlSelectorLabels
	}
}

#PostgresStatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      #config.#postgresqlFullname
		namespace: #config.metadata.namespace
		labels:    #config.#postgresqlLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config.#postgresqlFullname)-primary-headless"
		replicas:    1
		selector: matchLabels: #config.#postgresqlSelectorLabels
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: #config.#postgresqlSelectorLabels
				annotations: {
					"checksum/config": hex.Encode(sha256.Sum256('listen_addresses = \'*\'port = 5432'))
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				securityContext: {
					fsGroup:             999
					fsGroupChangePolicy: "OnRootMismatch"
					seccompProfile: type: "RuntimeDefault"
				}
				terminationGracePeriodSeconds: 120
				containers: [
					{
						name:            "postgresql"
						image:           #config.postgresql.image.reference
						imagePullPolicy: #config.postgresql.image.pullPolicy
						args: [
							"-c",
							"config_file=/etc/postgresql/generated/postgresql.conf",
							"-c",
							"hba_file=/etc/postgresql/generated/pg_hba.conf",
						]
						ports: [
							{
								name:          "postgres"
								containerPort: 5432
							},
						]
						env: [
							{name: "PGDATA", value: "/var/lib/postgresql/data/pgdata"},
							{name: "POSTGRES_USER", value: "postgres"},
							{name: "POSTGRES_DB", value: #config.postgresql.auth.database},
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.#postgresqlFullname)-auth"
									key:  "postgres-password"
								}
							},
							{name: "APP_DATABASE", value: #config.postgresql.auth.database},
							{name: "APP_USERNAME", value: #config.postgresql.auth.username},
							{
								name: "APP_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.#postgresqlFullname)-auth"
									key:  #config.postgresql.auth.existingSecretUserPasswordKey
								}
							},
							for ev in #config.postgresql.extraEnv {
								ev
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
							let _readinessScript = """
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
								"""
							exec: command: [
								"sh",
								"-ec",
								_readinessScript,
							]
							initialDelaySeconds: 20
							periodSeconds:       10
							timeoutSeconds:      5
							failureThreshold:    6
						}
						startupProbe: {
							let _startupScript = """
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
								"""
							exec: command: [
								"sh",
								"-ec",
								_startupScript,
							]
							initialDelaySeconds: 10
							periodSeconds:       10
							timeoutSeconds:      5
							failureThreshold:    60
						}
						securityContext: {
							allowPrivilegeEscalation: false
							capabilities: drop: ["ALL"]
							readOnlyRootFilesystem: false
							runAsNonRoot:           true
							runAsUser:              999
							runAsGroup:             999
						}
						resources: #config.#postgresResources
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/var/lib/postgresql/data"
							},
							{
								name:      "config"
								mountPath: "/etc/postgresql/generated"
							},
							{
								name:      "initdb"
								mountPath: "/docker-entrypoint-initdb.d"
							},
						]
					},
				]
				volumes: [
					{
						name: "config"
						configMap: name: "\(#config.#postgresqlFullname)-config"
					},
					{
						name: "initdb"
						projected: {
							defaultMode: 0o755
							sources: [
								{
									configMap: name: "\(#config.#postgresqlFullname)-initdb"
								},
							]
						}
					},
					if !#config.postgresql.standalone.persistence.enabled {
						{
							name: "data"
							emptyDir: {}
						}
					},
				]
			}
		}
		if #config.postgresql.standalone.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: {
						name:   "data"
						labels: #config.#postgresqlLabels
					}
					spec: {
						accessModes: ["ReadWriteOnce"]
						resources: requests: storage: #config.postgresql.standalone.persistence.size
					}
				},
			]
		}
	}
}
