package templates

import (
	"list"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config:    #Config
	#cmName?:   string
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		strategy: type: #config.strategy
		if !#config.autoscaling.enabled {
			replicas: #config.replicaCount
		}
		revisionHistoryLimit: #config.revisionHistoryLimit
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: *#config.serviceAccount.name | string
				if #config.serviceAccount.name == "" {
					serviceAccountName: #config.metadata.name
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.initContainers != _|_ && len(#config.initContainers) > 0 {
					initContainers: #config.initContainers
				}
				containers: [
					{
						name:            "umami"
						image:           #config.#imageRef
						imagePullPolicy: #config.image.pullPolicy
						env: list.Concat([[
							// Database Settings
							{
								name: "DATABASE_URL"
								valueFrom: secretKeyRef: {
									if #config.database.existingSecret == "" {
										name: #config.metadata.name + "-db"
										key:  "database-url"
									}
									if #config.database.existingSecret != "" {
										name: #config.database.existingSecret
										if #config.database.databaseUrlKey == "" {
											key: "database-url"
										}
										if #config.database.databaseUrlKey != "" {
											key: #config.database.databaseUrlKey
										}
									}
								}
							},
							// App Settings
							{
								name: "APP_SECRET"
								valueFrom: secretKeyRef: {
									if #config.umami.appSecret.existingSecret == "" {
										name: #config.metadata.name + "-app-secret"
										key:  "app-secret"
									}
									if #config.umami.appSecret.existingSecret != "" {
										name: #config.umami.appSecret.existingSecret
										key:  "app-secret"
									}
								}
							},
							if #config.umami.clientIpHeader != "" {
								name:  "CLIENT_IP_HEADER"
								value: #config.umami.clientIpHeader
							},
							{
								name:  "CLOUD_MODE"
								value: #config.umami.cloudMode
							},
							if #config.umami.collectApiEndpoint != "" {
								name:  "COLLECT_API_ENDPOINT"
								value: #config.umami.collectApiEndpoint
							},
							{
								name:  "CORS_MAX_AGE"
								value: #config.umami.corsMaxAge
							},
							{
								name:  "DISABLE_BOT_CHECK"
								value: #config.umami.disableBotCheck
							},
							if !#config.umami.removeDisableLoginEnv {
								name:  "DISABLE_LOGIN"
								value: #config.umami.disableLogin
							},
							{
								name:  "DISABLE_TELEMETRY"
								value: #config.umami.disableTelemetry
							},
							{
								name:  "DISABLE_UPDATES"
								value: #config.umami.disableUpdates
							},
							{
								name:  "FORCE_SSL"
								value: #config.umami.forceSSL
							},
							{
								name:  "HOSTNAME"
								value: #config.umami.hostname
							},
							if #config.umami.ignoreHostname != "" {
								name:  "IGNORE_HOSTNAME"
								value: #config.umami.ignoreHostname
							},
							if #config.umami.ignoredIpAddresses != "" {
								name:  "IGNORE_IP"
								value: #config.umami.ignoredIpAddresses
							},
							{
								name:  "LOG_QUERY"
								value: #config.umami.logQuery
							},
							{
								name:  "PORT"
								value: "\(#config.service.port)"
							},
							{
								name:  "REMOVE_TRAILING_SLASH"
								value: #config.umami.removeTrailingSlash
							},
							{
								name:  "TRACKER_SCRIPT_NAME"
								value: #config.umami.trackerScriptName
							},
						], #config.extraEnv])
						ports: [
							{
								name:          "http"
								containerPort: #config.service.port
								protocol:      "TCP"
							},
						]
						livenessProbe: #config.livenessProbe & {
							if #config.livenessProbe.httpGet != _|_ {
								httpGet: port: #config.livenessProbe.httpGet.port | #config.service.port
							}
						}
						readinessProbe: #config.readinessProbe & {
							if #config.readinessProbe.httpGet != _|_ {
								httpGet: port: #config.readinessProbe.httpGet.port | #config.service.port
							}
						}
						startupProbe: #config.startupProbe & {
							if #config.startupProbe.httpGet != _|_ {
								httpGet: port: #config.startupProbe.httpGet.port | #config.service.port
							}
						}
						if #config.resources != _|_ {
							resources: #config.resources
						}
						if #config.securityContext != _|_ {
							securityContext: #config.securityContext
						}
						if #cmName != _|_ {
							volumeMounts: [
								{
									name:      "custom-script"
									mountPath: #config.umami.customScript.mountPath
									subPath:   #config.umami.customScript.key
								},
							]
						}
					},
				]
				if #cmName != _|_ {
					volumes: [
						{
							name: "custom-script"
							configMap: name: #cmName
						},
					]
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
			}
		}
	}
}
