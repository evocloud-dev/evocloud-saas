package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MysqlDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.#mysqlServiceName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "mysql"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "mysql"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "mysql"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            #config.#serviceAccountName
				automountServiceAccountToken: #config.serviceAccount.create
				securityContext:              #config.mysql.podSecurityContext
				containers: [{
					name:            "mysql"
					image:           "\(#config.mysql.image.repository):\(#config.mysql.image.tag)"
					imagePullPolicy: #config.mysql.image.pullPolicy
					ports: [{
						name:          "mysql"
						containerPort: 3306
						protocol:      "TCP"
					}]
					env: [
						{
							name: "MYSQL_DATABASE"
							valueFrom: configMapKeyRef: {
								name: #config.#configName
								key:  "MYSQL_DATABASE"
							}
						},
						{
							name: "MYSQL_USER"
							valueFrom: configMapKeyRef: {
								name: #config.#configName
								key:  "MYSQL_USER"
							}
						},
						{
							name: "MYSQL_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #config.#secretName
								key:  "MYSQL_PASSWORD"
							}
						},
						{
							name: "MYSQL_ROOT_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #config.#secretName
								key:  "MYSQL_ROOT_PASSWORD"
							}
						},
					]
					livenessProbe: {
						exec: command: [
							"/bin/sh",
							"-c",
							"mariadb-admin ping -h 127.0.0.1 -u$MYSQL_USER -p$MYSQL_PASSWORD",
						]
						initialDelaySeconds: 30
						timeoutSeconds:      10
						periodSeconds:       20
					}
					readinessProbe: {
						exec: command: [
							"/bin/sh",
							"-c",
							"mariadb-admin ping -h 127.0.0.1 -u$MYSQL_USER -p$MYSQL_PASSWORD",
						]
						initialDelaySeconds: 20
						timeoutSeconds:      10
						periodSeconds:       10
					}
					resources:       #config.mysql.resources
					securityContext: #config.mysql.securityContext
					volumeMounts: [{
						name:      "mysql-data"
						mountPath: "/var/lib/mysql"
					}]
				}]
				volumes: [{
					name: "mysql-data"
					if #config.persistence.mysqlData.enabled {
						persistentVolumeClaim: claimName: "\(#config.#fullname)-mysql-data"
					}
					if !#config.persistence.mysqlData.enabled {
						emptyDir: {}
					}
				}]
				if #config.mysql.nodeSelector != _|_ {
					nodeSelector: #config.mysql.nodeSelector
				}
				if #config.mysql.affinity != _|_ {
					affinity: #config.mysql.affinity
				}
				if #config.mysql.tolerations != _|_ {
					tolerations: #config.mysql.tolerations
				}
			}
		}
	}
}

#MysqlService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#mysqlServiceName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "mysql"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [{
			name:       "mysql"
			port:       #config.mysql.service.port
			targetPort: "mysql"
			protocol:   "TCP"
		}]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "mysql"
		}
	}
}
