package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#ServerDeployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      *"\((#config.metadata.name))-server" | string
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.server.annotations != _|_ {
			annotations: #config.server.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.server.autoscaling.enabled {
			replicas: #config.server.replicas
		}
		revisionHistoryLimit: #config.server.revisionHistoryLimit
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "server"
		}
		if #config.server.deploymentStrategy != _|_ {
			strategy: #config.server.deploymentStrategy
		}
		template: {
			metadata: {
				labels: #config.metadata.labels & #config.server.podLabels & {
					"app.kubernetes.io/component": "server"
				}
				if #config.server.podAnnotations != _|_ {
					annotations: #config.server.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: *"\((#config.metadata.name))-server" | string
				if !#config.server.serviceAccount.create && #config.server.serviceAccount.name != "" {
					serviceAccountName: #config.server.serviceAccount.name
				}
				if !#config.server.serviceAccount.create && #config.server.serviceAccount.name == "" {
					serviceAccountName: "default"
				}
				automountServiceAccountToken: false
				enableServiceLinks:           false

				if #config.server.podSecurityContext != _|_ {
					securityContext: #config.server.podSecurityContext
				}
				if #config.server.dnsPolicy != null {
					dnsPolicy: #config.server.dnsPolicy
				}
				if #config.server.dnsConfig != null {
					dnsConfig: #config.server.dnsConfig
				}
				if #config.server.priorityClassName != "" {
					priorityClassName: #config.server.priorityClassName
				}
				if #config.server.hostNetwork {
					hostNetwork: true
				}

				#realRegistry: {
					if #config.global.image.registry != null && #config.global.image.registry != "" {
						#config.global.image.registry
					}
					if #config.global.image.registry == null || #config.global.image.registry == "" {
						#config.server.container.image.registry
					}
				}
				#realTag: {
					if #config.server.container.image.tag != "" {
						#config.server.container.image.tag
					}
					if #config.server.container.image.tag == "" {
						#config.moduleVersion
					}
				}
				#imageRef: "\(#realRegistry)/\(#config.server.container.image.repository):\(#realTag)"

				#realPullPolicy: {
					if #config.global.image.pullPolicy != null && #config.global.image.pullPolicy != "" {
						#config.global.image.pullPolicy
					}
					if #config.global.image.pullPolicy == null || #config.global.image.pullPolicy == "" {
						if #config.server.container.image.pullPolicy != _|_ && #config.server.container.image.pullPolicy != "" {
							#config.server.container.image.pullPolicy
						}
						if #config.server.container.image.pullPolicy == _|_ || #config.server.container.image.pullPolicy == "" {
							"IfNotPresent"
						}
					}
				}

				#realImagePullSecrets: {
					if len(#config.server.imagePullSecrets) > 0 {
						#config.server.imagePullSecrets
					}
					if len(#config.server.imagePullSecrets) == 0 {
						#config.global.imagePullSecrets
					}
				}
				if len(#realImagePullSecrets) > 0 {
					imagePullSecrets: #realImagePullSecrets
				}

				if #config.server.nodeSelector != _|_ && len(#config.server.nodeSelector) > 0 {
					nodeSelector: #config.server.nodeSelector
				}
				if (#config.server.nodeSelector == _|_ || len(#config.server.nodeSelector) == 0) && len(#config.global.nodeSelector) > 0 {
					nodeSelector: #config.global.nodeSelector
				}

				if #config.server.tolerations != _|_ && len(#config.server.tolerations) > 0 {
					tolerations: #config.server.tolerations
				}
				if (#config.server.tolerations == _|_ || len(#config.server.tolerations) == 0) && len(#config.global.tolerations) > 0 {
					tolerations: #config.global.tolerations
				}

				if #config.server.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.server.topologySpreadConstraints
				}

				if #config.server.antiAffinity.enabled || #config.server.podAffinity != _|_ || #config.server.nodeAffinity != _|_ {
					affinity: {
						if #config.server.antiAffinity.enabled && #config.server.podAntiAffinity != _|_ {
							podAntiAffinity: #config.server.podAntiAffinity
						}
						if #config.server.podAffinity != _|_ {
							podAffinity: #config.server.podAffinity
						}
						if #config.server.nodeAffinity != _|_ {
							nodeAffinity: #config.server.nodeAffinity
						}
					}
				}

				containers: [
					for c in #config.server.extraContainers {c},
					{
						name: "server"
						command: [
							"bash",
							"-c",
							"mkdir -p /data/config\nnode dist/server\n",
						]
						if #config.server.container.extraArgs != _|_ && len(#config.server.container.extraArgs) > 0 {
							args: [
								for k, v in #config.server.container.extraArgs
								if v != "" {
									"--\(k)=\(v)"
								},
							]
						}
						image:           #imageRef
						imagePullPolicy: #realPullPolicy

						if #config.server.container.resources != _|_ {
							resources: #config.server.container.resources
						}
						if #config.server.container.securityContext != _|_ {
							securityContext: #config.server.container.securityContext
						}

						volumeMounts: [
							{
								name:      "config"
								mountPath: "/config/production.yaml"
								subPath:   "production.yaml"
								readOnly:  true
							},
							{
								name:      "data"
								mountPath: "/data"
							},
						]

						ports: [
							{
								name:          "server"
								containerPort: #config.server.containerPort
								protocol:      "TCP"
							},
							{
								name:          "metrics"
								containerPort: #config.server.metricsPort
								protocol:      "TCP"
							},
							{
								name:          "rtmp"
								containerPort: #config.server.rtmpPort
								protocol:      "TCP"
							},
							{
								name:          "rtmps"
								containerPort: #config.server.rtmpsPort
								protocol:      "TCP"
							},
						]

						#adminSecretName: *"\(#config.metadata.name)-server-admin" | string
						if #config.server.config.admin.existingSecret != "" {
							#adminSecretName: #config.server.config.admin.existingSecret
						}
						#adminSecretOptional: *true | bool
						if #config.server.config.admin.existingSecret != "" || #config.server.config.admin.password != "" {
							#adminSecretOptional: false
						}

						#postgresSecretName: *"\(#config.metadata.name)-server-postgres" | string
						if #config.server.externalPostgres.existingSecret != "" {
							#postgresSecretName: #config.server.externalPostgres.existingSecret
						}
						#postgresSecretOptional: *true | bool
						if #config.server.externalPostgres.existingSecret != "" || #config.server.externalPostgres.password != "" {
							#postgresSecretOptional: false
						}

						#redisSecretName: *"\(#config.metadata.name)-server-redis" | string
						if #config.server.externalRedis.existingSecret != "" {
							#redisSecretName: #config.server.externalRedis.existingSecret
						}
						#redisSecretOptional: *true | bool
						if #config.server.externalRedis.existingSecret != "" || #config.server.externalRedis.password != "" {
							#redisSecretOptional: false
						}

						#peertubeSecretName: *"\(#config.metadata.name)-server-peertube-secret" | string
						if #config.server.config.secrets.existingSecret != "" {
							#peertubeSecretName: #config.server.config.secrets.existingSecret
						}
						#peertubeSecretOptional: *true | bool
						if #config.server.config.secrets.existingSecret != "" || #config.server.config.secrets.peertube != "" {
							#peertubeSecretOptional: false
						}

						env: [
							{
								name:  "NODE_ENV"
								value: "production"
							},
							{
								name:  "NODE_CONFIG_DIR"
								value: "/app/config:/app/support/docker/production/config:/config:/data/config"
							},
							{
								name:  "PEERTUBE_LOCAL_CONFIG"
								value: "/data/config"
							},
							{
								name: "PT_INITIAL_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									name:     #adminSecretName
									key:      "admin-password"
									optional: #adminSecretOptional
								}
							},
							{
								name: "PEERTUBE_DB_USERNAME"
								valueFrom: secretKeyRef: {
									name:     #postgresSecretName
									key:      "postgres-username"
									optional: false
								}
							},
							{
								name: "PEERTUBE_DB_PASSWORD"
								valueFrom: secretKeyRef: {
									name:     #postgresSecretName
									key:      "postgres-password"
									optional: #postgresSecretOptional
								}
							},
							{
								name: "PEERTUBE_REDIS_AUTH"
								valueFrom: secretKeyRef: {
									name:     #redisSecretName
									key:      "redis-password"
									optional: #redisSecretOptional
								}
							},
							{
								name: "PEERTUBE_SECRET"
								valueFrom: secretKeyRef: {
									name:     #peertubeSecretName
									key:      "peertube-secret"
									optional: #peertubeSecretOptional
								}
							},
							if #config.server.objectStorage.enabled {
								{
									name: "PEERTUBE_OBJECT_STORAGE_CREDENTIALS_ACCESS_KEY_ID"
									valueFrom: secretKeyRef: {
										name: #config.server.objectStorage.existingSecret
										key:  "access-key-id"
									}
								}
							},
							if #config.server.objectStorage.enabled {
								{
									name: "PEERTUBE_OBJECT_STORAGE_CREDENTIALS_SECRET_ACCESS_KEY"
									valueFrom: secretKeyRef: {
										name: #config.server.objectStorage.existingSecret
										key:  "secret-access-key"
									}
								}
							},
							for e in #config.global.extraEnvVars {e},
							for e in #config.server.container.extraEnvVars {e},
						]

						if #config.server.startupProbe != _|_ {
							startupProbe: #config.server.startupProbe
						}
						if #config.server.livenessProbe != _|_ {
							livenessProbe: #config.server.livenessProbe
						}
						if #config.server.readinessProbe != _|_ {
							readinessProbe: #config.server.readinessProbe
						}
					},
				]

				#configMapName: *"\(#config.metadata.name)-server-config" | string
				if #config.server.config.configMapName != _|_ && #config.server.config.configMapName != null {
					#configMapName: #config.server.config.configMapName
				}

				volumes: [
					{
						name: "config"
						configMap: name: #configMapName
					},
					{
						name: "data"
						if #config.server.persistence.enabled {
							persistentVolumeClaim: claimName: *"\((#config.metadata.name))-server-storage" | string
							if #config.server.persistence.existingClaim != "" {
								persistentVolumeClaim: claimName: #config.server.persistence.existingClaim
							}
						}
						if !#config.server.persistence.enabled {
							emptyDir: {}
						}
					},
				]
			}
		}
	}
}
