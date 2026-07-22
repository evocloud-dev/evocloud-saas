package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#BackendDeployment: appsv1.#Deployment & {
	#config: #Config
	let backend = #config.backend

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-backend"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "backend"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: backend.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "backend"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "backend"
				}
				if backend.podAnnotations != _|_ {
					annotations: backend.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace:        backend.shareProcessNamespace
				automountServiceAccountToken: backend.automountServiceAccountToken
				serviceAccountName:           backend.serviceAccountName
				
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if backend.podSecurityContext != _|_ {
					securityContext: backend.podSecurityContext
				}

				containers: [
					{
						name:            #config.chartName
						image:           backend.image.reference | *#config.image.reference
						imagePullPolicy: backend.image.pullPolicy | *#config.image.pullPolicy
						
						if backend.command != _|_ { command: backend.command }
						if backend.args != _|_ { args: backend.args }
						if backend.securityContext != _|_ { securityContext: backend.securityContext }
						if backend.resources != _|_ { resources: backend.resources }
						
						if backend.envVars != _|_ {
							env: [
								for k, v in backend.envVars {
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
							containerPort: backend.service.targetPort
							protocol:      "TCP"
						}]

						if backend.probes.liveness != _|_ {
							livenessProbe: {
								if backend.probes.liveness.path != _|_ {
									httpGet: {
										path: backend.probes.liveness.path
										port: backend.service.targetPort
									}
								}
								if backend.probes.liveness.initialDelaySeconds != _|_ {
									initialDelaySeconds: backend.probes.liveness.initialDelaySeconds
								}
								if backend.probes.liveness.periodSeconds != _|_ {
									periodSeconds: backend.probes.liveness.periodSeconds
								}
								if backend.probes.liveness.timeoutSeconds != _|_ {
									timeoutSeconds: backend.probes.liveness.timeoutSeconds
								}
							}
						}
						if backend.probes.readiness != _|_ {
							readinessProbe: {
								if backend.probes.readiness.path != _|_ {
									httpGet: {
										path: backend.probes.readiness.path
										port: backend.service.targetPort
									}
								}
								if backend.probes.readiness.initialDelaySeconds != _|_ {
									initialDelaySeconds: backend.probes.readiness.initialDelaySeconds
								}
								if backend.probes.readiness.periodSeconds != _|_ {
									periodSeconds: backend.probes.readiness.periodSeconds
								}
								if backend.probes.readiness.timeoutSeconds != _|_ {
									timeoutSeconds: backend.probes.readiness.timeoutSeconds
								}
							}
						}
						if backend.probes.startup != _|_ {
							startupProbe: {
								httpGet: {
									path: backend.probes.startup.path
									port: backend.service.targetPort
								}
								initialDelaySeconds: backend.probes.startup.initialDelaySeconds
								periodSeconds:       backend.probes.startup.periodSeconds
								if backend.probes.startup.timeoutSeconds != _|_ {
									timeoutSeconds: backend.probes.startup.timeoutSeconds
								}
							}
						}

						volumeMounts: [
							if #config.mountFiles != _|_ for idx, val in #config.mountFiles {
								name:      "files-\(idx)"
								mountPath: val.path
								subPath:   "content"
							},
							if backend.persistence != _|_ for name, vol in backend.persistence {
								name:      name
								mountPath: vol.mountPath
							},
							if backend.extraVolumeMounts != _|_ for vol in backend.extraVolumeMounts {
								name:      vol.name
								mountPath: vol.mountPath
								subPath:   vol.subPath
								readOnly:  vol.readOnly
							},
							if backend.themeCustomization.enabled {
								name:      "theme-customization"
								mountPath: backend.themeCustomization.mount_path
								readOnly:  true
							},
							{
								name:      "tmp-volume"
								mountPath: "/tmp"
							},
						]
					},
					if backend.sidecars != _|_ for sidecar in backend.sidecars {
						sidecar
					},
				]

				if backend.nodeSelector != _|_ { nodeSelector: backend.nodeSelector }
				if backend.affinity != _|_ { affinity: backend.affinity }
				if backend.tolerations != _|_ { tolerations: backend.tolerations }

				volumes: [
					if #config.mountFiles != _|_ for idx, _ in #config.mountFiles {
						name: "files-\(idx)"
						configMap: name: "\(#config.metadata.name)-files-\(idx)"
					},
					if backend.persistence != _|_ for name, vol in backend.persistence {
						name: name
						if vol.type == "emptyDir" {
							emptyDir: {}
						}
						if vol.type != "emptyDir" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-\(name)"
						}
					},
					if backend.extraVolumes != _|_ for vol in backend.extraVolumes {
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
					if backend.themeCustomization.enabled {
						name: "theme-customization"
						configMap: name: "docs-theme-customization"
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

#BackendPodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-backend"
		namespace: #config.metadata.namespace
	}
	spec: {
		maxUnavailable: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "backend"
		}
	}
}