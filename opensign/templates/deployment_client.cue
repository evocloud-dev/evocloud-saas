package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

#ClientDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-client"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.client.replicas
		selector: metav1.#LabelSelector & {
			matchLabels: {
				"app.kubernetes.io/name":     "opensign-client"
				"app.kubernetes.io/instance": #config.metadata.name
			}
		}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "opensign-client"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: *#config.client.serviceAccount.name | "\(#config.metadata.name)-client"
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				containers: [{
					name:            "client"
					image:           #config.client.image.reference
					imagePullPolicy: #config.client.image.pullPolicy
					ports: [{
						name:          "http"
						containerPort: #config.client.port
						protocol:      "TCP"
					}]
					envFrom: [{
						secretRef: name: "\(#config.metadata.name)-env"
					}]
					resources:       #config.client.resources
					securityContext: #config.client.securityContext
				}]
			}
		}
	}
}
