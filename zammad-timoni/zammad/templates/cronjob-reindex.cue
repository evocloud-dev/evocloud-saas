package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

#CronJobReindex: batchv1.#CronJob & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config.metadata.name)-cronjob-reindex"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "zammad-cronjob-reindex"
		}
		annotations: {
			if #config.commonAnnotations != _|_ {
				#config.commonAnnotations
			}
			if #config.zammadConfig.cronJob.reindex.annotations != _|_ {
				#config.zammadConfig.cronJob.reindex.annotations
			}
		}
	}

	spec: {
		suspend:  #config.zammadConfig.cronJob.reindex.suspend
		schedule: #config.zammadConfig.cronJob.reindex.schedule
		jobTemplate: spec: {
			ttlSecondsAfterFinished: 300
			template: {
				metadata: {
					annotations: {
						if #config.podAnnotations != _|_ {
							#config.podAnnotations
						}
						if #config.zammadConfig.cronJob.reindex.podAnnotations != _|_ {
							#config.zammadConfig.cronJob.reindex.podAnnotations
						}
					}
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "zammad-init"
						if #config.zammadConfig.cronJob.reindex.podLabels != _|_ {
							#config.zammadConfig.cronJob.reindex.podLabels
						}
					}
				}
				spec: {
					restartPolicy: "Never"

					// PodSpec
					if len(#config.imagePullSecrets) > 0 {
						imagePullSecrets: #config.imagePullSecrets
					}
					if #config.serviceAccount.create {
						serviceAccountName: #config.serviceAccount.name
					}
					if #config.nodeSelector != _|_ {
						nodeSelector: #config.nodeSelector
					}
					if #config.affinity != _|_ {
						affinity: #config.affinity
					}
					if #config.tolerations != _|_ {
						tolerations: #config.tolerations
					}
					if #config.podSecurityContext != _|_ {
						securityContext: #config.podSecurityContext
					}

					// Custom user PodSpec
					if #config.zammadConfig.cronJob.reindex.podSpec != _|_ {
						#config.zammadConfig.cronJob.reindex.podSpec
					}

					// Init Containers
					initContainers: [
						if #config.zammadConfig.initContainers.volumePermissions.enabled {
							{
								name:            "zammad-volume-permissions"
								image:           "\(#config.zammadConfig.initContainers.volumePermissions.image.repository):\(#config.zammadConfig.initContainers.volumePermissions.image.tag)"
								imagePullPolicy: #config.zammadConfig.initContainers.volumePermissions.image.pullPolicy
								command:         #config.zammadConfig.initContainers.volumePermissions.command
								if #config.zammadConfig.initContainers.volumePermissions.resources != _|_ {
									resources: #config.zammadConfig.initContainers.volumePermissions.resources
								}
								if #config.zammadConfig.initContainers.volumePermissions.securityContext != _|_ {
									securityContext: #config.zammadConfig.initContainers.volumePermissions.securityContext
								}
								volumeMounts: #config._zammadVolumeMounts
							}
						},
					]

					// Main Containers
					containers: [
						{
							name:            "reindex"
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy

							// Container Config (from initContainers.postgresql)
							if #config.zammadConfig.initContainers.postgresql.resources != _|_ {
								resources: #config.zammadConfig.initContainers.postgresql.resources
							}
							if #config.zammadConfig.initContainers.postgresql.securityContext != _|_ {
								securityContext: #config.zammadConfig.initContainers.postgresql.securityContext
							}

							command: [
								"bundle",
								"exec",
								"rake",
								"zammad:searchindex:rebuild",
							]
							env:          #config._zammadEnv
							volumeMounts: #config._zammadVolumeMounts
						},
					]

					volumes: #config._zammadVolumes
				}
			}
		}
	}
}
