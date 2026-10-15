package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#ApplicationDeployment: appsv1.#Deployment & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "application"
	}

	_affinity: timoniv1.#Affinity & {
		#Values:      #config.affinity
		#MatchLabels: #meta.#LabelSelector
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #meta
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.app.replicas
		selector: matchLabels: #meta.#LabelSelector
		template: {
			metadata: {
				labels: #meta.#LabelSelector
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.serviceAccountName
				automountServiceAccountToken: #config.automountServiceAccountToken
				containers: [
					{
						name:            "application"
						image:           #config.images.api.reference
						imagePullPolicy: #config.images.api.pullPolicy
						ports: [
							{
								name:          "http"
								containerPort: #config.app.port
								protocol:      "TCP"
							},
						]
						env: [
							{name: "ENVIRONMENT", value:    #config.app.environment},
							{name: "APP_KEY", value:        #config.app.key},
							{name: "CONSOLE_HOST", value:   #config.app.consoleHost},
							{name: "FRONTEND_HOSTS", value: #config.app.frontendHosts},
							if #config.database.enabled {
								name: "DATABASE_URL"
								if #config.database.allowEmptyPassword {
									value: "mysql://" + #config.database.user + "@" + #config.metadata.name + "-mysql:3306/" + #config.database.name
								}
								if !#config.database.allowEmptyPassword {
									value: "mysql://" + #config.database.user + ":" + #config.database.password + "@" + #config.metadata.name + "-mysql:3306/" + #config.database.name
								}
							},
							if !#config.database.enabled && #config.database.url != _|_ {
								name:  "DATABASE_URL"
								value: #config.database.url
							},
							if !#config.database.enabled && #config.database.urlSecretRef != _|_ {
								name: "DATABASE_URL"
								valueFrom: secretKeyRef: {
									name: #config.database.urlSecretRef.name
									key:  #config.database.urlSecretRef.key
								}
							},
							{name: "QUEUE_CONNECTION", value: "redis"},
							{name: "CACHE_DRIVER", value: "redis"},
							{name: "CACHE_PATH", value: "/fleetbase/api/storage/framework/cache"},
							if #config.cache.enabled {
								name:  "CACHE_URL"
								value: "tcp://" + #config.metadata.name + "-redis:6379"
							},
							if #config.cache.enabled {
								name:  "REDIS_URL"
								value: "tcp://" + #config.metadata.name + "-redis:6379"
							},
							if !#config.cache.enabled && #config.cache.url != _|_ {
								name:  "CACHE_URL"
								value: #config.cache.url
							},
							if !#config.cache.enabled && #config.cache.url != _|_ {
								name:  "REDIS_URL"
								value: #config.cache.url
							},
							if !#config.cache.enabled && #config.cache.urlSecretRef != _|_ {
								name: "CACHE_URL"
								valueFrom: secretKeyRef: {
									name: #config.cache.urlSecretRef.name
									key:  #config.cache.urlSecretRef.key
								}
							},
							if !#config.cache.enabled && #config.cache.urlSecretRef != _|_ {
								name: "REDIS_URL"
								valueFrom: secretKeyRef: {
									name: #config.cache.urlSecretRef.name
									key:  #config.cache.urlSecretRef.key
								}
							},
							{name: "SESSION_DOMAIN", value: "localhost"},
							{name: "BROADCAST_DRIVER", value: "socketcluster"},
							{name: "MAIL_FROM_NAME", value: "Fleetbase"},
							{name: "APP_NAME", value: "Fleetbase"},
							{name: "LOG_CHANNEL", value: "daily"},
							{name: "REGISTRY_HOST", value: "https://registry.fleetbase.io"},
							{name: "REGISTRY_PREINSTALLED_EXTENSIONS", value: "true"},
							{name: "OSRM_HOST", value: "https://router.project-osrm.org"},
							if #config.socket.enabled {
								name:  "SOCKETCLUSTER_HOST"
								value: #config.metadata.name + "-socket"
							},
							if #config.socket.enabled {
								name:  "SOCKETCLUSTER_PORT"
								value: "\(#config.socket.port)"
							},
							if #config.app.extraEnv != _|_ {
								for e in #config.app.extraEnv {e}
							},
						]
						envFrom: [
							if #config.app.secretRef != _|_ {
								secretRef: name: #config.app.secretRef
							},
						]
						livenessProbe: {
							httpGet: {
								path: "/health"
								port: "http"
							}
							initialDelaySeconds: 30
							periodSeconds:       10
							timeoutSeconds:      5
						}
						readinessProbe: {
							httpGet: {
								path: "/health"
								port: "http"
							}
							initialDelaySeconds: 15
							periodSeconds:       10
							timeoutSeconds:      5
						}
						resources:       #config.app.resources
						if #config.app.securityContext != _|_ {
							securityContext: #config.app.securityContext
						}
						let _hasVolumeMounts = #config.app.persistence.enabled || #config.app.envFileSecretRef != _|_
						if _hasVolumeMounts {
							volumeMounts: [
								if #config.app.persistence.enabled {
									name:      "storage-app"
									mountPath: "/fleetbase/api/storage/app"
								},
								if #config.app.envFileSecretRef != _|_ {
									name:      "env-file"
									mountPath: "/fleetbase/api/.env"
									subPath:   ".env"
									readOnly:  true
								},
							]
						}
					},
				]
				let _hasVolumes = #config.app.persistence.enabled || #config.app.envFileSecretRef != _|_
				if _hasVolumes {
					volumes: [
						if #config.app.persistence.enabled {
							name: "storage-app"
							persistentVolumeClaim: claimName: #config.metadata.name + "-app-storage"
						},
						if #config.app.envFileSecretRef != _|_ {
							name: "env-file"
							secret: secretName: #config.app.envFileSecretRef
						},
					]
				}
				if #config.app.podSecurityContext != _|_ {
					securityContext: #config.app.podSecurityContext
				}
				if #config.app.podSecurityContext == _|_ && #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				nodeSelector: #config.nodeSelector
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				affinity: _affinity
			}
		}
	}
}

#ApplicationService: corev1.#Service & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "application"
	}

	apiVersion: "v1"
	kind:       "Service"
	metadata:   #meta
	spec: corev1.#ServiceSpec & {
		type: [
			if #config.app.service != _|_ { #config.app.service.type },
			corev1.#ServiceTypeClusterIP,
		][0]
		selector: #meta.#LabelSelector
		ports: [
			{
				name:       "http"
				port: [
					if #config.app.service != _|_ { #config.app.service.port },
					#config.app.port,
				][0]
				targetPort: "http"
				protocol:   "TCP"
			},
		]
	}
}

#ApplicationStoragePVC: corev1.#PersistentVolumeClaim & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "app-storage"
	}

	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata:   #meta
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [for mode in #config.app.persistence.accessModes {mode}]
		resources: requests: (corev1.#ResourceStorage): #config.app.persistence.size
		if #config.app.persistence.storageClass != _|_ {
			storageClassName: #config.app.persistence.storageClass
		}
	}
}