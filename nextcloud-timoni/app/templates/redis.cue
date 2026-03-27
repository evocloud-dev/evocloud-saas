package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Redis: {
	#in: #Config

	deployment: appsv1.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      #in.redis._name
			namespace: #in.metadata.namespace
			labels:    #in.metadata.labels & {
				"app.kubernetes.io/component": "redis"
			}
		}
		spec: appsv1.#DeploymentSpec & {
			selector: matchLabels: {
				"app.kubernetes.io/name":      #in.metadata.name
				"app.kubernetes.io/component": "redis"
			}
			template: {
				metadata: labels: {
					"app.kubernetes.io/name":      #in.metadata.name
					"app.kubernetes.io/component": "redis"
				}
				spec: corev1.#PodSpec & {
					containers: [
						{
							name:  "redis"
							image: "\(#in.redis.image.registry)/\(#in.redis.image.repository):\(#in.redis.image.tag)"
							ports: [
								{
									containerPort: #in.redis.port
									name:          "redis"
								},
							]
							if #in.redis.auth.enabled {
								env: [
									{
										name: "REDIS_PASSWORD"
										if #in.redis.auth.existingSecret == "" {
											value: #in.redis.auth.password
										}
										if #in.redis.auth.existingSecret != "" {
											valueFrom: secretKeyRef: {
												name: #in.redis.auth.existingSecret
												key:  #in.redis.auth.existingSecretPasswordKey
											}
										}
									},
								]
							}
							volumeMounts: [
								{
									name:      "data"
									mountPath: "/data"
								},
							]
						},
					]
					volumes: [
						{
							name: "data"
							if !#in.redis.master.persistence.enabled {
								emptyDir: {}
							}
							if #in.redis.master.persistence.enabled {
								persistentVolumeClaim: claimName: #in.redis._name
							}
						},
					]
				}
			}
		}
	}

	service: corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      #in.redis.primaryHost
			namespace: #in.metadata.namespace
			labels:    #in.metadata.labels & {
				"app.kubernetes.io/component": "redis"
			}
		}
		spec: corev1.#ServiceSpec & {
			type: corev1.#ServiceTypeClusterIP
			ports: [
				{
					port:       #in.redis.port
					targetPort: "redis"
					protocol:   "TCP"
					name:       "redis"
				},
			]
			selector: {
				"app.kubernetes.io/name":      #in.metadata.name
				"app.kubernetes.io/component": "redis"
			}
		}
	}
}
