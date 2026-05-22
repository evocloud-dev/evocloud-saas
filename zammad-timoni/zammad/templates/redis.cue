package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#RedisConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-redis-config"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "redis"
		}
	}
	data: {
		"redis.conf": """
			# Redis configuration
			bind * -::*
			port 6379
			"""
	}
}

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "redis"
		}
	}
	spec: {
		serviceName: "\(#config.metadata.name)-redis-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "redis"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/component": "redis"
			}
			spec: {
				automountServiceAccountToken: false
				securityContext: {
					fsGroup: 999
				}
				containers: [
					{
						name:            "redis"
						image:           #config._redisImageRef
						imagePullPolicy: #config.redis.image.pullPolicy
						command: [
							"/bin/sh",
							"-c",
							"CONFIG_FILE=\"/usr/local/etc/redis/redis.conf\"\nredis-server \"$CONFIG_FILE\" --requirepass \"${REDIS_PASSWORD}\"\n"
						]
						securityContext: {
							allowPrivilegeEscalation: false
							runAsUser:                999
							runAsGroup:               999
							runAsNonRoot:            true
							readOnlyRootFilesystem:  true
						}
						ports: [{
							name:          "redis"
							containerPort: 6379
						}]
						if #config.redis.resources != _|_ {
							resources: #config.redis.resources
						}
						env: [{
							name: "REDIS_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #config._redisSecretName
								key:  "redis-password"
							}
						}, {
							name: "REDISCLI_AUTH"
							valueFrom: secretKeyRef: {
								name: #config._redisSecretName
								key:  "redis-password"
							}
						}]
						livenessProbe: {
							exec: command: ["/bin/sh", "-c", "redis-cli -h 127.0.0.1 ping"]
							initialDelaySeconds: 30
							periodSeconds:       10
							timeoutSeconds:      10
						}
						readinessProbe: {
							exec: command: ["/bin/sh", "-c", "redis-cli -h 127.0.0.1 ping"]
							initialDelaySeconds: 5
							periodSeconds:       10
							timeoutSeconds:      10
						}
						volumeMounts: [{
							name:      "data"
							mountPath: "/data"
						}, {
							name:      "config"
							mountPath: "/usr/local/etc/redis"
						}]
					},
					if #config.zammadConfig.redis.sentinel.enabled {
						{
							name:            "sentinel"
							image:           #config._redisImageRef
							imagePullPolicy: #config.redis.image.pullPolicy
							command: [
								"/bin/sh",
								"-c",
								"cat > /tmp/sentinel.conf <<EOF\nport 26379\nsentinel monitor mymaster ${MY_POD_IP} 6379 1\nsentinel down-after-milliseconds mymaster 5000\nsentinel failover-timeout mymaster 60000\nsentinel parallel-syncs mymaster 1\nsentinel auth-pass mymaster ${REDIS_PASSWORD}\nrequirepass ${REDIS_PASSWORD}\nprotected-mode no\nEOF\nredis-sentinel /tmp/sentinel.conf\n"
							]
							ports: [{
								name:          "sentinel"
								containerPort: 26379
							}]
							env: [{
								name: "REDIS_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config._redisSecretName
									key:  "redis-password"
								}
							}, {
								name: "MY_POD_IP"
								valueFrom: fieldRef: fieldPath: "status.podIP"
							}]
							volumeMounts: [{
								name:      "empty-dir"
								mountPath: "/tmp"
							}]
						}
					}
				]
				volumes: [
					{
						name: "config"
						configMap: name: "\(#config.metadata.name)-redis-config"
					},
					if #config.zammadConfig.redis.sentinel.enabled {
						{
							name: "empty-dir"
							emptyDir: {}
						}
					}
				]
			}
		}
		volumeClaimTemplates: [{
			apiVersion: "v1"
			kind:       "PersistentVolumeClaim"
			metadata: name: "data"
			spec: {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: "8Gi"
			}
		}]
	}
}

#RedisService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis-master"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "redis"
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "redis"
			port:       6379
			targetPort: "redis"
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "redis"
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
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "redis"
		}
	}
	spec: {
		clusterIP: "None"
		ports: [{
			name:       "redis"
			port:       6379
			targetPort: "redis"
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "redis"
		}
	}
}

#RedisSentinelService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "redis"
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "sentinel"
			port:       26379
			targetPort: "sentinel"
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "redis"
		}
	}
}
