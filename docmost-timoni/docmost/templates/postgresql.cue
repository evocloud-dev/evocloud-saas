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
				if #config.serviceAccount.name != "" {
					serviceAccountName: #config.serviceAccount.name
				}
				if #config.serviceAccount.name == "" {
					if #config.serviceAccount.create {
						serviceAccountName: #config.metadata.name
					}
					if !#config.serviceAccount.create {
						serviceAccountName: "default"
					}
				}
				securityContext: {
					runAsUser:    999
					runAsGroup:   999
					fsGroup:      999
					runAsNonRoot: true
				}
				initContainers: [
					{
						name:  "volume-permissions"
						image: "docker.io/library/busybox:1.37"
						command: ["sh", "-c", "chown -R 999:999 /var/lib/postgresql /var/run/postgresql"]
						securityContext: {
							runAsUser:                0
							runAsNonRoot:             false
							allowPrivilegeEscalation: false
							capabilities: {
								drop: ["ALL"]
								add: ["CHOWN", "FOWNER", "DAC_OVERRIDE"]
							}
						}
						volumeMounts: [
							{
								name:      "postgresql-data"
								mountPath: "/var/lib/postgresql"
							},
							{
								name:      "postgres-run"
								mountPath: "/var/run/postgresql"
							},
						]
					}
				]
				containers: [{
					name:            "postgresql"
					image:           "\(#config.postgresql.image.repository):\(#config.postgresql.image.tag)"
					imagePullPolicy: #config.postgresql.image.pullPolicy
					securityContext: {
						runAsUser:                999
						runAsGroup:               999
						allowPrivilegeEscalation: false
						readOnlyRootFilesystem:   true
						capabilities: drop: ["ALL"]
					}
					if #config.postgresql.resources != _|_ {
						resources: #config.postgresql.resources
					}
					ports: [{
						containerPort: 5432
						name:          "postgresql"
					}]
					env: [
						{
							name:  "PGDATA"
							value: "/var/lib/postgresql/data"
						},
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
						},
						{
							name:      "postgres-run"
							mountPath: "/var/run/postgresql"
						},
						{
							name:      "tmp-dir"
							mountPath: "/tmp"
						}
					]
				}]
				volumes: [
					{
						name: "init-scripts"
						configMap: name: #initdbCmName
					},
					{
						name: "postgres-run"
						emptyDir: {}
					},
					{
						name: "tmp-dir"
						emptyDir: {}
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
