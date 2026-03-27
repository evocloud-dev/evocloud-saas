package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#RedisDeployment: {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		selector: matchLabels: #config.selector.labels & {
			app: "redis"
		}
		template: {
			metadata: labels: #config.selector.labels & {
				app: "redis"
			}
			spec: corev1.#PodSpec & {
				securityContext: {
					fsGroup: 1001
				}
				initContainers: [
					{
						name:  "init-redis"
						image: "busybox:latest"
						securityContext: {
							runAsUser:  1001
							runAsGroup: 1001
						}
						command: ["sh", "-c", "mkdir -p /mnt/etc /mnt/tmp /mnt/logs /mnt/data && if [ -f /config/redis.conf ]; then cp /config/redis.conf /mnt/etc/redis.conf; fi"]
						volumeMounts: [
							{
								name:      "redis-config-source"
								mountPath: "/config"
							},
							{
								name:      "redis-etc"
								mountPath: "/mnt/etc"
							},
							{
								name:      "redis-tmp"
								mountPath: "/mnt/tmp"
							},
							{
								name:      "redis-logs"
								mountPath: "/mnt/logs"
							},
							{
								name:      "redis-data"
								mountPath: "/mnt/data"
							},
						]
					},
				]
				containers: [
					{
						name:  "redis"
						image: "\(#config.redis.image.registry)/\(#config.redis.image.repository):\(#config.redis.image.tag)"
						securityContext: {
							runAsUser:  1001
							runAsGroup: 1001
						}
						env: [
							{
								name: "REDIS_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-redis-auth"
									key:  "default-password"
								}
							},
						]
						ports: [
							{
								containerPort: 6379
								name:          "redis"
							},
						]
						livenessProbe: {
							tcpSocket: port: "redis"
							initialDelaySeconds: 30
							periodSeconds:       10
							timeoutSeconds:      5
						}
						readinessProbe: {
							exec: command: ["redis-cli", "ping"]
							initialDelaySeconds: 5
							periodSeconds:       10
							timeoutSeconds:      5
						}
						volumeMounts: [
							{
								name:      "redis-etc"
								mountPath: "/opt/bitnami/redis/etc"
							},
							{
								name:      "redis-tmp"
								mountPath: "/opt/bitnami/redis/tmp"
							},
							{
								name:      "redis-logs"
								mountPath: "/opt/bitnami/redis/logs"
							},
							{
								name:      "redis-data"
								mountPath: "/bitnami/redis/data"
							},
						]
					},
				]
				volumes: [
					{
						name: "redis-config-source"
						configMap: name: "\(#config.metadata.name)-redis-config"
					},
					{
						name: "redis-etc"
						emptyDir: {}
					},
					{
						name: "redis-tmp"
						emptyDir: {}
					},
					{
						name: "redis-logs"
						emptyDir: {}
					},
					{
						name: "redis-data"
						emptyDir: {}
					},
				]
			}
		}
	}
}

#RedisService: {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		selector: #config.selector.labels & {
			app: "redis"
		}
		ports: [
			{
				name:       "redis"
				port:       6379
				targetPort: 6379
			},
		]
	}
}

#RedisSecret: {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-redis-auth"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		"default-password": #config.redis.auth.aclUsers.default.password
	}
}

#RedisConfigMap: corev1.#ConfigMap & {
	#config: #Config
	if #config.redis.configuration != _|_ {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "\(#config.metadata.name)-redis-config"
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
		}
		data: {
			"redis.conf": #config.redis.configuration
		}
	}
}
