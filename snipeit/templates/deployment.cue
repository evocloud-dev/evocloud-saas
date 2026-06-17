package templates

import (
	"encoding/yaml"
	"uuid"
	"list"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "snipeit"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicaCount
		revisionHistoryLimit: #config.revisionHistoryLimit
		if #config.deploymentStrategy != _|_ {
			strategy: #config.deploymentStrategy
		}
		selector: matchLabels: {
			"app.kubernetes.io/name":     "snipeit"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			let _secretData = {
				if #config.mysql.enabled {
					MYSQL_USER: #config.mysql.mysqlUser
					MYSQL_DATABASE: #config.mysql.mysqlDatabase
					MYSQL_PASSWORD: #config.mysql.mysqlPassword
					MYSQL_PORT_3306_TCP_ADDR: "\(#config.metadata.name)-mysql"
					MYSQL_PORT_3306_TCP_PORT: "3306"
					APP_KEY: #config.config.snipeit.key
				}
				if !#config.mysql.enabled {
					MYSQL_USER: #config.config.mysql.externalDatabase.user
					MYSQL_DATABASE: #config.config.mysql.externalDatabase.name
					MYSQL_PASSWORD: #config.config.mysql.externalDatabase.pass
					MYSQL_PORT_3306_TCP_ADDR: #config.config.mysql.externalDatabase.host
					MYSQL_PORT_3306_TCP_PORT: "\(#config.config.mysql.externalDatabase.port)"
					APP_KEY: #config.config.snipeit.key
				}
				for k, v in #config.config.snipeit.envConfig {
					"\(k)": v
				}
			}
			let _secretChecksum = uuid.SHA1(uuid.ns.DNS, yaml.Marshal(_secretData))

			metadata: {
				labels: {
					"app.kubernetes.io/name":     "snipeit"
					"app.kubernetes.io/instance": #config.metadata.name
				}
				annotations: {
					if #config.config.externalSecrets == "" {
						"checksum/secret": "\(_secretChecksum)"
					}
					for k, v in #config.extraAnnotations {
						"\(k)": v
					}
					if #config.podAnnotations != _|_ {
						#config.podAnnotations
					}
				}
			}
			spec: corev1.#PodSpec & {
				initContainers: [
					{
						name: "config-data"
						image: "busybox"
						command: ["sh", "-c", "find \(#config.persistence.sessions.mountPath) -not -user 1000 -exec chown 1000 {} \\+"]
						volumeMounts: [
							{
								name: "data"
								mountPath: #config.persistence.sessions.mountPath
								subPath: #config.persistence.sessions.subPath
							}
						]
					}
				]

				containers: [
					{
						name:            #config.metadata.name
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						env: [
							{
								name:  "APP_ENV"
								value: #config.config.snipeit.env
							},
							{
								name:  "APP_DEBUG"
								value: "\(#config.config.snipeit.debug)"
							},
							{
								name:  "APP_URL"
								value: #config.config.snipeit.url
							},
							{
								name:  "APP_TIMEZONE"
								value: #config.config.snipeit.timezone
							},
							{
								name:  "APP_LOCALE"
								value: #config.config.snipeit.locale
							},
							{
								name : "APP_KEY"
								value: #config.config.snipeit.key
							},
						]
						envFrom: [
							{
								secretRef: {
									name: #config.metadata.name
								}
							},
							if #config.config.externalSecrets != "" {
								secretRef: {
									name: #config.config.externalSecrets
								}
							}
						]
						ports: [
							{
								name:          "http"
								containerPort: 80
								protocol:      "TCP"
							},
						]
						livenessProbe: {
							httpGet: {
								path: "/health"
								port: 80
							}
							periodSeconds:  15
							timeoutSeconds: 3
						}
						readinessProbe: {
							httpGet: {
								path: "/health"
								port: 80
							}
							periodSeconds:  15
							timeoutSeconds: 3
						}
						if #config.resources != _|_ {
							resources: #config.resources
						}
						volumeMounts: list.Concat([
							[
								{
									name:      "data"
									mountPath: #config.persistence.www.mountPath
									subPath:   #config.persistence.www.subPath
								},
								{
									name:      "data"
									mountPath: #config.persistence.sessions.mountPath
									subPath:   #config.persistence.sessions.subPath
								},
							],
							#config.extraVolumeMounts,
						])
					},
				]
				volumes: list.Concat([
					[
						{
							name: "data"
							if #config.persistence.enabled {
								persistentVolumeClaim: {
									claimName: {
										if #config.persistence.existingClaim != "" {
											#config.persistence.existingClaim
										}
										if #config.persistence.existingClaim == "" {
											#config.metadata.name
										}
									}
								}
							}
							if !#config.persistence.enabled {
								emptyDir: {}
							}
						},
					],
					#config.extraVolumes,
				])
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
			}
		}
	}
}
