package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#RedisSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		if #config.redis.auth.password != "" {
			"redis-password": #config.redis.auth.password
		}
	}
}

#RedisService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis-master"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "redis"
			port:       6379
			targetPort: "redis"
		}]
		selector: {
			"app.kubernetes.io/name": "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#RedisHeadlessService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		type:      "ClusterIP"
		clusterIP: "None"
		ports: [{
			name:       "redis"
			port:       6379
			targetPort: "redis"
		}]
		selector: {
			"app.kubernetes.io/name": "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-redis-master"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
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
			spec: {
				containers: [{
					name:            "redis"
					image:           "\(#config.redis.image.repository):\(#config.redis.image.tag)"
					imagePullPolicy: #config.redis.image.pullPolicy
					if len(#config.redis.image.command) > 0 {
						command: #config.redis.image.command
					}
					if len(#config.redis.image.args) > 0 {
						args: #config.redis.image.args
					}
					env: [{
						name: "REDIS_PASSWORD"
						valueFrom: secretKeyRef: {
							name: {
								if #config.redis.auth.existingSecret != "" {
									#config.redis.auth.existingSecret
								}
								if #config.redis.auth.existingSecret == "" {
									"\(#config.metadata.name)-redis"
								}
							}
							key: {
								if #config.redis.auth.existingSecretPasswordKey != "" {
									#config.redis.auth.existingSecretPasswordKey
								}
								if #config.redis.auth.existingSecretPasswordKey == "" {
									"redis-password"
								}
							}
						}
					}]
					ports: [{
						name:          "redis"
						containerPort: 6379
					}]
					volumeMounts: [{
						name:      "redis-data"
						mountPath: #config.redis.persistence.mountPath
					}]
				}]
			}
		}
		volumeClaimTemplates: [{
			metadata: name: "redis-data"
			spec: {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: #config.redis.master.persistence.size
			}
		}]
	}
}
