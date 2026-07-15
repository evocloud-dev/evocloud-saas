package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#BackendCronJob: batchv1.#CronJob & {
	#config: #Config
	#cron:   _ // The specific cron configuration
	let backend = #config.backend

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config.metadata.name)-\(#cron.name)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "backend-cronjob"
			"cronjob-name":                #cron.name
		}
	}
	spec: batchv1.#CronJobSpec & {
		schedule:                   #cron.schedule
		concurrencyPolicy:          #cron.concurrencyPolicy | *"Forbid"
		successfulJobsHistoryLimit: #cron.successfulJobsHistoryLimit | *3
		failedJobsHistoryLimit:     #cron.failedJobsHistoryLimit | *1
		jobTemplate: spec: template: {
			metadata: {
				labels: #config.metadata.labels & {
					"app.kubernetes.io/component": "backend-cronjob"
					"cronjob-name":                #cron.name
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace: backend.shareProcessNamespace
				restartPolicy:         #cron.restartPolicy | *"Never"
				
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}

				containers: [
					{
						name:            #config.chartName
						image:           backend.image.reference | *#config.image.reference
						imagePullPolicy: backend.image.pullPolicy | *#config.image.pullPolicy
						args:            #cron.command

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
						]
					},
					if backend.sidecars != _|_ for sidecar in backend.sidecars {
						sidecar
					},
				]

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
				]
			}
		}
	}
}