package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#CeleryTranscribeDeployment: appsv1.#Deployment & {
	#config:   _
	#instance: _

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-celery-transcribe-\(#instance.name)"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "celery-transcribe"
			instance:                      #instance.name
		}
		if #instance.dpAnnotations != _|_ {
			annotations: #instance.dpAnnotations
		}
		if #instance.dpAnnotations == _|_ && #config.celeryTranscribe.dpAnnotations != _|_ {
			annotations: #config.celeryTranscribe.dpAnnotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #instance.replicas | *#config.celeryTranscribe.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "celery-transcribe"
			instance:                      #instance.name
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "celery-transcribe"
					instance:                      #instance.name
				}
				if #instance.podAnnotations != _|_ {
					annotations: #instance.podAnnotations
				}
				if #instance.podAnnotations == _|_ && #config.celeryTranscribe.podAnnotations != _|_ {
					annotations: #config.celeryTranscribe.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace:        #instance.shareProcessNamespace | *#config.celeryTranscribe.shareProcessNamespace
				automountServiceAccountToken: #instance.automountServiceAccountToken | *#config.celeryTranscribe.automountServiceAccountToken
				serviceAccountName:           #instance.serviceAccountName | *#config.celeryTranscribe.serviceAccountName
				
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				
				let podSecContext = #instance.podSecurityContext | *#config.celeryTranscribe.podSecurityContext
				if podSecContext != _|_ {
					securityContext: podSecContext
				}

				let sidecars = #instance.sidecars | *#config.celeryTranscribe.sidecars

				containers: [
					{
						name: #config.chartName
						
						image:           #instance.image.reference | *#config.celeryTranscribe.image.reference
						imagePullPolicy: #instance.image.pullPolicy | *#config.celeryTranscribe.image.pullPolicy | *#config.image.pullPolicy

						let cmd = #instance.command | *#config.celeryTranscribe.command
						if cmd != _|_ { command: cmd }

						let argsList = #instance.args | *#config.celeryTranscribe.args
						if argsList != _|_ { args: argsList }

						let secContext = #instance.securityContext | *#config.celeryTranscribe.securityContext
						if secContext != _|_ { securityContext: secContext }

						let res = #instance.resources | *#config.celeryTranscribe.resources
						if res != _|_ { resources: res }

						let mergedEnv = {
							for k, v in #config.celeryTranscribe.envVars {
								"\(k)": v
							}
							for k, v in #instance.extraEnvVars {
								"\(k)": v
							}
						}
						if mergedEnv != _|_ {
							env: [
								for k, v in mergedEnv {
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

						let targetPort = #instance.service.targetPort | *#config.celeryTranscribe.service.targetPort
						if #config.celeryTranscribe.service != _|_ {
							ports: [{
								name:          "http"
								containerPort: targetPort
								protocol:      "TCP"
							}]
						}

						let liveness = #instance.probes.liveness | *#config.celeryTranscribe.probes.liveness
						if liveness != _|_ && #config.celeryTranscribe.service != _|_ {
							livenessProbe: {
								httpGet: {
									path: liveness.path
									port: targetPort
								}
								initialDelaySeconds: liveness.initialDelaySeconds
								periodSeconds:       liveness.periodSeconds
								if liveness.timeoutSeconds != _|_ {
									timeoutSeconds: liveness.timeoutSeconds
								}
							}
						}

						let readiness = #instance.probes.readiness | *#config.celeryTranscribe.probes.readiness
						if readiness != _|_ && #config.celeryTranscribe.service != _|_ {
							readinessProbe: {
								httpGet: {
									path: readiness.path
									port: targetPort
								}
								initialDelaySeconds: readiness.initialDelaySeconds
								periodSeconds:       readiness.periodSeconds
								if readiness.timeoutSeconds != _|_ {
									timeoutSeconds: readiness.timeoutSeconds
								}
							}
						}

						let startup = #instance.probes.startup | *#config.celeryTranscribe.probes.startup
						if startup != _|_ && #config.celeryTranscribe.service != _|_ {
							startupProbe: {
								httpGet: {
									path: startup.path
									port: targetPort
								}
								initialDelaySeconds: startup.initialDelaySeconds
								periodSeconds:       startup.periodSeconds
								if startup.timeoutSeconds != _|_ {
									timeoutSeconds: startup.timeoutSeconds
								}
							}
						}

						let persistence = #instance.persistence | *#config.celeryTranscribe.persistence
						let extraVolumeMounts = #instance.extraVolumeMounts | *#config.celeryTranscribe.extraVolumeMounts
						volumeMounts: [
							if #config.mountFiles != _|_ for idx, val in #config.mountFiles {
								name:      "files-\(idx)"
								mountPath: val.path
								subPath:   "content"
							},
							if persistence != _|_ for name, vol in persistence {
								name:      name
								mountPath: vol.mountPath
							},
							if extraVolumeMounts != _|_ for vol in extraVolumeMounts {
								name:      vol.name
								mountPath: vol.mountPath
								subPath:   vol.subPath
								readOnly:  vol.readOnly
							},
						]
					},
					if sidecars != _|_ for sidecar in sidecars {
						sidecar
					},
				]

				let nodeSel = #instance.nodeSelector | *#config.celeryTranscribe.nodeSelector
				if nodeSel != _|_ { nodeSelector: nodeSel }

				let aff = #instance.affinity | *#config.celeryTranscribe.affinity
				if aff != _|_ { affinity: aff }

				let tol = #instance.tolerations | *#config.celeryTranscribe.tolerations
				if tol != _|_ { tolerations: tol }

				let persistence = #instance.persistence | *#config.celeryTranscribe.persistence
				let extraVolumes = #instance.extraVolumes | *#config.celeryTranscribe.extraVolumes
				volumes: [
					if #config.mountFiles != _|_ for idx, _ in #config.mountFiles {
						name: "files-\(idx)"
						configMap: name: "\(#config.metadata.name)-files-\(idx)"
					},
					if persistence != _|_ for name, vol in persistence {
						name: name
						if vol.type == "emptyDir" {
							emptyDir: {}
						}
						if vol.type != "emptyDir" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-celery-transcribe-\(#instance.name)-\(name)"
						}
					},
					if extraVolumes != _|_ for vol in extraVolumes {
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

#CeleryTranscribePDB: policyv1.#PodDisruptionBudget & {
	#config:   _
	#instance: _

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-celery-transcribe-\(#instance.name)"
		namespace: #config.metadata.namespace
	}
	spec: {
		maxUnavailable: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "celery-transcribe"
			instance:                      #instance.name
		}
	}
}