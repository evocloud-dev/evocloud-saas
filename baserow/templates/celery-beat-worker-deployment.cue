package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	"list"
)

#DeploymentCeleryBeatWorker: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-celery-beat-worker"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-beat-worker"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		if !#config.backend.celery.beatWorker.autoscaling.enabled {
			replicas: #config.backend.celery.beatWorker.replicaCount
		}
		revisionHistoryLimit: #config.backend.celery.beatWorker.revisionHistoryLimit
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-beat-worker"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				if #config.backend.celery.beatWorker.podAnnotations != _|_ {
					annotations: #config.backend.celery.beatWorker.podAnnotations
				}
				labels: {
					"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-beat-worker"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: {
				automountServiceAccountToken: false
				if len(#config.backend.celery.beatWorker.imagePullSecrets) > 0 {
					imagePullSecrets: #config.backend.celery.beatWorker.imagePullSecrets
				}
				if #config.backend.celery.beatWorker.serviceAccount.create {
					if #config.backend.celery.beatWorker.serviceAccount.name != "" {
						serviceAccountName: #config.backend.celery.beatWorker.serviceAccount.name
					}
					if #config.backend.celery.beatWorker.serviceAccount.name == "" {
						serviceAccountName: "\(#config.metadata.name)-celery"
					}
				}
				if !#config.backend.celery.beatWorker.serviceAccount.create {
					if #config.backend.celery.beatWorker.serviceAccount.name != "" {
						serviceAccountName: #config.backend.celery.beatWorker.serviceAccount.name
					}
					if #config.backend.celery.beatWorker.serviceAccount.name == "" {
						serviceAccountName: "default"
					}
				}
				if #config.backend.celery.beatWorker.podSecurityContext != _|_ {
					securityContext: #config.backend.celery.beatWorker.podSecurityContext
				}
				containers: [
					{
						name:            "celery-beat-worker"
						image:           "\(#config.backend.celery.beatWorker.image.registry)/\(#config.backend.celery.beatWorker.image.repository):\(#config.backend.celery.beatWorker.image.tag)"
						imagePullPolicy: #config.backend.celery.beatWorker.image.pullPolicy
						args: [
							"celery-beat",
						]
						_envListsBeat: [
							[
								{
									name: "BASEROW_JWT_SIGNING_KEY"
									valueFrom: secretKeyRef: {
										name: "\(#config.metadata.name)-backend"
										key:  "jwt-signing-key"
									}
								},
								{
									name: "SECRET_KEY"
									valueFrom: secretKeyRef: {
										name: "\(#config.metadata.name)-backend"
										key:  "secret-key"
									}
								},
								if #config.redis.auth.enabled || #config.externalRedis.auth.enabled {
									{
										name: "REDIS_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-redis"
											if #config.redis.enabled {
												key: "password"
											}
											if !#config.redis.enabled {
												key: #config.externalRedis.auth.userPasswordKey
											}
										}
									}
								},
							],
							#config.#OtelEnv,
							#config.backend.celery.beatWorker.extraEnv,
						]
						env: list.Concat(_envListsBeat)
						envFrom: [
							{
								configMapRef: name: "\(#config.metadata.name)"
							},
							{
								configMapRef: name: "\(#config.metadata.name)-backend"
							},
						]
						if #config.backend.celery.beatWorker.resources != _|_ {
							resources: #config.backend.celery.beatWorker.resources
						}
						if #config.backend.celery.beatWorker.securityContext != _|_ {
							securityContext: #config.backend.celery.beatWorker.securityContext
						}
					},
				]
				if #config.backend.celery.beatWorker.priorityClassName != "" {
					priorityClassName: #config.backend.celery.beatWorker.priorityClassName
				}
				if #config.backend.celery.beatWorker.nodeSelector != _|_ {
					nodeSelector: #config.backend.celery.beatWorker.nodeSelector
				}
				if #config.backend.celery.beatWorker.affinity != _|_ {
					affinity: #config.backend.celery.beatWorker.affinity
				}
				if len(#config.backend.celery.beatWorker.tolerations) > 0 {
					tolerations: #config.backend.celery.beatWorker.tolerations
				}
			}
		}
	}
}
