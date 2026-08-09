package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#RedisSVC: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata:   timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "redis-master"
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [
			{
				port:       6379
				targetPort: 6379
				protocol:   "TCP"
				name:       "redis"
			},
		]
		selector: {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  #config.metadata.name
		}
	}
}

#RedisHeadlessSVC: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata:   timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "redis-headless"
	}
	spec: corev1.#ServiceSpec & {
		type:      "ClusterIP"
		clusterIP: "None"
		ports: [
			{
				port:       6379
				targetPort: 6379
				protocol:   "TCP"
				name:       "redis"
			},
		]
		selector: {
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata:   timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "redis"
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas:    1
		serviceName: "\(#config.metadata.name)-redis-headless"
		selector: matchLabels: {
			"app.kubernetes.io/name":     "redis"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "redis"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: false
				if #config.redis.podSecurityContext != _|_ {
					securityContext: #config.redis.podSecurityContext
				}
				containers: [
					{
						name:  "redis"
						image: #config.redis.image.reference
						ports: [
							{
								containerPort: 6379
								name:          "redis"
							},
						]
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/data"
							},
						]
						if #config.redis.resources != _|_ {
							resources: #config.redis.resources
						}
						if #config.redis.securityContext != _|_ {
							securityContext: #config.redis.securityContext
						}
					},
				]
				if !#config.redis.persistence.enabled {
					volumes: [
						{
							name: "data"
							emptyDir: {}
						},
					]
				}
			}
		}
		if #config.redis.persistence.enabled {
			volumeClaimTemplates: [
				corev1.#PersistentVolumeClaim & {
					metadata: name: "data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: ["ReadWriteOnce"]
						if #config.redis.persistence.storageClass != "" {
							storageClassName: #config.redis.persistence.storageClass
						}
						resources: requests: storage: #config.redis.persistence.size
					}
				}
			]
		}
	}
}
