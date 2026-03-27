package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"strings"
	"list"
)

#MySQLDeployment: {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		strategy: {
			type: #config.mysql.primary.strategy
			if type == "RollingUpdate" {
				rollingUpdate: {
					maxUnavailable: 1
					maxSurge:       0
				}
			}
		}
		selector: matchLabels: #config.selector.labels & {
			app: "mysql"
		}
		template: {
			metadata: labels: #config.selector.labels & {
				app: "mysql"
			}
			spec: corev1.#PodSpec & {
				if #config.mysql.volumePermissions.enabled {
					securityContext: fsGroup: 1001
				}
				containers: [
					{
						name:  "mysql"
						image: "\(#config.mysql.image.registry)/\(#config.mysql.image.repository):\(#config.mysql.image.tag)"
						env: [
							{
								name:  "MYSQL_DATABASE"
								value: #config.mysql.auth.database
							},
							{
								name:  "MYSQL_USER"
								value: #config.mysql.auth.username
							},
							{
								name: "MYSQL_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-mysql"
									key:  "mysql-password"
								}
							},
							{
								name: "MYSQL_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-mysql"
									key:  "mysql-root-password"
								}
							},
							{
								name:  "MYSQL_AUTHENTICATION_PLUGIN"
								value: "mysql_native_password"
							},
						]
						ports: [
							{
								containerPort: 3306
								name:          "mysql"
							},
						]
						livenessProbe: {
							tcpSocket: port: "mysql"
							initialDelaySeconds: 30
							periodSeconds:       10
						}
						readinessProbe: {
							exec: command: ["/bin/sh", "-c", "mysqladmin ping -u$MYSQL_USER -p$MYSQL_PASSWORD"]
							initialDelaySeconds: 5
							periodSeconds:       10
						}
						command: ["/opt/bitnami/scripts/mysql/entrypoint.sh"]
						if #config.mysql.primary.extraFlags != _|_ {
							args: list.Concat([["/opt/bitnami/scripts/mysql/run.sh"], strings.Fields(#config.mysql.primary.extraFlags)])
						}
						volumeMounts: [
							{
								name:      "mysql-data"
								mountPath: "/bitnami/mysql"
							},
						]
						if #config.mysql.primary.resources != _|_ {
							resources: #config.mysql.primary.resources
						}
					},
				]
				volumes: [
					{
						name: "mysql-data"
						persistentVolumeClaim: claimName: "\(#config.metadata.name)-mysql"
					},
				]
			}
		}
	}
}

#MySQLService: {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		selector: #config.selector.labels & {
			app: "mysql"
		}
		ports: [
			{
				name:       "mysql"
				port:       3306
				targetPort: 3306
			},
		]
	}
}

#MySQLSecret: {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"mysql-password":      #config.mysql.auth.password
		"mysql-root-password": #config.mysql.auth.rootPassword
	}
}
