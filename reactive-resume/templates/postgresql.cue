package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
)



// #PostgresNetworkPolicy mirrors reactive-resume/charts/postgresql/templates/networkpolicy.yaml.
// It isolates the PostgreSQL pod: only in-namespace pods may reach port 5432, and
// egress is limited to DNS (UDP/TCP 53).
#PostgresNetworkPolicy: netv1.#NetworkPolicy & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: netv1.#NetworkPolicySpec & {
		podSelector: matchLabels: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		policyTypes: ["Ingress", "Egress"]
		ingress: [
			{
				from: [{podSelector: {}}]
				ports: [{protocol: "TCP", port: 5432}]
			},
		]
		egress: [
			{
				// Allow DNS
				ports: [
					{protocol: "UDP", port: 53},
					{protocol: "TCP", port: 53},
				]
			},
		]
	}
}

// #PostgresAuthSecret mirrors reactive-resume/charts/postgresql/templates/secret.yaml.
// Helm name: <release>-postgresql-auth with keys postgres-password and user-password.
#PostgresAuthSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-auth"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		// postgres superuser password (same value for simplicity)
		"postgres-password": [
			if #config.postgresql.auth.password != "" {#config.postgresql.auth.password},
			"ReactiveResumeDbDefaultPassword2026!",
		][0]
		// app user password used by initdb and the application
		"\(#config.postgresql.auth.existingSecretUserPasswordKey)": [
			if #config.postgresql.auth.password != "" {#config.postgresql.auth.password},
			"ReactiveResumeDbDefaultPassword2026!",
		][0]
	}
}

// #PostgresConfigMap mirrors reactive-resume/charts/postgresql/templates/configmap.yaml
// (the first ConfigMap: postgresql-config with postgresql.conf / pg_hba.conf).
#PostgresConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-config"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
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

// #PostgresInitdbConfigMap mirrors reactive-resume/charts/postgresql/templates/configmap.yaml
// (the second ConfigMap: postgresql-initdb with shell init scripts).
// Extra scripts from config.postgresql.initdb.scripts are merged in.
#PostgresInitdbConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-initdb"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {
		// Built-in init script: create app user, database, and replication role.
		// (Not user-overridable; always injected as 01-init-users.sh.)
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

		// User-supplied initdb scripts (e.g. 20-reactive-resume-schema.sh from values.cue).
		// These are merged from config.postgresql.initdb.scripts.
		if #config.postgresql.initdb != _|_ {
			if #config.postgresql.initdb.scripts != _|_ {
				#config.postgresql.initdb.scripts
			}
		}
	}
}

// #PostgresHeadlessService mirrors reactive-resume/charts/postgresql/templates/svc-headless.yaml.
// Required for StatefulSet pod DNS (e.g. reactive-resume-postgresql-0.<headless-svc>).
#PostgresHeadlessService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-primary-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
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
		selector: {
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "postgresql"
			"app.kubernetes.io/part-of":   "postgresql"
			"app.kubernetes.io/role":      "standalone"
		}
	}
}

// #PostgresService mirrors reactive-resume/charts/postgresql/templates/service.yaml.
#PostgresService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: corev1.#ServiceTypeClusterIP
		ports: [
			{
				name:       "postgres"
				port:       #config.postgresql.service.port
				targetPort: "postgres"
			},
		]
		selector: {
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "postgresql"
			"app.kubernetes.io/part-of":   "postgresql"
			"app.kubernetes.io/role":      "standalone"
		}
	}
}

// #PostgresStatefulSet mirrors reactive-resume/charts/postgresql/templates/statefulset.yaml.
// Includes: correct selectors, config/initdb/tmp/socket volumes, security contexts, all probes.
#PostgresStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas:    1
		serviceName: "\(#config.metadata.name)-postgresql-primary-headless"
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
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				terminationGracePeriodSeconds: 120
				securityContext: corev1.#PodSecurityContext & {
					fsGroup:             999
					fsGroupChangePolicy: "OnRootMismatch"
					seccompProfile: type: corev1.#SeccompProfileTypeRuntimeDefault
				}
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
							{name: "postgres", containerPort: 5432},
						]
						env: [
							{name: "PGDATA", value: "/var/lib/postgresql/data/pgdata"},
							{name: "POSTGRES_USER", value: "postgres"},
							{name: "POSTGRES_DB", value: #config.postgresql.auth.database},
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-postgresql-auth"
									key:  "postgres-password"
								}
							},
							{name: "APP_DATABASE", value: #config.postgresql.auth.database},
							{name: "APP_USERNAME", value: #config.postgresql.auth.username},
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
								"sh", "-ec",
								"PGPASSWORD=\"${POSTGRES_PASSWORD}\" pg_isready -U postgres -h 127.0.0.1 -p 5432 -d postgres",
							]
							initialDelaySeconds: 60
							periodSeconds:       20
							timeoutSeconds:      5
							failureThreshold:    6
						}
						readinessProbe: {
							exec: command: [
								"sh", "-ec",
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
								"sh", "-ec",
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
						securityContext: corev1.#SecurityContext & {
							allowPrivilegeEscalation: false
							readOnlyRootFilesystem:   true
							runAsNonRoot:             true
							runAsUser:                999
							runAsGroup:               999
							capabilities: drop: ["ALL"]
						}
						resources: corev1.#ResourceRequirements & {
							requests: {
								(corev1.#ResourceCPU):    "250m"
								(corev1.#ResourceMemory): "512Mi"
							}
							limits: {
								(corev1.#ResourceCPU):    "500m"
								(corev1.#ResourceMemory): "1Gi"
							}
						}
						volumeMounts: [
							{name: "data", mountPath: "/var/lib/postgresql/data"},
							{name: "config", mountPath: "/etc/postgresql/generated"},
							{name: "initdb", mountPath: "/docker-entrypoint-initdb.d"},
							{name: "postgres-tmp", mountPath: "/tmp"},
							{name: "postgres-socket", mountPath: "/var/run/postgresql"},
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
								{configMap: name: "\(#config.metadata.name)-postgresql-initdb"},
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
					resources: requests: storage: "8Gi"
				}
			},
		]
	}
}
