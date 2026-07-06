package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#Redis: {
	#config: #Config

	objects: [
		corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-redis-master"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: corev1.#ServiceSpec & {
				ports: [{
					name:       "redis"
					port:       6379
					protocol:   "TCP"
					targetPort: "redis"
				}]
				selector: {
					"app.kubernetes.io/name":      "redis"
					"app.kubernetes.io/instance":  #config.metadata.name
				}
				type: "ClusterIP"
			}
		},
		appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "\(#config.metadata.name)-redis"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: appsv1.#StatefulSetSpec & {
				replicas: 1
				selector: matchLabels: {
					"app.kubernetes.io/name":      "redis"
					"app.kubernetes.io/instance":  #config.metadata.name
				}
				serviceName: "\(#config.metadata.name)-redis"
				template: {
					metadata: labels: {
						"app.kubernetes.io/name":      "redis"
						"app.kubernetes.io/instance":  #config.metadata.name
					}
					spec: corev1.#PodSpec & {
						containers: [{
							name:  "redis"
							image: "\(#config.redis.image.repository):\(#config.redis.image.tag)"
							env: [{
								name:  "REDIS_REPLICATION_MODE"
								value: "master"
							}, {
								name:  "ALLOW_EMPTY_PASSWORD"
								value: "yes"
							}]
							ports: [{
								name:          "redis"
								containerPort: 6379
							}]
							volumeMounts: [{
								name:      "redis-data"
								mountPath: "/bitnami/redis/data"
							}]
						}]
						if !#config.redis.persistence.enabled {
							volumes: [{
								name: "redis-data"
								emptyDir: {}
							}]
						}
					}
				}
				if #config.redis.persistence.enabled {
					volumeClaimTemplates: [{
						metadata: name: "redis-data"
						spec: corev1.#PersistentVolumeClaimSpec & {
							if len(#config.redis.persistence.accessModes) > 0 {
								accessModes: #config.redis.persistence.accessModes
							}
							resources: #config.redis.persistence.resources
							if #config.redis.persistence.storageClassName != "" {
								storageClassName: #config.redis.persistence.storageClassName
							}
						}
					}]
				}
			}
		}
	]
}
