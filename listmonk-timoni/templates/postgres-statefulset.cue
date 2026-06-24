package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgresStatefulSet: {
	#config: #Config
	#helpers: #Helpers

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      #helpers.postgresStatefulSetName
		namespace: #config.metadata.namespace
		labels:    #helpers.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "listmonk-postgres"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":     #helpers.postgresStatefulSetName
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     #helpers.postgresStatefulSetName
				"app.kubernetes.io/instance": #config.metadata.name
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: false
				serviceAccountName: #helpers.serviceAccountName
				if len(#config.postgres.podSecurityContext) > 0 {
					securityContext: #config.postgres.podSecurityContext
				}
				if #config.postgres.volumePermissions.enabled {
					initContainers: [{
						name:            "volume-permissions"
						image:           #config.postgres.image.repository + ":" + #config.postgres.image.tag
						imagePullPolicy: "IfNotPresent"
						command: ["chown", "-R", "10001:10001", "/var/lib/postgresql/data"]
						if len(#config.postgres.volumePermissions.resources) > 0 {
							resources: #config.postgres.volumePermissions.resources
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
					name:            "postgres"
					image:           "\(#config.postgres.image.repository):\(#config.postgres.image.tag)"
					imagePullPolicy: "IfNotPresent"
					if len(#config.postgres.securityContext) > 0 {
						securityContext: #config.postgres.securityContext
					}
					ports: [{
						name:          "postgres"
						containerPort: 5432
					}]
					env: [{
						name:  "POSTGRES_USER"
						value: #config.database.user
					}, {
						name:  "POSTGRES_DB"
						value: #config.database.name
					}, {
						name:  "PGDATA"
						value: "/var/lib/postgresql/data/pgdata"
					}, {
						name: "POSTGRES_PASSWORD"
						valueFrom: secretKeyRef: {
							name: #helpers.dbSecretName
							key:  #config.database.passwordKey
						}
					}]
					readinessProbe: exec: command: ["pg_isready", "-h", "localhost", "-U", #config.database.user]
					resources: #config.postgres.resources
					volumeMounts: [
						{
							name:      "data"
							mountPath: "/var/lib/postgresql/data"
						},
						if #config.postgres.securityContext.readOnlyRootFilesystem != _|_ && #config.postgres.securityContext.readOnlyRootFilesystem == true {
							{
								name:      "postgres-run"
								mountPath: "/var/run/postgresql"
							}
						},
						if #config.postgres.securityContext.readOnlyRootFilesystem != _|_ && #config.postgres.securityContext.readOnlyRootFilesystem == true {
							{
								name:      "tmp"
								mountPath: "/tmp"
							}
						},
					]
				}]
				volumes: [
					if #config.postgres.securityContext.readOnlyRootFilesystem != _|_ && #config.postgres.securityContext.readOnlyRootFilesystem == true {
						{
							name: "postgres-run"
							emptyDir: {}
						}
					},
					if #config.postgres.securityContext.readOnlyRootFilesystem != _|_ && #config.postgres.securityContext.readOnlyRootFilesystem == true {
						{
							name: "tmp"
							emptyDir: {}
						}
					},
				]
			}
		}
		volumeClaimTemplates: [{
			metadata: {
				name: "data"
				labels: {
					"app.kubernetes.io/name":     #helpers.postgresStatefulSetName
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: corev1.#PersistentVolumeClaimSpec & {
				accessModes: ["ReadWriteOnce"]
				if #config.postgres.storage.storageClass != "" {
					storageClassName: #config.postgres.storage.storageClass
				}
				resources: requests: storage: #config.postgres.storage.size
			}
		}]
	}
}
