package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#WebDeployment: {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-web"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.web.replicaCount
		selector: matchLabels: {
			app:     #config.metadata.name
			release: #config.metadata.name
			role:    "web"
		}
		template: {
			metadata: {
				labels: {
					app:     #config.metadata.name
					release: #config.metadata.name
					role:    "web"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
				containers: [{
					args: [
						"bundle", "exec", "rails", "s",
						"-p", "\(#config.services.internalPort)",
						"-b", "0.0.0.0",
					]
					command: ["docker/entrypoints/rails.sh"]
					env: [
						if #config.postgresql.auth.existingSecret != _|_ {
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.postgresql.auth.existingSecret
									key:  "password"
								}
							}
						},
						if #config.redis.auth.existingSecret != _|_ {
							{
								name: "REDIS_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.redis.auth.existingSecret
									key:  "password"
								}
							}
						},
					]
					envFrom: [
						{
							secretRef: name: "\(#config.metadata.name)-env"
						},
						if #config.existingEnvSecret != "" {
							{
								secretRef: name: #config.existingEnvSecret
							}
						},
					]
					image: "\(#config.image.repository):\(#config.image.tag)"
					name:  "chatwoot-web"
					ports: [{
						containerPort: #config.services.internalPort
					}]
					imagePullPolicy: #config.image.pullPolicy
					if #config.web.resources != _|_ {
						resources: #config.web.resources
					}
					livenessProbe: #config.web.livenessProbe & {
						httpGet: {
							path: "/health"
							port: #config.services.internalPort
						}
					}
					readinessProbe: #config.web.readinessProbe & {
						httpGet: {
							path: "/api"
							port: #config.services.internalPort
						}
					}
					startupProbe: #config.web.startupProbe & {
						httpGet: {
							path: "/health"
							port: #config.services.internalPort
						}
					}
					volumeMounts: [{
						name:      "cache"
						mountPath: "/app/tmp"
					}]
				}]
				serviceAccountName: #config.metadata.name
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				volumes: [{
					name: "cache"
					emptyDir: {}
				}]
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
			}
		}
	}
}
