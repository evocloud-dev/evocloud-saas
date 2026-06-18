package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQLStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "postgresql"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "postgresql"
		replicas:    1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "postgresql"
				}
				annotations: #config.podAnnotations
			}
			spec: corev1.#PodSpec & {
				securityContext: {
					runAsUser:            #config.securityContext.runAsUser
					runAsGroup:           #config.securityContext.runAsGroup
					runAsNonRoot:         #config.securityContext.runAsNonRoot
					fsGroup:              #config.securityContext.runAsGroup
				}
				containers: [
					{
						name:            "postgresql"
						image:           "\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
						imagePullPolicy: #config.postgresql.image.pullPolicy
						securityContext: {
							readOnlyRootFilesystem: #config.securityContext.readOnlyRootFilesystem
							runAsUser:              #config.securityContext.runAsUser
							runAsGroup:             #config.securityContext.runAsGroup
							runAsNonRoot:           #config.securityContext.runAsNonRoot
							if len(#config.securityContext.capabilities.drop) > 0 {
								capabilities: drop: #config.securityContext.capabilities.drop
							}
						}
						ports: [
							{
								name:          "postgresql"
								containerPort: #config.postgresql.service.port
								protocol:      "TCP"
							},
						]
						env: [
							{
								name: "POSTGRES_USER"
								valueFrom: secretKeyRef: {
									name: "postgresql-credentials"
									key:  "username"
								}
							},
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "postgresql-credentials"
									key:  "password"
								}
							},
							{
								name: "POSTGRES_DB"
								valueFrom: secretKeyRef: {
									name: "postgresql-credentials"
									key:  "database"
								}
							},
							{
								name:  "PGDATA"
								value: "/var/lib/postgresql/data/pgdata"
							},
							{
								name:  "POSTGRES_INITDB_ARGS"
								value: "--auth-local=trust"
							},
						]
						volumeMounts: [
							{
								name:      "postgresql-data"
								mountPath: "/var/lib/postgresql"
							},
							{
								name:      "postgres-run"
								mountPath: "/var/run/postgresql"
							},
							{
								name:      "tmp-dir"
								mountPath: "/tmp"
							},
						]
						livenessProbe: {
							exec: command: [
								"sh",
								"-c",
								"pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}",
							]
							initialDelaySeconds: 30
							periodSeconds:       10
							timeoutSeconds:      5
							failureThreshold:    3
						}
						readinessProbe: {
							exec: command: [
								"sh",
								"-c",
								"pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}",
							]
							initialDelaySeconds: 5
							periodSeconds:       10
							timeoutSeconds:      5
							failureThreshold:    3
						}
						resources: {
							requests: {
								cpu:    #config.postgresql.resources.requests.cpu
								memory: #config.postgresql.resources.requests.memory
							}
							limits: {
								cpu:    #config.postgresql.resources.limits.cpu
								memory: #config.postgresql.resources.limits.memory
							}
						}
					},
				]
				volumes: [
					{
						name: "postgresql-data"
						persistentVolumeClaim: claimName: "postgresql-data"
					},
					{
						name: "postgres-run"
						emptyDir: {}
					},
					{
						name: "tmp-dir"
						emptyDir: {}
					},
				]
			}
		}
	}
}

#PostgreSQLService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "postgresql"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [
			{
				name:       "postgresql"
				port:       #config.postgresql.service.port
				targetPort: "postgresql"
				protocol:   "TCP"
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
}

#PostgreSQLSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "postgresql-credentials"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		username:           #config.postgresql.auth.username
		password:           #config.postgresql.auth.password
		database:           #config.postgresql.auth.database
		postgresPassword:   #config.postgresql.auth.postgresPassword
	}
}
