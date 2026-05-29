package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#PostgresqlSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-postgresql"
		namespace: #config.metadata.namespace
		labels: {
			chart:                         #config.metadata.labels.chart
			release:                       #config.metadata.labels.release
			heritage:                      #config.metadata.labels.heritage
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.fullname
			"app.kubernetes.io/component": "primary"
		}
	}
	stringData: {
		"postgres-password": #config.postgresql.auth.password
		"password":          #config.postgresql.auth.password
	}
}

#PostgresqlService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-postgresql"
		namespace: #config.metadata.namespace
		labels: {
			chart:                         #config.metadata.labels.chart
			release:                       #config.metadata.labels.release
			heritage:                      #config.metadata.labels.heritage
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.fullname
			"app.kubernetes.io/component": "primary"
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "tcp-postgresql"
			port:       5432
			targetPort: "postgresql"
		}]
		selector: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.fullname
		}
	}
}

#PostgresqlHeadlessService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-postgresql-hl"
		namespace: #config.metadata.namespace
		labels: {
			chart:                         #config.metadata.labels.chart
			release:                       #config.metadata.labels.release
			heritage:                      #config.metadata.labels.heritage
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.fullname
			"app.kubernetes.io/component": "primary"
		}
	}
	spec: {
		type:      "ClusterIP"
		clusterIP: "None"
		ports: [{
			name:       "tcp-postgresql"
			port:       5432
			targetPort: "postgresql"
		}]
		selector: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.fullname
		}
	}
}

#PostgresqlStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.fullname)-postgresql"
		namespace: #config.metadata.namespace
		labels: {
			chart:                         #config.metadata.labels.chart
			release:                       #config.metadata.labels.release
			heritage:                      #config.metadata.labels.heritage
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.fullname
			"app.kubernetes.io/component": "primary"
		}
	}
	spec: {
		serviceName: "\(#config.fullname)-postgresql-hl"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.fullname
			"app.kubernetes.io/component": "primary"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":      "postgresql"
				"app.kubernetes.io/instance":  #config.fullname
				"app.kubernetes.io/component": "primary"
			}
			spec: {
				containers: [{
					name:  "postgresql"
					image: "\(#config.postgresql.image.registry)/\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
					env: [{
						name:  "BITNAMI_DEBUG"
						value: "false"
					}, {
						name:  "POSTGRES_USER"
						value: #config.postgresql.auth.username
					}, {
						name:  "POSTGRES_PASSWORD_FILE"
						value: "/opt/bitnami/postgresql/secrets/password"
					}, {
						name:  "POSTGRES_POSTGRES_PASSWORD_FILE"
						value: "/opt/bitnami/postgresql/secrets/postgres-password"
					}, {
						name:  "POSTGRES_DATABASE"
						value: #config.postgresql.auth.database
					}, {
						name:  "PGDATA"
						value: "/bitnami/postgresql/data"
					}]
					ports: [{
						name:          "postgresql"
						containerPort: 5432
					}]
					livenessProbe: {
						exec: command: ["/bin/sh", "-c", "exec pg_isready -U \"\(#config.postgresql.auth.username)\" -d \"dbname=\(#config.postgresql.auth.database)\" -h 127.0.0.1 -p 5432"]
						initialDelaySeconds: 30
						periodSeconds:       10
						timeoutSeconds:      5
						successThreshold:    1
						failureThreshold:    6
					}
					readinessProbe: {
						exec: command: ["/bin/sh", "-c", "-e", "exec pg_isready -U \"\(#config.postgresql.auth.username)\" -d \"dbname=\(#config.postgresql.auth.database)\" -h 127.0.0.1 -p 5432\n[ -f /opt/bitnami/postgresql/tmp/.initialized ] || [ -f /bitnami/postgresql/.initialized ]\n"]
						initialDelaySeconds: 5
						periodSeconds:       10
						timeoutSeconds:      5
						successThreshold:    1
						failureThreshold:    6
					}
					volumeMounts: [
						{
							name:      "postgresql-password"
							mountPath: "/opt/bitnami/postgresql/secrets/"
							readOnly:  true
						},
						if #config.postgresql.primary.persistence.enabled {
							{
								name:      "data"
								mountPath: "/bitnami/postgresql"
							}
						},
					]
				}]
				volumes: [{
					name: "postgresql-password"
					secret: {
						secretName: "\(#config.fullname)-postgresql"
					}
				}]
			}
		}
		if #config.postgresql.primary.persistence.enabled {
			volumeClaimTemplates: [{
				metadata: name: "data"
				spec: {
					accessModes: #config.postgresql.primary.persistence.accessModes
					resources: requests: storage: "8Gi"
				}
			}]
		}
	}
}
