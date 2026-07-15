package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#RedisStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	let c = #config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      *"\((c.metadata.name))-redis" | string
		namespace: c.metadata.namespace
		labels: c.metadata.labels & {
			"app.kubernetes.io/component": "redis"
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: *"\((c.metadata.name))-redis" | string
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/name":      c.metadata.name
			"app.kubernetes.io/component": "redis"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":      c.metadata.name
				"app.kubernetes.io/component": "redis"
			}
			spec: corev1.#PodSpec & {
				containers: [
					{
						name:            "redis"
						image:           "\(c.redis.image.repository):\(c.redis.image.tag)"
						imagePullPolicy: "IfNotPresent"
						ports: [
							{
								containerPort: 6379
								name:          "redis"
							},
						]
						args: [
							"--requirepass",
							"$(REDIS_PASSWORD)",
						]
						env: [
							{
								name: "REDIS_PASSWORD"
								valueFrom: secretKeyRef: {
									name: *"\((c.metadata.name))-server-redis" | string
									key:  "redis-password"
								}
							},
						]
						resources: c.redis.resources
						volumeMounts: [
							if c.redis.persistence.enabled {
								{
									name:      "redis-data"
									mountPath: "/data"
								}
							},
						]
					},
				]
			}
		}
		if c.redis.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: name: "redis-data"
					spec: corev1.#PersistentVolumeClaimSpec & {
						accessModes: c.redis.persistence.accessModes
						resources: requests: storage: c.redis.persistence.size
						if c.redis.persistence.storageClass != "" {
							storageClassName: c.redis.persistence.storageClass
						}
					}
				},
			]
		}
	}
}

#RedisService: corev1.#Service & {
	#config: #Config
	let c = #config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      *"\((c.metadata.name))-redis" | string
		namespace: c.metadata.namespace
		labels: c.metadata.labels & {
			"app.kubernetes.io/component": "redis"
		}
	}
	spec: corev1.#ServiceSpec & {
		ports: [
			{
				port:       c.redis.service.port
				targetPort: 6379
				name:       "redis"
			},
		]
		selector: {
			"app.kubernetes.io/name":      c.metadata.name
			"app.kubernetes.io/component": "redis"
		}
		type: "ClusterIP"
	}
}
