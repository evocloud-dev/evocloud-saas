package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#QueueDeployment: appsv1.#Deployment & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "queue"
	}

	_affinity: timoniv1.#Affinity & {
		#Values:      #config.affinity
		#MatchLabels: #meta.#LabelSelector
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #meta
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.queue.replicas
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
						name:            "queue"
						image:           #config.images.api.reference
						imagePullPolicy: #config.images.api.pullPolicy
						command: ["php", "artisan", "queue:work"]
						// Environment variables listed directly from docker-compose.yml (lines 69-76)
						env: [
							{name: "APP_KEY", value: #config.app.key},
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
							if #config.queue.extraEnv != _|_ {
								for e in #config.queue.extraEnv {e}
							},
							if #config.queue.extraEnv == _|_ && #config.app.extraEnv != _|_ {
								for e in #config.app.extraEnv {e}
							},
						]
						envFrom: [
							if #config.queue.secretRef != _|_ {
								secretRef: name: #config.queue.secretRef
							},
							if #config.queue.secretRef == _|_ && #config.app.secretRef != _|_ {
								secretRef: name: #config.app.secretRef
							},
						]
						livenessProbe: {
							exec: {
								command: ["php", "artisan", "queue:status"]
							}
							initialDelaySeconds: 30
							periodSeconds:       30
							timeoutSeconds:      10
						}
						resources:       #config.queue.resources
						if #config.queue.securityContext != _|_ {
							securityContext: #config.queue.securityContext
						}
					},
				]
				if #config.queue.podSecurityContext != _|_ {
					securityContext: #config.queue.podSecurityContext
				}
				if #config.queue.podSecurityContext == _|_ && #config.podSecurityContext != _|_ {
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
