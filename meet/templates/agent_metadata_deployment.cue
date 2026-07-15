package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#AgentMetadataDeployment: appsv1.#Deployment & {
	#config: #Config
	let agentMetadata = #config.agentMetadata

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-agent-metadata"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "agent-metadata"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: agentMetadata.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "agent-metadata"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "agent-metadata"
				}
				if agentMetadata.podAnnotations != _|_ {
					annotations: agentMetadata.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace:        agentMetadata.shareProcessNamespace
				automountServiceAccountToken: agentMetadata.automountServiceAccountToken
				serviceAccountName:           agentMetadata.serviceAccountName
				
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if agentMetadata.podSecurityContext != _|_ {
					securityContext: agentMetadata.podSecurityContext
				}

				containers: [
					{
						name:            #config.chartName
						if agentMetadata.image != _|_ {
							image:           agentMetadata.image.reference
							imagePullPolicy: agentMetadata.image.pullPolicy
						}
						if agentMetadata.image == _|_ {
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
						}
						
						if agentMetadata.command != _|_ { command: agentMetadata.command }
						if agentMetadata.args != _|_ { args: agentMetadata.args }
						if agentMetadata.securityContext != _|_ { securityContext: agentMetadata.securityContext }
						if agentMetadata.resources != _|_ { resources: agentMetadata.resources }
						
						if agentMetadata.envVars != _|_ {
							env: [
								for k, v in agentMetadata.envVars {
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
							if agentMetadata.persistence != _|_ for name, vol in agentMetadata.persistence {
								name:      name
								mountPath: vol.mountPath
							},
							if agentMetadata.extraVolumeMounts != _|_ for vol in agentMetadata.extraVolumeMounts {
								name:      vol.name
								mountPath: vol.mountPath
								subPath:   vol.subPath
								readOnly:  vol.readOnly
							},
						]
					},
					if agentMetadata.sidecars != _|_ for sidecar in agentMetadata.sidecars {
						sidecar
					},
				]

				if agentMetadata.nodeSelector != _|_ { nodeSelector: agentMetadata.nodeSelector }
				if agentMetadata.affinity != _|_ { affinity: agentMetadata.affinity }
				if agentMetadata.tolerations != _|_ { tolerations: agentMetadata.tolerations }

				volumes: [
					if #config.mountFiles != _|_ for idx, _ in #config.mountFiles {
						name: "files-\(idx)"
						configMap: name: "\(#config.metadata.name)-files-\(idx)"
					},
					if agentMetadata.persistence != _|_ for name, vol in agentMetadata.persistence {
						name: name
						if vol.type == "emptyDir" {
							emptyDir: {}
						}
						if vol.type != "emptyDir" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-\(name)"
						}
					},
					if agentMetadata.extraVolumes != _|_ for vol in agentMetadata.extraVolumes {
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

#AgentMetadataPodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-agent-metadata"
		namespace: #config.metadata.namespace
	}
	spec: {
		maxUnavailable: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "agent-metadata"
		}
	}
}
