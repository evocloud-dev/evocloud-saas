package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#RedisConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.#fullname)-redis-config"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
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

#RedisHeadlessService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.#fullname)-redis-headless"
		namespace: #config.metadata.namespace
		labels: {
			#config.metadata.labels
			"app.kubernetes.io/component": "redis-headless"
		}
	}
	spec: corev1.#ServiceSpec & {
		clusterIP:                corev1.#ClusterIPNone
		publishNotReadyAddresses: true
		ports: [
			{
				name:       "redis"
				port:       6379
				targetPort: "redis"
			},
		]
		selector: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/component": "redis"
		}
	}
}

#RedisClientService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.#fullname)-redis-client"
		namespace: #config.metadata.namespace
		labels: {
			#config.metadata.labels
			"app.kubernetes.io/component": "redis-client"
		}
	}
	spec: corev1.#ServiceSpec & {
		type: corev1.#ServiceTypeClusterIP
		ports: [
			{
				name:       "redis"
				port:       6379
				targetPort: "redis"
			},
		]
		selector: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/component": "redis"
			"app.kubernetes.io/role":      "standalone"
		}
	}
}

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.#fullname)-redis"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(#config.#fullname)-redis-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/component": "redis"
			"app.kubernetes.io/role":      "standalone"
		}
		template: {
			metadata: {
				labels: {
					#config.metadata.labels
					"app.kubernetes.io/component": "redis"
					"app.kubernetes.io/role":      "standalone"
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            "default"
				automountServiceAccountToken:  false
				securityContext:               #config.redis.podSecurityContext
				terminationGracePeriodSeconds: 60
				containers: [
					{
						name:            "redis"
						image:           #config.redis.image.reference
						imagePullPolicy: #config.redis.image.pullPolicy
						command: ["redis-server"]
						args: ["/etc/redis/redis.conf"]
						ports: [
							{
								name:          "redis"
								containerPort: 6379
							},
						]
						livenessProbe: {
							exec: command: [
								"sh",
								"-ec",
								"redis-cli -p 6379 ping | grep -qx PONG",
							]
							initialDelaySeconds: 20
							periodSeconds:       15
							timeoutSeconds:      5
							failureThreshold:    6
						}
						readinessProbe: {
							exec: command: [
								"sh",
								"-ec",
								"redis-cli -p 6379 ping | grep -qx PONG",
							]
							initialDelaySeconds: 10
							periodSeconds:       10
							timeoutSeconds:      5
							failureThreshold:    3
						}
						startupProbe: {
							exec: command: [
								"sh",
								"-ec",
								"redis-cli -p 6379 ping | grep -qx PONG",
							]
							initialDelaySeconds: 5
							periodSeconds:       10
							timeoutSeconds:      5
							failureThreshold:    30
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
						configMap: name: "\(#config.#fullname)-redis-config"
					},
				]
			}
		}
		volumeClaimTemplates: [
			{
				metadata: {
					name:   "data"
					labels: #config.metadata.labels
				}
				spec: corev1.#PersistentVolumeClaimSpec & {
					accessModes: [corev1.#ReadWriteOnce]
					resources: requests: (corev1.#ResourceStorage): #config.redis.standalone.persistence.size
				}
			},
		]
	}
}
