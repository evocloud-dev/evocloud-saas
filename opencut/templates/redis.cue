package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#RedisSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.#redisFullname)-auth"
		namespace: #config.metadata.namespace
		labels:    #config.#redisLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		"redis-password": #config.#redisPassword
	}
}

#RedisConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.#redisFullname)-config"
		namespace: #config.metadata.namespace
		labels:    #config.#redisLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		"redis-standalone.conf": """
			bind 0.0.0.0
			protected-mode no
			dir /data
			appendonly yes
			save 900 1
			save 300 10
			save 60 10000
			"""
	}
}

#RedisHeadlessService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.#redisFullname)-headless"
		namespace: #config.metadata.namespace
		labels: #config.#redisLabels & {
			"app.kubernetes.io/component": "redis-headless"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		clusterIP:                "None"
		publishNotReadyAddresses: true
		ports: [
			{
				name:       "redis"
				port:       6379
				targetPort: "redis"
			},
		]
		selector: {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  #config.#fullname
			"app.kubernetes.io/component": "redis"
		}
	}
}

#RedisClientService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#redisServiceName
		namespace: #config.metadata.namespace
		labels: #config.#redisLabels & {
			"app.kubernetes.io/component": "redis-client"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [
			{
				name:       "redis"
				port:       6379
				targetPort: "redis"
			},
		]
		selector: #config.#redisSelectorLabels
	}
}

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config:       #Config
	#_probeScript: string
	if #config.redis.auth.enabled {
		#_probeScript: "redis-cli -a \"$REDIS_PASSWORD\" ping"
	}
	if !#config.redis.auth.enabled {
		#_probeScript: "redis-cli ping"
	}

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      #config.#redisFullname
		namespace: #config.metadata.namespace
		labels:    #config.#redisLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config.#redisFullname)-headless"
		replicas:    1
		selector: matchLabels: #config.#redisSelectorLabels
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: #config.#redisSelectorLabels
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: "default"
				securityContext: {
					fsGroup: 999
				}
				terminationGracePeriodSeconds: 60
				containers: [
					{
						name:            "redis"
						image:           #config.redis.image.reference
						imagePullPolicy: #config.redis.image.pullPolicy
						command: ["redis-server"]
						args: [
							"/etc/redis/redis.conf",
							if #config.redis.auth.enabled {
								"--requirepass"
							},
							if #config.redis.auth.enabled {
								"$(REDIS_PASSWORD)"
							},
						]
						ports: [
							{
								name:          "redis"
								containerPort: 6379
							},
						]
						if #config.redis.auth.enabled {
							env: [
								{
									name: "REDIS_PASSWORD"
									valueFrom: secretKeyRef: {
										name: "\(#config.#redisFullname)-auth"
										key:  "redis-password"
									}
								},
							]
						}
						livenessProbe: {
							exec: command: [
								"sh",
								"-ec",
								#_probeScript,
							]
							failureThreshold:    6
							initialDelaySeconds: 20
							periodSeconds:       15
							timeoutSeconds:      5
						}
						readinessProbe: {
							exec: command: [
								"sh",
								"-ec",
								#_probeScript,
							]
							failureThreshold:    3
							initialDelaySeconds: 10
							periodSeconds:       10
							timeoutSeconds:      5
						}
						startupProbe: {
							exec: command: [
								"sh",
								"-ec",
								#_probeScript,
							]
							failureThreshold:    30
							initialDelaySeconds: 5
							periodSeconds:       10
							timeoutSeconds:      5
						}
						resources:       #config.redis.standalone.resources
						securityContext: #config.redis.securityContext
						volumeMounts: [
							{
								name:      "config"
								mountPath: "/etc/redis/redis.conf"
								subPath:   "redis-standalone.conf"
							},
							{
								name:      "data"
								mountPath: "/data"
							},
						]
					},
				]
				volumes: [
					{
						name: "config"
						configMap: name: "\(#config.#redisFullname)-config"
					},
					if !#config.redis.standalone.persistence.enabled {
						{
							name: "data"
							emptyDir: {}
						}
					},
				]
			}
		}
		if #config.redis.standalone.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: {
						name: "data"
						labels: {
							"app.kubernetes.io/name":     "redis"
							"app.kubernetes.io/instance": #config.#fullname
						}
					}
					spec: {
						accessModes: ["ReadWriteOnce"]
						resources: requests: storage: #config.redis.standalone.persistence.size
					}
				},
			]
		}
	}
}
