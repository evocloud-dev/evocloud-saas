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
		name:      "postgresql-credentials"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			"helm.sh/resource-policy": "keep"
			"helm.sh/hook":            "pre-install"
		}
	}
	type: "Opaque"
	stringData: {
		"postgresql-password":  #config.postgresql.auth.postgresPassword
		"replication-password": #config.postgresql.auth.replicationPassword
	}
}

#PostgresqlService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "tcp-postgresql"
			port:       5432
			targetPort: "postgresql"
		}]
		selector: {
			"app.kubernetes.io/name": "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
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
		labels:    #config.metadata.labels
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
			"app.kubernetes.io/name": "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#PostgresqlStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		serviceName: "\(#config.metadata.name)-postgresql-hl"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name": "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "postgresql"
				"app.kubernetes.io/instance": #config.metadata.name
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.metadata.name
				automountServiceAccountToken: false
				if #config.postgresql.podSecurityContext != _|_ {
					securityContext: #config.postgresql.podSecurityContext
				}
				containers: [{
					name:  "postgresql"
					image: "\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
					imagePullPolicy: #config.postgresql.image.pullPolicy
					if #config.postgresql.securityContext != _|_ {
						securityContext: #config.postgresql.securityContext
					}
					if len(#config.postgresql.image.command) > 0 {
						command: #config.postgresql.image.command
					}
					if len(#config.postgresql.image.args) > 0 {
						args: #config.postgresql.image.args
					}
					env: [{
						name:  "POSTGRES_DB"
						value: #config.postgresql.auth.database
					}, {
						name: "POSTGRES_PASSWORD"
						valueFrom: secretKeyRef: {
							name: #config.postgresql.auth.existingSecret
							key:  #config.postgresql.auth.secretKeys.adminPasswordKey
						}
					}, {
						name:  "POSTGRES_USER"
						value: "postgres"
					}, {
						name:  "PGDATA"
						value: "/var/lib/postgresql/data/pgdata"
					}]
					ports: [{
						name:          "postgresql"
						containerPort: 5432
					}]
					resources: #config.postgresql.primary.resources
					volumeMounts: [{
						name:      "data"
						mountPath: #config.postgresql.persistence.mountPath
					}]
				}]
			}
		}
		volumeClaimTemplates: [{
			metadata: name: "data"
			spec: {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: #config.postgresql.primary.persistence.size
			}
		}]
	}
}
