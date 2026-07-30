package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#RabbitMQStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name: #config.metadata.name + "-rabbitmq"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels
	}
	spec: {
		serviceName: "rabbitmq"
		replicas: 1
		selector: {matchLabels: {app: #config.metadata.name + "-rabbitmq"}}
		template: {
			metadata: {labels: {app: #config.metadata.name + "-rabbitmq"}}
			spec: {
				automountServiceAccountToken: false
				serviceAccountName:           #config.metadata.name
				securityContext: {
					runAsUser:    999
					runAsGroup:   999
					fsGroup:      999
					runAsNonRoot: true
					seccompProfile: type: "RuntimeDefault"
				}
				initContainers: [
					{
						name:  "fix-rabbitmq-permissions"
						image: "busybox:latest"
						securityContext: {
							runAsUser:    0
							runAsNonRoot: false
						}
						command: [
							"sh",
							"-c",
							"if [ ! -s /var/lib/rabbitmq/.erlang.cookie ]; then head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' > /var/lib/rabbitmq/.erlang.cookie; fi && chmod 600 /var/lib/rabbitmq/.erlang.cookie && chown -R 999:999 /var/lib/rabbitmq && chmod 700 /var/lib/rabbitmq",
						]
						volumeMounts: [{name: "rabbitmq-data", mountPath: "/var/lib/rabbitmq"}]
					},
				]
				containers: [{
					name: #config.metadata.name + "-rabbitmq"
					image: #config.rabbitmq.image
					securityContext: {
						allowPrivilegeEscalation: false
						runAsNonRoot:             true
					}
					resources: {
						requests: {
							cpu:    "100m"
							memory: "256Mi"
						}
						limits: {
							cpu:    "500m"
							memory: "512Mi"
						}
					}
					ports: [{containerPort: 5672, name: "amqp"}]
					env: [
						{name: "RABBITMQ_DEFAULT_USER", value: "guest"},
						{name: "RABBITMQ_DEFAULT_PASS", value: "guest"}
					]
					volumeMounts: [{
						name:      "rabbitmq-data"
						mountPath: "/var/lib/rabbitmq"
					}]
				}]
			}
		}
		volumeClaimTemplates: [
			corev1.#PersistentVolumeClaim & {
				metadata: name: "rabbitmq-data"
				spec: corev1.#PersistentVolumeClaimSpec & {
					accessModes: ["ReadWriteOnce"]
					resources: {
						requests: storage: "5Gi"
					}
				}
			},
		]
	}
}

#RabbitMQService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name: #config.metadata.name + "-rabbitmq"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels
	}
	spec: {
		type: "ClusterIP"
		ports: [{port: 5672, targetPort: "amqp", name: "amqp"}]
		selector: {app: #config.metadata.name + "-rabbitmq"}
	}
}

#RabbitMQServiceAlias: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name: "rabbitmq"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels
	}
	spec: {
		type: "ClusterIP"
		ports: [{port: 5672, targetPort: "amqp", name: "amqp"}]
		selector: {app: #config.metadata.name + "-rabbitmq"}
	}
}
