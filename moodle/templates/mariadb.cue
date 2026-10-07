package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#MariadbSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #config.#dbSecret
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			"app.kubernetes.io/name":      #config.#dbAppName
			"app.kubernetes.io/component": "database"
		}
	}
	type: "Opaque"
	stringData: {
		"\(#config.#mariadbRootPasswordKey)":        #config.#mariadbRootPassword
		"\(#config.#mariadbUserPasswordKey)":        #config.#mariadbUserPassword
		"\(#config.#mariadbReplicationPasswordKey)": #config.#mariadbReplicationPassword
	}
}

#MariadbConfig: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.#dbFullname)-config"
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			"app.kubernetes.io/name":      #config.#dbAppName
			"app.kubernetes.io/component": "database"
		}
	}
	data: {
		"my.cnf": """
			[mysqld]
			port = \(#config.mariadb.service.port)
			bind-address = 0.0.0.0
			skip-name-resolve = ON
			"""
	}
}

#MariadbInitdb: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.#dbFullname)-initdb"
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			"app.kubernetes.io/name":      #config.#dbAppName
			"app.kubernetes.io/component": "database"
		}
	}
	data: {
		"00-bootstrap-users.sh": """
			#!/bin/sh
			set -eu

			mariadb --protocol=socket -uroot -p"${MARIADB_ROOT_PASSWORD}" <<EOSQL
			CREATE DATABASE IF NOT EXISTS \\`${MARIADB_DATABASE}\\`;
			CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
			GRANT ALL PRIVILEGES ON \\`${MARIADB_DATABASE}\\`.* TO '${MARIADB_USER}'@'%';
			FLUSH PRIVILEGES;
			EOSQL
			"""
	}
}

#MariadbHeadlessService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.#dbFullname)-headless"
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			"app.kubernetes.io/name":      #config.#dbAppName
			"app.kubernetes.io/component": "database"
		}
	}
	spec: {
		clusterIP:                "None"
		publishNotReadyAddresses: true
		selector: {
			"app.kubernetes.io/name":     #config.#dbAppName
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/role":     "standalone"
		}
		ports: [
			{
				name:       "mariadb"
				port:       #config.mariadb.service.port
				targetPort: "mariadb"
			},
		]
	}
}

#MariadbService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#dbFullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			"app.kubernetes.io/name":      #config.#dbAppName
			"app.kubernetes.io/component": "database"
		}
	}
	spec: {
		type: "ClusterIP"
		selector: {
			"app.kubernetes.io/name":     #config.#dbAppName
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/role":     "standalone"
		}
		ports: [
			{
				name:       "mariadb"
				port:       #config.mariadb.service.port
				targetPort: "mariadb"
				protocol:   "TCP"
			},
		]
	}
}

#MariadbStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      #config.#dbFullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			"app.kubernetes.io/name":      #config.#dbAppName
			"app.kubernetes.io/component": "database"
		}
	}
	spec: {
		serviceName: "\(#config.#dbFullname)-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":     #config.#dbAppName
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/role":     "standalone"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     #config.#dbAppName
				"app.kubernetes.io/instance": #config.metadata.name
				"app.kubernetes.io/role":     "standalone"
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            #config.#mariadbServiceAccountName
				terminationGracePeriodSeconds: #config.mariadb.terminationGracePeriodSeconds
				securityContext:               #config.mariadb.podSecurityContext
				containers: [
					{
						name:            #config.#dbAppName
						image:           #config.mariadb.image.reference
						imagePullPolicy: #config.mariadb.image.pullPolicy
						command: [
							"sh",
							"-ec",
							"""
							cp /config/my.cnf /etc/mysql/conf.d/zz-chart.cnf
							cat > /etc/mysql/conf.d/zz-role.cnf <<EOF
							[mysqld]
							server_id = 1
							read_only = OFF
							EOF
							exec docker-entrypoint.sh mariadbd
							""",
						]
						ports: [
							{
								name:          "mariadb"
								containerPort: #config.mariadb.service.port
							},
						]
						env: [
							{
								name: "MARIADB_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#dbSecret
									key:  #config.#mariadbRootPasswordKey
								}
							},
							{name: "MARIADB_ROOT_HOST", value: "%"},
							{name: "MARIADB_DATABASE", value: #config.mariadb.auth.database},
							{name: "MARIADB_USER", value: #config.mariadb.auth.username},
							{
								name: "MARIADB_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#dbSecret
									key:  #config.#mariadbUserPasswordKey
								}
							},
							{name: "REPLICATION_USERNAME", value: ""},
							{
								name: "REPLICATION_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#dbSecret
									key:  #config.#mariadbReplicationPasswordKey
								}
							},
						]
						livenessProbe: {
							exec: command: [
								"sh",
								"-ec",
								"mariadb-admin ping -h 127.0.0.1 -P \(#config.mariadb.service.port) -uroot --password=\"${MARIADB_ROOT_PASSWORD}\"",
							]
							initialDelaySeconds: 60
							periodSeconds:       20
							timeoutSeconds:      5
							failureThreshold:    6
						}
						readinessProbe: {
							exec: command: [
								"sh",
								"-ec",
								"mariadb-admin ping -h 127.0.0.1 -P \(#config.mariadb.service.port) -uroot --password=\"${MARIADB_ROOT_PASSWORD}\"",
							]
							initialDelaySeconds: 20
							periodSeconds:       10
							timeoutSeconds:      5
							failureThreshold:    6
						}
						startupProbe: {
							exec: command: [
								"sh",
								"-ec",
								"mariadb-admin ping -h 127.0.0.1 -P \(#config.mariadb.service.port) -uroot --password=\"${MARIADB_ROOT_PASSWORD}\"",
							]
							initialDelaySeconds: 10
							periodSeconds:       10
							timeoutSeconds:      5
							failureThreshold:    60
						}
						resources:       #config.mariadb.resources
						securityContext: #config.mariadb.securityContext
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/var/lib/mysql"
								subPath:   "mysql"
							},
							{
								name:      "config"
								mountPath: "/config"
							},
							{
								name:      "mariadb-conf"
								mountPath: "/etc/mysql/conf.d"
							},
							{
								name:      "initdb"
								mountPath: "/docker-entrypoint-initdb.d"
							},
						]
					},
				]
				volumes: [
					{
						name: "mariadb-conf"
						emptyDir: {}
					},
					{
						name: "config"
						configMap: name: "\(#config.#dbFullname)-config"
					},
					{
						name: "initdb"
						configMap: {
							name:        "\(#config.#dbFullname)-initdb"
							defaultMode: 0o755
						}
					},
					if !#config.mariadb.persistence.enabled {
						{
							name: "data"
							emptyDir: {}
						}
					},
				]
			}
		}
		if #config.mariadb.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: {
						name: "data"
						labels: {
							"app.kubernetes.io/name":     #config.#dbAppName
							"app.kubernetes.io/instance": #config.metadata.name
						}
					}
					spec: {
						accessModes: #config.mariadb.persistence.accessModes
						if #config.mariadb.persistence.storageClass != "" {
							if #config.mariadb.persistence.storageClass == "-" {
								storageClassName: ""
							}
							if #config.mariadb.persistence.storageClass != "-" {
								storageClassName: #config.mariadb.persistence.storageClass
							}
						}
						resources: requests: storage: #config.mariadb.persistence.size
					}
				},
			]
		}
	}
}
