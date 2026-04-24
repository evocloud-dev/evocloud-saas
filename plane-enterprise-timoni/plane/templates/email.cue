package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#EmailService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-email-service"
		namespace: #config.#namespace
	}
	spec: {
		type:                  "LoadBalancer"
		externalTrafficPolicy: "Local"
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-email-app"
		}
		ports: [
			{
				name:       "smtp"
				port:       25
				targetPort: 10025
				protocol:   "TCP"
			},
			{
				name:       "smtps"
				port:       465
				targetPort: 10465
				protocol:   "TCP"
			},
			{
				name:       "submission"
				port:       587
				targetPort: 10587
				protocol:   "TCP"
			},
		]
	}
}

#EmailDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-email-app"
		namespace: #config.#namespace
		annotations: {
			"reloader.stakater.com/auto": "true"
		}
	}
	spec: {
		replicas: #config.services.email_service.replicas
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-email-app"
		}
		template: {
			metadata: {
				namespace: #config.#namespace
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-email-app"
				}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-email-app"
					image:           "\(#config.services.email_service.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					securityContext: {
						runAsUser: 100
					}
					stdin: true
					tty:   true
					readinessProbe: {
						exec: {
							command: ["nc", "-zv", "localhost", "10025"]
						}
						initialDelaySeconds: 30
						periodSeconds:       10
						timeoutSeconds:      5
						failureThreshold:    3
					}
					resources: #config.services.email_service.resources
					envFrom: [
						{configMapRef: name: "\(#config.metadata.name)-email-vars"},
					]
					if #config.extraEnv != [] {
						env: #config.extraEnv
					}
					volumeMounts: [
						{
							name:      "spam-blacklist"
							mountPath: "/opt/email/spam.txt"
							subPath:   "spam.txt"
						},
						{
							name:      "spam-blacklist"
							mountPath: "/opt/email/domain-blacklist.txt"
							subPath:   "domain-blacklist.txt"
						},
					]
				}]
				volumes: [{
					name: "spam-blacklist"
					configMap: {
						name: "\(#config.metadata.name)-email-vars"
					}
				}]
				serviceAccount:     "\(#config.metadata.name)-srv-account"
				serviceAccountName: "\(#config.metadata.name)-srv-account"
			}
		}
	}
}
