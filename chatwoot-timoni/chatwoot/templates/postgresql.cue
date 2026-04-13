package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#Postgresql: {
	#config: #Config
	if #config.postgresql.enabled {
		apiVersion: "apps/v1"
		kind:       "StatefulSet"
		metadata: {
			name:      #config.postgresql.nameOverride
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
			if #config.metadata.annotations != _|_ {
				annotations: #config.metadata.annotations
			}
		}
		spec: appsv1.#StatefulSetSpec & {
			serviceName: #config.postgresql.nameOverride
			replicas:    1
			selector: matchLabels: {
				app: #config.postgresql.nameOverride
			}
			template: {
				metadata: labels: {
					app: #config.postgresql.nameOverride
				}
				spec: corev1.#PodSpec & {
					containers: [{
						name:  "postgresql"
						image: "\(#config.postgresql.image.registry)/\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
						env: [
							{
								name:  "POSTGRES_USER"
								value: #config.postgresql.auth.username
							},
							{
								name:  "POSTGRES_PASSWORD"
								value: #config.postgresql.auth.postgresPassword
							},
							{
								name:  "POSTGRES_DB"
								value: #config.postgresql.auth.database
							},
						]
						ports: [{
							containerPort: 5432
							name:          "postgresql"
						}]
						volumeMounts: [{
							name:      "data"
							mountPath: "/bitnami/postgresql"
						}]
					}]
				}
			}
			volumeClaimTemplates: [{
				metadata: name: "data"
				spec: {
					accessModes: ["ReadWriteOnce"]
					resources: requests: storage: "8Gi"
				}
			}]
		}
	}
}

#PostgresqlService: {
	#config: #Config
	if #config.postgresql.enabled {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      #config.postgresql.nameOverride
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
			if #config.metadata.annotations != _|_ {
				annotations: #config.metadata.annotations
			}
		}
		spec: corev1.#ServiceSpec & {
			ports: [{
				port:       5432
				targetPort: 5432
				name:       "postgresql"
			}]
			selector: {
				app: #config.postgresql.nameOverride
			}
		}
	}
}
