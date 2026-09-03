package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#FrontendDeployment: appsv1.#Deployment & {
	#config: #Config
	let frontend = #config.frontend

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-frontend"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "frontend"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: frontend.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "frontend"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "frontend"
				}
				if frontend.podAnnotations != _|_ {
					annotations: frontend.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace:        frontend.shareProcessNamespace
				automountServiceAccountToken: frontend.automountServiceAccountToken
				serviceAccountName:           frontend.serviceAccountName
				
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if frontend.podSecurityContext != _|_ {
					securityContext: frontend.podSecurityContext
				}

				containers: [
					{
						name:            #config.chartName
						if frontend.image != _|_ {
							image:           frontend.image.reference
							imagePullPolicy: frontend.image.pullPolicy
						}
						if frontend.image == _|_ {
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
						}
						
						if frontend.command != _|_ { command: frontend.command }
						if frontend.args != _|_ { args: frontend.args }
						if frontend.securityContext != _|_ { securityContext: frontend.securityContext }
						if frontend.resources != _|_ { resources: frontend.resources }
						
						if frontend.envVars != _|_ {
							env: [
								for k, v in frontend.envVars {
									name: k
									if (v & string) != _|_ {
										value: v
									}
									if (v & string) == _|_ {
										valueFrom: v
									}
								}
							]
						}

						ports: [{
							name:          "http"
							containerPort: #config.frontend.service.targetPort
							protocol:      "TCP"
						}]

						if frontend.probes.liveness != _|_ {
							livenessProbe: {
								httpGet: {
									path: frontend.probes.liveness.path
									port: frontend.service.targetPort
								}
								initialDelaySeconds: frontend.probes.liveness.initialDelaySeconds
								periodSeconds:       frontend.probes.liveness.periodSeconds
								if frontend.probes.liveness.timeoutSeconds != _|_ {
									timeoutSeconds: frontend.probes.liveness.timeoutSeconds
								}
							}
						}
						if frontend.probes.readiness != _|_ {
							readinessProbe: {
								httpGet: {
									path: frontend.probes.readiness.path
									port: frontend.service.targetPort
								}
								initialDelaySeconds: frontend.probes.readiness.initialDelaySeconds
								periodSeconds:       frontend.probes.readiness.periodSeconds
								if frontend.probes.readiness.timeoutSeconds != _|_ {
									timeoutSeconds: frontend.probes.readiness.timeoutSeconds
								}
							}
						}
						if frontend.probes.startup != _|_ {
							startupProbe: {
								httpGet: {
									path: frontend.probes.startup.path
									port: frontend.service.targetPort
								}
								initialDelaySeconds: frontend.probes.startup.initialDelaySeconds
								periodSeconds:       frontend.probes.startup.periodSeconds
								if frontend.probes.startup.timeoutSeconds != _|_ {
									timeoutSeconds: frontend.probes.startup.timeoutSeconds
								}
							}
						}

						volumeMounts: [
							if #config.mountFiles != _|_ for idx, val in #config.mountFiles {
								name:      "files-\(idx)"
								mountPath: val.path
								subPath:   "content"
							},
							if frontend.persistence != _|_ for name, vol in frontend.persistence {
								name:      name
								mountPath: vol.mountPath
							},
							if frontend.extraVolumeMounts != _|_ for vol in frontend.extraVolumeMounts {
								name:      vol.name
								mountPath: vol.mountPath
								subPath:   vol.subPath
								readOnly:  vol.readOnly
							},
							{
								name:      "tmp-volume"
								mountPath: "/tmp"
							},
						]
					},
					if frontend.sidecars != _|_ for sidecar in frontend.sidecars {
						sidecar
					},
				]

				if frontend.nodeSelector != _|_ { nodeSelector: frontend.nodeSelector }
				if frontend.affinity != _|_ { affinity: frontend.affinity }
				if frontend.tolerations != _|_ { tolerations: frontend.tolerations }

				volumes: [
					if #config.mountFiles != _|_ for idx, _ in #config.mountFiles {
						name: "files-\(idx)"
						configMap: name: "\(#config.metadata.name)-files-\(idx)"
					},
					if frontend.persistence != _|_ for name, vol in frontend.persistence {
						name: name
						if vol.type == "emptyDir" {
							emptyDir: {}
						}
						if vol.type != "emptyDir" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-\(name)"
						}
					},
					if frontend.extraVolumes != _|_ for vol in frontend.extraVolumes {
						name: vol.name
						if vol.existingClaim != _|_ {
							persistentVolumeClaim: claimName: vol.existingClaim
						}
						if vol.existingClaim == _|_ {
							if vol.hostPath != _|_ { hostPath: vol.hostPath }
							if vol.csi != _|_ { csi: vol.csi }
							if vol.configMap != _|_ { configMap: vol.configMap }
							if vol.emptyDir != _|_ { emptyDir: vol.emptyDir }
							if vol.hostPath == _|_ && vol.csi == _|_ && vol.configMap == _|_ && vol.emptyDir == _|_ {
								emptyDir: {}
							}
						}
					},
					{
						name: "tmp-volume"
						emptyDir: {}
					},
				]
			}
		}
	}
}

#FrontendPodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-frontend"
		namespace: #config.metadata.namespace
	}
	spec: {
		maxUnavailable: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "frontend"
		}
	}
}