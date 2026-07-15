package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#PostgresqlService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "postgres"
		namespace: #config.metadata.namespace
	}
	spec: corev1.#ServiceSpec & {
		ports: [{
			name:       "tcp-postgresql"
			port:       5432
			targetPort: 5432
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "postgresql"
		}
		type: "ClusterIP"
	}
}

#PostgresqlStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "postgresql"
		namespace: #config.metadata.namespace
	}
	spec: appsv1.#StatefulSetSpec & {
		selector: matchLabels: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "postgresql"
		}
		serviceName: "postgres"
		replicas:    1
		template: {
			metadata: labels: {
				"app.kubernetes.io/instance": "extra"
				"app.kubernetes.io/name":     "postgresql"
			}
			spec: corev1.#PodSpec & {
				terminationGracePeriodSeconds: 10
				automountServiceAccountToken:  #config.postgresql.automountServiceAccountToken
				serviceAccountName:            #config.postgresql.serviceAccountName
				if #config.postgresql.podSecurityContext != null {
					securityContext: #config.postgresql.podSecurityContext
				}
				containers: [{
					name:  "pg"
					image: #config.postgresql.image.reference
					if #config.postgresql.securityContext != null {
						securityContext: #config.postgresql.securityContext
					}
					if #config.postgresql.resources != null {
						resources: #config.postgresql.resources
					}
					ports: [{
						containerPort: 5432
						name:          "tcp-postgresql"
					}]
					env: [{
						name:  "POSTGRES_PASSWORD"
						value: #config.postgresql.password
					}, {
						name:  "POSTGRES_USER"
						value: #config.postgresql.username
					}, {
						name:  "POSTGRES_DB"
						value: #config.postgresql.database
					}, {
						name:  "PGDATA"
						value: "/var/lib/postgresql/data/pgdata"
					}]
					readinessProbe: {
						exec: command: ["pg_isready", "-U", #config.postgresql.username, "-d", #config.postgresql.database, "-h", "127.0.0.1"]
						initialDelaySeconds: 5
						periodSeconds:        5
					}
					livenessProbe: {
						exec: command: ["pg_isready", "-U", #config.postgresql.username, "-d", #config.postgresql.database, "-h", "127.0.0.1"]
						initialDelaySeconds: 15
						periodSeconds:        10
					}
					volumeMounts: [{
						name:      "data"
						mountPath: "/var/lib/postgresql"
					}, {
						name:      "postgres-run"
						mountPath: "/var/run/postgresql"
					}, {
						name:      "tmp-dir"
						mountPath: "/tmp"
					}]
				}]
				volumes: [{
					name: "postgres-run"
					emptyDir: {}
				}, {
					name: "tmp-dir"
					emptyDir: {}
				}]
			}
		}
		volumeClaimTemplates: [{
			metadata: name: "data"
			spec: {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: "1Gi"
			}
		}]
	}
}
