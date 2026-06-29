package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#PostgresqlStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
	spec: {
		serviceName: "\(#config.metadata.name)-postgresql-hl"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "postgresql"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/component": "postgresql"
			}
			spec: {
				automountServiceAccountToken: false
				serviceAccountName:           #config._serviceAccountName
				securityContext: {
					fsGroup:             1001
					runAsUser:           1001
					runAsGroup:          1001
					runAsNonRoot:        true
				}
				containers: [{
					name:            "postgresql"
					image:           "docker.io/bitnamilegacy/postgresql:17.5.0-debian-12-r20"
					imagePullPolicy: "Always"
					securityContext: {
						allowPrivilegeEscalation: false
						runAsUser:                1001
						runAsGroup:               1001
						runAsNonRoot:            true
						readOnlyRootFilesystem:  true
						capabilities: drop: ["ALL"]
					}
					env: [{
						name:  "POSTGRESQL_PORT_NUMBER"
						value: "5432"
					}, {
						name:  "POSTGRESQL_VOLUME_DIR"
						value: "/bitnami/postgresql"
					}, {
						name:  "PGDATA"
						value: "/bitnami/postgresql/data"
					}, {
						name:  "POSTGRES_USER"
						value: "zammad"
					}, {
						name:  "POSTGRES_PASSWORD_FILE"
						value: "/opt/bitnami/postgresql/secrets/password"
					}, {
						name:  "POSTGRES_POSTGRES_PASSWORD_FILE"
						value: "/opt/bitnami/postgresql/secrets/postgres-password"
					}, {
						name:  "POSTGRES_DATABASE"
						value: "zammad_production"
					}]
					ports: [{
						name:          "postgresql"
						containerPort: 5432
					}]
					if #config.postgresql.primary.resources != _|_ {
						resources: #config.postgresql.primary.resources
					}
					livenessProbe: {
						exec: command: ["/bin/sh", "-c", "exec pg_isready -U zammad -d dbname=zammad_production -h 127.0.0.1 -p 5432"]
						initialDelaySeconds: 30
						periodSeconds:       10
						timeoutSeconds:      10
					}
					readinessProbe: {
						exec: command: ["/bin/sh", "-c", "exec pg_isready -U zammad -d dbname=zammad_production -h 127.0.0.1 -p 5432"]
						initialDelaySeconds: 5
						periodSeconds:       10
						timeoutSeconds:      10
					}
					volumeMounts: [{
						name:      "empty-dir"
						mountPath: "/tmp"
						subPath:   "tmp-dir"
					}, {
						name:      "empty-dir"
						mountPath: "/opt/bitnami/postgresql/conf"
						subPath:   "app-conf-dir"
					}, {
						name:      "empty-dir"
						mountPath: "/opt/bitnami/postgresql/tmp"
						subPath:   "app-tmp-dir"
					}, {
						name:      "postgresql-password"
						mountPath: "/opt/bitnami/postgresql/secrets/"
					}, {
						name:      "dshm"
						mountPath: "/dev/shm"
					}, {
						name:      "data"
						mountPath: "/bitnami/postgresql"
					}]
				}]
				volumes: [{
					name: "empty-dir"
					emptyDir: {}
				}, {
					name: "postgresql-password"
					secret: secretName: #config._postgresqlSecretName
				}, {
					name: "dshm"
					emptyDir: medium: "Memory"
				}]
			}
		}
		volumeClaimTemplates: [{
			apiVersion: "v1"
			kind:       "PersistentVolumeClaim"
			metadata: name: "data"
			spec: {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: "8Gi"
			}
		}]
	}
}

#PostgresqlService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "postgresql"
			port:       5432
			targetPort: "postgresql"
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "postgresql"
		}
	}
}

#PostgresqlHeadlessService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-hl"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
	spec: {
		clusterIP: "None"
		ports: [{
			name:       "postgresql"
			port:       5432
			targetPort: "postgresql"
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "postgresql"
		}
	}
}
