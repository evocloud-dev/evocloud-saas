package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#WebDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-web"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.web.autoscaling.enabled {
			replicas: #config.web.replicaCount
		}
		revisionHistoryLimit: #config.web.revisionHistoryLimit
		if len(#config.web.deploymentStrategy) > 0 {
			strategy: #config.web.deploymentStrategy
		}
		selector: matchLabels: {
			"app.kubernetes.io/name":      "\(#config.metadata.name)-web"
			"app.kubernetes.io/instance":  #config.metadata.name
		}
		template: {
			metadata: {
				if len(#config.web.podAnnotations) > 0 {
					annotations: #config.web.podAnnotations
				}
				labels: {
					"app.kubernetes.io/name":      "\(#config.metadata.name)-web"
					"app.kubernetes.io/instance":  #config.metadata.name
					if len(#config.web.podLabels) > 0 {
						#config.web.podLabels
					}
				}
			}
			spec: corev1.#PodSpec & {
				if len(#config.web.imagePullSecrets) > 0 {
					imagePullSecrets: #config.web.imagePullSecrets
				}
				serviceAccountName: #config.web.#serviceAccountName
				if len(#config.web.podSecurityContext) > 0 {
					securityContext: #config.web.podSecurityContext
				}
				containers: [{
					name:  "shlink-web"
					image: "\(#config.web.image.registry)/\(#config.web.image.repository):\(#config.web.image.tag)"
					imagePullPolicy: #config.web.image.pullPolicy
					if len(#config.web.securityContext) > 0 {
						securityContext: #config.web.securityContext
					}
					if len(#config.web.extraEnv) > 0 {
						env: #config.web.extraEnv
					}
					ports: [{
						name:          "http"
						containerPort: 8080
						protocol:      "TCP"
					}]
					livenessProbe: httpGet: {
						path: "/"
						port: "http"
					}
					readinessProbe: httpGet: {
						path: "/"
						port: "http"
					}
					if len(#config.web.resources) > 0 {
						resources: #config.web.resources
					}
					volumeMounts: [
						{
							name:      "cache-dir"
							mountPath: "/var/cache/nginx"
						},
						{
							name:      "run-dir"
							mountPath: "/var/run"
						},
						{
							name:      "tmp-dir"
							mountPath: "/tmp"
						},
						if len(#config.web.configuration) > 0 {
							{
								name:      "servers"
								mountPath: "/usr/share/nginx/html/servers.json"
								subPath:   "servers.json"
							}
						}
					]
				}]
				if len(#config.web.nodeSelector) > 0 {
					nodeSelector: #config.web.nodeSelector
				}
				if len(#config.web.tolerations) > 0 {
					tolerations: #config.web.tolerations
				}
				if len(#config.web.affinity) > 0 {
					affinity: #config.web.affinity
				}
				volumes: [
					{
						name: "cache-dir"
						emptyDir: {}
					},
					{
						name: "run-dir"
						emptyDir: {}
					},
					{
						name: "tmp-dir"
						emptyDir: {}
					},
					if len(#config.web.configuration) > 0 {
						{
							name: "servers"
							configMap: name: "\(#config.metadata.name)-web"
						}
					}
				]
			}
		}
	}
}
