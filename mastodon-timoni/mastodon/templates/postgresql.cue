package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Postgresql: {
	#config: #Config

	#name: "\(#config.metadata.name)-postgresql"

	service: corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			namespace: #config.#namespace
			name:      #name
			labels:    #config.metadata.labels
		}
		spec: corev1.#ServiceSpec & {
			type: "ClusterIP"
			ports: [{
				name:       "tcp-postgresql"
				port:       5432
				targetPort: "tcp-postgresql"
			}]
			selector: "app.kubernetes.io/name": #name
		}
	}

	statefulSet: appsv1.#StatefulSet & {
		apiVersion: "apps/v1"
		kind:       "StatefulSet"
		metadata: {
			namespace: #config.#namespace
			name:      #name
			labels:    #config.metadata.labels
		}
		spec: appsv1.#StatefulSetSpec & {
			replicas: 1
			selector: matchLabels: "app.kubernetes.io/name": #name
			serviceName: #name
			template: {
				metadata: labels: "app.kubernetes.io/name": #name
				spec: corev1.#PodSpec & {
					containers: [{
						name:  "postgresql"
						image: "\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
						imagePullPolicy: #config.postgresql.image.pullPolicy
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
									if #config.postgresql.auth.existingSecret != "" {
										name: #config.postgresql.auth.existingSecret
									}
									if #config.postgresql.auth.existingSecret == "" {
										name: #name
									}
									key: "password"
								}
							},
						]
						ports: [{
							name:          "tcp-postgresql"
							containerPort: 5432
						}]
						livenessProbe: {
							exec: command: ["/bin/sh", "-c", "exec pg_isready -U \"\(#config.postgresql.auth.username)\" -d \"\(#config.postgresql.auth.database)\" -h 127.0.0.1 -p 5432"]
							initialDelaySeconds: 30
							periodSeconds:        10
							timeoutSeconds:       5
							successThreshold:     1
							failureThreshold:     6
						}
						readinessProbe: {
							exec: command: ["/bin/sh", "-c", "exec pg_isready -U \"\(#config.postgresql.auth.username)\" -d \"\(#config.postgresql.auth.database)\" -h 127.0.0.1 -p 5432"]
							initialDelaySeconds: 5
							periodSeconds:        10
							timeoutSeconds:       5
							successThreshold:     1
							failureThreshold:     6
						}
						volumeMounts: [{
							name:      "data"
							mountPath: "/bitnami/postgresql"
						}]
					}]
				}
			}
			volumeClaimTemplates: [{
				metadata: name: "data"
				spec: corev1.#PersistentVolumeClaimSpec & {
					accessModes: ["ReadWriteOnce"]
					resources: requests: storage: "8Gi"
				}
			}]
		}
	}
}
