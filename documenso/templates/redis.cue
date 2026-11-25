package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#RedisAuthSecret: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.#fullname)-redis-auth"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.commonLabels { "\(k)": v }
			"app.kubernetes.io/name":       "redis"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/version":    #config.redis.image.tag
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/part-of":    "helmforge"
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	type: "Opaque"
	stringData: {
		"redis-password": [if #config.redis.auth.password != "" { #config.redis.auth.password }, "insecure-default-redis-password"][0]
	}
}

#RedisConfigMap: {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.#fullname)-redis-config"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.commonLabels { "\(k)": v }
			"app.kubernetes.io/name":       "redis"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/version":    #config.redis.image.tag
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/part-of":    "helmforge"
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	data: {
		"redis-standalone.conf": """
			bind 0.0.0.0
			protected-mode no
			port 6379
			dir /data
			appendonly yes
			save 900 1
			save 300 10
			save 60 10000

			"""
	}
}

#RedisHeadlessService: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.#fullname)-redis-headless"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.commonLabels { "\(k)": v }
			"app.kubernetes.io/name":       "redis"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/version":    #config.redis.image.tag
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/part-of":    "helmforge"
			"app.kubernetes.io/component":  "redis-headless"
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	spec: {
		clusterIP:                "None"
		publishNotReadyAddresses: true
		ports: [{
			name:       "redis"
			port:       6379
			targetPort: "redis"
		}]
		selector: {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "redis"
		}
	}
}

#RedisService: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.#fullname)-redis-client"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.commonLabels { "\(k)": v }
			"app.kubernetes.io/name":       "redis"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/version":    #config.redis.image.tag
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/part-of":    "helmforge"
			"app.kubernetes.io/component":  "redis-client"
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "redis"
			port:       6379
			targetPort: "redis"
		}]
		selector: {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "redis"
			"app.kubernetes.io/role":      "standalone"
		}
	}
}

#RedisStatefulSet: {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.#fullname)-redis"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.commonLabels { "\(k)": v }
			"app.kubernetes.io/name":       "redis"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/version":    #config.redis.image.tag
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/part-of":    "helmforge"
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config.#fullname)-redis-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "redis"
			"app.kubernetes.io/part-of":   "redis"
			"app.kubernetes.io/role":      "standalone"
		}
		template: {
			metadata: labels: {
				for k, v in #config.commonLabels { "\(k)": v }
				"app.kubernetes.io/name":      "redis"
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/component": "redis"
				"app.kubernetes.io/part-of":   "redis"
				"app.kubernetes.io/role":      "standalone"
			}
			spec: {
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				securityContext:              #config.redis.podSecurityContext
				terminationGracePeriodSeconds: 60
				containers: [{
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
					ports: [{
						name:          "redis"
						containerPort: 6379
					}]
					if #config.redis.auth.enabled {
						env: [{
							name: "REDIS_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #config.#redisSecretName
								key:  #config.#redisSecretKey
							}
						}]
					}
					livenessProbe: {
						exec: command: [
							"sh",
							"-ec",
							if #config.redis.auth.enabled {
								"REDISCLI_AUTH=\"$REDIS_PASSWORD\" redis-cli  -p 6379 ping | grep -qx PONG"
							},
							if !#config.redis.auth.enabled {
								"redis-cli  -p 6379 ping | grep -qx PONG"
							},
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
							if #config.redis.auth.enabled {
								"REDISCLI_AUTH=\"$REDIS_PASSWORD\" redis-cli  -p 6379 ping | grep -qx PONG"
							},
							if !#config.redis.auth.enabled {
								"redis-cli  -p 6379 ping | grep -qx PONG"
							},
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
							if #config.redis.auth.enabled {
								"REDISCLI_AUTH=\"$REDIS_PASSWORD\" redis-cli  -p 6379 ping | grep -qx PONG"
							},
							if !#config.redis.auth.enabled {
								"redis-cli  -p 6379 ping | grep -qx PONG"
							},
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
				}]
				volumes: [
					{
						name: "config"
						configMap: name: "\(#config.#fullname)-redis-config"
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
			volumeClaimTemplates: [{
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
			}]
		}
	}
}
