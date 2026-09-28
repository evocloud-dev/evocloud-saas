package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MySQLAuthSecret: corev1.#Secret & {
	#config: #Config

	let _rootPassword = [
		if #config.mysql.auth.rootPassword != "" {#config.mysql.auth.rootPassword},
		if #config.mysql.auth.password != "" {#config.mysql.auth.password},
		"gT0JFJI04PsFT2VpjXc4gk9zgd4YMK62",
	][0]

	let _userPassword = [
		if #config.mysql.auth.password != "" {#config.mysql.auth.password},
		"4p0WuisZ2Dc00vhzHCUYt0W1cHIo1vtt",
	][0]

	let _replicationPassword = [
		if #config.mysql.auth.replicationPassword != "" {#config.mysql.auth.replicationPassword},
		"EN68ln0InqddkS7xcDMEDw5R6QtAsaeu",
	][0]

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config._name)-mysql-auth"
		namespace: #config.metadata.namespace
		labels: {
			"helm.sh/chart":                "mysql-2.0.3"
			"app.kubernetes.io/name":       "mysql"
			"app.kubernetes.io/instance":   #config._name
			"app.kubernetes.io/version":    #config.mysql.image.tag
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/part-of":    "helmforge"
		}
	}
	type: "Opaque"
	stringData: {
		"mysql-root-password":        _rootPassword
		"mysql-user-password":        _userPassword
		"mysql-replication-password": _replicationPassword
	}
}

#MySQLConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config._name)-mysql-config"
		namespace: #config.metadata.namespace
		labels: {
			"helm.sh/chart":                "mysql-2.0.3"
			"app.kubernetes.io/name":       "mysql"
			"app.kubernetes.io/instance":   #config._name
			"app.kubernetes.io/version":    #config.mysql.image.tag
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/part-of":    "helmforge"
		}
	}
	data: {
		"my.cnf": """
			[mysqld]
			port = 3306
			bind-address = 0.0.0.0
			mysqlx = 0
			skip-name-resolve = ON

			"""
	}
}

#MySQLInitDBConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config._name)-mysql-initdb"
		namespace: #config.metadata.namespace
		labels: {
			"helm.sh/chart":                "mysql-2.0.3"
			"app.kubernetes.io/name":       "mysql"
			"app.kubernetes.io/instance":   #config._name
			"app.kubernetes.io/version":    #config.mysql.image.tag
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/part-of":    "helmforge"
		}
	}
	data: {
		"00-bootstrap-users.sh": """
			#!/bin/sh
			set -eu

			mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" <<EOSQL
			CREATE DATABASE IF NOT EXISTS `${MYSQL_DATABASE}`;
			CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
			GRANT ALL PRIVILEGES ON `${MYSQL_DATABASE}`.* TO '${MYSQL_USER}'@'%';
			FLUSH PRIVILEGES;
			EOSQL

			"""
	}
}

#MySQLHeadlessService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config._name)-mysql-headless"
		namespace: #config.metadata.namespace
		labels: {
			"helm.sh/chart":                "mysql-2.0.3"
			"app.kubernetes.io/name":       "mysql"
			"app.kubernetes.io/instance":   #config._name
			"app.kubernetes.io/version":    #config.mysql.image.tag
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/part-of":    "helmforge"
		}
	}
	spec: corev1.#ServiceSpec & {
		clusterIP:                "None"
		publishNotReadyAddresses: true
		ports: [
			{
				name:       "mysql"
				port:       3306
				targetPort: "mysql"
			},
		]
		selector: {
			"app.kubernetes.io/name":      "mysql"
			"app.kubernetes.io/instance":  #config._name
			"app.kubernetes.io/component": "mysql"
			"app.kubernetes.io/part-of":   "mysql"
			"app.kubernetes.io/role":      "standalone"
		}
	}
}

#MySQLService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config._name)-mysql"
		namespace: #config.metadata.namespace
		labels: {
			"helm.sh/chart":                "mysql-2.0.3"
			"app.kubernetes.io/name":       "mysql"
			"app.kubernetes.io/instance":   #config._name
			"app.kubernetes.io/version":    #config.mysql.image.tag
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/part-of":    "helmforge"
		}
	}
	spec: corev1.#ServiceSpec & {
		type: corev1.#ServiceTypeClusterIP
		ports: [
			{
				name:       "mysql"
				port:       3306
				targetPort: "mysql"
			},
		]
		selector: {
			"app.kubernetes.io/name":      "mysql"
			"app.kubernetes.io/instance":  #config._name
			"app.kubernetes.io/component": "mysql"
			"app.kubernetes.io/part-of":   "mysql"
			"app.kubernetes.io/role":      "standalone"
		}
	}
}

#MySQLStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	let _mysqlSelector = {
		"app.kubernetes.io/name":      "mysql"
		"app.kubernetes.io/instance":  #config._name
		"app.kubernetes.io/component": "mysql"
		"app.kubernetes.io/part-of":   "mysql"
		"app.kubernetes.io/role":      "standalone"
	}

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config._name)-mysql"
		namespace: #config.metadata.namespace
		labels: {
			"helm.sh/chart":                "mysql-2.0.3"
			"app.kubernetes.io/name":       "mysql"
			"app.kubernetes.io/instance":   #config._name
			"app.kubernetes.io/version":    #config.mysql.image.tag
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/part-of":    "helmforge"
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config._name)-mysql-headless"
		replicas:    1
		selector: matchLabels: _mysqlSelector
		template: {
			metadata: {
				labels: _mysqlSelector
				annotations: {
					"checksum/config": "a42e052a2b6e3f7a1d69c0eef627e2286deb3ed509fa844a2f7ef4a235e5fa14"
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				securityContext: {
					fsGroup:             999
					fsGroupChangePolicy: "OnRootMismatch"
					seccompProfile: type: "RuntimeDefault"
				}
				terminationGracePeriodSeconds: 120
				containers: [
					{
						name:            "mysql"
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
								containerPort: 3306
							},
						]
						env: [
							{
								name: "MYSQL_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config._name)-mysql-auth"
									key:  "mysql-root-password"
								}
							},
							{
								name:  "MYSQL_ROOT_HOST"
								value: "%"
							},
							{
								name:  "MYSQL_DATABASE"
								value: #config._dbName
							},
							{
								name:  "MYSQL_USER"
								value: #config._dbUsername
							},
							{
								name: "MYSQL_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config._name)-mysql-auth"
									key:  "mysql-user-password"
								}
							},
							{
								name:  "REPLICATION_USERNAME"
								value: ""
							},
							{
								name: "REPLICATION_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config._name)-mysql-auth"
									key:  "mysql-replication-password"
								}
							},
						]
						livenessProbe: {
							exec: command: [
								"sh",
								"-ec",
								"MYSQL_PWD=\"${MYSQL_ROOT_PASSWORD}\" mysqladmin ping -h 127.0.0.1 -P 3306 -uroot",
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
								"MYSQL_PWD=\"${MYSQL_ROOT_PASSWORD}\" mysqladmin ping -h 127.0.0.1 -P 3306 -uroot",
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
								"MYSQL_PWD=\"${MYSQL_ROOT_PASSWORD}\" mysqladmin ping -h 127.0.0.1 -P 3306 -uroot",
							]
							initialDelaySeconds: 10
							periodSeconds:       10
							timeoutSeconds:      5
							failureThreshold:    60
						}
						securityContext: {
							allowPrivilegeEscalation: false
							capabilities: drop: ["ALL"]
							readOnlyRootFilesystem: false
							runAsGroup:             999
							runAsNonRoot:           true
							runAsUser:              999
						}
						if #config.mysql.resources != {} {
							resources: #config.mysql.resources
						}
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
						configMap: name: "\(#config._name)-mysql-config"
					},
					{
						name: "initdb"
						projected: {
							defaultMode: 0o755
							sources: [
								{
									configMap: name: "\(#config._name)-mysql-initdb"
								},
							]
						}
					},
				]
			}
		}
		volumeClaimTemplates: [
			{
				metadata: {
					name: "data"
					labels: {
						"app.kubernetes.io/name":     "mysql"
						"app.kubernetes.io/instance": #config._name
					}
				}
				spec: corev1.#PersistentVolumeClaimSpec & {
					accessModes: #config.mysql.persistence.accessModes
					if #config.mysql.persistence.storageClass != "" {
						storageClassName: #config.mysql.persistence.storageClass
					}
					resources: requests: storage: #config.mysql.persistence.size
				}
			},
		]
	}
}
