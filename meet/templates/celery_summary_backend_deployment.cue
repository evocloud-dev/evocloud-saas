package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#CelerySummaryBackendDeployment: appsv1.#Deployment & {
	#config: #Config
	let celerySummaryBackend = #config.celerySummaryBackend

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-celery-summary-backend"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "celery-summary-backend"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: celerySummaryBackend.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "celery-summary-backend"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "celery-summary-backend"
				}
				if celerySummaryBackend.podAnnotations != _|_ {
					annotations: celerySummaryBackend.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace:        celerySummaryBackend.shareProcessNamespace
				automountServiceAccountToken: celerySummaryBackend.automountServiceAccountToken
				serviceAccountName:           celerySummaryBackend.serviceAccountName
				
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if celerySummaryBackend.podSecurityContext != _|_ {
					securityContext: celerySummaryBackend.podSecurityContext
				}

				containers: [
					{
						name:            #config.chartName
						if celerySummaryBackend.image != _|_ {
							image:           celerySummaryBackend.image.reference
							imagePullPolicy: celerySummaryBackend.image.pullPolicy
						}
						if celerySummaryBackend.image == _|_ {
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
						}
						
						if celerySummaryBackend.command != _|_ { command: celerySummaryBackend.command }
						if celerySummaryBackend.args != _|_ { args: celerySummaryBackend.args }
						if celerySummaryBackend.securityContext != _|_ { securityContext: celerySummaryBackend.securityContext }
						if celerySummaryBackend.resources != _|_ { resources: celerySummaryBackend.resources }
						
						if celerySummaryBackend.envVars != _|_ {
							env: [
								for k, v in celerySummaryBackend.envVars {
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

						if celerySummaryBackend.service != _|_ {
							ports: [{
								name:          "http"
								containerPort: celerySummaryBackend.service.targetPort
								protocol:      "TCP"
							}]
						}

						if celerySummaryBackend.service != _|_ && celerySummaryBackend.probes.liveness != _|_ {
							livenessProbe: {
								httpGet: {
									path: celerySummaryBackend.probes.liveness.path
									port: celerySummaryBackend.service.targetPort
								}
								initialDelaySeconds: celerySummaryBackend.probes.liveness.initialDelaySeconds
								periodSeconds:       celerySummaryBackend.probes.liveness.periodSeconds
								if celerySummaryBackend.probes.liveness.timeoutSeconds != _|_ {
									timeoutSeconds: celerySummaryBackend.probes.liveness.timeoutSeconds
								}
							}
						}
						if celerySummaryBackend.service != _|_ && celerySummaryBackend.probes.readiness != _|_ {
							readinessProbe: {
								httpGet: {
									path: celerySummaryBackend.probes.readiness.path
									port: celerySummaryBackend.service.targetPort
								}
								initialDelaySeconds: celerySummaryBackend.probes.readiness.initialDelaySeconds
								periodSeconds:       celerySummaryBackend.probes.readiness.periodSeconds
								if celerySummaryBackend.probes.readiness.timeoutSeconds != _|_ {
									timeoutSeconds: celerySummaryBackend.probes.readiness.timeoutSeconds
								}
							}
						}
						if celerySummaryBackend.service != _|_ && celerySummaryBackend.probes.startup != _|_ {
							startupProbe: {
								httpGet: {
									path: celerySummaryBackend.probes.startup.path
									port: celerySummaryBackend.service.targetPort
								}
								initialDelaySeconds: celerySummaryBackend.probes.startup.initialDelaySeconds
								periodSeconds:       celerySummaryBackend.probes.startup.periodSeconds
								if celerySummaryBackend.probes.startup.timeoutSeconds != _|_ {
									timeoutSeconds: celerySummaryBackend.probes.startup.timeoutSeconds
								}
							}
						}

						volumeMounts: [
							if #config.mountFiles != _|_ for idx, val in #config.mountFiles {
								name:      "files-\(idx)"
								mountPath: val.path
								subPath:   "content"
							},
							if celerySummaryBackend.persistence != _|_ for name, vol in celerySummaryBackend.persistence {
								name:      name
								mountPath: vol.mountPath
							},
							if celerySummaryBackend.extraVolumeMounts != _|_ for vol in celerySummaryBackend.extraVolumeMounts {
								name:      vol.name
								mountPath: vol.mountPath
								subPath:   vol.subPath
								readOnly:  vol.readOnly
							},
						]
					},
					if celerySummaryBackend.sidecars != _|_ for sidecar in celerySummaryBackend.sidecars {
						sidecar
					},
				]

				if celerySummaryBackend.nodeSelector != _|_ { nodeSelector: celerySummaryBackend.nodeSelector }
				if celerySummaryBackend.affinity != _|_ { affinity: celerySummaryBackend.affinity }
				if celerySummaryBackend.tolerations != _|_ { tolerations: celerySummaryBackend.tolerations }

				volumes: [
					if #config.mountFiles != _|_ for idx, _ in #config.mountFiles {
						name: "files-\(idx)"
						configMap: name: "\(#config.metadata.name)-files-\(idx)"
					},
					if celerySummaryBackend.persistence != _|_ for name, vol in celerySummaryBackend.persistence {
						name: name
						if vol.type == "emptyDir" {
							emptyDir: {}
						}
						if vol.type != "emptyDir" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-\(name)"
						}
					},
					if celerySummaryBackend.extraVolumes != _|_ for vol in celerySummaryBackend.extraVolumes {
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

#CelerySummaryBackendPodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-celery-summary-backend"
		namespace: #config.metadata.namespace
	}
	spec: {
		maxUnavailable: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "celery-summary-backend"
		}
	}
}