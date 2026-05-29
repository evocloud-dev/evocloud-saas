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
				serviceAccountName: #helpers.serviceAccountName
				containers: [{
					name:            "postgres"
					image:           "\(#config.postgres.image.repository):\(#config.postgres.image.tag)"
					imagePullPolicy: "IfNotPresent"
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
					volumeMounts: [{
						name:      "data"
						mountPath: "/var/lib/postgresql/data"
					}]
				}]
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
