package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#Redis: {
	#config: #Config
	if #config.redis.enabled {
		apiVersion: "apps/v1"
		kind:       "StatefulSet"
		metadata: {
			name:      #config.redis.nameOverride
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
			if #config.metadata.annotations != _|_ {
				annotations: #config.metadata.annotations
			}
		}
		spec: appsv1.#StatefulSetSpec & {
			serviceName: #config.redis.nameOverride
			replicas:    1
			selector: matchLabels: {
				app: #config.redis.nameOverride
			}
			template: {
				metadata: labels: {
					app: #config.redis.nameOverride
				}
				spec: corev1.#PodSpec & {
					containers: [
						{
							name:  "redis"
							image: "\( #config.redis.image.repository ):\( #config.redis.image.tag )"
							env: [{
								name:  "REDIS_PASSWORD"
								value: #config.redis.auth.password
							}]
							ports: [{
								containerPort: 6379
								name:          "redis"
							}]
							volumeMounts: [{
								name:      "data"
								mountPath: "/bitnami/redis/data"
							}]
						},
						if #config.redis.sentinel.enabled {
							{
								name:  "sentinel"
								image: "\( #config.redis.sentinel.image.repository ):\( #config.redis.sentinel.image.tag )"
								command: ["/bin/sh", "-c"]
								args: [
									"printf \"port 26379\\nsentinel monitor \(#config.redis.sentinel.masterSet) 127.0.0.1 6379 1\\nsentinel auth-pass \(#config.redis.sentinel.masterSet) $REDIS_PASSWORD\\n\" > /tmp/sentinel.conf && redis-server /tmp/sentinel.conf --sentinel",
								]
								env: [
									{
										name:  "REDIS_PASSWORD"
										value: #config.redis.auth.password
									},
								]
								ports: [{
									containerPort: 26379
									name:          "redis-sentinel"
								}]
							}
						},
					]
				}
			}
			volumeClaimTemplates: [{
				metadata: name: "data"
				spec: {
					accessModes: ["ReadWriteOnce"]
					resources: requests: storage: "8Gi"
				}
			}]
		}
	}
}

#RedisService: {
	#config: #Config
	if #config.redis.enabled {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      #config.redis.nameOverride
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
			if #config.metadata.annotations != _|_ {
				annotations: #config.metadata.annotations
			}
		}
		spec: corev1.#ServiceSpec & {
			ports: [{
				port:       6379
				targetPort: 6379
				name:       "redis"
			}]
			selector: {
				app: #config.redis.nameOverride
			}
		}
	}
}

#RedisMasterService: {
	#config: #Config
	if #config.redis.enabled {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "\(#config.redis.nameOverride)-master"
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
			if #config.metadata.annotations != _|_ {
				annotations: #config.metadata.annotations
			}
		}
		spec: corev1.#ServiceSpec & {
			ports: [{
				port:       6379
				targetPort: 6379
				name:       "redis"
			}]
			selector: {
				app: #config.redis.nameOverride
			}
		}
	}
}

#RedisSentinelService: {
	#config: #Config
	if #config.redis.enabled && #config.redis.sentinel.enabled {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "\(#config.redis.nameOverride)-sentinel"
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
			if #config.metadata.annotations != _|_ {
				annotations: #config.metadata.annotations
			}
		}
		spec: corev1.#ServiceSpec & {
			ports: [{
				port:       26379
				targetPort: 26379
				name:       "redis-sentinel"
			}]
			selector: {
				app: #config.redis.nameOverride
			}
		}
	}
}
