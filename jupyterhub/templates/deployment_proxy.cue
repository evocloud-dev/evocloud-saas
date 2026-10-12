package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#ProxyDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.#proxyFullname
		namespace: #config.metadata.namespace
		labels:    #config.#componentLabels & {#component: "proxy"}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: #config.#selectorLabels & {#component: "proxy"}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: #config.#podLabels & {#component: "proxy"}
				if len(#config.podAnnotations) > 0 {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				serviceAccountName:            #config.#serviceAccountName
				automountServiceAccountToken: false
				securityContext:              #config.podSecurityContext

				containers: [
					{
						name:            "proxy"
						image:           #config.proxy.image.reference
						imagePullPolicy: #config.proxy.image.pullPolicy
						args: [
							"--ip=\(#config.#proxyBindIp)",
							"--port=8000",
							"--api-ip=\(#config.#proxyApiBindIp)",
							"--api-port=8001",
							"--default-target=http://\(#config.#hubFullname):8081",
							"--error-target=http://\(#config.#hubFullname):8081\(#config.#hubErrorPath)",
							"--log-level=\(#config.proxy.logLevel)",
						]
						ports: [
							{
								name:          "http"
								containerPort: 8000
								protocol:      "TCP"
							},
							{
								name:          "api"
								containerPort: 8001
								protocol:      "TCP"
							},
						]
						env: [
							{
								name: "CONFIGPROXY_AUTH_TOKEN"
								valueFrom: secretKeyRef: {
									name: #config.#secretName
									key:  #config.proxy.existingSecretTokenKey
								}
							},
						]
						readinessProbe: {
							tcpSocket: port: "api"
							initialDelaySeconds: #config.readinessProbe.initialDelaySeconds
							periodSeconds:       #config.readinessProbe.periodSeconds
							timeoutSeconds:      #config.readinessProbe.timeoutSeconds
							failureThreshold:    #config.readinessProbe.failureThreshold
						}
						resources:       #config.proxy.resources
						securityContext: #config.securityContext
					},
				]

				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 {
					affinity: #config.affinity
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				if len(#config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
			}
		}
	}
}
