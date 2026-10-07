package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#RedisSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "redis-auth"
	}
	type: corev1.#SecretTypeOpaque
	stringData: {
		"redis-password": "redis"
	}
}

#RedisConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "redis-config"
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
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "redis-headless"
	}
	metadata: labels: {
		"app.kubernetes.io/component": "redis-headless"
	}
	spec: corev1.#ServiceSpec & {
		clusterIP:                "None"
		publishNotReadyAddresses: true
		selector: {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "redis"
		}
		ports: [
			{
				name:       "redis"
				port:       6379
				targetPort: "redis"
			},
		]
	}
}

#RedisService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "redis"
	}
	spec: corev1.#ServiceSpec & {
		type: corev1.#ServiceTypeClusterIP
		selector: {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "redis"
			"app.kubernetes.io/role":      "standalone"
		}
		ports: [
			{
				name:       "redis"
				port:       6379
				targetPort: "redis"
			},
		]
	}
}

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "redis"
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config.metadata.name)-redis-headless"
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
				"app.kubernetes.io/name":      "redis"
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/component": "redis"
				"app.kubernetes.io/part-of":   "redis"
				"app.kubernetes.io/role":      "standalone"
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: "default"
				if #config.redis.automountServiceAccountToken != _|_ {
					automountServiceAccountToken: #config.redis.automountServiceAccountToken
				}
				if #config.redis.podSecurityContext != _|_ {
					securityContext: #config.redis.podSecurityContext
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
							"--requirepass",
							"$(REDIS_PASSWORD)",
						]
						ports: [
							{
								name:          "redis"
								containerPort: 6379
							},
						]
						env: [
							{
								name: "REDIS_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-redis-auth"
									key:  "redis-password"
								}
							},
						]
						livenessProbe: {
							exec: command: [
								"sh",
								"-ec",
								"REDISCLI_AUTH=\"$REDIS_PASSWORD\" redis-cli -p 6379 ping | grep -qx PONG",
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
								"REDISCLI_AUTH=\"$REDIS_PASSWORD\" redis-cli -p 6379 ping | grep -qx PONG",
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
								"REDISCLI_AUTH=\"$REDIS_PASSWORD\" redis-cli -p 6379 ping | grep -qx PONG",
							]
							failureThreshold:    30
							initialDelaySeconds: 5
							periodSeconds:       10
							timeoutSeconds:      5
						}
						if #config.redis.resources != _|_ {
							resources: #config.redis.resources
						}
						if #config.redis.securityContext != _|_ {
							securityContext: #config.redis.securityContext
						}
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
				spec: corev1.#PersistentVolumeClaimSpec & {
					accessModes: #config.redis.persistence.accessModes
					if #config.redis.persistence.storageClass != "" {
						storageClassName: #config.redis.persistence.storageClass
					}
					resources: requests: {
						(corev1.#ResourceStorage): #config.redis.persistence.size
					}
				}
			},
		]
	}
}
