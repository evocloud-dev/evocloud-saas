package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#KcPostgresqlService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "kc-postgres"
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
			"app.kubernetes.io/name":     "kc-postgresql"
		}
		type: "ClusterIP"
	}
}

#KcPostgresqlStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "kc-postgresql"
		namespace: #config.metadata.namespace
	}
	spec: appsv1.#StatefulSetSpec & {
		selector: matchLabels: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "kc-postgresql"
		}
		serviceName: "kc-postgres"
		replicas:    1
		template: {
			metadata: labels: {
				"app.kubernetes.io/instance": "extra"
				"app.kubernetes.io/name":     "kc-postgresql"
			}
			spec: corev1.#PodSpec & {
				terminationGracePeriodSeconds: 10
				automountServiceAccountToken:  #config.kc_postgresql.automountServiceAccountToken
				serviceAccountName:            #config.kc_postgresql.serviceAccountName
				if #config.kc_postgresql.podSecurityContext != null {
					securityContext: #config.kc_postgresql.podSecurityContext
				}
				containers: [{
					name:  "pg"
					image: #config.kc_postgresql.image.reference
					if #config.kc_postgresql.securityContext != null {
						securityContext: #config.kc_postgresql.securityContext
					}
					if #config.kc_postgresql.resources != null {
						resources: #config.kc_postgresql.resources
					}
					ports: [{
						containerPort: 5432
						name:          "tcp-postgresql"
					}]
					env: [{
						name:  "POSTGRES_PASSWORD"
						value: #config.keycloak.db.password
					}, {
						name:  "POSTGRES_USER"
						value: #config.keycloak.db.username
					}, {
						name:  "POSTGRES_DB"
						value: #config.keycloak.db.database
					}, {
						name:  "PGDATA"
						value: "/var/lib/postgresql/data/pgdata"
					}]
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
