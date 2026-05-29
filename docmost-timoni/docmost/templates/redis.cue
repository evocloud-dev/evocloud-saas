package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#RedisService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis-client"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		ports: [{
			port:       6379
			targetPort: 6379
			name:       "redis"
		}]
		selector: {
			"app.kubernetes.io/name": "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#RedisHeadlessService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		clusterIP: "None"
		ports: [{
			port:       6379
			targetPort: 6379
			name:       "redis"
		}]
		selector: {
			"app.kubernetes.io/name": "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#RedisDeployment: appsv1.#StatefulSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config.metadata.name)-redis-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name": "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name": "redis"
				"app.kubernetes.io/instance": #config.metadata.name
			}
			spec: corev1.#PodSpec & {
				containers: [{
					name:            "redis"
					image:           "\(#config.redis.image.repository):\(#config.redis.image.tag)"
					imagePullPolicy: #config.redis.image.pullPolicy
					ports: [{
						containerPort: 6379
						name:          "redis"
					}]
					let _startCmd = {
						if #config.redis.auth.enabled {
							"redis-server --requirepass $(REDIS_PASSWORD)"
						}
						if !#config.redis.auth.enabled {
							"redis-server"
						}
					}
					command: ["sh", "-c", _startCmd]
					env: [
						if #config.redis.auth.enabled {
							{
								name: "REDIS_PASSWORD"
								value: {
									if #config.redis.auth.password != "" { #config.redis.auth.password }
									if #config.redis.auth.password == "" { "redis-default-pass-change-me" }
								}
							}
						}
					]
					volumeMounts: [
						{
							name:      "redis-data"
							mountPath: "/data"
						}
					]
				}]
				if !#config.redis.standalone.persistence.enabled {
					volumes: [
						{
							name: "redis-data"
							emptyDir: {}
						}
					]
				}
			}
		}
		if #config.redis.standalone.persistence.enabled {
			volumeClaimTemplates: [{
				metadata: name: "redis-data"
				spec: corev1.#PersistentVolumeClaimSpec & {
					accessModes: ["ReadWriteOnce"]
					resources: requests: storage: #config.redis.standalone.persistence.size
				}
			}]
		}
	}
}
