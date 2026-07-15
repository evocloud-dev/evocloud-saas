package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#CeleryBackendDeployment: appsv1.#Deployment & {
	#config: #Config
	let celeryBackend = #config.celeryBackend

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-celery-backend"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "celery-backend"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: celeryBackend.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "celery-backend"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "celery-backend"
				}
				if celeryBackend.podAnnotations != _|_ {
					annotations: celeryBackend.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace:        celeryBackend.shareProcessNamespace
				automountServiceAccountToken: celeryBackend.automountServiceAccountToken
				serviceAccountName:           celeryBackend.serviceAccountName
				
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if celeryBackend.podSecurityContext != _|_ {
					securityContext: celeryBackend.podSecurityContext
				}

				containers: [
					{
						name:            #config.chartName
						image:           celeryBackend.image.reference | *#config.image.reference
						imagePullPolicy: celeryBackend.image.pullPolicy | *#config.image.pullPolicy
						
						if celeryBackend.command != _|_ { command: celeryBackend.command }
						if celeryBackend.args != _|_ { args: celeryBackend.args }
						if celeryBackend.securityContext != _|_ { securityContext: celeryBackend.securityContext }
						if celeryBackend.resources != _|_ { resources: celeryBackend.resources }
						
						if celeryBackend.envVars != _|_ {
							env: [
								for k, v in celeryBackend.envVars {
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

						if celeryBackend.service != _|_ {
							ports: [{
								name:          "http"
								containerPort: celeryBackend.service.targetPort
								protocol:      "TCP"
							}]
						}

						if celeryBackend.service != _|_ && celeryBackend.probes.liveness != _|_ {
							livenessProbe: {
								httpGet: {
									path: celeryBackend.probes.liveness.path
									port: celeryBackend.service.targetPort
								}
								initialDelaySeconds: celeryBackend.probes.liveness.initialDelaySeconds
								periodSeconds:       celeryBackend.probes.liveness.periodSeconds
								if celeryBackend.probes.liveness.timeoutSeconds != _|_ {
									timeoutSeconds: celeryBackend.probes.liveness.timeoutSeconds
								}
							}
						}
						if celeryBackend.service != _|_ && celeryBackend.probes.readiness != _|_ {
							readinessProbe: {
								httpGet: {
									path: celeryBackend.probes.readiness.path
									port: celeryBackend.service.targetPort
								}
								initialDelaySeconds: celeryBackend.probes.readiness.initialDelaySeconds
								periodSeconds:       celeryBackend.probes.readiness.periodSeconds
								if celeryBackend.probes.readiness.timeoutSeconds != _|_ {
									timeoutSeconds: celeryBackend.probes.readiness.timeoutSeconds
								}
							}
						}
						if celeryBackend.service != _|_ && celeryBackend.probes.startup != _|_ {
							startupProbe: {
								httpGet: {
									path: celeryBackend.probes.startup.path
									port: celeryBackend.service.targetPort
								}
								initialDelaySeconds: celeryBackend.probes.startup.initialDelaySeconds
								periodSeconds:       celeryBackend.probes.startup.periodSeconds
								if celeryBackend.probes.startup.timeoutSeconds != _|_ {
									timeoutSeconds: celeryBackend.probes.startup.timeoutSeconds
								}
							}
						}

						volumeMounts: [
							if #config.mountFiles != _|_ for idx, val in #config.mountFiles {
								name:      "files-\(idx)"
								mountPath: val.path
								subPath:   "content"
							},
							if celeryBackend.persistence != _|_ for name, vol in celeryBackend.persistence {
								name:      name
								mountPath: vol.mountPath
							},
							if celeryBackend.extraVolumeMounts != _|_ for vol in celeryBackend.extraVolumeMounts {
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
					if celeryBackend.sidecars != _|_ for sidecar in celeryBackend.sidecars {
						sidecar
					},
				]

				if celeryBackend.nodeSelector != _|_ { nodeSelector: celeryBackend.nodeSelector }
				if celeryBackend.affinity != _|_ { affinity: celeryBackend.affinity }
				if celeryBackend.tolerations != _|_ { tolerations: celeryBackend.tolerations }

				volumes: [
					if #config.mountFiles != _|_ for idx, _ in #config.mountFiles {
						name: "files-\(idx)"
						configMap: name: "\(#config.metadata.name)-files-\(idx)"
					},
					if celeryBackend.persistence != _|_ for name, vol in celeryBackend.persistence {
						name: name
						if vol.type == "emptyDir" {
							emptyDir: {}
						}
						if vol.type != "emptyDir" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-\(name)"
						}
					},
					if celeryBackend.extraVolumes != _|_ for vol in celeryBackend.extraVolumes {
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

#CeleryBackendPodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-celery-backend"
		namespace: #config.metadata.namespace
	}
	spec: {
		maxUnavailable: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "celery-backend"
		}
	}
}