package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
)

#RedisSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-redis-auth"
		namespace: #config.namespace
		labels:    #config.metadata.labels & #config.commonLabels
	}
	type: "Opaque"
	stringData: {
		"redis-password": #config.redis.auth.password
	}
}

#RedisService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-redis-client"
		namespace: #config.namespace
		labels:    #config.metadata.labels & #config.commonLabels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [{
			port:       #config.redis.service.port
			targetPort: 6379
			protocol:   "TCP"
			name:       "redis"
		}]
		selector: {
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#RedisHeadlessService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.fullname)-redis-headless"
		namespace: #config.namespace
		labels:    #config.metadata.labels & #config.commonLabels
	}
	spec: corev1.#ServiceSpec & {
		type:      "ClusterIP"
		clusterIP: "None"
		ports: [{
			port:       #config.redis.service.port
			targetPort: 6379
			protocol:   "TCP"
			name:       "redis"
		}]
		selector: {
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.fullname)-redis"
		namespace: #config.namespace
		labels:    #config.metadata.labels & #config.commonLabels
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas:    1
		serviceName: "\(#config.fullname)-redis-headless"
		selector: matchLabels: {
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "redis"
				"app.kubernetes.io/instance": #config.metadata.name
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: false
				serviceAccountName:           #config.serviceAccountName
				if #config.redis.podSecurityContext != _|_ {
					securityContext: #config.redis.podSecurityContext
				}
				containers: [{
					name:            "redis"
					image:           "\(#config.redis.image.repository):\(#config.redis.image.tag)"
					imagePullPolicy: #config.redis.image.pullPolicy
					command: ["redis-server"]
					if #config.hasRedisPassword {
						args: [
							"--requirepass",
							"$(REDIS_PASSWORD)",
						]
						env: [{
							name: "REDIS_PASSWORD"
							valueFrom: secretKeyRef: {
								name: "\(#config.fullname)-redis-auth"
								key:  "redis-password"
							}
						}]
					}
					ports: [{
						containerPort: 6379
						name:          "redis"
					}]
					volumeMounts: [{
						name:      "data"
						mountPath: "/data"
					}]
					if #config.redis.standalone.resources != _|_ {
						resources: #config.redis.standalone.resources
					}
					if #config.redis.securityContext != _|_ {
						securityContext: #config.redis.securityContext
					}
				}]
				if !#config.redis.standalone.persistence.enabled {
					volumes: [{
						name: "data"
						emptyDir: {}
					}]
				}
			}
		}
		if #config.redis.standalone.persistence.enabled {
			volumeClaimTemplates: [
				corev1.#PersistentVolumeClaim & {
					metadata: name: "data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: ["ReadWriteOnce"]
						if #config.redis.standalone.persistence.storageClass != "" {
							storageClassName: #config.redis.standalone.persistence.storageClass
						}
						resources: requests: (corev1.#ResourceStorage): resource.#Quantity & #config.redis.standalone.persistence.size
					}
				},
			]
		}
	}
}
