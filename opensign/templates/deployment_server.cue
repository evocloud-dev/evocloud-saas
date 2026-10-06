package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

#ServerDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-server"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.server.replicas
		selector: metav1.#LabelSelector & {
			matchLabels: {
				"app.kubernetes.io/name":     "opensign-server"
				"app.kubernetes.io/instance": #config.metadata.name
			}
		}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "opensign-server"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: *#config.server.serviceAccount.name | "\(#config.metadata.name)-server"
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				containers: [{
					name:            "server"
					image:           #config.server.image.reference
					imagePullPolicy: #config.server.image.pullPolicy
					ports: [{
						name:          "http"
						containerPort: #config.server.port
						protocol:      "TCP"
					}]
					env: [
						{
							name:  "NODE_ENV"
							value: #config.server.env.NODE_ENV
						},
						{
							name:  "SERVER_URL"
							value: "$(HOST_URL)/api/app"
						},
						{
							name:  "PUBLIC_URL"
							value: "$(HOST_URL)"
						},
					]
					envFrom: [{
						secretRef: name: "\(#config.metadata.name)-env"
					}]
					resources:       #config.server.resources
					securityContext: #config.server.securityContext
					readinessProbe: {
						tcpSocket: port: #config.server.port
						initialDelaySeconds: 20
						periodSeconds:       10
					}
					volumeMounts: [{
						name:      "files"
						mountPath: "/usr/src/app/files"
					}]
				}]
				volumes: [{
					name: "files"
					persistentVolumeClaim: claimName: "opensign-files"
				}]
			}
		}
	}
}
