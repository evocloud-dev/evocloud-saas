package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
)

#RedisServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels:    #config._redisLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
}

#RedisSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-redis-auth"
		namespace: #config.metadata.namespace
		labels:    #config._redisLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		"redis-password": #config._redisPassword
	}
}

#RedisConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-redis-config"
		namespace: #config.metadata.namespace
		labels:    #config._redisLabels
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


			maxmemory-policy noeviction
			appendonly yes

			"""
	}
}

#RedisHeadlessService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis-headless"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config._redisLabels {
				"\(k)": v
			}
			"app.kubernetes.io/component": "redis-headless"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		clusterIP:                "None"
		publishNotReadyAddresses: true
		ports: [
			{
				name:       "redis"
				port:       #config.redis.service.ports.redis
				targetPort: "redis"
			},
		]
		selector: {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "redis"
		}
	}
}

#RedisClientService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis-client"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config._redisLabels {
				"\(k)": v
			}
			"app.kubernetes.io/component": "redis-client"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [
			{
				name:       "redis"
				port:       #config.redis.service.ports.redis
				targetPort: "redis"
			},
		]
		selector: #config._redisSelectorLabels
	}
}

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels:    #config._redisLabels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		serviceName: "\(#config.metadata.name)-redis-headless"
		replicas:    1
		selector: matchLabels: #config._redisSelectorLabels
		template: {
			metadata: {
				labels: #config._redisSelectorLabels
				if #config.podAnnotations != _|_ {
					annotations: {
						for k, v in #config.podAnnotations {
							"\(k)": v
						}
					}
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "\(#config.metadata.name)-redis"
				securityContext:              #config.redis.podSecurityContext
				terminationGracePeriodSeconds: 60
				containers: [
					{
						name:            "redis"
						image:           #config.redis.image.reference
						imagePullPolicy: #config.redis.image.pullPolicy
						command: ["redis-server"]
						args: [
							"/etc/redis/redis.conf",
							"--requirepass",
							"$(REDIS_PASSWORD)",
						]
						ports: [
							{
								name:          "redis"
								containerPort: #config.redis.service.ports.redis
							},
						]
						env: [
							{
								name: "REDIS_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-redis-auth"
									key:  #config.redis.auth.existingSecretPasswordKey
								}
							},
						]
						livenessProbe: {
							exec: command: [
								"sh",
								"-ec",
								"REDISCLI_AUTH=\"$REDIS_PASSWORD\" redis-cli  -p \(#config.redis.service.ports.redis) ping | grep -qx PONG",
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
								"REDISCLI_AUTH=\"$REDIS_PASSWORD\" redis-cli  -p \(#config.redis.service.ports.redis) ping | grep -qx PONG",
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
								"REDISCLI_AUTH=\"$REDIS_PASSWORD\" redis-cli  -p \(#config.redis.service.ports.redis) ping | grep -qx PONG",
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
						configMap: name: "\(#config.metadata.name)-redis-config"
					},
				]
			}
		}
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
					accessModes: ["ReadWriteOnce"]
					resources: requests: storage: #config.redis.standalone.persistence.size
				}
			},
		]
	}
}

#RedisNetworkPolicy: networkingv1.#NetworkPolicy & {
	#config: #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(#config._fullname)-redis"
		namespace: #config.metadata.namespace
		labels:    #config._labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		podSelector: matchLabels: {
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/name":     "redis"
		}
		policyTypes: ["Ingress", "Egress"]
		ingress: [
			{
				from: [
					{
						podSelector: matchLabels: #config._selectorLabels
					},
				]
				ports: [{protocol: "TCP", port: #config.redis.service.ports.redis}]
			},
		]
		egress: []
	}
}