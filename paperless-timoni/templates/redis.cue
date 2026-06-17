package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#RedisSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	type:       "Opaque"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	stringData: "redis-password": #config.redis.auth.password
}

#RedisService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis-master"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type:     corev1.#ServiceTypeClusterIP
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "redis"
		}
		ports: [{
			name:       "redis"
			port:       6379
			targetPort: name
			protocol:   "TCP"
		}]
	}
}

#RedisHeadlessService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-redis-headless"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
		type:      corev1.#ServiceTypeClusterIP
		clusterIP: "None"
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "redis"
		}
		ports: [{
			name:       "redis"
			port:       6379
			targetPort: name
			protocol:   "TCP"
		}]
	}
}

#RedisDeployment: appsv1.#Deployment & {
	#config:    #Config
	#secretName: "\(#config.metadata.name)-redis"
	if #config.redis.auth.existingSecret != _|_ {
		#secretName: #config.redis.auth.existingSecret
	}
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-redis-master"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		revisionHistoryLimit: 3
		replicas:             1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "redis"
		}
		template: {
			metadata: labels: #config.selector.labels & {
				"app.kubernetes.io/component": "redis"
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           "default"
				automountServiceAccountToken: true
				dnsPolicy:                    "ClusterFirst"
				enableServiceLinks:           true
				containers: [{
					name:            "redis"
					image:           "\(#config.redis.image.repository):\(#config.redis.image.tag)"
					imagePullPolicy: #config.redis.image.pullPolicy
					args: [
						"redis-server",
						"--appendonly",
						if #config.redis.master.persistence.enabled {
							"yes"
						},
						if !#config.redis.master.persistence.enabled {
							"no"
						},
						"--save",
						"",
						if #config.redis.auth.enabled {
							"--requirepass"
						},
						if #config.redis.auth.enabled {
							"$(REDIS_PASSWORD)"
						},
					]
					if #config.redis.auth.enabled {
						env: [{
							name: "REDIS_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #secretName
								key:  #config.redis.auth.existingSecretPasswordKey
							}
						}]
					}
					ports: [{
						name:          "redis"
						containerPort: 6379
						protocol:      "TCP"
					}]
					resources: {
						requests: {
							cpu:    #config.redis.master.resources.requests.cpu
							memory: #config.redis.master.resources.requests.memory
						}
						limits: {
							cpu:    #config.redis.master.resources.limits.cpu
							memory: #config.redis.master.resources.limits.memory
						}
					}
					if #config.redis.master.persistence.enabled {
						volumeMounts: [{
							name:      "data"
							mountPath: "/data"
						}]
					}
				}]
				if #config.redis.master.persistence.enabled {
					volumes: [{
						name: "data"
						persistentVolumeClaim: claimName: "\(#config.metadata.name)-redis-master"
					}]
				}
			}
		}
	}
}

#RedisPersistentVolumeClaim: corev1.#PersistentVolumeClaim & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {
		name:      "\(#config.metadata.name)-redis-master"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
		if #config.redis.master.persistence.retain {
			annotations: "helm.sh/resource-policy": "keep"
		}
	}
	spec: corev1.#PersistentVolumeClaimSpec & {
		accessModes: [#config.redis.master.persistence.accessMode]
		if #config.redis.master.persistence.storageClass != _|_ {
			storageClassName: #config.redis.master.persSistence.storageClass
		}
		resources: requests: storage: #config.redis.master.persistence.size
	}
}