package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	resource "k8s.io/apimachinery/pkg/api/resource"
)

#PostgreSQLSecret: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-postgresql-auth"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"user-password": #config.postgresql.auth.password
	}
}

#PostgreSQLService: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [{
			port:       5432
			targetPort: 5432
			protocol:   "TCP"
			name:       "tcp-postgresql"
		}]
		selector: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#PostgreSQLHeadlessService: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-postgresql-primary-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type:      "ClusterIP"
		clusterIP: "None"
		ports: [{
			port:       5432
			targetPort: 5432
			protocol:   "TCP"
			name:       "tcp-postgresql"
		}]
		selector: {
			"app.kubernetes.io/name":     "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#PostgreSQLStatefulSet: {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.fullname)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas:    1
		serviceName: "\(#config.fullname)-postgresql-primary-headless"
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
				automountServiceAccountToken: [
					if #config.postgresql.automountServiceAccountToken != _|_ {
						#config.postgresql.automountServiceAccountToken
					},
					false,
				][0]
				serviceAccountName: [
					if #config.postgresql.serviceAccountName != _|_ {
						#config.postgresql.serviceAccountName
					},
					if #config.serviceAccount.create {
						if #config.serviceAccount.name != "" {
							#config.serviceAccount.name
						}
						if #config.serviceAccount.name == "" {
							#config.fullname
						}
					},
					"default",
				][0]
				if #config.postgresql.podSecurityContext != _|_ {
					securityContext: #config.postgresql.podSecurityContext
				}
				containers: [{
					name:            "postgresql"
					image:           "\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
					imagePullPolicy: #config.postgresql.image.pullPolicy
					if #config.postgresql.securityContext != _|_ {
						securityContext: #config.postgresql.securityContext
					}
					ports: [{
						containerPort: 5432
						name:          "postgresql"
					}]
					if #config.postgresql.resources != _|_ {
						resources: #config.postgresql.resources
					}
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
								name: "\(#config.fullname)-postgresql-auth"
								key:  "user-password"
							}
						},
						{
							name:  "PGDATA"
							value: "/var/lib/postgresql/data/pgdata"
						},
					]
					volumeMounts: [{
						name:      "data"
						mountPath: "/var/lib/postgresql/data"
					}]
				}]
				if !#config.postgresql.standalone.persistence.enabled {
					volumes: [{
						name: "data"
						emptyDir: {}
					}]
				}
			}
		}
		if #config.postgresql.standalone.persistence.enabled {
			volumeClaimTemplates: [
				corev1.#PersistentVolumeClaim & {
					metadata: name: "data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: ["ReadWriteOnce"]
						resources: requests: (corev1.#ResourceStorage): resource.#Quantity & #config.postgresql.standalone.persistence.size
					}
				},
			]
		}
	}
}
