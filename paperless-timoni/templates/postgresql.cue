package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQLPasswordKey: {
	#config: #Config
	value: "postgres-password"
	if #config.postgresql.auth.password != _|_ {
		value: "password"
	}
}

#PostgreSQLSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	type:       "Opaque"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	stringData: {
		if #config.postgresql.auth.password != _|_ {
			password: #config.postgresql.auth.password
		}
		if #config.postgresql.auth.password == _|_ {
			"postgres-password": #config.postgresql.auth.postgresPassword
		}
	}
}

#PostgreSQLService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: corev1.#ServiceTypeClusterIP
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
		ports: [{
			name:       "postgresql"
			port:       5432
			targetPort: name
			protocol:   "TCP"
		}]
	}
}

#PostgreSQLHeadlessService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type:      corev1.#ServiceTypeClusterIP
		clusterIP: "None"
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
		ports: [{
			name:       "postgresql"
			port:       5432
			targetPort: name
			protocol:   "TCP"
		}]
	}
}

#PostgreSQLPersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
		if #config.postgresql.primary.persistence.retain {
			annotations: "helm.sh/resource-policy": "keep"
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.postgresql.primary.persistence.accessMode]
		if #config.postgresql.primary.persistence.storageClass != _|_ {
			storageClassName: #config.postgresql.primary.persistence.storageClass
		}
		resources: requests: storage: #config.postgresql.primary.persistence.size
	}
}

#PostgreSQLDeployment: appsv1.#Deployment & {
	#config:    #Config
	#secretName: "\(#config.metadata.name)-postgresql"
	if #config.postgresql.auth.existingSecret != _|_ {
		#secretName: #config.postgresql.auth.existingSecret
	}
	#passwordKey: (#PostgreSQLPasswordKey & {#config: #config}).value
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		revisionHistoryLimit: 3
		replicas:             1
		strategy: type:        "Recreate"
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
		template: {
			metadata: labels: #config.selector.labels & {
				"app.kubernetes.io/component": "postgresql"
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: true
				dnsPolicy:                    "ClusterFirst"
				enableServiceLinks:           true
				containers: [{
					name:            "postgresql"
					image:           "\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
					imagePullPolicy: #config.postgresql.image.pullPolicy
					env: [
						{
							name:  "POSTGRES_DB"
							value: #config.postgresql.auth.database
						},
						{
							name:  "POSTGRES_USER"
							value: #config.postgresql.auth.username
						},
						{
							name: "POSTGRES_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #secretName
								key:  #passwordKey
							}
						},
						{
							name:  "PGDATA"
							value: "/var/lib/postgresql/data/pgdata"
						},
					]
					ports: [{
						name:          "postgresql"
						containerPort: 5432
						protocol:      "TCP"
					}]
					resources: {
						requests: {
							cpu:    #config.postgresql.primary.resources.requests.cpu
							memory: #config.postgresql.primary.resources.requests.memory
						}
						limits: {
							cpu:    #config.postgresql.primary.resources.limits.cpu
							memory: #config.postgresql.primary.resources.limits.memory
						}
					}
					if #config.postgresql.primary.persistence.enabled {
						volumeMounts: [{
							name:      "data"
							mountPath: "/var/lib/postgresql/data"
						}]
					}
				}]
				if #config.postgresql.primary.persistence.enabled {
					volumes: [{
						name: "data"
						persistentVolumeClaim: claimName: "\(#config.metadata.name)-postgresql"
					}]
				}
			}
		}
	}
}