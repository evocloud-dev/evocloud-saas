package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQL: {
	#config: #Config
	if #config.postgresql.enabled {
		service: corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-postgresql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels & {
					"app.kubernetes.io/component": "postgresql"
				}
			}
			spec: corev1.#ServiceSpec & {
				type: "ClusterIP"
				ports: [
					{
						name:       "tcp-postgresql"
						port:       5432
						targetPort: "postgresql"
					},
				]
				selector: {
					"app.kubernetes.io/name":      #config.metadata.name
					"app.kubernetes.io/component": "postgresql"
				}
			}
		}

		headlessService: corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-postgresql-hl"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels & {
					"app.kubernetes.io/component": "postgresql"
				}
			}
			spec: corev1.#ServiceSpec & {
				type:      "ClusterIP"
				clusterIP: "None"
				ports: [
					{
						name:       "tcp-postgresql"
						port:       5432
						targetPort: "postgresql"
					},
				]
				selector: {
					"app.kubernetes.io/name":      #config.metadata.name
					"app.kubernetes.io/component": "postgresql"
				}
			}
		}

		statefulSet: appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "\(#config.metadata.name)-postgresql"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels & {
					"app.kubernetes.io/component": "postgresql"
				}
			}
			spec: appsv1.#StatefulSetSpec & {
				serviceName: "\(#config.metadata.name)-postgresql-hl"
				replicas:    1
				selector: matchLabels: {
					"app.kubernetes.io/name":      #config.metadata.name
					"app.kubernetes.io/component": "postgresql"
				}
				template: {
					metadata: labels: {
						"app.kubernetes.io/name":      #config.metadata.name
						"app.kubernetes.io/component": "postgresql"
					}
					spec: corev1.#PodSpec & {
						containers: [
							{
								name:            "postgresql"
								image:           "\(#config.postgresql.primary.image.repository):\(#config.postgresql.primary.image.tag)"
								imagePullPolicy: #config.postgresql.primary.image.pullPolicy
								env: [
									{
										name:  "POSTGRES_USER"
										value: #config.postgresql.auth.username
									},
									{
										name: "POSTGRES_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-postgresql"
											key:  "password"
										}
									},
									{
										name:  "POSTGRES_DB"
										value: #config.postgresql.auth.database
									},
								]
								ports: [
									{
										name:          "postgresql"
										containerPort: 5432
									},
								]
								volumeMounts: [
									{
										name:      "data"
										mountPath: "/var/lib/postgresql/data"
									},
								]
								if #config.postgresql.primary.resources != _|_ {
									resources: #config.postgresql.primary.resources
								}
								livenessProbe: {
									exec: command: [
										"/bin/sh",
										"-c",
										"exec pg_isready -U \(#config.postgresql.auth.username) -d \(#config.postgresql.auth.database) -h localhost",
									]
									initialDelaySeconds: #config.postgresql.healthCheck.initialDelaySeconds
									periodSeconds:       #config.postgresql.healthCheck.periodSeconds
									timeoutSeconds:      #config.postgresql.healthCheck.timeoutSeconds
									failureThreshold:    #config.postgresql.healthCheck.failureThreshold
								}
								readinessProbe: {
									exec: command: [
										"/bin/sh",
										"-c",
										"exec pg_isready -U \(#config.postgresql.auth.username) -d \(#config.postgresql.auth.database) -h localhost",
									]
									initialDelaySeconds: 5
									periodSeconds:       5
									timeoutSeconds:      1
								}
							},
						]
					}
				}
				volumeClaimTemplates: [
					{
						metadata: name: "data"
						spec: corev1.#PersistentVolumeClaimSpec & {
							accessModes: #config.postgresql.primary.persistence.accessModes
							resources: requests: storage: #config.postgresql.primary.persistence.size
							if #config.postgresql.primary.persistence.storageClass != "" {
								storageClassName: #config.postgresql.primary.persistence.storageClass
							}
						}
					},
				]
			}
		}
	}
}
