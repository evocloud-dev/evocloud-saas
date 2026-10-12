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
		name:      #config.#redisSecret
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/component": "redis"
		}
	}
	type: "Opaque"
	stringData: {
		"\(#config.#redisKey)": #config.#redisPassword
	}
}

#RedisConfig: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.#redisFullname)-config"
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/component": "redis"
		}
	}
	data: {
		"redis-standalone.conf": """
			bind 0.0.0.0
			port \(#config.redis.service.port)
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
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.#redisFullname)-headless"
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/component": "redis-headless"
		}
	}
	spec: {
		clusterIP:                "None"
		publishNotReadyAddresses: true
		selector: {
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [
			{
				name:       "redis"
				port:       #config.redis.service.port
				targetPort: "redis"
			},
		]
	}
}

#RedisService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#redisHost
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/component": "redis-client"
		}
	}
	spec: {
		type: "ClusterIP"
		selector: {
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/role":     "standalone"
		}
		ports: [
			{
				name:       "redis"
				port:       #config.redis.service.port
				targetPort: "redis"
				protocol:   "TCP"
			},
		]
	}
}

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      #config.#redisFullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/component": "redis"
		}
	}
	spec: {
		serviceName: "\(#config.#redisFullname)-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/role":     "standalone"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "redis"
				"app.kubernetes.io/instance": #config.metadata.name
				"app.kubernetes.io/role":     "standalone"
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            #config.#redisServiceAccountName
				automountServiceAccountToken: false
				terminationGracePeriodSeconds: #config.redis.terminationGracePeriodSeconds
				securityContext:               #config.redis.podSecurityContext
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
								containerPort: #config.redis.service.port
							},
						]
						env: [
							if #config.redis.auth.enabled {
								{
									name: "REDIS_PASSWORD"
									valueFrom: secretKeyRef: {
										name: #config.#redisSecret
										key:  #config.#redisKey
									}
								}
							},
						]
						livenessProbe: {
							exec: command: [
								"sh",
								"-ec",
								"REDISCLI_AUTH=\"$REDIS_PASSWORD\" redis-cli -p \(#config.redis.service.port) ping | grep -qx PONG",
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
								"REDISCLI_AUTH=\"$REDIS_PASSWORD\" redis-cli -p \(#config.redis.service.port) ping | grep -qx PONG",
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
								"REDISCLI_AUTH=\"$REDIS_PASSWORD\" redis-cli -p \(#config.redis.service.port) ping | grep -qx PONG",
							]
							failureThreshold:    30
							initialDelaySeconds: 5
							periodSeconds:       10
							timeoutSeconds:      5
						}
						resources:       #config.redis.resources
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
					if !#config.redis.persistence.enabled {
						{
							name: "data"
							emptyDir: {}
						}
					},
				]
			}
		}
		if #config.redis.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: {
						name: "data"
						labels: {
							"app.kubernetes.io/name":     "redis"
							"app.kubernetes.io/instance": #config.metadata.name
						}
					}
					spec: {
						accessModes: #config.redis.persistence.accessModes
						if #config.redis.persistence.storageClass != "" {
							if #config.redis.persistence.storageClass == "-" {
								storageClassName: ""
							}
							if #config.redis.persistence.storageClass != "-" {
								storageClassName: #config.redis.persistence.storageClass
							}
						}
						resources: requests: storage: #config.redis.persistence.size
					}
				},
			]
		}
	}
}
