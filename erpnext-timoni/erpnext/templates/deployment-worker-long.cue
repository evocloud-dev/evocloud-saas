package templates

import (
	"list"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#WorkerLongDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-worker-l"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name":     "\(#config.metadata.name)-worker-l"
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/app":      "frappe"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.worker.long.autoscaling.enabled {
			replicas: #config.worker.long.replicaCount
		}
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-worker-l"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: {
					for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
						"\(k)": v
					}
					"app.kubernetes.io/name":     "\(#config.metadata.name)-worker-l"
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
				if #config.worker.long.initContainers != _|_ {
					initContainers: #config.worker.long.initContainers
				}
				containers: list.Concat([
					[
						{
							name:            "worker"
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
							workingDir:      "/home/frappe/frappe-bench"
							args:            ["bench", "worker", "--queue", #config.worker.long.queue]
							env: #config._globalEnv
							if #config.worker.long.envVars != _|_ {
								env: list.Concat([#config._globalEnv, #config.worker.long.envVars])
							}
							livenessProbe:  #config.worker.long._resolvedLivenessProbe
							readinessProbe: #config.worker.long._resolvedReadinessProbe
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
							resources:       #config.worker.long.resources
							securityContext: #config.securityContext
						},
					],
					#config.worker.long.sidecars,
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
