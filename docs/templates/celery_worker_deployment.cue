package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#CeleryWorkerDeployment: appsv1.#Deployment & {
	#config: #Config
	let celeryWorker = #config.backend.celery

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-celery-worker"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "celery-worker"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: celeryWorker.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "celery-worker"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "celery-worker"
				}
				if celeryWorker.podAnnotations != _|_ {
					annotations: celeryWorker.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace:        celeryWorker.shareProcessNamespace
				automountServiceAccountToken: celeryWorker.automountServiceAccountToken
				serviceAccountName:           celeryWorker.serviceAccountName
				
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if celeryWorker.podSecurityContext != _|_ {
					securityContext: celeryWorker.podSecurityContext
				}

				containers: [
					{
						name:            #config.chartName
						image:           celeryWorker.image.reference | *#config.image.reference
						imagePullPolicy: celeryWorker.image.pullPolicy | *#config.image.pullPolicy
						
						if celeryWorker.command != _|_ { command: celeryWorker.command }
						if celeryWorker.args != _|_ { args: celeryWorker.args }
						if celeryWorker.securityContext != _|_ { securityContext: celeryWorker.securityContext }
						if celeryWorker.resources != _|_ { resources: celeryWorker.resources }
						
						if celeryWorker.envVars != _|_ {
							env: [
								for k, v in celeryWorker.envVars {
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

						if celeryWorker.probes.liveness != _|_ {
							livenessProbe: {
								if celeryWorker.probes.liveness.exec != _|_ {
									exec: command: celeryWorker.probes.liveness.exec.command
								}
								if celeryWorker.probes.liveness.initialDelaySeconds != _|_ {
									initialDelaySeconds: celeryWorker.probes.liveness.initialDelaySeconds
								}
								if celeryWorker.probes.liveness.timeoutSeconds != _|_ {
									timeoutSeconds: celeryWorker.probes.liveness.timeoutSeconds
								}
							}
						}
						if celeryWorker.probes.readiness != _|_ {
							readinessProbe: {
								if celeryWorker.probes.readiness.exec != _|_ {
									exec: command: celeryWorker.probes.readiness.exec.command
								}
								if celeryWorker.probes.readiness.initialDelaySeconds != _|_ {
									initialDelaySeconds: celeryWorker.probes.readiness.initialDelaySeconds
								}
								if celeryWorker.probes.readiness.timeoutSeconds != _|_ {
									timeoutSeconds: celeryWorker.probes.readiness.timeoutSeconds
								}
							}
						}

						volumeMounts: [
							if #config.mountFiles != _|_ for idx, val in #config.mountFiles {
								name:      "files-\(idx)"
								mountPath: val.path
								subPath:   "content"
							},
							if celeryWorker.persistence != _|_ for name, vol in celeryWorker.persistence {
								name:      name
								mountPath: vol.mountPath
							},
							if celeryWorker.extraVolumeMounts != _|_ for vol in celeryWorker.extraVolumeMounts {
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
					if celeryWorker.sidecars != _|_ for sidecar in celeryWorker.sidecars {
						sidecar
					},
				]

				if celeryWorker.nodeSelector != _|_ { nodeSelector: celeryWorker.nodeSelector }
				if celeryWorker.affinity != _|_ { affinity: celeryWorker.affinity }
				if celeryWorker.tolerations != _|_ { tolerations: celeryWorker.tolerations }

				volumes: [
					if #config.mountFiles != _|_ for idx, _ in #config.mountFiles {
						name: "files-\(idx)"
						configMap: name: "\(#config.metadata.name)-files-\(idx)"
					},
					if celeryWorker.persistence != _|_ for name, vol in celeryWorker.persistence {
						name: name
						if vol.type == "emptyDir" {
							emptyDir: {}
						}
						if vol.type != "emptyDir" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-\(name)"
						}
					},
					if celeryWorker.extraVolumes != _|_ for vol in celeryWorker.extraVolumes {
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

#CeleryWorkerPodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-celery-worker"
		namespace: #config.metadata.namespace
	}
	spec: {
		maxUnavailable: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "celery-worker"
		}
	}
}