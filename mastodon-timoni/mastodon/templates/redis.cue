package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Redis: {
	#config: #Config

	#name: "\(#config.metadata.name)-redis"

	service: corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			namespace: #config.#namespace
			name:      "\(#name)-master"
			labels:    #config.metadata.labels
		}
		spec: corev1.#ServiceSpec & {
			type: "ClusterIP"
			ports: [{
				name:       "tcp-redis"
				port:       #config.redis.port
				targetPort: "redis"
			}]
			selector: "app.kubernetes.io/name": #name
		}
	}

	statefulSet: appsv1.#StatefulSet & {
		apiVersion: "apps/v1"
		kind:       "StatefulSet"
		metadata: {
			namespace: #config.#namespace
			name:      "\(#name)-master"
			labels:    #config.metadata.labels
		}
		spec: appsv1.#StatefulSetSpec & {
			replicas: 1
			selector: matchLabels: "app.kubernetes.io/name": #name
			serviceName: "\(#name)-master"
			template: {
				metadata: labels: "app.kubernetes.io/name": #name
				spec: corev1.#PodSpec & {
					containers: [{
						name:  "redis"
						image: "\(#config.redis.image.repository):\(#config.redis.image.tag)"
						imagePullPolicy: #config.redis.image.pullPolicy
						args: [
							"--requirepass",
							"$(REDIS_PASSWORD)",
						]
						env: [
							{
								name: "REDIS_PASSWORD"
								valueFrom: secretKeyRef: {
									if #config.redis.auth.existingSecret != "" {
										name: #config.redis.auth.existingSecret
									}
									if #config.redis.auth.existingSecret == "" {
										name: #name
									}
									key: #config.redis.auth.existingSecretKey
								}
							},
						]
						ports: [{
							name:          "redis"
							containerPort: #config.redis.port
						}]
						livenessProbe: {
							exec: command: ["redis-cli", "ping"]
							initialDelaySeconds: 30
							periodSeconds:        10
							timeoutSeconds:       5
							successThreshold:     1
							failureThreshold:     6
						}
						readinessProbe: {
							exec: command: ["redis-cli", "ping"]
							initialDelaySeconds: 5
							periodSeconds:        10
							timeoutSeconds:       5
							successThreshold:     1
							failureThreshold:     6
						}
						volumeMounts: [{
							name:      "redis-data"
							mountPath: "/bitnami/redis/data"
						}]
					}]
				}
			}
			volumeClaimTemplates: [{
				metadata: name: "redis-data"
				spec: corev1.#PersistentVolumeClaimSpec & {
					accessModes: ["ReadWriteOnce"]
					resources: requests: storage: "8Gi"
				}
			}]
		}
	}
}
