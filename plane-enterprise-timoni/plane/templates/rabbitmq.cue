package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#RabbitmqService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-rabbitmq"
		labels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-rabbitmq"
		}
	}
	spec: {
		type: "ClusterIP"
		if !#config.services.rabbitmq.assign_cluster_ip {
			clusterIP: "None"
		}
		ports: [{
			name:       "rabbitmq-5672"
			port:       5672
			protocol:   "TCP"
			targetPort: 5672
		}, {
			name:       "rabbitmq-mgmt-15672"
			port:       15672
			protocol:   "TCP"
			targetPort: 15672
		}]
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-rabbitmq"
		}
	}
}

#RabbitmqStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-rabbitmq-wl"
	}
	spec: {
		serviceName: "\(#config.metadata.name)-rabbitmq"
		// Replicas omitted to match literal Helm chart defaults
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-rabbitmq"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-rabbitmq"
				}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				// {{- include "plane.podScheduling" .Values.services.rabbitmq }}
				nodeSelector: #config.services.rabbitmq.nodeSelector
				tolerations:  #config.services.rabbitmq.tolerations
				affinity:     #config.services.rabbitmq.affinity

				containers: [{
					name:            "\(#config.metadata.name)-rabbitmq"
					image:           #config.services.rabbitmq.image
					imagePullPolicy: "IfNotPresent"
					ports: [{
						containerPort: 5672
						name:          "amqp"
					}, {
						containerPort: 15672
						name:          "management"
					}]
					stdin: true
					tty:   true
					envFrom: [{
						secretRef: {
							name:     "\(#config.metadata.name)-rabbitmq-secrets"
							optional: false
						}
					}]
					if #config.extraEnv != [] {
						env: [
							for e in #config.extraEnv {e},
						]
					}
					volumeMounts: [{
						name:      "pvc-\(#config.metadata.name)-rabbitmq-vol"
						mountPath: "/var/lib/rabbitmq"
					}]
					readinessProbe: {
						exec: command: ["rabbitmq-diagnostics", "-q", "check_running"]
						initialDelaySeconds: 10
						timeoutSeconds:      5
					}
				}]
			}
		}
		volumeClaimTemplates: [{
			metadata: name: "pvc-\(#config.metadata.name)-rabbitmq-vol"
			spec: {
				accessModes: ["ReadWriteOnce"]
				storageClassName: #config.env.storageClass
				resources: requests: storage: #config.services.rabbitmq.volumeSize
			}
		}]
	}
}
