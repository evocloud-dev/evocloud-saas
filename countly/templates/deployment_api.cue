package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#DeploymentApi: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-api"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":       "\(#config.metadata.name)-api"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/version":    #config.moduleVersion
			"app.kubernetes.io/managed-by": "timoni"
		}
	}

	_serviceAccountName: string
	if #config.api.serviceAccount.name != "" {
		_serviceAccountName: #config.api.serviceAccount.name
	}
	if #config.api.serviceAccount.name == "" {
		_serviceAccountName: "\(#config.metadata.name)-api"
	}

	_mailSecretName: string
	if #config.config.api.mail.auth.existingSecret != "" {
		_mailSecretName: #config.config.api.mail.auth.existingSecret
	}
	if #config.config.api.mail.auth.existingSecret == "" {
		_mailSecretName: "\(#config.metadata.name)-api"
	}

	_mongodbUrl: string
	if #config.mongodb.enabled {
		_mongodbUrl: "mongodb://\(#config.metadata.name)-mongodb:27017/\(#config.mongodb.auth.database)"
	}
	if !#config.mongodb.enabled {
		_mongodbUrl: "mongodb://\(#config.externalMongodb.hostname):\(#config.externalMongodb.port)/\(#config.externalMongodb.auth.database)"
	}

	spec: appsv1.#DeploymentSpec & {
		replicas: #config.api.replicaCount
		revisionHistoryLimit: #config.api.revisionHistoryLimit
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-api"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "\(#config.metadata.name)-api"
					"app.kubernetes.io/instance": #config.metadata.name
					if #config.api.selectorLabels != _|_ {
						for k, v in #config.api.selectorLabels {
							"\(k)": v
						}
					}
				}
				if #config.api.podAnnotations != _|_ {
					annotations: #config.api.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: _serviceAccountName
				
				if #config.api.imagePullSecrets != _|_ {
					imagePullSecrets: #config.api.imagePullSecrets
				}
				if #config.api.podSecurityContext != _|_ {
					securityContext: #config.api.podSecurityContext
				}
				if #config.api.priorityClassName != "" {
					priorityClassName: #config.api.priorityClassName
				}

				// 🛠️ 1. Declare the temporary emptyDir volume for the app workspace
				volumes: [
					{
						name: "countly-app-volume"
						emptyDir: {}
					}
				]

				// 🛠️ 2. Add the initContainer to move files and shift ownership to non-root (UID 10001)
				initContainers: [
					{
						name:  "prepare-countly-permissions"
						image: "\(#config.api.image.registry)/\(#config.api.image.repository):\(#config.api.image.tag)"
						command: ["sh", "-c", "cp -a /opt/countly/. /mnt/countly && chown -R 65510:65510 /mnt/countly"]
						securityContext: {
							runAsUser: 0 // Root access required temporarily only to copy and override directory permissions
						}
						volumeMounts: [
							{
								name:      "countly-app-volume"
								mountPath: "/mnt/countly"
							}
						]
					}
				]

				containers: [
					{
						name:            "\(#config.metadata.name)-api"
						image:           "\(#config.api.image.registry)/\(#config.api.image.repository):\(#config.api.image.tag)"
						imagePullPolicy: #config.api.image.pullPolicy
						
						let envMap = {
							"COUNTLY_PLUGINS": #config.config.plugins
							"COUNTLY_CONFIG_API_FILESTORAGE": #config.config.api.filestorage
							"COUNTLY_CONFIG_API_API_WORKERS": #config.config.api.workerCount
							"COUNTLY_CONFIG__MONGODB": _mongodbUrl
							"NODE_OPTIONS": #config.config.nodeOptions
							if #config.hostname != "" {
								"COUNTLY_CONFIG_HOSTNAME": #config.hostname
							}
							if #config.config.api.mail.enabled {
								if #config.config.api.mail.host != "" {
									"COUNTLY_CONFIG__MAIL_CONFIG_HOST": #config.config.api.mail.host
								}
								if #config.config.api.mail.port != 0 {
									"COUNTLY_CONFIG__MAIL_CONFIG_PORT": "\(#config.config.api.mail.port)"
								}
								if #config.config.api.mail.auth.username != "" {
									"COUNTLY_CONFIG__MAIL_CONFIG_AUTH_USER": #config.config.api.mail.auth.username
								}
								if #config.config.api.mail.from != "" {
									"COUNTLY_CONFIG__MAIL_STRINGS_FROM": #config.config.api.mail.from
								}
							}
						}

						env: [
							for k, v in envMap {
								name: k
								value: v
							},
							if #config.config.api.mail.enabled && (#config.config.api.mail.auth.existingSecret != "" || #config.config.api.mail.auth.password != "") {
								{
									name: "COUNTLY_CONFIG__MAIL_CONFIG_AUTH_PASS"
									valueFrom: corev1.#EnvVarSource & {
										secretKeyRef: corev1.#SecretKeySelector & {
											name: _mailSecretName
											key:  "mail-password"
										}
									}
								}
							},
							for x in #config.extraEnv { x },
							for x in #config.api.extraEnv { x }
						]

						ports: [
							{
								name:          "http"
								containerPort: 3001
								protocol:      "TCP"
							},
						]
						volumeMounts: [
							{
								name:      "countly-app-volume"
								mountPath: "/opt/countly/"
							}
						]

						livenessProbe: corev1.#Probe & {
							httpGet: {
								path: "/o/ping"
								port: 3001
							}
							failureThreshold:    #config.api.livenessProbe.failureThreshold
							initialDelaySeconds: #config.api.livenessProbe.initialDelaySeconds
							periodSeconds:       #config.api.livenessProbe.periodSeconds
							successThreshold:    #config.api.livenessProbe.successThreshold
							timeoutSeconds:      #config.api.livenessProbe.timeoutSeconds
						}

						readinessProbe: corev1.#Probe & {
							httpGet: {
								path: "/o/ping"
								port: 3001
							}
							failureThreshold:    #config.api.readinessProbe.failureThreshold
							initialDelaySeconds: #config.api.readinessProbe.initialDelaySeconds
							periodSeconds:       #config.api.readinessProbe.periodSeconds
							successThreshold:    #config.api.readinessProbe.successThreshold
							timeoutSeconds:      #config.api.readinessProbe.timeoutSeconds
						}

						if #config.api.resources != _|_ {
							resources: #config.api.resources
						}
						if #config.api.securityContext != _|_ {
							securityContext: #config.api.securityContext
						}
					},
				]

				if #config.api.nodeSelector != _|_ {
					nodeSelector: #config.api.nodeSelector
				}
				if #config.api.affinity != _|_ {
					affinity: #config.api.affinity
				}
				if #config.api.tolerations != _|_ {
					tolerations: #config.api.tolerations
				}
			}
		}
	}
}
