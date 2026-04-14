package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQL: {
	#config: #Config

	if #config.postgresql.bundled {
		objects: {
			if #config.postgresql.auth.existingSecret == "" {
				secret: corev1.#Secret & {
					apiVersion: "v1"
					kind:       "Secret"
					metadata: {
						name:      "\(#config.metadata.name)-postgresql"
						namespace: #config.metadata.namespace
						labels:    #config.metadata.labels & #config.postgresql.commonLabels
						if #config.metadata.annotations != _|_ {
							annotations: #config.metadata.annotations
						}
					}
					type: "Opaque"
					stringData: {
						password:            #config.postgresql.auth.password
						"postgres-password": #config.postgresql.auth.postgresPassword
					}
				}
			}

			svc: corev1.#Service & {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      "\(#config.metadata.name)-postgresql"
					namespace: #config.metadata.namespace
					labels:    #config.metadata.labels & #config.postgresql.commonLabels
					if #config.metadata.annotations != _|_ {
						annotations: #config.metadata.annotations
					}
				}
				spec: corev1.#ServiceSpec & {
					type: "ClusterIP"
					ports: [{
						name:       "tcp-postgresql"
						port:       5432
						targetPort: "tcp-postgresql"
					}]
					selector: {
						"app.kubernetes.io/name":     "postgresql"
						"app.kubernetes.io/instance": #config.metadata.name
					}
				}
			}

			sts: appsv1.#StatefulSet & {
				apiVersion: "apps/v1"
				kind:       "StatefulSet"
				metadata: {
					name:      "\(#config.metadata.name)-postgresql"
					namespace: #config.metadata.namespace
					labels:    #config.metadata.labels & #config.postgresql.commonLabels
					if #config.metadata.annotations != _|_ {
						annotations: #config.metadata.annotations
					}
				}
				spec: appsv1.#StatefulSetSpec & {
					replicas:    1
					serviceName: "\( #config.metadata.name )-postgresql"
					selector: matchLabels: {
						"app.kubernetes.io/name":     "postgresql"
						"app.kubernetes.io/instance": #config.metadata.name
					}
					template: {
						metadata: labels: {
							"app.kubernetes.io/name":     "postgresql"
							"app.kubernetes.io/instance": #config.metadata.name
						}
						spec: corev1.#PodSpec & {
							if #config.postgresql.global.containerSecurityContext.enabled {
								securityContext: fsGroup: 1001
							}
							containers: [{
								name:            "postgresql"
								image:           #config.postgresql.image.reference
								imagePullPolicy: #config.postgresql.image.imagePullPolicy
								env: [
									{name: "POSTGRESQL_PORT_NUMBER", value: "5432"},
									{name: "POSTGRESQL_VOLUME_DIR", value:  "/bitnami/postgresql"},
									{name: "PGDATA", value:                 "/bitnami/postgresql/data"},
									{name: "POSTGRESQL_USERNAME", value:   #config.postgresql.auth.username},
									{
										name: "POSTGRESQL_PASSWORD"
										valueFrom: secretKeyRef: {
											if #config.postgresql.auth.existingSecret != "" {
												name: #config.postgresql.auth.existingSecret
											}
											if #config.postgresql.auth.existingSecret == "" {
												name: "\(#config.metadata.name)-postgresql"
											}
											key: "password"
										}
									},
									{
										name: "POSTGRESQL_POSTGRES_PASSWORD"
										valueFrom: secretKeyRef: {
											if #config.postgresql.auth.existingSecret != "" {
												name: #config.postgresql.auth.existingSecret
											}
											if #config.postgresql.auth.existingSecret == "" {
												name: "\(#config.metadata.name)-postgresql"
											}
											key: "postgres-password"
										}
									},
									{name: "POSTGRESQL_DATABASE", value: #config.postgresql.auth.database},
								]
								ports: [{
									name:          "tcp-postgresql"
									containerPort: 5432
								}]
								volumeMounts: [{
									name:      "data"
									mountPath: "/bitnami/postgresql"
								}]
								if #config.postgresql.global.containerSecurityContext.enabled {
									securityContext: {
										allowPrivilegeEscalation: #config.postgresql.global.containerSecurityContext.allowPrivilegeEscalation
										capabilities:             #config.postgresql.global.containerSecurityContext.capabilities
										seccompProfile:           #config.postgresql.global.containerSecurityContext.seccompProfile
										readOnlyRootFilesystem:   (!#config.develop && #config.postgresql.global.containerSecurityContext.readOnlyRootFilesystem)
										runAsNonRoot:             #config.postgresql.global.containerSecurityContext.runAsNonRoot
									}
								}
							}]
						}
					}
					volumeClaimTemplates: [{
						metadata: name: "data"
						spec: corev1.#PersistentVolumeClaimSpec & {
							accessModes: #config.persistence.accessModes
							storageClassName: #config.persistence.storageClassName
							resources: requests: storage: "8Gi"
						}
					}]
				}
			}
		}
	}
}
