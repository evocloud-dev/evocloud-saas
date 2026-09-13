package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
)

#PostgreSQLSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-postgresql-auth"
		namespace: #config.namespace
		labels:    #config.metadata.labels & #config.commonLabels
	}
	type: "Opaque"
	stringData: {
		"user-password": [
			if #config.postgresql.auth.password != "" {#config.postgresql.auth.password},
			"CHANGE_ME_POSTGRESQL_PASSWORD",
		][0]
	}
}

#PostgreSQLService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-postgresql"
		namespace: #config.namespace
		labels:    #config.metadata.labels & #config.commonLabels
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

#PostgreSQLHeadlessService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-postgresql-primary-headless"
		namespace: #config.namespace
		labels:    #config.metadata.labels & #config.commonLabels
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

#PostgreSQLInitConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.fullname)-postgresql-initdb"
		namespace: #config.namespace
		labels:    #config.metadata.labels & #config.commonLabels
	}
	data: #config.postgresql.initdb.scripts
}

#PostgreSQLStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.fullname)-postgresql"
		namespace: #config.namespace
		labels:    #config.metadata.labels & #config.commonLabels
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
				automountServiceAccountToken: false
				serviceAccountName:           #config.serviceAccountName
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
					if #config.postgresql.standalone.resources != _|_ {
						resources: #config.postgresql.standalone.resources
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
					volumeMounts: [
						{
							name:      "data"
							mountPath: "/var/lib/postgresql/data"
						},
						if len(#config.postgresql.initdb.scripts) > 0 {
							name:      "initdb"
							mountPath: "/docker-entrypoint-initdb.d"
						},
					]
				}]
				volumes: [
					if !#config.postgresql.standalone.persistence.enabled {
						name: "data"
						emptyDir: {}
					},
					if len(#config.postgresql.initdb.scripts) > 0 {
						name: "initdb"
						configMap: {
							name:        "\(#config.fullname)-postgresql-initdb"
							defaultMode: 0o755
						}
					},
				]
			}
		}
		if #config.postgresql.standalone.persistence.enabled {
			volumeClaimTemplates: [
				corev1.#PersistentVolumeClaim & {
					metadata: name: "data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: ["ReadWriteOnce"]
						if #config.postgresql.standalone.persistence.storageClass != "" {
							storageClassName: #config.postgresql.standalone.persistence.storageClass
						}
						resources: requests: (corev1.#ResourceStorage): resource.#Quantity & #config.postgresql.standalone.persistence.size
					}
				},
			]
		}
	}
}
