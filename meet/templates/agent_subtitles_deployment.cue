package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#AgentSubtitlesDeployment: appsv1.#Deployment & {
	#config: #Config
	let agentSubtitles = #config.agentSubtitles

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-agent-subtitles"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "agent-subtitles"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: agentSubtitles.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "agent-subtitles"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "agent-subtitles"
				}
				if agentSubtitles.podAnnotations != _|_ {
					annotations: agentSubtitles.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace:        agentSubtitles.shareProcessNamespace
				automountServiceAccountToken: agentSubtitles.automountServiceAccountToken
				serviceAccountName:           agentSubtitles.serviceAccountName
				
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if agentSubtitles.podSecurityContext != _|_ {
					securityContext: agentSubtitles.podSecurityContext
				}

				containers: [
					{
						name:            #config.chartName
						if agentSubtitles.image != _|_ {
							image:           agentSubtitles.image.reference
							imagePullPolicy: agentSubtitles.image.pullPolicy
						}
						if agentSubtitles.image == _|_ {
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
						}
						
						if agentSubtitles.command != _|_ { command: agentSubtitles.command }
						if agentSubtitles.args != _|_ { args: agentSubtitles.args }
						if agentSubtitles.securityContext != _|_ { securityContext: agentSubtitles.securityContext }
						if agentSubtitles.resources != _|_ { resources: agentSubtitles.resources }
						
						if agentSubtitles.envVars != _|_ {
							env: [
								for k, v in agentSubtitles.envVars {
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

						volumeMounts: [
							if #config.mountFiles != _|_ for idx, val in #config.mountFiles {
								name:      "files-\(idx)"
								mountPath: val.path
								subPath:   "content"
							},
							if agentSubtitles.persistence != _|_ for name, vol in agentSubtitles.persistence {
								name:      name
								mountPath: vol.mountPath
							},
							if agentSubtitles.extraVolumeMounts != _|_ for vol in agentSubtitles.extraVolumeMounts {
								name:      vol.name
								mountPath: vol.mountPath
								subPath:   vol.subPath
								readOnly:  vol.readOnly
							},
						]
					},
					if agentSubtitles.sidecars != _|_ for sidecar in agentSubtitles.sidecars {
						sidecar
					},
				]

				if agentSubtitles.nodeSelector != _|_ { nodeSelector: agentSubtitles.nodeSelector }
				if agentSubtitles.affinity != _|_ { affinity: agentSubtitles.affinity }
				if agentSubtitles.tolerations != _|_ { tolerations: agentSubtitles.tolerations }

				volumes: [
					if #config.mountFiles != _|_ for idx, _ in #config.mountFiles {
						name: "files-\(idx)"
						configMap: name: "\(#config.metadata.name)-files-\(idx)"
					},
					if agentSubtitles.persistence != _|_ for name, vol in agentSubtitles.persistence {
						name: name
						if vol.type == "emptyDir" {
							emptyDir: {}
						}
						if vol.type != "emptyDir" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-\(name)"
						}
					},
					if agentSubtitles.extraVolumes != _|_ for vol in agentSubtitles.extraVolumes {
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

#AgentSubtitlesPodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-agent-subtitles"
		namespace: #config.metadata.namespace
	}
	spec: {
		maxUnavailable: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "agent-subtitles"
		}
	}
}