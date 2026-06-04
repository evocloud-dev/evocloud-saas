package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#DeploymentNginx: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config._nginxDeploymentName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "nginx"
		}
	}
	spec: {
		replicas: #config.webProxy.replicaCount
		selector: matchLabels: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "nginx"
		}
		template: {
			metadata: {
				labels: #config._baseLabels & {
					"app.kubernetes.io/component": "nginx"
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
				if len(#config.webProxy.podSecurityContext) > 0 {
					securityContext: #config.webProxy.podSecurityContext
				}
				containers: [{
					name:            "nginx"
					image:           #config._webProxyImageRef
					imagePullPolicy: #config.webProxy.image.pullPolicy
					ports: [{
						name:          "http"
						containerPort: #config.webProxy.service.targetPort
					}]
					volumeMounts: [{
						name:      "nginx-config"
						mountPath: "/etc/nginx/conf.d/default.conf"
						subPath:   "default.conf"
					}]
					
					startupProbe: {
						tcpSocket: port: "http"
						periodSeconds:    #config.webProxy.probes.startup.periodSeconds
						timeoutSeconds:   #config.webProxy.probes.startup.timeoutSeconds
						failureThreshold: #config.webProxy.probes.startup.failureThreshold
					}
					livenessProbe: {
						tcpSocket: port: "http"
						initialDelaySeconds: #config.webProxy.probes.liveness.initialDelaySeconds
						periodSeconds:       #config.webProxy.probes.liveness.periodSeconds
						timeoutSeconds:      #config.webProxy.probes.liveness.timeoutSeconds
						failureThreshold:    #config.webProxy.probes.liveness.failureThreshold
					}
					readinessProbe: {
						tcpSocket: port: "http"
						initialDelaySeconds: #config.webProxy.probes.readiness.initialDelaySeconds
						periodSeconds:       #config.webProxy.probes.readiness.periodSeconds
						timeoutSeconds:      #config.webProxy.probes.readiness.timeoutSeconds
						failureThreshold:    #config.webProxy.probes.readiness.failureThreshold
					}
					
					if len(#config.webProxy.securityContext) > 0 {
						securityContext: #config.webProxy.securityContext
					}
					if len(#config.webProxy.resources) > 0 {
						resources: #config.webProxy.resources
					}
				}]
				volumes: [{
					name: "nginx-config"
					configMap: name: #config._nginxConfigName
				}]
				
				if len(#config.webProxy.nodeSelector) > 0 {
					nodeSelector: #config.webProxy.nodeSelector
				}
				if len(#config.webProxy.affinity) > 0 {
					affinity: #config.webProxy.affinity
				}
				if len(#config.webProxy.tolerations) > 0 {
					tolerations: #config.webProxy.tolerations
				}
				if len(#config.webProxy.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.webProxy.topologySpreadConstraints
				}
			}
		}
	}
}
