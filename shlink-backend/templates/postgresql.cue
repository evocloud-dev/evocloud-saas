package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#PostgreSQL: {
	#config: #Config

	objects: [
		corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(#config.metadata.name)-postgresql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			type: corev1.#SecretTypeOpaque
			stringData: {
				"postgres-password": #config.postgresql.auth.password
				"password":          #config.postgresql.auth.password
			}
		},
		corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-postgresql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: corev1.#ServiceSpec & {
				ports: [{
					name:       "tcp-postgresql"
					port:       5432
					protocol:   "TCP"
					targetPort: "postgresql"
				}]
				selector: {
					"app.kubernetes.io/name":      "postgresql"
					"app.kubernetes.io/instance":  #config.metadata.name
				}
				type: "ClusterIP"
			}
		},
		corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-postgresql-headless"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: corev1.#ServiceSpec & {
				clusterIP: "None"
				ports: [{
					name:       "tcp-postgresql"
					port:       5432
					protocol:   "TCP"
					targetPort: "postgresql"
				}]
				selector: {
					"app.kubernetes.io/name":      "postgresql"
					"app.kubernetes.io/instance":  #config.metadata.name
				}
				type: "ClusterIP"
			}
		},
		appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "\(#config.metadata.name)-postgresql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: appsv1.#StatefulSetSpec & {
				replicas: 1
				selector: matchLabels: {
					"app.kubernetes.io/name":      "postgresql"
					"app.kubernetes.io/instance":  #config.metadata.name
				}
				serviceName: "\(#config.metadata.name)-postgresql-headless"
				template: {
					metadata: labels: {
						"app.kubernetes.io/name":      "postgresql"
						"app.kubernetes.io/instance":  #config.metadata.name
					}
					spec: corev1.#PodSpec & {
						containers: [{
							name:  "postgresql"
							image: "\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
							env: [{
								name:  "POSTGRES_DB"
								value: #config.postgresql.auth.database
							}, {
								name:  "POSTGRES_USER"
								value: #config.postgresql.auth.username
							}, {
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									key:  "postgres-password"
									name: "\(#config.metadata.name)-postgresql"
								}
							}]
							ports: [{
								name:          "postgresql"
								containerPort: 5432
							}]
							volumeMounts: [{
								name:      "data"
								mountPath: "/bitnami/postgresql"
							}]
						}]
						if !#config.postgresql.persistence.enabled {
							volumes: [{
								name: "data"
								emptyDir: {}
							}]
						}
					}
				}
				if #config.postgresql.persistence.enabled {
					volumeClaimTemplates: [{
						metadata: name: "data"
						spec: corev1.#PersistentVolumeClaimSpec & {
							if len(#config.postgresql.persistence.accessModes) > 0 {
								accessModes: #config.postgresql.persistence.accessModes
							}
							resources: #config.postgresql.persistence.resources
							if #config.postgresql.persistence.storageClassName != "" {
								storageClassName: #config.postgresql.persistence.storageClassName
							}
						}
					}]
				}
			}
		}
	]
}
