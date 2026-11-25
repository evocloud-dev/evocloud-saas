package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#InbucketService: {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.#fullname)-inbucket"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.commonLabels { "\(k)": v }
			"app.kubernetes.io/name":       "inbucket"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component":  "mailcatcher"
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/part-of":    "helmforge"
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	spec: {
		type: #config.inbucket.service.type
		ports: [
			{
				name:       "smtp"
				port:       #config.inbucket.service.smtpPort
				targetPort: "smtp"
				protocol:   "TCP"
			},
			{
				name:       "http"
				port:       #config.inbucket.service.webPort
				targetPort: "http"
				protocol:   "TCP"
			},
			{
				name:       "pop3"
				port:       #config.inbucket.service.pop3Port
				targetPort: "pop3"
				protocol:   "TCP"
			},
		]
		selector: {
			"app.kubernetes.io/name":      "inbucket"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "mailcatcher"
		}
	}
}

#InbucketDeployment: {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.#fullname)-inbucket"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.commonLabels { "\(k)": v }
			"app.kubernetes.io/name":       "inbucket"
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component":  "mailcatcher"
			"app.kubernetes.io/managed-by": "timoni"
			"app.kubernetes.io/part-of":    "helmforge"
		}
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: {
			"app.kubernetes.io/name":      "inbucket"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "mailcatcher"
		}
		template: {
			metadata: labels: {
				for k, v in #config.commonLabels { "\(k)": v }
				"app.kubernetes.io/name":      "inbucket"
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/component": "mailcatcher"
			}
			spec: {
				serviceAccountName:           "default"
				automountServiceAccountToken: false
				containers: [{
					name:            "inbucket"
					image:           #config.#inbucketImage
					imagePullPolicy: #config.inbucket.image.pullPolicy
					ports: [
						{
							name:          "smtp"
							containerPort: 2500
							protocol:      "TCP"
						},
						{
							name:          "http"
							containerPort: 9000
							protocol:      "TCP"
						},
						{
							name:          "pop3"
							containerPort: 1100
							protocol:      "TCP"
						},
					]
					livenessProbe: {
						tcpSocket: port: "smtp"
						initialDelaySeconds: 10
						periodSeconds:       10
					}
					readinessProbe: {
						tcpSocket: port: "smtp"
						initialDelaySeconds: 5
						periodSeconds:       5
					}
					resources: {
						requests: {
							cpu:    "10m"
							memory: "32Mi"
						}
						limits: {
							cpu:    "100m"
							memory: "128Mi"
						}
					}
				}]
			}
		}
	}
}
