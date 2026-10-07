package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#MysqlSecret: corev1.#Secret & {
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
		"\(#config.#mysqlRootPasswordKey)":        #config.#mysqlRootPassword
		"\(#config.#mysqlUserPasswordKey)":        #config.#mysqlUserPassword
		"\(#config.#mysqlReplicationPasswordKey)": #config.#mysqlReplicationPassword
	}
}

#MysqlConfig: corev1.#ConfigMap & {
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
			port = \(#config.mysql.service.port)
			bind-address = 0.0.0.0
			mysqlx = 0
			skip-name-resolve = ON
			"""
	}
}

#MysqlInitdb: corev1.#ConfigMap & {
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

			mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" <<EOSQL
			CREATE DATABASE IF NOT EXISTS \\`${MYSQL_DATABASE}\\`;
			CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
			GRANT ALL PRIVILEGES ON \\`${MYSQL_DATABASE}\\`.* TO '${MYSQL_USER}'@'%';
			FLUSH PRIVILEGES;
			EOSQL
			"""
	}
}

#MysqlHeadlessService: corev1.#Service & {
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
				name:       "mysql"
				port:       #config.mysql.service.port
				targetPort: "mysql"
			},
		]
	}
}

#MysqlService: corev1.#Service & {
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
				name:       "mysql"
				port:       #config.mysql.service.port
				targetPort: "mysql"
				protocol:   "TCP"
			},
		]
	}
}

#MysqlStatefulSet: appsv1.#StatefulSet & {
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
				serviceAccountName:            #config.#mysqlServiceAccountName
				automountServiceAccountToken: false
				terminationGracePeriodSeconds: #config.mysql.terminationGracePeriodSeconds
				securityContext:               #config.mysql.podSecurityContext
				containers: [
					{
						name:            #config.#dbAppName
						image:           #config.mysql.image.reference
						imagePullPolicy: #config.mysql.image.pullPolicy
						command: [
							"sh",
							"-ec",
							"""
							cp /config/my.cnf /etc/mysql/conf.d/zz-chart.cnf
							cat > /etc/mysql/conf.d/zz-role.cnf <<EOF
							[mysqld]
							server_id = 1
							read_only = OFF
							super_read_only = OFF
							EOF
							exec docker-entrypoint.sh mysqld
							""",
						]
						ports: [
							{
								name:          "mysql"
								containerPort: #config.mysql.service.port
							},
						]
						env: [
							{
								name: "MYSQL_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#dbSecret
									key:  #config.#mysqlRootPasswordKey
								}
							},
							{name: "MYSQL_ROOT_HOST", value: "%"},
							{name: "MYSQL_DATABASE", value: #config.mysql.auth.database},
							{name: "MYSQL_USER", value: #config.mysql.auth.username},
							{
								name: "MYSQL_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#dbSecret
									key:  #config.#mysqlUserPasswordKey
								}
							},
							{name: "REPLICATION_USERNAME", value: ""},
							{
								name: "REPLICATION_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#dbSecret
									key:  #config.#mysqlReplicationPasswordKey
								}
							},
						]
						livenessProbe: {
							exec: command: [
								"sh",
								"-ec",
								"MYSQL_PWD=\"${MYSQL_ROOT_PASSWORD}\" mysqladmin ping -h 127.0.0.1 -P \(#config.mysql.service.port) -uroot",
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
								"MYSQL_PWD=\"${MYSQL_ROOT_PASSWORD}\" mysqladmin ping -h 127.0.0.1 -P \(#config.mysql.service.port) -uroot",
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
								"MYSQL_PWD=\"${MYSQL_ROOT_PASSWORD}\" mysqladmin ping -h 127.0.0.1 -P \(#config.mysql.service.port) -uroot",
							]
							initialDelaySeconds: 10
							periodSeconds:       10
							timeoutSeconds:      5
							failureThreshold:    60
						}
						resources:       #config.mysql.resources
						securityContext: #config.mysql.securityContext
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/var/lib/mysql"
							},
							{
								name:      "config"
								mountPath: "/config"
							},
							{
								name:      "mysql-conf"
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
						name: "mysql-conf"
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
					if !#config.mysql.persistence.enabled {
						{
							name: "data"
							emptyDir: {}
						}
					},
				]
			}
		}
		if #config.mysql.persistence.enabled {
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
						accessModes: #config.mysql.persistence.accessModes
						if #config.mysql.persistence.storageClass != "" {
							if #config.mysql.persistence.storageClass == "-" {
								storageClassName: ""
							}
							if #config.mysql.persistence.storageClass != "-" {
								storageClassName: #config.mysql.persistence.storageClass
							}
						}
						resources: requests: storage: #config.mysql.persistence.size
					}
				},
			]
		}
	}
}
