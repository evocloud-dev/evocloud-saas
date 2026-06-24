package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#FrontendDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config._frontendName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "frontend"
		}
	}
	spec: {
		if !#config.frontend.autoscaling.enabled {
			replicas: #config.frontend.replicaCount
		}
		selector: matchLabels: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "frontend"
		}
		template: {
			metadata: {
				labels: #config._baseLabels & {
					"app.kubernetes.io/component": "frontend"
					for k, v in #config.podLabels {(k): v}
				}
				if len(#config._podAnnotations) > 0 {
					annotations: #config._podAnnotations
				}
			}
			spec: {
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: #config._saName
				if len(#config.frontend.podSecurityContext) > 0 {
					securityContext: #config.frontend.podSecurityContext
				}
				containers: [{
					name:            "frontend"
					image:           #config._frontendImageRef
					imagePullPolicy: #config.frontend.image.pullPolicy
					if len(#config.frontend.command) > 0 {
						command: #config.frontend.command
					}
					if len(#config.frontend.args) > 0 {
						args: #config.frontend.args
					}
					ports: [{
						name:          "http"
						containerPort: #config.frontend.service.targetPort
					}]
					env: #config._frontendEnv
					
					startupProbe: {
						if #config.frontend.probes.type == "tcpSocket" {
							tcpSocket: port: "http"
						}
						if #config.frontend.probes.type == "httpGet" {
							httpGet: {path: "/", port: "http"}
						}
						periodSeconds:    #config.frontend.probes.startup.periodSeconds
						timeoutSeconds:   #config.frontend.probes.startup.timeoutSeconds
						failureThreshold: #config.frontend.probes.startup.failureThreshold
					}
					livenessProbe: {
						if #config.frontend.probes.type == "tcpSocket" {
							tcpSocket: port: "http"
						}
						if #config.frontend.probes.type == "httpGet" {
							httpGet: {path: "/", port: "http"}
						}
						initialDelaySeconds: #config.frontend.probes.liveness.initialDelaySeconds
						periodSeconds:       #config.frontend.probes.liveness.periodSeconds
						timeoutSeconds:      #config.frontend.probes.liveness.timeoutSeconds
						failureThreshold:    #config.frontend.probes.liveness.failureThreshold
					}
					readinessProbe: {
						if #config.frontend.probes.type == "tcpSocket" {
							tcpSocket: port: "http"
						}
						if #config.frontend.probes.type == "httpGet" {
							httpGet: {path: "/", port: "http"}
						}
						initialDelaySeconds: #config.frontend.probes.readiness.initialDelaySeconds
						periodSeconds:       #config.frontend.probes.readiness.periodSeconds
						timeoutSeconds:      #config.frontend.probes.readiness.timeoutSeconds
						failureThreshold:    #config.frontend.probes.readiness.failureThreshold
					}
					
					if len(#config.frontend.securityContext) > 0 {
						securityContext: #config.frontend.securityContext
					}
					if len(#config.frontend.resources) > 0 {
						resources: #config.frontend.resources
					}
					volumeMounts: [
						if #config.frontend.securityContext.readOnlyRootFilesystem != _|_ && #config.frontend.securityContext.readOnlyRootFilesystem == true {
							{
								name:      "tmp"
								mountPath: "/tmp"
							}
						},
					]
				}]
				volumes: [
					if #config.frontend.securityContext.readOnlyRootFilesystem != _|_ && #config.frontend.securityContext.readOnlyRootFilesystem == true {
						{
							name: "tmp"
							emptyDir: {}
						}
					},
				]
				
				if len(#config.frontend.nodeSelector) > 0 {
					nodeSelector: #config.frontend.nodeSelector
				}
				if len(#config.frontend.affinity) > 0 {
					affinity: #config.frontend.affinity
				}
				if len(#config.frontend.tolerations) > 0 {
					tolerations: #config.frontend.tolerations
				}
				if len(#config.frontend.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.frontend.topologySpreadConstraints
				}
			}
		}
	}
}
