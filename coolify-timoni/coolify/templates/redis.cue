package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Redis: {
	#config: #Config
	if #config.redis.enabled {
		service: corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-redis-master"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels & {
					"app.kubernetes.io/component": "redis"
				}
			}
			spec: corev1.#ServiceSpec & {
				type: "ClusterIP"
				ports: [
					{
						name:       "redis"
						port:       #config.redis.service.ports.redis
						targetPort: "redis"
					},
				]
				selector: {
					"app.kubernetes.io/name":      #config.metadata.name
					"app.kubernetes.io/component": "redis"
				}
			}
		}

		headlessService: corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-redis-headless"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels & {
					"app.kubernetes.io/component": "redis"
				}
			}
			spec: corev1.#ServiceSpec & {
				type:      "ClusterIP"
				clusterIP: "None"
				ports: [
					{
						name:       "redis"
						port:       #config.redis.service.ports.redis
						targetPort: "redis"
					},
				]
				selector: {
					"app.kubernetes.io/name":      #config.metadata.name
					"app.kubernetes.io/component": "redis"
				}
			}
		}

		statefulSet: appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "\(#config.metadata.name)-redis-master"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels & {
					"app.kubernetes.io/component": "redis"
				}
			}
			spec: appsv1.#StatefulSetSpec & {
				serviceName: "\(#config.metadata.name)-redis-headless"
				replicas:    1
				selector: matchLabels: {
					"app.kubernetes.io/name":      #config.metadata.name
					"app.kubernetes.io/component": "redis"
				}
				template: {
					metadata: labels: {
						"app.kubernetes.io/name":      #config.metadata.name
						"app.kubernetes.io/component": "redis"
					}
					spec: corev1.#PodSpec & {
						containers: [
							{
								name:            "redis"
								image:           "\(#config.redis.image.repository):\(#config.redis.image.tag)"
								imagePullPolicy: #config.redis.image.pullPolicy
								command: ["/bin/sh"]
								args: [
									"-c",
									"valkey-server --requirepass \"$REDIS_PASSWORD\"",
								]
								env: [
									{
										name: "REDIS_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-redis"
											key:  "redis-password"
										}
									},
									{
										name:  "ALLOW_EMPTY_PASSWORD"
										value: "no"
									},
								]
								ports: [
									{
										name:          "redis"
										containerPort: #config.redis.service.ports.redis
									},
								]
								volumeMounts: [
									{
										name:      "redis-data"
										mountPath: "/data"
									},
								]
								if #config.redis.master.resources != _|_ {
									resources: #config.redis.master.resources
								}
								livenessProbe: {
									exec: command: [
										"sh",
										"-c",
										"redis-cli -a $REDIS_PASSWORD ping",
									]
									initialDelaySeconds: 30
									periodSeconds:       10
									timeoutSeconds:      5
									successThreshold:    1
									failureThreshold:    5
								}
								readinessProbe: {
									exec: command: [
										"sh",
										"-c",
										"redis-cli -a $REDIS_PASSWORD ping",
									]
									initialDelaySeconds: 5
									periodSeconds:       10
									timeoutSeconds:      1
									successThreshold:    1
									failureThreshold:    3
								}
							},
						]
					}
				}
				volumeClaimTemplates: [
					{
						metadata: name: "redis-data"
						spec: corev1.#PersistentVolumeClaimSpec & {
							accessModes: #config.redis.persistence.accessModes
							resources: requests: storage: #config.redis.persistence.size
							if #config.redis.persistence.storageClassName != "" {
								storageClassName: #config.redis.persistence.storageClassName
							}
						}
					},
				]
			}
		}
	}
}
