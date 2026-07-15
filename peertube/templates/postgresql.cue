package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgresqlStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	let c = #config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      *"\((c.metadata.name))-postgresql" | string
		namespace: c.metadata.namespace
		labels: c.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: *"\((c.metadata.name))-postgresql" | string
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":      c.metadata.name
			"app.kubernetes.io/component": "postgresql"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":      c.metadata.name
				"app.kubernetes.io/component": "postgresql"
			}
			spec: corev1.#PodSpec & {
				containers: [
					{
						name:            "postgresql"
						image:           "\(c.postgresql.image.repository):\(c.postgresql.image.tag)"
						imagePullPolicy: "IfNotPresent"
						ports: [
							{
								containerPort: 5432
								name:          "postgresql"
							},
						]
						env: [
							{
								name:  "POSTGRES_DB"
								value: "peertube"
							},
							{
								name: "POSTGRES_USER"
								valueFrom: secretKeyRef: {
									name: *"\((c.metadata.name))-server-postgres" | string
									key:  "postgres-username"
								}
							},
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: *"\((c.metadata.name))-server-postgres" | string
									key:  "postgres-password"
								}
							},
						]
						resources: c.postgresql.resources
						volumeMounts: [
							if c.postgresql.persistence.enabled {
								{
									name:      "postgres-data"
									mountPath: "/var/lib/postgresql/data"
									subPath:   "pgdata"
								}
							},
						]
					},
				]
			}
		}
		if c.postgresql.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: name: "postgres-data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: c.postgresql.persistence.accessModes
						resources: requests: storage: c.postgresql.persistence.size
						if c.postgresql.persistence.storageClass != "" {
							storageClassName: c.postgresql.persistence.storageClass
						}
					}
				},
			]
		}
	}
}

#PostgresqlService: corev1.#Service & {
	#config: #Config
	let c = #config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      *"\((c.metadata.name))-postgresql" | string
		namespace: c.metadata.namespace
		labels: c.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
	}
	spec: corev1.#ServiceSpec & {
		ports: [
			{
				port:       c.postgresql.service.port
				targetPort: 5432
				name:       "postgresql"
			},
		]
		selector: {
			"app.kubernetes.io/name":      c.metadata.name
			"app.kubernetes.io/component": "postgresql"
		}
		type: "ClusterIP"
	}
}
