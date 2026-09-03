package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#CelerySummarizeDeployment: appsv1.#Deployment & {
	#config: #Config
	let celerySummarize = #config.celerySummarize

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-celery-summarize"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "celery-summarize"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: celerySummarize.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "celery-summarize"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "celery-summarize"
				}
				if celerySummarize.podAnnotations != _|_ {
					annotations: celerySummarize.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace:        celerySummarize.shareProcessNamespace
				automountServiceAccountToken: celerySummarize.automountServiceAccountToken
				serviceAccountName:           celerySummarize.serviceAccountName
				
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if celerySummarize.podSecurityContext != _|_ {
					securityContext: celerySummarize.podSecurityContext
				}

				containers: [
					{
						name:            #config.chartName
						if celerySummarize.image != _|_ {
							image:           celerySummarize.image.reference
							imagePullPolicy: celerySummarize.image.pullPolicy
						}
						if celerySummarize.image == _|_ {
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
						}
						
						if celerySummarize.command != _|_ { command: celerySummarize.command }
						if celerySummarize.args != _|_ { args: celerySummarize.args }
						if celerySummarize.securityContext != _|_ { securityContext: celerySummarize.securityContext }
						if celerySummarize.resources != _|_ { resources: celerySummarize.resources }
						
						if celerySummarize.envVars != _|_ {
							env: [
								for k, v in celerySummarize.envVars {
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

						if celerySummarize.service != _|_ {
							ports: [{
								name:          "http"
								containerPort: celerySummarize.service.targetPort
								protocol:      "TCP"
							}]
						}

						if celerySummarize.service != _|_ && celerySummarize.probes.liveness != _|_ {
							livenessProbe: {
								httpGet: {
									path: celerySummarize.probes.liveness.path
									port: celerySummarize.service.targetPort
								}
								initialDelaySeconds: celerySummarize.probes.liveness.initialDelaySeconds
								periodSeconds:       celerySummarize.probes.liveness.periodSeconds
								if celerySummarize.probes.liveness.timeoutSeconds != _|_ {
									timeoutSeconds: celerySummarize.probes.liveness.timeoutSeconds
								}
							}
						}
						if celerySummarize.service != _|_ && celerySummarize.probes.readiness != _|_ {
							readinessProbe: {
								httpGet: {
									path: celerySummarize.probes.readiness.path
									port: celerySummarize.service.targetPort
								}
								initialDelaySeconds: celerySummarize.probes.readiness.initialDelaySeconds
								periodSeconds:       celerySummarize.probes.readiness.periodSeconds
								if celerySummarize.probes.readiness.timeoutSeconds != _|_ {
									timeoutSeconds: celerySummarize.probes.readiness.timeoutSeconds
								}
							}
						}
						if celerySummarize.service != _|_ && celerySummarize.probes.startup != _|_ {
							startupProbe: {
								httpGet: {
									path: celerySummarize.probes.startup.path
									port: celerySummarize.service.targetPort
								}
								initialDelaySeconds: celerySummarize.probes.startup.initialDelaySeconds
								periodSeconds:       celerySummarize.probes.startup.periodSeconds
								if celerySummarize.probes.startup.timeoutSeconds != _|_ {
									timeoutSeconds: celerySummarize.probes.startup.timeoutSeconds
								}
							}
						}

						volumeMounts: [
							if #config.mountFiles != _|_ for idx, val in #config.mountFiles {
								name:      "files-\(idx)"
								mountPath: val.path
								subPath:   "content"
							},
							if celerySummarize.persistence != _|_ for name, vol in celerySummarize.persistence {
								name:      name
								mountPath: vol.mountPath
							},
							if celerySummarize.extraVolumeMounts != _|_ for vol in celerySummarize.extraVolumeMounts {
								name:      vol.name
								mountPath: vol.mountPath
								subPath:   vol.subPath
								readOnly:  vol.readOnly
							},
						]
					},
					if celerySummarize.sidecars != _|_ for sidecar in celerySummarize.sidecars {
						sidecar
					},
				]

				if celerySummarize.nodeSelector != _|_ { nodeSelector: celerySummarize.nodeSelector }
				if celerySummarize.affinity != _|_ { affinity: celerySummarize.affinity }
				if celerySummarize.tolerations != _|_ { tolerations: celerySummarize.tolerations }

				volumes: [
					if #config.mountFiles != _|_ for idx, _ in #config.mountFiles {
						name: "files-\(idx)"
						configMap: name: "\(#config.metadata.name)-files-\(idx)"
					},
					if celerySummarize.persistence != _|_ for name, vol in celerySummarize.persistence {
						name: name
						if vol.type == "emptyDir" {
							emptyDir: {}
						}
						if vol.type != "emptyDir" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-\(name)"
						}
					},
					if celerySummarize.extraVolumes != _|_ for vol in celerySummarize.extraVolumes {
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
				]
			}
		}
	}
}

#CelerySummarizePodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-celery-summarize"
		namespace: #config.metadata.namespace
	}
	spec: {
		maxUnavailable: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "celery-summarize"
		}
	}
}