package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#PostgresConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-init"
		namespace: #config.metadata.namespace
	}
	data: #config.postgresql.initdb.scripts
}

#PostgresService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		ports: [{
			port:       5432
			targetPort: 5432
			name:       "tcp-postgresql"
		}]
		selector: {
			"app.kubernetes.io/name": "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#PostgresHeadlessService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql-primary-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		clusterIP: "None"
		ports: [{
			port:       5432
			targetPort: 5432
			name:       "tcp-postgresql"
		}]
		selector: {
			"app.kubernetes.io/name": "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#PostgresStatefulSet: appsv1.#StatefulSet & {
	#config:        #Config
	#initdbCmName:  string
	apiVersion:     "apps/v1"
	kind:           "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-postgresql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config.metadata.name)-postgresql-primary-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name": "postgresql"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name": "postgresql"
				"app.kubernetes.io/instance": #config.metadata.name
			}
			spec: corev1.#PodSpec & {
				containers: [{
					name:            "postgresql"
					image:           "\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
					imagePullPolicy: #config.postgresql.image.pullPolicy
					ports: [{
						containerPort: 5432
						name:          "postgresql"
					}]
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
							value: {
								if #config.postgresql.auth.password != "" { #config.postgresql.auth.password }
								if #config.postgresql.auth.password == "" { "postgres-default-pass-change-me" }
							}
						},
						{
							name: "APP_DATABASE"
							value: #config.postgresql.auth.database
						},
						{
							name: "APP_USERNAME"
							value: #config.postgresql.auth.username
						}
					]
					volumeMounts: [
						{
							name:      "postgresql-data"
							mountPath: "/var/lib/postgresql"
						},
						{
							name:      "init-scripts"
							mountPath: "/docker-entrypoint-initdb.d"
						}
					]
				}]
				volumes: [
					{
						name: "init-scripts"
						configMap: name: #initdbCmName
					}
				]
			}
		}
		volumeClaimTemplates: [{
			metadata: name: "postgresql-data"
			spec: corev1.#PersistentVolumeClaimSpec & {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: #config.postgresql.standalone.persistence.size
			}
		}]
	}
}
