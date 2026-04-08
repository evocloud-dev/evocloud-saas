package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#RedisDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name: "\(#config.metadata.name)-redis"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "redis"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		strategy: {
			type: "RollingUpdate"
			rollingUpdate: {
				maxSurge:       1
				maxUnavailable: 1
			}
		}
		replicas: 1
		selector: matchLabels: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/component": "redis"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":      #config.metadata.name
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/component": "redis"
			}
			spec: corev1.#PodSpec & {
				securityContext: {
					runAsUser: #config.securityContext.runAsUser
					fsGroup:   #config.securityContext.fsGroup
				}
				containers: [
					{
						name:            "redis"
						image:           #config.redis.internal.image.reference
						imagePullPolicy: #config.redis.internal.image.pullPolicy
						command: ["redis-stack-server"]
						args: [
							"--port",
							"\(#config.redis.internal.service.port)",
							"--maxmemory-policy",
							"noeviction",
							"--dir",
							"/data",
						]
						ports: [
							{
								containerPort: #config.redis.internal.service.port
								name:          "redis"
							},
						]
						resources: #config.redis.internal.resources
						volumeMounts: [
							{
								name:      "redis-data"
								mountPath: "/data"
							},
						]
					},
				]
				volumes: [
					{
						name: "redis-data"
						if #config.redis.internal.persistence.enabled {
							persistentVolumeClaim: claimName: {
								if #config.redis.internal.persistence.existingClaim != "" {
									#config.redis.internal.persistence.existingClaim
								}
								if #config.redis.internal.persistence.existingClaim == "" {
									"\(#config.metadata.name)-redis"
								}
							}
						}
						if !#config.redis.internal.persistence.enabled {
							emptyDir: {}
						}
					},
				]
			}
		}
	}
}
