package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)


#RabbitMQ: {
	#config: #Config

	objects: [
		corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(#config.metadata.name)-rabbitmq"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			type: corev1.#SecretTypeOpaque
			stringData: {
				"rabbitmq-password": #config.config.rabbitmq.auth.password
			}
		},
		corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-rabbitmq"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: corev1.#ServiceSpec & {
				ports: [{
					name:       "amqp"
					port:       5672
					protocol:   "TCP"
					targetPort: "amqp"
				}, {
					name:       "stats"
					port:       15672
					protocol:   "TCP"
					targetPort: "stats"
				}]
				selector: {
					"app.kubernetes.io/name":      "rabbitmq"
					"app.kubernetes.io/instance":  #config.metadata.name
				}
				type: "ClusterIP"
			}
		},
		appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "\(#config.metadata.name)-rabbitmq"
				namespace: #config.metadata.namespace
				labels:    #config.metadata.labels
			}
			spec: appsv1.#StatefulSetSpec & {
				replicas: 1
				selector: matchLabels: {
					"app.kubernetes.io/name":      "rabbitmq"
					"app.kubernetes.io/instance":  #config.metadata.name
				}
				serviceName: "\(#config.metadata.name)-rabbitmq"
				template: {
					metadata: labels: {
						"app.kubernetes.io/name":      "rabbitmq"
						"app.kubernetes.io/instance":  #config.metadata.name
					}
					spec: corev1.#PodSpec & {
						containers: [{
							name:  "rabbitmq"
							image: "\(#config.rabbitmq.image.repository):\(#config.rabbitmq.image.tag)"
							env: [{
								name:  "RABBITMQ_USERNAME"
								value: #config.#rabbitmqUsername
							}, {
								name: "RABBITMQ_PASSWORD"
								valueFrom: secretKeyRef: {
									key:  "rabbitmq-password"
									name: "\(#config.metadata.name)-rabbitmq"
								}
							}]
							ports: [{
								name:          "amqp"
								containerPort: 5672
							}, {
								name:          "stats"
								containerPort: 15672
							}]
							volumeMounts: [{
								name:      "rabbitmq-data"
								mountPath: "/var/lib/rabbitmq"
							}]
						}]
						if !#config.rabbitmq.persistence.enabled {
							volumes: [{
								name: "rabbitmq-data"
								emptyDir: {}
							}]
						}
					}
				}
				if #config.rabbitmq.persistence.enabled {
					volumeClaimTemplates: [{
						metadata: name: "rabbitmq-data"
						spec: corev1.#PersistentVolumeClaimSpec & {
							if len(#config.rabbitmq.persistence.accessModes) > 0 {
								accessModes: #config.rabbitmq.persistence.accessModes
							}
							resources: #config.rabbitmq.persistence.resources
							if #config.rabbitmq.persistence.storageClassName != "" {
								storageClassName: #config.rabbitmq.persistence.storageClassName
							}
						}
					}]
				}
			}
		}
	]
}
