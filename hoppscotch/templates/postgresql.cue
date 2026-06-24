package templates

import (
	"encoding/base64"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQLSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.postgresqlSecretName
		namespace: #config.namespace
		labels:    #config.labels
	}
	type: "Opaque"
	data: {
		let userPassword = [if #config.postgresql.auth.password != "" { #config.postgresql.auth.password }, "hoppscotch-default-password-change-me-!!"][0]
		let postgresPassword = "hoppscotch-default-superuser-password-change-me-!!"

		"postgres-password": '\(base64.Encode(null, postgresPassword))'
		"user-password":     '\(base64.Encode(null, userPassword))'
	}
}

#PostgreSQLInitDBCM: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-initdb"
		namespace: #config.namespace
		labels:    #config.labels
	}
	data: {
		"01-init-users.sh": """
			#!/bin/bash
			set -euo pipefail
			export PGPASSWORD="${POSTGRES_PASSWORD}"
			psql --username "${POSTGRES_USER}" --dbname postgres \\
			  --set=app_username="${APP_USERNAME}" \\
			  --set=app_password="${APP_PASSWORD}" \\
			  --set=app_database="${APP_DATABASE}" <<'SQL'
			SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'app_username', :'app_password')
			WHERE :'app_username' <> ''
			  AND :'app_password' <> ''
			  AND NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'app_username') \\gexec

			SELECT format('CREATE DATABASE %I OWNER %I', :'app_database', :'app_username')
			WHERE :'app_database' <> ''
			  AND :'app_username' <> ''
			  AND NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'app_database') \\gexec
			SQL

			if [ -n "${APP_DATABASE}" ] && [ -n "${APP_USERNAME}" ]; then
			  psql --username "${POSTGRES_USER}" --dbname "${APP_DATABASE}" \\
			    -c "GRANT ALL ON SCHEMA public TO \\"${APP_USERNAME}\\";"
			fi
			"""

		for name, content in #config.postgresql.initdb.scripts {
			"\(name)": content
		}
	}
}

#PostgreSQLService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.namespace
		labels:    #config.labels
	}
	spec: {
		type: "ClusterIP"
		ports: [
			{
				name:       "tcp-postgresql"
				port:       5432
				targetPort: "postgresql"
				protocol:   "TCP"
			},
		]
		selector: {
			"app.kubernetes.io/name": "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#PostgreSQLHeadlessService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-primary-headless"
		namespace: #config.namespace
		labels:    #config.labels
	}
	spec: {
		clusterIP: "None"
		publishNotReadyAddresses: true
		ports: [
			{
				name:       "postgres"
				port:       5432
				targetPort: "postgresql"
				protocol:   "TCP"
			},
		]
		selector: {
			"app.kubernetes.io/name": "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#PostgreSQLStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.namespace
		labels:    #config.labels
	}
	spec: {
		serviceName: "\(#config.metadata.name)-postgresql-primary-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name": "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name": "postgresql"
				"app.kubernetes.io/instance": #config.metadata.name
			}
			spec: {
				securityContext: {
					fsGroup:             999
					fsGroupChangePolicy: "OnRootMismatch"
				}
				containers: [
					{
						name:            "postgresql"
						image:           "\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
						imagePullPolicy: #config.postgresql.image.pullPolicy
						ports: [
							{
								name:          "postgresql"
								containerPort: 5432
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
								value: "postgres"
							},
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.postgresqlSecretName
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
									name: #config.postgresqlSecretName
									key:  [if #config.postgresql.auth.existingSecretUserPasswordKey != "" { #config.postgresql.auth.existingSecretUserPasswordKey }, "user-password"][0]
								}
							},
						]
						resources: #config.postgresql.standalone.resources
						securityContext: {
							runAsUser:                999
							runAsGroup:               999
							runAsNonRoot:             true
							allowPrivilegeEscalation: false
							readOnlyRootFilesystem:   false
							capabilities: drop: ["ALL"]
						}
						livenessProbe: {
							exec: command: ["pg_isready", "-U", "postgres"]
							initialDelaySeconds: 30
							periodSeconds:        10
							timeoutSeconds:       5
							failureThreshold:     6
						}
						readinessProbe: {
							exec: command: ["pg_isready", "-U", "postgres"]
							initialDelaySeconds: 15
							periodSeconds:        10
							timeoutSeconds:       5
							failureThreshold:     6
						}
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/var/lib/postgresql/data"
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
				corev1.#PersistentVolumeClaim & {
					metadata: name: "data"
					spec: {
						accessModes: ["ReadWriteOnce"]
						resources: requests: storage: #config.postgresql.standalone.persistence.size
					}
				},
			]
		}
	}
}
