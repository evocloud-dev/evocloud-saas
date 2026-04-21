package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgresQLService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config._fullname)-postgresql"
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
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
}

#PostgresQLStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config._fullname)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config._fullname)-postgresql"
		replicas:    1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
		template: {
			metadata: labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "postgresql"
			}
			spec: corev1.#PodSpec & {
				securityContext: {
					fsGroup: 1001
				}
				containers: [
					{
						name:  "postgresql"
						image: "\(#config.postgresql.image.registry)/\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
						imagePullPolicy: #config.postgresql.image.pullPolicy
						securityContext: {
							runAsUser:                1001
							runAsGroup:               1001
							runAsNonRoot:             true
							allowPrivilegeEscalation: false
							capabilities: drop: ["ALL"]
						}
						env: [
							{
								name: "POSTGRESQL_USERNAME"
								value: #config.postgresql.auth.username
							},
							{
								name: "POSTGRESQL_DATABASE"
								value: #config.postgresql.auth.database
							},
							{
								name: "POSTGRESQL_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config._fullname)-postgresql"
									key:  "postgres-password"
								}
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
								mountPath: #config.postgresql.persistence.mountPath
								if #config.postgresql.persistence.subPath != "" {
									subPath: #config.postgresql.persistence.subPath
								}
							},
							{
								name:      "postgresql-conf"
								mountPath: "/opt/bitnami/postgresql/conf"
							},
							{
								name:      "postgresql-tmp"
								mountPath: "/opt/bitnami/postgresql/tmp"
							},
						]
					},
				]
				volumes: [
					{
						name: "postgresql-conf"
						emptyDir: {}
					},
					{
						name: "postgresql-tmp"
						emptyDir: {}
					},
				]
			}
		}
		volumeClaimTemplates: [
			if #config.postgresql.persistence.enabled {
				corev1.#PersistentVolumeClaim & {
					metadata: name: "data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: [#config.postgresql.persistence.accessMode]
						if #config.postgresql.persistence.storageClass != "" {
							storageClassName: #config.postgresql.persistence.storageClass
						}
						resources: requests: storage: #config.postgresql.persistence.size
					}
				}
			},
		]
	}
}

#PostgresQLHeadlessService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config._fullname)-postgresql-hl"
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
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
}
