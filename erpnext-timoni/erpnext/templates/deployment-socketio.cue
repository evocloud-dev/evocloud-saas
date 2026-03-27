package templates

import (
	"list"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#SocketioDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-socketio"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name":     "\(#config.metadata.name)-socketio"
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/app":      "frappe"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.socketio.autoscaling.enabled {
			replicas: #config.socketio.replicaCount
		}
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-socketio"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: {
					for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
						"\(k)": v
					}
					"app.kubernetes.io/name":     "\(#config.metadata.name)-socketio"
					"app.kubernetes.io/instance": #config.metadata.name
					"app.kubernetes.io/app":      "frappe"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: #config.metadata.name
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.socketio.initContainers != _|_ {
					initContainers: #config.socketio.initContainers
				}
				containers: list.Concat([
					[
						{
							name:            "socketio"
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
							workingDir:      "/home/frappe/frappe-bench"
							command: ["node", "apps/frappe/socketio.js"]
							env: #config._globalEnv
							if #config.socketio.envVars != _|_ {
								env: list.Concat([#config._globalEnv, #config.socketio.envVars])
							}
							ports: [
								{
									name:          "http"
									containerPort: #config.socketio.service.port
									protocol:      "TCP"
								},
							]
							livenessProbe:  #config.socketio.livenessProbe
							readinessProbe: #config.socketio.readinessProbe
							volumeMounts: [
								{
									mountPath: "/home/frappe/frappe-bench/sites"
									name:      "sites-dir"
								},
								{
									mountPath: "/home/frappe/frappe-bench/logs"
									name:      "logs"
								},
							]
							resources:       #config.socketio.resources
							securityContext: #config.securityContext
						},
					],
					#config.socketio.sidecars,
				])
				volumes: [
					{
						name: "sites-dir"
						if #config.persistence.worker.enabled {
							persistentVolumeClaim: {
								if #config.persistence.worker.existingClaim != "" {
									claimName: #config.persistence.worker.existingClaim
								}
								if #config.persistence.worker.existingClaim == "" {
									claimName: #config.metadata.name
								}
								readOnly: false
							}
						}
						if !#config.persistence.worker.enabled {
							emptyDir: {}
						}
					},
					{
						name: "logs"
						if #config.persistence.logs.enabled {
							persistentVolumeClaim: {
								if #config.persistence.logs.existingClaim != "" {
									claimName: #config.persistence.logs.existingClaim
								}
								if #config.persistence.logs.existingClaim == "" {
									claimName: "\(#config.metadata.name)-logs"
								}
								readOnly: false
							}
						}
						if !#config.persistence.logs.enabled {
							emptyDir: {}
						}
					},
				]
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
			}
		}
	}
}

