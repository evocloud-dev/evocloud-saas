package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#ImaginaryDeployment: appsv1.#Deployment & {
	#in:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #in.metadata & {
		name: #in.imaginary.primaryHost
	}
	spec: {
		replicas: #in.imaginary.replicaCount
		selector: matchLabels: {
			"app.kubernetes.io/name":      #in.metadata.labels["app.kubernetes.io/name"]
			"app.kubernetes.io/instance":  #in.metadata.labels["app.kubernetes.io/instance"]
			"app.kubernetes.io/component": "imaginary"
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":      #in.metadata.labels["app.kubernetes.io/name"]
					"app.kubernetes.io/instance":  #in.metadata.labels["app.kubernetes.io/instance"]
					"app.kubernetes.io/component": "imaginary"
				}
				if #in.imaginary.podLabels != _|_ {
					for k, v in #in.imaginary.podLabels {
						"\(k)": v
					}
				}
				if #in.imaginary.podAnnotations != _|_ {
					annotations: #in.imaginary.podAnnotations
				}
			}
			spec: {
				if #in.imagePullSecrets != _|_ {
					imagePullSecrets: #in.imagePullSecrets
				}
				containers: [
					{
						name:            "imaginary"
						image:           #in.imaginary.image.reference
						imagePullPolicy: #in.imaginary.image.pullPolicy
						env: [
							{
								name:  "PORT"
								value: "9000"
							},
						]
						ports: [
							{
								name:          "http"
								containerPort: 9000
							},
						]
						if #in.imaginary.readinessProbe.enabled {
							readinessProbe: {
								httpGet: {
									path:   "/health"
									port:   "http"
									scheme: "HTTP"
								}
								failureThreshold: #in.imaginary.readinessProbe.failureThreshold
								successThreshold: #in.imaginary.readinessProbe.successThreshold
								periodSeconds:    #in.imaginary.readinessProbe.periodSeconds
								timeoutSeconds:   #in.imaginary.readinessProbe.timeoutSeconds
							}
						}
						if #in.imaginary.livenessProbe.enabled {
							livenessProbe: {
								httpGet: {
									path:   "/health"
									port:   "http"
									scheme: "HTTP"
								}
								failureThreshold: #in.imaginary.livenessProbe.failureThreshold
								successThreshold: #in.imaginary.livenessProbe.successThreshold
								periodSeconds:    #in.imaginary.livenessProbe.periodSeconds
								timeoutSeconds:   #in.imaginary.livenessProbe.timeoutSeconds
							}
						}
						if #in.imaginary.resources != _|_ {
							resources: #in.imaginary.resources
						}
						if #in.imaginary.securityContext != _|_ {
							securityContext: #in.imaginary.securityContext
						}
					},
				]
				if #in.imaginary.podSecurityContext != _|_ {
					securityContext: #in.imaginary.podSecurityContext
				}
				if #in.imaginary.nodeSelector != _|_ {
					nodeSelector: #in.imaginary.nodeSelector
				}
				if #in.imaginary.tolerations != _|_ {
					tolerations: #in.imaginary.tolerations
				}
				if #in.imaginary.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #in.imaginary.topologySpreadConstraints
				}
				if #in.imaginary.priorityClassName != _|_ {
					priorityClassName: #in.imaginary.priorityClassName
				}
				if #in.imaginary.affinity != _|_ {
					affinity: #in.imaginary.affinity
				}
			}
		}
	}
}

#ImaginaryService: corev1.#Service & {
	#in:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata:   #in.metadata & {
		name: #in.imaginary.primaryHost
		if #in.imaginary.service.labels != _|_ {
			labels: #in.imaginary.service.labels
		}
		if #in.imaginary.service.annotations != _|_ {
			annotations: #in.imaginary.service.annotations
		}
	}
	spec: {
		type: #in.imaginary.service.type
		if #in.imaginary.service.loadBalancerIP != "" {
			loadBalancerIP: #in.imaginary.service.loadBalancerIP
		}
		ports: [
			{
				name:       "http"
				port:       80
				targetPort: "http"
				if #in.imaginary.service.nodePort != _|_ {
					nodePort: #in.imaginary.service.nodePort
				}
			},
		]
		selector: {
			"app.kubernetes.io/name":      #in.metadata.labels["app.kubernetes.io/name"]
			"app.kubernetes.io/instance":  #in.metadata.labels["app.kubernetes.io/instance"]
			"app.kubernetes.io/component": "imaginary"
		}
	}
}
