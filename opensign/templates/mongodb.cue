package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

#MongoDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-mongo"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: metav1.#LabelSelector & {
			matchLabels: {
				"app.kubernetes.io/name":     "opensign-mongo"
				"app.kubernetes.io/instance": #config.metadata.name
			}
		}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "opensign-mongo"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: false
				serviceAccountName: [
					if #config.mongodb.serviceAccount.name != "" {#config.mongodb.serviceAccount.name},
					"\(#config.metadata.name)-mongo",
				][0]
				if #config.mongodb.podSecurityContext != _|_ {
					securityContext: #config.mongodb.podSecurityContext
				}
				if #config.mongodb.podSecurityContext == _|_ {
					if #config.podSecurityContext != _|_ {
						securityContext: #config.podSecurityContext
					}
				}
				containers: [{
					name:            "mongo"
					image:           #config.mongodb.image.reference
					imagePullPolicy: #config.mongodb.image.pullPolicy
					ports: [{
						name:          "mongodb"
						containerPort: #config.mongodb.port
						protocol:      "TCP"
					}]
					resources:       #config.mongodb.resources
					securityContext: #config.mongodb.securityContext
					if #config.mongodb.probes.readiness.enabled {
						readinessProbe: {
							tcpSocket: port: #config.mongodb.port
							initialDelaySeconds: #config.mongodb.probes.readiness.initialDelaySeconds
							periodSeconds:       #config.mongodb.probes.readiness.periodSeconds
							timeoutSeconds:      #config.mongodb.probes.readiness.timeoutSeconds
							failureThreshold:    #config.mongodb.probes.readiness.failureThreshold
						}
					}
					if #config.mongodb.probes.liveness.enabled {
						livenessProbe: {
							tcpSocket: port: #config.mongodb.port
							initialDelaySeconds: #config.mongodb.probes.liveness.initialDelaySeconds
							periodSeconds:       #config.mongodb.probes.liveness.periodSeconds
							timeoutSeconds:      #config.mongodb.probes.liveness.timeoutSeconds
							failureThreshold:    #config.mongodb.probes.liveness.failureThreshold
						}
					}
					volumeMounts: [{
						name:      "data"
						mountPath: "/data/db"
					}]
				}]
				volumes: [
					if #config.mongodb.persistence.enabled {
						name: "data"
						persistentVolumeClaim: claimName: "\(#config.metadata.name)-mongo-data"
					},
					if !#config.mongodb.persistence.enabled {
						name: "data"
						emptyDir: {}
					},
				]
			}
		}
	}
}
