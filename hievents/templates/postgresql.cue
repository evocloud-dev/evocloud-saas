package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgresqlHeadlessService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config._postgresName + "-headless"
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
	spec: {
		clusterIP: "None"
		ports: [{
			name:       "postgresql"
			port:       #config.postgresql.service.port
			targetPort: "postgresql"
		}]
		selector: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "postgresql"
		}
	}
}

#PostgresqlService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config._postgresName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "postgresql"
			port:       #config.postgresql.service.port
			targetPort: "postgresql"
		}]
		selector: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "postgresql"
		}
	}
}

#PostgresqlStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      #config._postgresName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
	spec: {
		serviceName: #config._postgresName + "-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "postgresql"
		}
		template: {
			metadata: labels: #config._baseLabels & {
				"app.kubernetes.io/component": "postgresql"
			}
			spec: {
				serviceAccountName: #config._saName
				if len(#config.postgresql.podSecurityContext) > 0 {
					securityContext: #config.postgresql.podSecurityContext
				}
				if #config.postgresql.persistence.enabled && #config.postgresql.volumePermissions.enabled {
					initContainers: [{
						name:            "volume-permissions"
						image:           #config.postgresql.image.repository + ":" + #config.postgresql.image.tag
						imagePullPolicy: #config.postgresql.image.pullPolicy
						command: ["chown", "-R", "10001:10001", "/var/lib/postgresql/data"]
						if len(#config.postgresql.volumePermissions.resources) > 0 {
							resources: #config.postgresql.volumePermissions.resources
						}
						securityContext: {
							runAsUser:                0
							runAsGroup:               0
							runAsNonRoot:             false
							allowPrivilegeEscalation: false
							readOnlyRootFilesystem:   true
							capabilities: {
								drop: ["ALL"]
								add: ["CHOWN", "DAC_OVERRIDE", "FOWNER"]
							}
						}
						volumeMounts: [{
							name:      "data"
							mountPath: "/var/lib/postgresql/data"
						}]
					}]
				}
				containers: [{
					name:            "postgresql"
					image:           #config.postgresql.image.repository + ":" + #config.postgresql.image.tag
					imagePullPolicy: #config.postgresql.image.pullPolicy
					if len(#config.postgresql.securityContext) > 0 {
						securityContext: #config.postgresql.securityContext
					}
					ports: [{
						name:          "postgresql"
						containerPort: 5432
					}]
					env: [{
						name:  "POSTGRES_DB"
						value: #config.hieventsConfig.postgresql.database
					}, {
						name:  "POSTGRES_USER"
						value: #config.hieventsConfig.postgresql.username
					}, {
						name: "POSTGRES_PASSWORD"
						valueFrom: secretKeyRef: {
							name: #config._postgresSecretName
							key:  #config.secrets.postgresql.passwordKey
						}
					}, {
						name:  "PGDATA"
						value: "/var/lib/postgresql/data/pgdata"
					}]
					livenessProbe: {
						exec: command: [
							"sh",
							"-c",
							"pg_isready -h localhost -U \"$POSTGRES_USER\" -d \"$POSTGRES_DB\"",
						]
						initialDelaySeconds: 30
						periodSeconds:       10
					}
					readinessProbe: {
						exec: command: [
							"sh",
							"-c",
							"pg_isready -h localhost -U \"$POSTGRES_USER\" -d \"$POSTGRES_DB\"",
						]
						initialDelaySeconds: 5
						periodSeconds:       10
					}
					if len(#config.postgresql.resources) > 0 {
						resources: #config.postgresql.resources
					}
					volumeMounts: [
						if #config.postgresql.persistence.enabled {
							{
								name:      "data"
								mountPath: "/var/lib/postgresql/data"
							}
						},
						if #config.postgresql.securityContext.readOnlyRootFilesystem != _|_ && #config.postgresql.securityContext.readOnlyRootFilesystem == true {
							{
								name:      "postgres-run"
								mountPath: "/var/run/postgresql"
							}
						},
						if #config.postgresql.securityContext.readOnlyRootFilesystem != _|_ && #config.postgresql.securityContext.readOnlyRootFilesystem == true {
							{
								name:      "tmp"
								mountPath: "/tmp"
							}
						},
					]
				}]
				volumes: [
					if #config.postgresql.securityContext.readOnlyRootFilesystem != _|_ && #config.postgresql.securityContext.readOnlyRootFilesystem == true {
						{
							name: "postgres-run"
							emptyDir: {}
						}
					},
					if #config.postgresql.securityContext.readOnlyRootFilesystem != _|_ && #config.postgresql.securityContext.readOnlyRootFilesystem == true {
						{
							name: "tmp"
							emptyDir: {}
						}
					},
				]
			}
		}
		if #config.postgresql.persistence.enabled {
			volumeClaimTemplates: [{
				metadata: name: "data"
				spec: {
					accessModes: ["ReadWriteOnce"]
					if #config.postgresql.persistence.storageClass != "" {
						storageClassName: #config.postgresql.persistence.storageClass
					}
					resources: requests: storage: #config.postgresql.persistence.size
				}
			}]
		}
	}
}
