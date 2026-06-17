package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#mysqlSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.mysql.labels
	}
	type: "Opaque"
	stringData: {
		if #config.mysql.mysqlRootPassword != "" || !#config.mysql.allowEmptyRootPassword {
			"mysql-root-password": #config.mysql.mysqlRootPassword
		}
		if #config.mysql.mysqlPassword != "" || !#config.mysql.allowEmptyRootPassword {
			"mysql-password": #config.mysql.mysqlPassword
		}
	}
}

#MysqlConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-mysql-configuration"
		namespace: #config.metadata.namespace
		labels:    #config.mysql.labels
	}
	data: #config.mysql.configurationFiles
}

#MysqlInitializationConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-mysql-initialization"
		namespace: #config.metadata.namespace
		labels:    #config.mysql.labels
	}
	data: #config.mysql.initializationFiles
}

#MysqlServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      #config.mysql.serviceAccountName
		namespace: #config.metadata.namespace
		labels:    #config.mysql.labels
	}
}

#MysqlDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.mysql.labels
		annotations: #config.mysql.deploymentAnnotations
	}
	spec: {
		strategy: type: "Recreate"
		selector: matchLabels: #config.mysql.selector
		template: {
			metadata: {
				labels: #config.mysql.selector & #config.mysql.podLabels
				annotations: #config.mysql.podAnnotations
			}
			spec: {
				if #config.mysql.schedulerName != _|_ {
					schedulerName: #config.mysql.schedulerName
				}
				if len(#config.mysql.imagePullSecrets) > 0 {
					imagePullSecrets: #config.mysql.imagePullSecrets
				}
				if #config.mysql.priorityClassName != _|_ {
					priorityClassName: #config.mysql.priorityClassName
				}
				if #config.mysql.securityContext.enabled {
					securityContext: {
						fsGroup:   #config.mysql.securityContext.fsGroup
						runAsUser: #config.mysql.securityContext.runAsUser
					}
				}
				serviceAccountName: #config.mysql.serviceAccountName
				initContainers: [
					{
						name:            "remove-lost-found"
						image:           "\(#config.mysql.busybox.image):\(#config.mysql.busybox.tag)"
						imagePullPolicy: #config.mysql.imagePullPolicy
						resources:       #config.mysql.initContainer.resources
						command: ["rm", "-fr", "/var/lib/mysql/lost+found"]
						volumeMounts: [{
							name:      "data"
							mountPath: "/var/lib/mysql"
							if #config.mysql.persistence.subPath != _|_ {
								subPath: #config.mysql.persistence.subPath
							}
						}]
					},
					for c in #config.mysql.extraInitContainers {c},
				]
				containers: [
					{
						name:            "\(#config.metadata.name)-mysql"
						image:           "\(#config.mysql.image):\(#config.mysql.imageTag)"
						imagePullPolicy: #config.mysql.imagePullPolicy
						if len(#config.mysql.args) > 0 {
							args: #config.mysql.args
						}
						resources: #config.mysql.resources
						env: [
							if #config.mysql.mysqlAllowEmptyPassword {
								{name: "MYSQL_ALLOW_EMPTY_PASSWORD", value: "true"}
							},
							if !(#config.mysql.allowEmptyRootPassword && #config.mysql.mysqlRootPassword == "") {
								{
									name: "MYSQL_ROOT_PASSWORD"
									valueFrom: secretKeyRef: {
										name: #config.mysql.secretName
										key:  "mysql-root-password"
										if #config.mysql.mysqlAllowEmptyPassword {
											optional: true
										}
									}
								}
							},
							if !(#config.mysql.allowEmptyRootPassword && #config.mysql.mysqlPassword == "") {
								{
									name: "MYSQL_PASSWORD"
									valueFrom: secretKeyRef: {
										name: #config.mysql.secretName
										key:  "mysql-password"
										if #config.mysql.mysqlAllowEmptyPassword || #config.mysql.mysqlUser == "" {
											optional: true
										}
									}
								}
							},
							{name: "MYSQL_USER", value: #config.mysql.mysqlUser},
							{name: "MYSQL_DATABASE", value: #config.mysql.mysqlDatabase},
							if #config.mysql.timezone != _|_ {
								{name: "TZ", value: #config.mysql.timezone}
							},
							for env in #config.mysql.extraEnvVars {env},
						]
						ports: [
							{name: "mysql", containerPort: 3306},
						]
						livenessProbe: {
							exec: {
								if #config.mysql.mysqlAllowEmptyPassword {
									command: ["mysqladmin", "ping"]
								}
								if !#config.mysql.mysqlAllowEmptyPassword {
									command: ["sh", "-c", "mysqladmin ping -u root -p${MYSQL_ROOT_PASSWORD}"]
								}
							}
							initialDelaySeconds: #config.mysql.livenessProbe.initialDelaySeconds
							periodSeconds:      #config.mysql.livenessProbe.periodSeconds
							timeoutSeconds:     #config.mysql.livenessProbe.timeoutSeconds
							successThreshold:   #config.mysql.livenessProbe.successThreshold
							failureThreshold:   #config.mysql.livenessProbe.failureThreshold
						}
						readinessProbe: {
							exec: {
								if #config.mysql.mysqlAllowEmptyPassword {
									command: ["mysqladmin", "ping"]
								}
								if !#config.mysql.mysqlAllowEmptyPassword {
									command: ["sh", "-c", "mysqladmin ping -u root -p${MYSQL_ROOT_PASSWORD}"]
								}
							}
							initialDelaySeconds: #config.mysql.readinessProbe.initialDelaySeconds
							periodSeconds:      #config.mysql.readinessProbe.periodSeconds
							timeoutSeconds:     #config.mysql.readinessProbe.timeoutSeconds
							successThreshold:   #config.mysql.readinessProbe.successThreshold
							failureThreshold:   #config.mysql.readinessProbe.failureThreshold
						}
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/var/lib/mysql"
								if #config.mysql.persistence.subPath != _|_ {
									subPath: #config.mysql.persistence.subPath
								}
							},
							for key, _ in #config.mysql.configurationFiles {
								{
									name:      "configurations"
									mountPath: "\(#config.mysql.configurationFilesPath)\(key)"
									subPath:   key
								}
							},
							if len([for key, _ in #config.mysql.initializationFiles {key}]) > 0 {
								{name: "migrations", mountPath: "/docker-entrypoint-initdb.d"}
							},
							if #config.mysql.ssl.enabled {
								{name: "certificates", mountPath: "/ssl"}
							},
							for mount in #config.mysql.extraVolumeMounts {mount},
						]
					},
					if #config.mysql.metrics.enabled {
						{
							name:            "metrics"
							image:           "\(#config.mysql.metrics.image):\(#config.mysql.metrics.imageTag)"
							imagePullPolicy: #config.mysql.metrics.imagePullPolicy
							if !#config.mysql.mysqlAllowEmptyPassword {
								env: [{
									name: "MYSQL_ROOT_PASSWORD"
									valueFrom: secretKeyRef: {
										name: #config.mysql.secretName
										key:  "mysql-root-password"
									}
								}]
							}
							if #config.mysql.mysqlAllowEmptyPassword {
								command: ["sh", "-c", "DATA_SOURCE_NAME=\"root@(localhost:3306)/\" /bin/mysqld_exporter"]
							}
							if !#config.mysql.mysqlAllowEmptyPassword {
								command: ["sh", "-c", "DATA_SOURCE_NAME=\"root:$MYSQL_ROOT_PASSWORD@(localhost:3306)/\" /bin/mysqld_exporter"]
							}
							args:  #config.mysql.metrics.flags
							ports: [{name: "metrics", containerPort: 9104}]
							livenessProbe: {
								httpGet: {
									path: "/"
									port: "metrics"
								}
								initialDelaySeconds: #config.mysql.metrics.livenessProbe.initialDelaySeconds
								timeoutSeconds:     #config.mysql.metrics.livenessProbe.timeoutSeconds
							}
							readinessProbe: {
								httpGet: {
									path: "/"
									port: "metrics"
								}
								initialDelaySeconds: #config.mysql.metrics.readinessProbe.initialDelaySeconds
								timeoutSeconds:     #config.mysql.metrics.readinessProbe.timeoutSeconds
							}
							resources: #config.mysql.metrics.resources
						}
					},
				]
				volumes: [
					if len([for key, _ in #config.mysql.configurationFiles {key}]) > 0 {
						{
							name: "configurations"
							configMap: name: "\(#config.metadata.name)-mysql-configuration"
						}
					},
					if len([for key, _ in #config.mysql.initializationFiles {key}]) > 0 {
						{
							name: "migrations"
							configMap: name: "\(#config.metadata.name)-mysql-initialization"
						}
					},
					if #config.mysql.ssl.enabled {
						{
							name: "certificates"
							secret: secretName: #config.mysql.ssl.secret
						}
					},
					if #config.mysql.persistence.enabled && #config.mysql.persistence.existingClaim != "" {
						{
							name: "data"
							persistentVolumeClaim: claimName: #config.mysql.persistence.existingClaim
						}
					},
					if #config.mysql.persistence.enabled && #config.mysql.persistence.existingClaim == "" {
						{
							name: "data"
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-mysql"
						}
					},
					if !#config.mysql.persistence.enabled {
						{name: "data", emptyDir: {}}
					},
					for volume in #config.mysql.extraVolumes {volume},
				]
				nodeSelector: #config.mysql.nodeSelector
				affinity:     #config.mysql.affinity
				if len(#config.mysql.tolerations) > 0 {
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
		name:      "\(#config.metadata.name)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.mysql.labels
		annotations: #config.mysql.service.annotations & {
			if #config.mysql.metrics.enabled {
				for k, v in #config.mysql.metrics.annotations {
					"\(k)": v
				}
			}
		}
	}
	spec: {
		type: #config.mysql.service.type
		if #config.mysql.service.type == "LoadBalancer" && #config.mysql.service.loadBalancerIP != _|_ {
			loadBalancerIP: #config.mysql.service.loadBalancerIP
		}
		ports: [
			{
				name:       "mysql"
				port:       #config.mysql.service.port
				targetPort: "mysql"
				if #config.mysql.service.nodePort != _|_ {
					nodePort: #config.mysql.service.nodePort
				}
			},
			if #config.mysql.metrics.enabled {
				{
					name:       "metrics"
					port:       9104
					targetPort: "metrics"
				}
			},
		]
		selector: #config.mysql.selector
	}
}

#MysqlSSLSecret: corev1.#Secret & {
	#config: #Config
	#certificate: {
		name: string
		ca:   string
		cert: string
		key:  string
	}
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #certificate.name
		namespace: #config.metadata.namespace
		labels:    #config.mysql.labels
	}
	type: "Opaque"
	stringData: {
		"ca.pem":          #certificate.ca
		"server-cert.pem": #certificate.cert
		"server-key.pem":  #certificate.key
	}
}

#MysqlServiceMonitor: {
	#config: #Config
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      "\(#config.metadata.name)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.mysql.labels & #config.mysql.metrics.serviceMonitor.additionalLabels
	}
	spec: {
		endpoints: [{port: "metrics", interval: "30s"}]
		namespaceSelector: matchNames: [#config.metadata.namespace]
		selector: matchLabels: #config.mysql.selector
	}
}


#MysqlTestConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-mysql-test"
		namespace: #config.metadata.namespace
		labels:    #config.mysql.labels
	}
	data: {
		"run.sh": ""
	}
}


#MysqlPersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config: #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-mysql"
		namespace: #config.metadata.namespace
		labels:    #config.mysql.labels
		annotations: #config.mysql.persistence.annotations
	}
	spec: {
		accessModes: [#config.mysql.persistence.accessMode]
		resources: requests: storage: #config.mysql.persistence.size
		if #config.mysql.persistence.storageClass != _|_ {
			if #config.mysql.persistence.storageClass == "-" {
				storageClassName: ""
			}
			if #config.mysql.persistence.storageClass != "-" {
				storageClassName: #config.mysql.persistence.storageClass
			}
		}
	}
}