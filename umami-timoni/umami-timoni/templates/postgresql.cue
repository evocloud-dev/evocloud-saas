package templates

import (
	"list"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQL: {
	#config: #Config

	objects: {
		svc: corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      #config.metadata.name + "-postgresql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: corev1.#ServiceSpec & {
				type: "ClusterIP"
				ports: [{
					name:       "tcp-postgresql"
					port:       5432
					targetPort: "postgresql"
				}]
				selector: "app.kubernetes.io/name": #config.metadata.name + "-postgresql"
			}
		}

		"svc-hl": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      #config.metadata.name + "-postgresql-hl"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: corev1.#ServiceSpec & {
				type:      "ClusterIP"
				clusterIP: "None"
				ports: [{
					name:       "tcp-postgresql"
					port:       5432
					targetPort: "postgresql"
				}]
				selector: "app.kubernetes.io/name": #config.metadata.name + "-postgresql"
			}
		}

		sts: appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      #config.metadata.name + "-postgresql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: appsv1.#StatefulSetSpec & {
				serviceName: #config.metadata.name + "-postgresql-hl"
				replicas:    1
				selector: matchLabels: "app.kubernetes.io/name": #config.metadata.name + "-postgresql"
				template: {
					metadata: labels: "app.kubernetes.io/name": #config.metadata.name + "-postgresql"
					spec: corev1.#PodSpec & {
						automountServiceAccountToken: #config.postgresql.automountServiceAccountToken
						serviceAccountName: *#config.postgresql.serviceAccountName | string
						if #config.postgresql.serviceAccountName == "" {
							if #config.serviceAccount.name == "" {
								serviceAccountName: #config.metadata.name
							}
							if #config.serviceAccount.name != "" {
								serviceAccountName: #config.serviceAccount.name
							}
						}
						if #config.postgresql.podSecurityContext != _|_ {
							securityContext: #config.postgresql.podSecurityContext
						}
						containers: [{
							name:  "postgresql"
							image: #config.#pgImageRef
							ports: [{
								name:          "postgresql"
								containerPort: 5432
							}]
							imagePullPolicy: #config.postgresql.image.pullPolicy
							if #config.postgresql.resources != _|_ {
								resources: #config.postgresql.resources
							}
							if #config.postgresql.securityContext != _|_ {
								securityContext: #config.postgresql.securityContext
							}
							env: [
								{
									name:  "POSTGRESQL_USERNAME"
									value: #config.postgresql.auth.username
								},
								{
									name:  "POSTGRESQL_PASSWORD"
									value: #config.postgresql.auth.password
								},
								{
									name:  "POSTGRESQL_DATABASE"
									value: #config.postgresql.auth.database
								},
							]
							livenessProbe:  #config.postgresql.livenessProbe
							readinessProbe: #config.postgresql.readinessProbe
							volumeMounts: [
								{
									name:      "data"
									mountPath: "/bitnami/postgresql"
								},
								{
									name:      "pg-conf"
									mountPath: "/opt/bitnami/postgresql/conf"
								},
								{
									name:      "pg-tmp"
									mountPath: "/opt/bitnami/postgresql/tmp"
								},
								{
									name:      "tmp"
									mountPath: "/tmp"
								}
							]
						}]
						volumes: list.Concat([
							[
								if !#config.postgresql.persistence.enabled {
									{
										name: "data"
										emptyDir: {}
									}
								}
							],
							[
								{
									name: "pg-conf"
									emptyDir: {}
								},
								{
									name: "pg-tmp"
									emptyDir: {}
								},
								{
									name: "tmp"
									emptyDir: {}
								}
							]
						])
					}
				}
				if #config.postgresql.persistence.enabled {
					volumeClaimTemplates: [
						{
							metadata: name: "data"
							spec: corev1.#PersistentVolumeClaimSpec & {
								accessModes: ["ReadWriteOnce"]
								resources: requests: storage: #config.postgresql.persistence.size
							}
						},
					]
				}
			}
		}
	}
}
