package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#RedisService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name: "\(#config.metadata.name)-redis"
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "redis"
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		selector: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/component": "redis"
		}
		ports: [
			{
				port:       #config.redis.internal.service.port
				targetPort: #config.redis.internal.service.port
				protocol:   "TCP"
				name:       "redis"
			},
		]
	}
}
