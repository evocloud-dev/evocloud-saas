package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#MigrateJob: batchv1.#Job & {
	#config: #Config
	let backend = #config.backend

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-migrate"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "backend-migrate"
		}
		annotations: {
			"argocd.argoproj.io/sync-options": "Replace=true,Force=true"
			if backend.migrateJobAnnotations != _|_ {
				backend.migrateJobAnnotations
			}
		}
	}
	spec: batchv1.#JobSpec & {
		ttlSecondsAfterFinished: backend.jobs.ttlSecondsAfterFinished
		backoffLimit:            backend.jobs.backoffLimit
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "backend-migrate"
				}
				if backend.podAnnotations != _|_ {
					annotations: backend.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace: backend.shareProcessNamespace
				restartPolicy:         backend.migrate.restartPolicy
				
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
						
						if backend.migrate.command != _|_ { command: backend.migrate.command }
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
					{
						name: "tmp-volume"
						emptyDir: {}
					},
				]
			}
		}
	}
}