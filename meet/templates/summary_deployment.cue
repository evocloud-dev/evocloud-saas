package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#SummaryDeployment: appsv1.#Deployment & {
	#config: #Config
	let summary = #config.summary

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-summary"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "summary"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: summary.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "summary"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "summary"
				}
				if summary.podAnnotations != _|_ {
					annotations: summary.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace:        summary.shareProcessNamespace
				automountServiceAccountToken: summary.automountServiceAccountToken
				serviceAccountName:           summary.serviceAccountName
				
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if summary.podSecurityContext != _|_ {
					securityContext: summary.podSecurityContext
				}

				containers: [
					{
						name:            #config.chartName
						if summary.image != _|_ {
							image:           summary.image.reference
							imagePullPolicy: summary.image.pullPolicy
						}
						if summary.image == _|_ {
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
						}
						
						if summary.command != _|_ { command: summary.command }
						if summary.args != _|_ { args: summary.args }
						if summary.securityContext != _|_ { securityContext: summary.securityContext }
						if summary.resources != _|_ { resources: summary.resources }
						
						if summary.envVars != _|_ {
							env: [
								for k, v in summary.envVars {
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
							containerPort: #config.summary.service.targetPort
							protocol:      "TCP"
						}]

						if summary.probes.liveness != _|_ {
							livenessProbe: {
								httpGet: {
									path: summary.probes.liveness.path
									port: summary.service.targetPort
								}
								initialDelaySeconds: summary.probes.liveness.initialDelaySeconds
								periodSeconds:       summary.probes.liveness.periodSeconds
								if summary.probes.liveness.timeoutSeconds != _|_ {
									timeoutSeconds: summary.probes.liveness.timeoutSeconds
								}
							}
						}
						if summary.probes.readiness != _|_ {
							readinessProbe: {
								httpGet: {
									path: summary.probes.readiness.path
									port: summary.service.targetPort
								}
								initialDelaySeconds: summary.probes.readiness.initialDelaySeconds
								periodSeconds:       summary.probes.readiness.periodSeconds
								if summary.probes.readiness.timeoutSeconds != _|_ {
									timeoutSeconds: summary.probes.readiness.timeoutSeconds
								}
							}
						}
						if summary.probes.startup != _|_ {
							startupProbe: {
								httpGet: {
									path: summary.probes.startup.path
									port: summary.service.targetPort
								}
								initialDelaySeconds: summary.probes.startup.initialDelaySeconds
								periodSeconds:       summary.probes.startup.periodSeconds
								if summary.probes.startup.timeoutSeconds != _|_ {
									timeoutSeconds: summary.probes.startup.timeoutSeconds
								}
							}
						}

						volumeMounts: [
							if #config.mountFiles != _|_ for idx, val in #config.mountFiles {
								name:      "files-\(idx)"
								mountPath: val.path
								subPath:   "content"
							},
							if summary.persistence != _|_ for name, vol in summary.persistence {
								name:      name
								mountPath: vol.mountPath
							},
							if summary.extraVolumeMounts != _|_ for vol in summary.extraVolumeMounts {
								name:      vol.name
								mountPath: vol.mountPath
								subPath:   vol.subPath
								readOnly:  vol.readOnly
							},
						]
					},
					if summary.sidecars != _|_ for sidecar in summary.sidecars {
						sidecar
					},
				]

				if summary.nodeSelector != _|_ { nodeSelector: summary.nodeSelector }
				if summary.affinity != _|_ { affinity: summary.affinity }
				if summary.tolerations != _|_ { tolerations: summary.tolerations }

				volumes: [
					if #config.mountFiles != _|_ for idx, _ in #config.mountFiles {
						name: "files-\(idx)"
						configMap: name: "\(#config.metadata.name)-files-\(idx)"
					},
					if summary.persistence != _|_ for name, vol in summary.persistence {
						name: name
						if vol.type == "emptyDir" {
							emptyDir: {}
						}
						if vol.type != "emptyDir" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-\(name)"
						}
					},
					if summary.extraVolumes != _|_ for vol in summary.extraVolumes {
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

#SummaryPodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-summary"
		namespace: #config.metadata.namespace
	}
	spec: {
		maxUnavailable: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "summary"
		}
	}
}