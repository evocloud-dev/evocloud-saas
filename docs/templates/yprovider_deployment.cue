package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#YProviderDeployment: appsv1.#Deployment & {
	#config: #Config
	let yProvider = #config.yProvider

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-y-provider"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "yProvider"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: yProvider.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "yProvider"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "yProvider"
				}
				if yProvider.podAnnotations != _|_ {
					annotations: yProvider.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace:        yProvider.shareProcessNamespace
				automountServiceAccountToken: yProvider.automountServiceAccountToken
				serviceAccountName:           yProvider.serviceAccountName
				
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if yProvider.podSecurityContext != _|_ {
					securityContext: yProvider.podSecurityContext
				}

				containers: [
					{
						name:            #config.chartName
						image:           yProvider.image.reference
						imagePullPolicy: yProvider.image.pullPolicy | *#config.image.pullPolicy
						
						if yProvider.command != _|_ { command: yProvider.command }
						if yProvider.args != _|_ { args: yProvider.args }
						if yProvider.securityContext != _|_ { securityContext: yProvider.securityContext }
						if yProvider.resources != _|_ { resources: yProvider.resources }
						
						if yProvider.envVars != _|_ {
							env: [
								for k, v in yProvider.envVars {
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
							containerPort: yProvider.service.targetPort
							protocol:      "TCP"
						}]

						if yProvider.probes.liveness != _|_ {
							livenessProbe: {
								tcpSocket: {
									port: yProvider.service.targetPort
								}
								initialDelaySeconds: yProvider.probes.liveness.initialDelaySeconds
								periodSeconds:       yProvider.probes.liveness.periodSeconds
								if yProvider.probes.liveness.timeoutSeconds != _|_ {
									timeoutSeconds: yProvider.probes.liveness.timeoutSeconds
								}
							}
						}
						if yProvider.probes.readiness != _|_ {
							readinessProbe: {
								tcpSocket: {
									port: yProvider.service.targetPort
								}
								initialDelaySeconds: yProvider.probes.readiness.initialDelaySeconds
								periodSeconds:       yProvider.probes.readiness.periodSeconds
								if yProvider.probes.readiness.timeoutSeconds != _|_ {
									timeoutSeconds: yProvider.probes.readiness.timeoutSeconds
								}
							}
						}
						if yProvider.probes.startup != _|_ {
							startupProbe: {
								httpGet: {
									path: yProvider.probes.startup.path
									port: yProvider.service.targetPort
								}
								initialDelaySeconds: yProvider.probes.startup.initialDelaySeconds
								periodSeconds:       yProvider.probes.startup.periodSeconds
								if yProvider.probes.startup.timeoutSeconds != _|_ {
									timeoutSeconds: yProvider.probes.startup.timeoutSeconds
								}
							}
						}

						volumeMounts: [
							if #config.mountFiles != _|_ for idx, val in #config.mountFiles {
								name:      "files-\(idx)"
								mountPath: val.path
								subPath:   "content"
							},
							if yProvider.persistence != _|_ for name, vol in yProvider.persistence {
								name:      name
								mountPath: vol.mountPath
							},
							if yProvider.extraVolumeMounts != _|_ for vol in yProvider.extraVolumeMounts {
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
					if yProvider.sidecars != _|_ for sidecar in yProvider.sidecars {
						sidecar
					},
				]

				if yProvider.nodeSelector != _|_ { nodeSelector: yProvider.nodeSelector }
				if yProvider.affinity != _|_ { affinity: yProvider.affinity }
				if yProvider.tolerations != _|_ { tolerations: yProvider.tolerations }

				volumes: [
					if #config.mountFiles != _|_ for idx, _ in #config.mountFiles {
						name: "files-\(idx)"
						configMap: name: "\(#config.metadata.name)-files-\(idx)"
					},
					if yProvider.persistence != _|_ for name, vol in yProvider.persistence {
						name: name
						if vol.type == "emptyDir" {
							emptyDir: {}
						}
						if vol.type != "emptyDir" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-\(name)"
						}
					},
					if yProvider.extraVolumes != _|_ for vol in yProvider.extraVolumes {
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

#YProviderPodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-y-provider"
		namespace: #config.metadata.namespace
	}
	spec: {
		maxUnavailable: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "yProvider"
		}
	}
}
