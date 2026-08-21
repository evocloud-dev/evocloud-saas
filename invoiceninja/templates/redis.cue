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
		name:      #config.#redisServiceName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "redis"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "redis"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "redis"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            #config.#serviceAccountName
				automountServiceAccountToken: #config.serviceAccount.create
				securityContext:              #config.redis.podSecurityContext
				containers: [{
					name:            "redis"
					image:           "\(#config.redis.image.repository):\(#config.redis.image.tag)"
					imagePullPolicy: #config.redis.image.pullPolicy
					if #config.secret.redisPassword != "" {
						command: [
							"redis-server",
							"--requirepass",
							"$(REDISCLI_AUTH)",
						]
						env: [{
							name: "REDISCLI_AUTH"
							valueFrom: secretKeyRef: {
								name: #config.#secretName
								key:  "REDIS_PASSWORD"
							}
						}]
					}
					ports: [{
						name:          "redis"
						containerPort: 6379
						protocol:      "TCP"
					}]
					livenessProbe: {
						exec: command: [
							"redis-cli",
							"ping",
						]
						initialDelaySeconds: 10
						periodSeconds:       20
					}
					readinessProbe: {
						exec: command: [
							"redis-cli",
							"ping",
						]
						initialDelaySeconds: 5
						periodSeconds:       10
					}
					resources:       #config.redis.resources
					securityContext: #config.redis.securityContext
					volumeMounts: [{
						name:      "redis-data"
						mountPath: "/data"
					}]
				}]
				volumes: [{
					name: "redis-data"
					if #config.persistence.redisData.enabled {
						persistentVolumeClaim: claimName: "\(#config.#fullname)-redis-data"
					}
					if !#config.persistence.redisData.enabled {
						emptyDir: {}
					}
				}]
			}
		}
	}
}

#RedisService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#redisServiceName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "redis"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [{
			name:       "redis"
			port:       #config.redis.service.port
			targetPort: "redis"
			protocol:   "TCP"
		}]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "redis"
		}
	}
}
