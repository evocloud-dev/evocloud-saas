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
					volumeMounts: [{
						name:      "data"
						mountPath: "/data/db"
					}]
				}]
				volumes: [{
					name: "data"
					persistentVolumeClaim: claimName: "mongo-data"
				}]
			}
		}
	}
}
