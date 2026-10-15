package templates

import (
	"crypto/sha256"
	"encoding/hex"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
)

#PostgresNetworkPolicy: networkingv1.#NetworkPolicy & {
	#config: #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config._postgresLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		podSelector: matchLabels: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		policyTypes: ["Ingress", "Egress"]
		ingress: [
			{
				from: [
					{podSelector: {}},
				]
				ports: [
					{
						protocol: "TCP"
						port:     #config.postgresql.service.port
					},
				]
			},
		]
		egress: [
			{
				ports: [
					{protocol: "UDP", port: 53},
					{protocol: "TCP", port: 53},
				]
			},
		]
	}
}

#PostgresSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-auth"
		namespace: #config.metadata.namespace
		labels:    #config._postgresLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		"postgres-password": #config._postgresPassword
		"user-password":     #config._userPassword
	}
}

#PostgresConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-config"
		namespace: #config.metadata.namespace
		labels:    #config._postgresLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		"postgres_exporter.yml": """
			{}

			"""
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
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-initdb"
		namespace: #config.metadata.namespace
		labels:    #config._postgresLabels
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
		"20-affine-vector.sh": """
			#!/bin/bash
			set -euo pipefail
			export PGPASSWORD="${POSTGRES_PASSWORD}"
			psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${APP_DATABASE}" <<'SQL'
			CREATE EXTENSION IF NOT EXISTS vector;
			SQL

			"""
		for k, v in #config.postgresql.initdb.scripts {
			if k != "20-affine-vector.sh" {
				"\(k)": v
			}
		}
	}
}

#PostgresHeadlessService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-primary-headless"
		namespace: #config.metadata.namespace
		labels:    #config._postgresLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		clusterIP:                "None"
		publishNotReadyAddresses: true
		ports: [
			{
				name:       "postgres"
				port:       #config.postgresql.service.port
				targetPort: "postgres"
			},
		]
		selector: #config._postgresSelectorLabels
	}
}

#PostgresService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config._postgresLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [
			{
				name:       "postgres"
				port:       #config.postgresql.service.port
				targetPort: "postgres"
			},
		]
		selector: #config._postgresSelectorLabels
	}
}

#PostgresStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	_configData: """
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
		local   all             all                                     scram-sha-256
		host    all             all             127.0.0.1/32            scram-sha-256
		host    all             all             ::1/128                 scram-sha-256
		host all             all             0.0.0.0/0            scram-sha-256
		host all             all             ::/0            scram-sha-256
		"""
	_configChecksum: hex.Encode(sha256.Sum256(_configData))

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config._postgresLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		serviceName: "\(#config.metadata.name)-postgresql-primary-headless"
		replicas:    1
		selector: matchLabels: #config._postgresSelectorLabels
		template: {
			metadata: {
				labels: #config._postgresSelectorLabels
				annotations: {
					"checksum/config": _configChecksum
					if #config.podAnnotations != _|_ {
						for k, v in #config.podAnnotations {
							"\(k)": v
						}
					}
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				securityContext:              #config.postgresql.podSecurityContext
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
								containerPort: #config.postgresql.service.port
							},
						]
						env: [
							{
								name:  "PGDATA"
								value: "/var/lib/postgresql/data/pgdata"
							},
							{
								name:  "POSTGRES_USER"
								value: "postgres"
							},
							{
								name:  "POSTGRES_DB"
								value: #config.postgresql.auth.database
							},
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-postgresql-auth"
									key:  "postgres-password"
								}
							},
							{
								name:  "APP_DATABASE"
								value: #config.postgresql.auth.database
							},
							{
								name:  "APP_USERNAME"
								value: #config.postgresql.auth.username
							},
							{
								name: "APP_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-postgresql-auth"
									key:  #config.postgresql.auth.existingSecretUserPasswordKey
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
						resources:       #config.postgresql.standalone.resources
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
							{
								name:      "postgres-tmp"
								mountPath: "/tmp"
							},
							{
								name:      "postgres-socket"
								mountPath: "/var/run/postgresql"
							},
						]
					},
				]
				volumes: [
					{
						name: "config"
						configMap: name: "\(#config.metadata.name)-postgresql-config"
					},
					{
						name: "initdb"
						projected: {
							defaultMode: 0o755
							sources: [
								{
									configMap: name: "\(#config.metadata.name)-postgresql-initdb"
								},
							]
						}
					},
					{
						name: "postgres-tmp"
						emptyDir: sizeLimit: "1Gi"
					},
					{
						name: "postgres-socket"
						emptyDir: {
							medium:    "Memory"
							sizeLimit: "16Mi"
						}
					},
				]
			}
		}
		volumeClaimTemplates: [
			{
				metadata: {
					name: "data"
					labels: {
						"app.kubernetes.io/name":     "postgresql"
						"app.kubernetes.io/instance": #config.metadata.name
					}
				}
				spec: {
					accessModes: ["ReadWriteOnce"]
					resources: requests: storage: #config.postgresql.standalone.persistence.size
				}
			},
		]
	}
}