package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.#serviceName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.autoscaling.enabled {
			replicas: #config.replicas
		}
		selector: matchLabels: #config.selector.labels
		if #config.deployment.updateStrategy != _|_ {
			strategy: #config.deployment.updateStrategy
		}
		template: {
			metadata: {
				if len(#config.podAnnotations) > 0 {
					annotations: #config.podAnnotations
				}
				labels: #config.selector.labels
			}
			spec: corev1.#PodSpec & {
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				automountServiceAccountToken: #config.automountServiceAccountToken
				serviceAccountName:           #config.#serviceAccountName
				securityContext:    #config.podSecurityContext
				containers: [
					{
						name:            #config.#appName
						securityContext: #config.securityContext
						image:           #config.#imageReference
						volumeMounts: [
							{
								name:      "limesurvey-main"
								mountPath: "/var/www/html/plugins"
								subPath:   "plugins"
							},
							{
								name:      "limesurvey-main"
								mountPath: "/var/www/html/upload"
								subPath:   "upload"
							},
							{
								name:      "limesurvey-main"
								mountPath: "/var/lime/sessions"
								subPath:   "sessions"
							},
							{
								name:      "limesurvey-main"
								mountPath: "/var/www/html/application/config"
								subPath:   "config"
							},
							for v in #config.extraVolumeMounts {
								name:      v.name
								mountPath: v.mountPath
								subPath:   v.subPath
								if v.readOnly != _|_ {
									readOnly: v.readOnly
								}
							},
							for v in #config.extraEmptyDirMounts {
								name:      v.name
								mountPath: v.mountPath
							},
						]
						env: [
							{
								name:  "LIMESURVEY_DB_TYPE"
								value: #config.#dbType
							},
							{
								name:  "LIMESURVEY_DB_HOST"
								value: #config.#dbHost
							},
							{
								name:  "LIMESURVEY_DB_PORT"
								value: #config.#dbPort
							},
							{
								name:  "LIMESURVEY_DB_USER"
								value: #config.#dbUser
							},
							{
								name: "LIMESURVEY_DB_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#databaseSecretName
									key:  "mariadb-password"
								}
							},
							{
								name:  "LIMESURVEY_DB_NAME"
								value: #config.#dbName
							},
							{
								name:  "LIMESURVEY_ADMIN_USER"
								value: #config.limesurvey.admin.username
							},
							{
								name: "LIMESURVEY_ADMIN_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#secretName
									key:  "limesurvey-admin-password"
								}
							},
							{
								name:  "LIMESURVEY_ADMIN_NAME"
								value: #config.limesurvey.admin.name
							},
							{
								name:  "LIMESURVEY_ADMIN_EMAIL"
								value: #config.limesurvey.admin.email
							},
							{
								name:  "LIMESURVEY_TABLE_PREFIX"
								value: #config.limesurvey.tablePrefix
							},
							{
								name:  "LIMESURVEY_DEBUG"
								value: #config.limesurvey.debug
							},
							{
								name:  "LIMESURVEY_SQL_DEBUG"
								value: #config.limesurvey.sqlDebug
							},
							{
								name:  "LIMESURVEY_USE_INNODB"
								value: #config.limesurvey.useInnodb
							},
							{
								name:  "LIMESURVEY_DB_SESSIONS"
								value: #config.limesurvey.dbSessions
							},
							{
								name:  "LIMESURVEY_PHP_SESSION_SAVE_HANDLER"
								value: #config.limesurvey.phpSessionSaveHandler
							},
							{
								name:  "LIMESURVEY_PHP_SESSION_SAVE_PATH"
								value: #config.limesurvey.phpSessionSavePath
							},
							{
								name:  "LIMESURVEY_DONT_SHOW_SCRIPT_NAME"
								value: #config.limesurvey.dontShowScriptName
							},
							{
								name:  "LIMESURVEY_DONT_UPDATE"
								value: #config.limesurvey.dontUpdate
							},
							{
								name:  "TZ"
								value: #config.limesurvey.tz
							},
							{
								name:  "LIMESURVEY_SMTP_HOST"
								value: #config.limesurvey.smtp.host
							},
							if #config.limesurvey.smtp.user != "" || #config.limesurvey.smtp.existingSecret != "" {
								{
									name: "LIMESURVEY_SMTP_USER"
									valueFrom: secretKeyRef: {
										name: #config.#smtpSecretName
										key:  "limesurvey-smtp-user"
									}
								}
							},
							{
								name: "LIMESURVEY_SMTP_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#smtpSecretName
									key:  "limesurvey-smtp-password"
								}
							},
							{
								name:  "LIMESURVEY_SMTP_SSL"
								value: #config.limesurvey.smtp.ssl
							},
							{
								name:  "LIMESURVEY_FROM_EMAIL"
								value: #config.limesurvey.smtp.from_email
							},
							{
								name:  "LIMESURVEY_SMTP_DEBUG"
								value: #config.limesurvey.smtp.debug
							},
							{
								name:  "LIMESURVEY_API_MODE"
								value: #config.limesurvey.apiMode
							},
						]
						imagePullPolicy: #config.image.pullPolicy
						if #config.deployment.lifecycleHooks != _|_ {
							lifecycle: #config.deployment.lifecycleHooks
						}
						ports: [
							{
								name:          "http"
								containerPort: #config.service.port
								protocol:      "TCP"
							},
						]
						if #config.limesurvey.startupProbe.enabled {
							startupProbe: {
								httpGet:             #config.limesurvey.startupProbe.httpGet
								initialDelaySeconds: #config.limesurvey.startupProbe.initialDelaySeconds
								periodSeconds:       #config.limesurvey.startupProbe.periodSeconds
								timeoutSeconds:      #config.limesurvey.startupProbe.timeoutSeconds
								successThreshold:    #config.limesurvey.startupProbe.successThreshold
								failureThreshold:    #config.limesurvey.startupProbe.failureThreshold
							}
						}
						if #config.limesurvey.livenessProbe.enabled {
							livenessProbe: {
								httpGet:             #config.limesurvey.livenessProbe.httpGet
								initialDelaySeconds: #config.limesurvey.livenessProbe.initialDelaySeconds
								periodSeconds:       #config.limesurvey.livenessProbe.periodSeconds
								timeoutSeconds:      #config.limesurvey.livenessProbe.timeoutSeconds
								successThreshold:    #config.limesurvey.livenessProbe.successThreshold
								failureThreshold:    #config.limesurvey.livenessProbe.failureThreshold
							}
						}
						if #config.limesurvey.readinessProbe.enabled {
							readinessProbe: {
								httpGet:             #config.limesurvey.readinessProbe.httpGet
								initialDelaySeconds: #config.limesurvey.readinessProbe.initialDelaySeconds
								periodSeconds:       #config.limesurvey.readinessProbe.periodSeconds
								timeoutSeconds:      #config.limesurvey.readinessProbe.timeoutSeconds
								successThreshold:    #config.limesurvey.readinessProbe.successThreshold
								failureThreshold:    #config.limesurvey.readinessProbe.failureThreshold
							}
						}
						resources: #config.resources
					},
				]
				initContainers: [
					{
						name:            "db-isalive"
						securityContext: #config.initContainerSecurityContext
						image:           #config.#imageReference
						env: [
							{
								name:  "LIMESURVEY_DB_HOST"
								value: #config.#dbHost
							},
							{
								name:  "LIMESURVEY_DB_PORT"
								value: #config.#dbPort
							},
						]
						imagePullPolicy: #config.image.pullPolicy
						command: [
							"sh",
							"-c",
							"until nc -z -v -w30 ${LIMESURVEY_DB_HOST} ${LIMESURVEY_DB_PORT}; do echo waiting for db; sleep 5; done;",
						]
					},
				]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 {
					affinity: #config.affinity
				}
				if len(#config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				volumes: [
					{
						name: "limesurvey-main"
						if #config.persistence.enabled {
							persistentVolumeClaim: {
								claimName: #config.#pvcClaimName
							}
						}
						if !#config.persistence.enabled {
							emptyDir: {}
						}
					},
					for v in #config.extraVolumeMounts {
						name: v.name
						if v.existingClaim != "" {
							persistentVolumeClaim: {
								claimName: v.existingClaim
							}
						}
						if v.existingClaim == "" && v.hostPath != "" {
							hostPath: {
								path: v.hostPath
							}
						}
						if v.existingClaim == "" && v.hostPath == "" && v.configMap != "" {
							configMap: {
								name: v.configMap
								if v.items != _|_ {
									items: v.items
								}
							}
						}
						if v.existingClaim == "" && v.hostPath == "" && v.configMap == "" {
							emptyDir: {}
						}
					},
					for v in #config.extraEmptyDirMounts {
						name:     v.name
						emptyDir: {}
					},
				]
			}
		}
	}
}
