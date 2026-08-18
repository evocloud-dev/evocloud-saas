package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#RedisSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	stringData: {
		"password": #config.redis.auth.password
	}
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
	spec: {
		type: "ClusterIP"
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [
			{
				name:       "tcp-redis"
				port:       6379
				targetPort: "tcp-redis"
			},
		]
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
	spec: {
		type:      "ClusterIP"
		clusterIP: "None"
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [
			{
				name:       "tcp-redis"
				port:       6379
				targetPort: "tcp-redis"
			},
		]
	}
}

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		replicas: 1
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		serviceName: "\(#config.metadata.name)-redis-headless"
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "\(#config.metadata.name)-redis"
				"app.kubernetes.io/instance": #config.metadata.name
			}
			spec: {
				automountServiceAccountToken: false
				serviceAccountName: "\(#config.metadata.name)-redis"
				if #config.redis.podSecurityContext != _|_ {
					securityContext: #config.redis.podSecurityContext
				}
				containers: [
					{
						name:            "redis"
						image:           "\(#config.redis.image.registry)/\(#config.redis.image.repository):\(#config.redis.image.tag)"
						imagePullPolicy: "IfNotPresent"
						env: [
							{
								name: "REDIS_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(#config.metadata.name)-redis"
									key:  "password"
								}
							},
						]
						args: [
							"--requirepass",
							"$(REDIS_PASSWORD)",
						]
						ports: [
							{
								name:          "tcp-redis"
								containerPort: 6379
							},
						]
						if #config.redis.resources != _|_ {
							resources: #config.redis.resources
						}
						if #config.redis.securityContext != _|_ {
							securityContext: #config.redis.securityContext
						}
						if #config.redis.persistence.enabled {
							volumeMounts: [
								{
									name:      "redis-data"
									mountPath: "/data"
								},
							]
						}
					},
				]
			}
		}
		if #config.redis.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: name: "redis-data"
					spec: {
						accessModes: #config.redis.persistence.accessModes
						if #config.redis.persistence.resources != _|_ {
							resources: #config.redis.persistence.resources
						}
						if #config.redis.persistence.storageClassName != "" {
							storageClassName: #config.redis.persistence.storageClassName
						}
					}
				},
			]
		}
	}
}

#RedisServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      "\(#config.metadata.name)-redis"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
}
