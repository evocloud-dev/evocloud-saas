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
				automountServiceAccountToken: false
				serviceAccountName: [
					if #config.client.serviceAccount.name != "" {#config.client.serviceAccount.name},
					"\(#config.metadata.name)-client",
				][0]
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
					env: [
						{
							name:  "PUBLIC_URL"
							value: #config.config.publicUrl
						},
						{
							name:  "REACT_APP_SERVERURL"
							value: #config.config.apiUrl
						},
						{
							name:  "REACT_APP_APPID"
							value: "opensign"
						},
					]
					envFrom: [{
						secretRef: name: [
							if #config.existingSecret != "" {#config.existingSecret},
							"\(#config.metadata.name)-env",
						][0]
					}]
					resources:       #config.client.resources
					securityContext: #config.client.securityContext
					if #config.client.probes.readiness.enabled {
						readinessProbe: {
							httpGet: {
								path: "/"
								port: #config.client.port
							}
							initialDelaySeconds: #config.client.probes.readiness.initialDelaySeconds
							periodSeconds:       #config.client.probes.readiness.periodSeconds
							timeoutSeconds:      #config.client.probes.readiness.timeoutSeconds
							failureThreshold:    #config.client.probes.readiness.failureThreshold
						}
					}
					if #config.client.probes.liveness.enabled {
						livenessProbe: {
							httpGet: {
								path: "/"
								port: #config.client.port
							}
							initialDelaySeconds: #config.client.probes.liveness.initialDelaySeconds
							periodSeconds:       #config.client.probes.liveness.periodSeconds
							timeoutSeconds:      #config.client.probes.liveness.timeoutSeconds
							failureThreshold:    #config.client.probes.liveness.failureThreshold
						}
					}
					if #config.client.probes.startup.enabled {
						startupProbe: {
							tcpSocket: port: #config.client.port
							initialDelaySeconds: #config.client.probes.startup.initialDelaySeconds
							periodSeconds:       #config.client.probes.startup.periodSeconds
							timeoutSeconds:      #config.client.probes.startup.timeoutSeconds
							failureThreshold:    #config.client.probes.startup.failureThreshold
						}
					}
				}]
			}
		}
	}
}
