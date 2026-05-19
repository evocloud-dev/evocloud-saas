package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#RedisService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-redis-master"
		namespace: #config.metadata.namespace
		labels: {
			chart:                         #config.metadata.labels.chart
			release:                       #config.metadata.labels.release
			heritage:                      #config.metadata.labels.heritage
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  #config.fullname
			"app.kubernetes.io/component": "master"
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "tcp-redis"
			port:       6379
			targetPort: "redis"
		}]
		selector: {
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.fullname
		}
	}
}

#RedisHeadlessService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-redis-headless"
		namespace: #config.metadata.namespace
		labels: {
			chart:                         #config.metadata.labels.chart
			release:                       #config.metadata.labels.release
			heritage:                      #config.metadata.labels.heritage
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  #config.fullname
			"app.kubernetes.io/component": "master"
		}
	}
	spec: {
		type:      "ClusterIP"
		clusterIP: "None"
		ports: [{
			name:       "tcp-redis"
			port:       6379
			targetPort: "redis"
		}]
		selector: {
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.fullname
		}
	}
}

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.fullname)-redis-master"
		namespace: #config.metadata.namespace
		labels: {
			chart:                         #config.metadata.labels.chart
			release:                       #config.metadata.labels.release
			heritage:                      #config.metadata.labels.heritage
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  #config.fullname
			"app.kubernetes.io/component": "master"
		}
	}
	spec: {
		serviceName: "\(#config.fullname)-redis-headless"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  #config.fullname
			"app.kubernetes.io/component": "master"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":      "redis"
				"app.kubernetes.io/instance":  #config.fullname
				"app.kubernetes.io/component": "master"
			}
			spec: {
				containers: [{
					name:  "redis"
					image: "\(#config.redis.image.registry)/\(#config.redis.image.repository):\(#config.redis.image.tag)"
					command: ["redis-server"]
					args: ["--save", "60", "1", "--dir", "/data", "--loglevel", "warning", "--protected-mode", "no"]
					env: [
						if #config.redis.auth.enabled {
							{
								name:  "REDIS_PASSWORD"
								value: #config.redis.auth.password
							}
						},
						{
							name:  "ALLOW_EMPTY_PASSWORD"
							value: "yes"
						},
						{
							name:  "REDIS_REPLICATION_MODE"
							value: "master"
						},
						{
							name:  "REDIS_PORT"
							value: "6379"
						},
					]
					ports: [{
						name:          "redis"
						containerPort: 6379
					}]
					livenessProbe: {
						exec: command: ["redis-cli", "ping"]
						initialDelaySeconds: 30
						periodSeconds:       10
						timeoutSeconds:      5
						successThreshold:    1
						failureThreshold:    5
					}
					readinessProbe: {
						exec: command: ["redis-cli", "ping"]
						initialDelaySeconds: 5
						periodSeconds:       10
						timeoutSeconds:      5
						successThreshold:    1
						failureThreshold:    5
					}
					volumeMounts: [
						{
							name:      "redis-data"
							mountPath: "/data"
						},
					]
				}]
				volumes: [{
					name: "redis-data"
					emptyDir: {}
				}]
			}
		}
	}
}
