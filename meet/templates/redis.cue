package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#RedisService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "redis-master"
		namespace: #config.metadata.namespace
	}
	spec: corev1.#ServiceSpec & {
		ports: [{
			name:       "tcp-redis"
			port:       6379
			targetPort: 6379
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "redis"
		}
		type: "ClusterIP"
	}
}

#RedisConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "redis"
		namespace: #config.metadata.namespace
	}
	data: {
		"redis.conf": """
			bind 0.0.0.0
			port 6379
			user default on >pass ~* &* +@all
			"""
	}
}

#RedisDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "redis"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "redis"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		selector: matchLabels: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "redis"
		}
		replicas: 1
		template: {
			metadata: labels: {
				"app.kubernetes.io/instance": "extra"
				"app.kubernetes.io/name":     "redis"
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: #config.redis.automountServiceAccountToken
				serviceAccountName:           #config.redis.serviceAccountName
				if #config.redis.podSecurityContext != null {
					securityContext: #config.redis.podSecurityContext
				}
				containers: [{
					name: "redis"
					if #config.redis.securityContext != null {
						securityContext: #config.redis.securityContext
					}
					if #config.redis.resources != null {
						resources: #config.redis.resources
					}
					args: [
						"redis-server",
						"/usr/local/etc/redis/redis.conf",
					]
					image:           #config.redis.image.reference
					imagePullPolicy: "IfNotPresent"
					ports: [{
						containerPort: 6379
						name:          "tcp-redis"
					}]
					volumeMounts: [{
						name:      "redis"
						mountPath: "/usr/local/etc/redis"
						readOnly:  true
					}, {
						name:      "redis-data"
						mountPath: "/data"
					}]
				}]
				volumes: [{
					name: "redis"
					configMap: name: "redis"
				}, {
					name: "redis-data"
					emptyDir: {}
				}]
			}
		}
	}
}
