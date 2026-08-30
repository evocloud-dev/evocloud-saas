package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		let pvcClaimName = [
			if #config.persistence.existingClaim != "" {
				#config.persistence.existingClaim
			},
			"\(#config.fullname)-data",
		][0]

		replicas: 1
		selector: {
			matchLabels: #config.selector.labels
		}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: #config.selector.labels & #config.podLabels
				if len(#config.podAnnotations) > 0 {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: [
					if #config.automountServiceAccountToken != _|_ {
						#config.automountServiceAccountToken
					},
					false,
				][0]
				serviceAccountName: #config.serviceAccountName
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds

				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}

				if #config.databaseMode != "sqlite" {
					initContainers: [{
						name:  "wait-for-db"
						image: "docker.io/library/busybox:1.37"
						command: [
							"sh",
							"-c",
							"""
							echo "Waiting for \(#config.databaseHost):\(#config.databasePort) ..."
							until nc -z -w2 \(#config.databaseHost) \(#config.databasePort); do
							  sleep 2
							done
							echo "Database is reachable."
							""",
						]
					}]
				}

				containers: [{
					name:            "answer"
					image:           "\(#config.image.repository):\(#config.image.tag)"
					imagePullPolicy: #config.image.pullPolicy
					if #config.securityContext != _|_ {
						securityContext: #config.securityContext
					}
					ports: [{
						name:          "http"
						containerPort: 80
						protocol:      "TCP"
					}]
					env: [
						if #config.answer.autoInstall {
							name:  "AUTO_INSTALL"
							value: "true"
						},
						if #config.answer.autoInstall {
							name:  "DB_TYPE"
							value: #config.dbType
						},
						if #config.answer.autoInstall && #config.databaseMode != "sqlite" {
							name:  "DB_HOST"
							value: #config.dbHostPort
						},
						if #config.answer.autoInstall && #config.databaseMode != "sqlite" {
							name:  "DB_NAME"
							value: #config.databaseName
						},
						if #config.answer.autoInstall && #config.databaseMode != "sqlite" {
							name:  "DB_USERNAME"
							value: #config.databaseUsername
						},
						if #config.answer.autoInstall && #config.databaseMode != "sqlite" {
							name: "DB_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #config.databaseSecretName
								key:  #config.databaseSecretKey
							}
						},
						if #config.answer.autoInstall && #config.databaseMode == "sqlite" {
							name:  "DB_FILE"
							value: #config.database.sqlite.file
						},
						if #config.answer.autoInstall {
							name:  "LANGUAGE"
							value: #config.answer.language
						},
						if #config.answer.autoInstall {
							name:  "SITE_NAME"
							value: #config.answer.siteName
						},
						if #config.answer.autoInstall {
							name:  "SITE_URL"
							value: #config.siteUrl
						},
						if #config.answer.autoInstall {
							name:  "CONTACT_EMAIL"
							value: #config.answer.contactEmail
						},
						if #config.answer.autoInstall {
							name:  "EXTERNAL_CONTENT_DISPLAY"
							value: #config.answer.externalContentDisplay
						},
						if #config.answer.autoInstall {
							name:  "ADMIN_NAME"
							value: #config.admin.name
						},
						if #config.answer.autoInstall {
							name: "ADMIN_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #config.adminSecretName
								key:  #config.adminSecretKey
							}
						},
						if #config.answer.autoInstall {
							name:  "ADMIN_EMAIL"
							value: #config.admin.email
						},
						{
							name:  "LOG_LEVEL"
							value: #config.answer.logLevel
						},
						{
							name:  "NEW_QUESTION_NOTIFICATION_EMAIL_QUEUE_SIZE"
							value: "\( #config.answer.notifications.newQuestionEmail.queueSize )"
						},
						{
							name:  "NEW_QUESTION_NOTIFICATION_EMAIL_SEND_INTERVAL_SECONDS"
							value: "\( #config.answer.notifications.newQuestionEmail.sendIntervalSeconds )"
						},
						for e in #config.answer.extraEnv {e},
					]

					if #config.startupProbe.enabled {
						startupProbe: {
							httpGet: {
								path: #config.startupProbe.path
								port: "http"
							}
							initialDelaySeconds: #config.startupProbe.initialDelaySeconds
							periodSeconds:       #config.startupProbe.periodSeconds
							timeoutSeconds:      #config.startupProbe.timeoutSeconds
							failureThreshold:    #config.startupProbe.failureThreshold
						}
					}
					if #config.livenessProbe.enabled {
						livenessProbe: {
							httpGet: {
								path: #config.livenessProbe.path
								port: "http"
							}
							initialDelaySeconds: #config.livenessProbe.initialDelaySeconds
							periodSeconds:       #config.livenessProbe.periodSeconds
							timeoutSeconds:      #config.livenessProbe.timeoutSeconds
							failureThreshold:    #config.livenessProbe.failureThreshold
						}
					}
					if #config.readinessProbe.enabled {
						readinessProbe: {
							httpGet: {
								path: #config.readinessProbe.path
								port: "http"
							}
							initialDelaySeconds: #config.readinessProbe.initialDelaySeconds
							periodSeconds:       #config.readinessProbe.periodSeconds
							timeoutSeconds:      #config.readinessProbe.timeoutSeconds
							failureThreshold:    #config.readinessProbe.failureThreshold
						}
					}

					if #config.resources != _|_ {
						resources: #config.resources
					}

					volumeMounts: [
						{
							name:      "data"
							mountPath: "/data"
						},
						for vm in #config.extraVolumeMounts {vm},
					]
				}]

				volumes: [
					{
						name: "data"
						if #config.persistence.enabled {
							persistentVolumeClaim: {
								claimName: pvcClaimName
							}
						}
						if !#config.persistence.enabled {
							emptyDir: {}
						}
					},
					for v in #config.extraVolumes {v},
				]
			}
		}
	}
}
