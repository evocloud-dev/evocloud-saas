package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQLDeployment: {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		strategy: {
			type: #config.postgresql.primary.strategy
			if type == "RollingUpdate" {
				rollingUpdate: {
					maxUnavailable: 1
					maxSurge:       0
				}
			}
		}
		selector: matchLabels: #config.selector.labels & {
			app: "postgresql"
		}
		template: {
			metadata: labels: #config.selector.labels & {
				app: "postgresql"
			}
			spec: corev1.#PodSpec & {
				if #config.postgresql.podSecurityContext != _|_ {
					securityContext: #config.postgresql.podSecurityContext
				}
				serviceAccountName:            #config.metadata.name
				automountServiceAccountToken: false
				initContainers: [
					{
						name:  "prepare-rw-conf"
						image: "\(#config.postgresql.image.registry)/\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
						command: ["sh", "-c", "cp -rT /opt/bitnami/postgresql/conf /opt/bitnami/postgresql/conf-rw"]
						securityContext: {
							runAsUser:                1001
							runAsGroup:               1001
							runAsNonRoot:             true
							allowPrivilegeEscalation: false
							readOnlyRootFilesystem:   true
							capabilities: drop: ["ALL"]
						}
						volumeMounts: [
							{
								name:      "postgresql-conf"
								mountPath: "/opt/bitnami/postgresql/conf-rw"
							},
						]
					},
				]
				containers: [
					{
						name:  "postgresql"
						image: "\(#config.postgresql.image.registry)/\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
						env: [
							{
								name:  "POSTGRESQL_DATABASE"
								value: #config.postgresql.auth.database
							},
							{
								name:  "POSTGRESQL_USERNAME"
								value: #config.postgresql.auth.username
							},
							{
								name: "POSTGRESQL_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-postgresql"
									key:  "password"
								}
							},
							{
								name: "POSTGRESQL_POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-postgresql"
									key:  "postgres-password"
								}
							},
						]
						ports: [
							{
								containerPort: 5432
								name:          "postgresql"
							},
						]
						livenessProbe: {
							exec: command: ["pg_isready", "-U", "\(#config.postgresql.auth.username)", "-d", "\(#config.postgresql.auth.database)"]
							initialDelaySeconds: 30
							periodSeconds:       10
						}
						readinessProbe: {
							exec: command: ["pg_isready", "-U", "\(#config.postgresql.auth.username)", "-d", "\(#config.postgresql.auth.database)"]
							initialDelaySeconds: 5
							periodSeconds:       10
						}
						volumeMounts: [
							{
								name:      "postgresql-data"
								mountPath: "/bitnami/postgresql"
							},
							if #config.postgresql.primary.extendedConfiguration != _|_ {
								{
									name:      "postgresql-config"
									mountPath: "/bitnami/postgresql/conf/conf.d"
								}
							},
							{
								name:      "postgresql-tmp"
								mountPath: "/opt/bitnami/postgresql/tmp"
							},
							{
								name:      "postgresql-tmp"
								mountPath: "/tmp"
							},
							{
								name:      "postgresql-conf"
								mountPath: "/opt/bitnami/postgresql/conf"
							},
						]
						if #config.postgresql.primary.resources != _|_ {
							resources: #config.postgresql.primary.resources
						}
						if #config.postgresql.securityContext != _|_ {
							securityContext: #config.postgresql.securityContext
						}
					},
				]
				volumes: [
					{
						name: "postgresql-data"
						persistentVolumeClaim: claimName: "\(#config.metadata.name)-postgresql"
					},
					if #config.postgresql.primary.extendedConfiguration != _|_ {
						{
							name: "postgresql-config"
							configMap: name: "\(#config.metadata.name)-postgresql-config"
						}
					},
					{
						name: "postgresql-tmp"
						emptyDir: {}
					},
					{
						name: "postgresql-conf"
						emptyDir: {}
					},
				]
			}
		}
	}
}

#PostgreSQLService: {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		selector: #config.selector.labels & {
			app: "postgresql"
		}
		ports: [
			{
				name:       "postgresql"
				port:       5432
				targetPort: 5432
			},
		]
	}
}

#PostgreSQLConfigMap: corev1.#ConfigMap & {
	#config: #Config
	if #config.postgresql.primary.extendedConfiguration != _|_ {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "\(#config.metadata.name)-postgresql-config"
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
		}
		data: {
			"extended-configuration.conf": #config.postgresql.primary.extendedConfiguration
		}
	}
}

#PostgreSQLSecret: {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"password":          #config.postgresql.auth.password
		"postgres-password": #config.postgresql.auth.postgresPassword
	}
}
