package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#RedisHeadlessService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config._redisName + "-headless"
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "redis"
		}
	}
	spec: {
		clusterIP: "None"
		ports: [{
			name:       "redis"
			port:       #config.redis.service.port
			targetPort: "redis"
		}]
		selector: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "redis"
		}
	}
}

#RedisService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config._redisName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "redis"
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "redis"
			port:       #config.redis.service.port
			targetPort: "redis"
		}]
		selector: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "redis"
		}
	}
}

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      #config._redisName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "redis"
		}
	}
	spec: {
		serviceName: #config._redisName + "-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "redis"
		}
		template: {
			metadata: labels: #config._baseLabels & {
				"app.kubernetes.io/component": "redis"
			}
			spec: {
				containers: [{
					name:            "redis"
					image:           #config.redis.image.repository + ":" + #config.redis.image.tag
					imagePullPolicy: #config.redis.image.pullPolicy
					ports: [{
						name:          "redis"
						containerPort: 6379
					}]
					command: ["redis-server", "--requirepass", "$(REDIS_PASSWORD)"]
					env: [{
						name: "REDIS_PASSWORD"
						valueFrom: secretKeyRef: {
							name: #config._redisSecretName
							key:  #config.secrets.redis.passwordKey
						}
					}]
					livenessProbe: {
						exec: command: [
							"redis-cli",
							"-a",
							"$(REDIS_PASSWORD)",
							"ping",
						]
						initialDelaySeconds: 15
						periodSeconds:       10
					}
					readinessProbe: {
						exec: command: [
							"redis-cli",
							"-a",
							"$(REDIS_PASSWORD)",
							"ping",
						]
						initialDelaySeconds: 5
						periodSeconds:       10
					}
					if len(#config.redis.resources) > 0 {
						resources: #config.redis.resources
					}
					if #config.redis.persistence.enabled {
						volumeMounts: [{
							name:      "data"
							mountPath: "/data"
						}]
					}
				}]
			}
		}
		if #config.redis.persistence.enabled {
			volumeClaimTemplates: [{
				metadata: name: "data"
				spec: {
					accessModes: ["ReadWriteOnce"]
					if #config.redis.persistence.storageClass != "" {
						storageClassName: #config.redis.persistence.storageClass
					}
					resources: requests: storage: #config.redis.persistence.size
				}
			}]
		}
	}
}
