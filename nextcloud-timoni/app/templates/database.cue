package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgreSQL: {
	#in: #Config

	deployment: appsv1.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      #in.database.postgresql.primaryHost
			namespace: #in.metadata.namespace
			labels:    #in.metadata.labels & {
				"app.kubernetes.io/component": "database"
			}
		}
		spec: appsv1.#DeploymentSpec & {
			selector: matchLabels: {
				"app.kubernetes.io/name":      #in.metadata.name
				"app.kubernetes.io/component": "database"
			}
			template: {
				metadata: {
					labels: {
						"app.kubernetes.io/name":      #in.metadata.name
						"app.kubernetes.io/component": "database"
					}
				}
				spec: corev1.#PodSpec & {
					automountServiceAccountToken: false
					serviceAccountName: #in.rbac.serviceAccount.name
					securityContext: #in.database.postgresql.podSecurityContext
					containers: [
						{
							name:            "postgresql"
							image:           #in.database.postgresql.image
							securityContext: #in.database.postgresql.securityContext
							resources:       #in.database.postgresql.resources
							env: [
								{
									name:  "POSTGRES_USER"
									value: #in.database.postgresql.auth.username
								},
								{
									name:  "POSTGRES_PASSWORD"
									value: #in.database.postgresql.auth.password
								},
								{
									name:  "POSTGRES_DB"
									value: #in.database.postgresql.auth.database
								},
							]
							ports: [
								{
									containerPort: 5432
									name:          "tcp-postgresql"
								},
							]
							volumeMounts: [
								if #in.database.postgresql.persistence.enabled {
									{
										name:      "data"
										mountPath: "/var/lib/postgresql"
									}
								},
								if #in.database.postgresql.securityContext.readOnlyRootFilesystem != _|_ && #in.database.postgresql.securityContext.readOnlyRootFilesystem == true {
									{
										name:      "var-run-postgresql"
										mountPath: "/var/run/postgresql"
									}
								},
								if #in.database.postgresql.securityContext.readOnlyRootFilesystem != _|_ && #in.database.postgresql.securityContext.readOnlyRootFilesystem == true {
									{
										name:      "tmp"
										mountPath: "/tmp"
									}
								},
							]
						},
					]
					volumes: [
						if #in.database.postgresql.persistence.enabled {
							{
								name: "data"
								persistentVolumeClaim: claimName: #in.database.postgresql.primaryHost
							}
						},
						if #in.database.postgresql.securityContext.readOnlyRootFilesystem != _|_ && #in.database.postgresql.securityContext.readOnlyRootFilesystem == true {
							{
								name: "var-run-postgresql"
								emptyDir: {}
							}
						},
						if #in.database.postgresql.securityContext.readOnlyRootFilesystem != _|_ && #in.database.postgresql.securityContext.readOnlyRootFilesystem == true {
							{
								name: "tmp"
								emptyDir: {}
							}
						},
					]
				}
			}
		}
	}

	service: corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      #in.database.postgresql.primaryHost
			namespace: #in.metadata.namespace
			labels:    #in.metadata.labels & {
				"app.kubernetes.io/component": "database"
			}
		}
		spec: corev1.#ServiceSpec & {
			type: corev1.#ServiceTypeClusterIP
			ports: [
				{
					port:       5432
					targetPort: "tcp-postgresql"
					protocol:   "TCP"
					name:       "tcp-postgresql"
				},
			]
			selector: {
				"app.kubernetes.io/name":      #in.metadata.name
				"app.kubernetes.io/component": "database"
			}
		}
	}
}

#MariaDB: {
	#in: #Config

	deployment: appsv1.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      #in.database.mariadb.primaryHost
			namespace: #in.metadata.namespace
			labels:    #in.metadata.labels & {
				"app.kubernetes.io/component": "database"
			}
		}
		spec: appsv1.#DeploymentSpec & {
			selector: matchLabels: {
				"app.kubernetes.io/name":      #in.metadata.name
				"app.kubernetes.io/component": "database"
			}
			template: {
				metadata: labels: {
					"app.kubernetes.io/name":      #in.metadata.name
					"app.kubernetes.io/component": "database"
				}
				spec: corev1.#PodSpec & {
					containers: [
						{
							name:  "mariadb"
							image: #in.database.mariadb.image
							env: [
								{
									name:  "MARIADB_ROOT_PASSWORD"
									value: #in.database.mariadb.auth.rootPassword
								},
								{
									name:  "MARIADB_USER"
									value: #in.database.mariadb.auth.username
								},
								{
									name:  "MARIADB_PASSWORD"
									value: #in.database.mariadb.auth.password
								},
								{
									name:  "MARIADB_DATABASE"
									value: #in.database.mariadb.auth.database
								},
							]
							ports: [
								{
									containerPort: 3306
									name:          "mysql"
								},
							]
							if #in.database.mariadb.persistence.enabled {
								volumeMounts: [
									{
										name:      "data"
										mountPath: "/bitnami/mariadb"
									},
								]
							}
						},
					]
					if #in.database.mariadb.persistence.enabled {
						volumes: [
							{
								name: "data"
								persistentVolumeClaim: claimName: #in.database.mariadb.primaryHost
							},
						]
					}
				}
			}
		}
	}

	service: corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      #in.database.mariadb.primaryHost
			namespace: #in.metadata.namespace
			labels:    #in.metadata.labels & {
				"app.kubernetes.io/component": "database"
			}
		}
		spec: corev1.#ServiceSpec & {
			type: corev1.#ServiceTypeClusterIP
			ports: [
				{
					port:       3306
					targetPort: "mysql"
					protocol:   "TCP"
					name:       "mysql"
				},
			]
			selector: {
				"app.kubernetes.io/name":      #in.metadata.name
				"app.kubernetes.io/component": "database"
			}
		}
	}
}
