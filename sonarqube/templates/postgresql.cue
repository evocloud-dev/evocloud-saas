package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#PGSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\( #config.postgresqlFullname )-auth"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		"user-password": [
			if #config.postgresql.auth.password != "" {
				#config.postgresql.auth.password
			},
			if #config.postgresql.auth.password == "" {
				"change-me-please-db-password!"
			},
		][0]
	}
}

#PGSVC: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.postgresqlFullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [
			{
				port:       5432
				targetPort: 5432
				protocol:   "TCP"
				name:       "tcp-postgresql"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#PGHeadlessSVC: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\( #config.postgresqlFullname )-primary-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type:      "ClusterIP"
		clusterIP: "None"
		ports: [
			{
				port:       5432
				targetPort: 5432
				protocol:   "TCP"
				name:       "tcp-postgresql"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#PGStatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      #config.postgresqlFullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "postgresql"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas:    1
		serviceName: "\( #config.postgresqlFullname )-primary-headless"
		selector: matchLabels: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "postgresql"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: false
				// We can default service account to default or sonarqube's service account name
				serviceAccountName: [
					if #config.serviceAccount.create {
						if #config.serviceAccount.name != "" {
							#config.serviceAccount.name
						}
						if #config.serviceAccount.name == "" {
							#config.fullname
						}
					},
					if !#config.serviceAccount.create {
						if #config.serviceAccount.name != "" {
							#config.serviceAccount.name
						}
						if #config.serviceAccount.name == "" {
							"default"
						}
					},
				][0]

				if #config.postgresql.podSecurityContext != _|_ {
					securityContext: #config.postgresql.podSecurityContext
				}
				containers: [
					{
						name:            "postgresql"
						image:           #config.postgresql.image.reference
						imagePullPolicy: #config.postgresql.image.pullPolicy
						ports: [
							{
								containerPort: 5432
								name:          "postgresql"
							},
						]
						env: [
							{
								name:  "POSTGRES_DB"
								value: #config.postgresql.auth.database
							},
							{
								name:  "POSTGRES_USER"
								value: #config.postgresql.auth.username
							},
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\( #config.postgresqlFullname )-auth"
									key:  "user-password"
								}
							},
							{
								name:  "PGDATA"
								value: "/var/lib/postgresql/data/pgdata"
							},
						]
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/var/lib/postgresql/data"
							},
						]
						if #config.postgresql.resources != _|_ {
							resources: #config.postgresql.resources
						}
						if #config.postgresql.securityContext != _|_ {
							securityContext: #config.postgresql.securityContext
						}
					},
				]
				if !#config.postgresql.standalone.persistence.enabled {
					volumes: [
						{
							name: "data"
							emptyDir: {}
						},
					]
				}
			}
		}
		if #config.postgresql.standalone.persistence.enabled {
			volumeClaimTemplates: [
				corev1.#PersistentVolumeClaim & {
					metadata: name: "data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: #config.postgresql.standalone.persistence.accessModes
						if #config.postgresql.standalone.persistence.storageClass != "" {
							storageClassName: #config.postgresql.standalone.persistence.storageClass
						}
						resources: requests: storage: #config.postgresql.standalone.persistence.size
					}
				},
			]
		}
	}
}
