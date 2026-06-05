package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

#SchedulerCronJob: batchv1.#CronJob & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      #config._schedulerName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "scheduler"
		}
	}
	spec: {
		schedule:          #config.scheduler.schedule
		concurrencyPolicy: #config.scheduler.concurrencyPolicy
		if #config.scheduler.successfulJobsHistoryLimit != _|_ {
			successfulJobsHistoryLimit: #config.scheduler.successfulJobsHistoryLimit
		}
		if #config.scheduler.failedJobsHistoryLimit != _|_ {
			failedJobsHistoryLimit: #config.scheduler.failedJobsHistoryLimit
		}
		jobTemplate: spec: template: {
			metadata: labels: #config._baseLabels & {
				"app.kubernetes.io/component": "scheduler"
			}
			spec: {
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: #config._saName
				restartPolicy:      "OnFailure"
				if len(#config.scheduler.podSecurityContext) > 0 {
					securityContext: #config.scheduler.podSecurityContext
				}
				if len(#config.scheduler.podSecurityContext) == 0 && len(#config.backend.podSecurityContext) > 0 {
					securityContext: #config.backend.podSecurityContext
				}
				
				if #config.initContainers.postgresql.enabled || #config.initContainers.redis.enabled {
					initContainers: [
						if #config.initContainers.postgresql.enabled {
							#config._postgresInitContainer
						},
						if #config.initContainers.redis.enabled {
							#config._redisInitContainer
						},
					]
				}
				
				containers: [{
					name:            "scheduler"
					image:           #config._backendImageRef
					imagePullPolicy: #config.backend.image.pullPolicy
					if len(#config.scheduler.command) > 0 {
						command: #config.scheduler.command
					}
					if len(#config.scheduler.args) > 0 {
						args: #config.scheduler.args
					}
					env: #config._appEnv
					
					if len(#config.scheduler.securityContext) > 0 {
						securityContext: #config.scheduler.securityContext
					}
					if len(#config.scheduler.securityContext) == 0 && len(#config.backend.securityContext) > 0 {
						securityContext: #config.backend.securityContext
					}
					if len(#config.scheduler.resources) > 0 {
						resources: #config.scheduler.resources
					}
					if #config.backend.persistence.enabled && #config.hieventsConfig.storage.driver == "local" {
						volumeMounts: [{
							name:      "storage"
							mountPath: #config.backend.persistence.mountPath
						}]
					}
				}]
				if #config.backend.persistence.enabled && #config.hieventsConfig.storage.driver == "local" {
					volumes: [{
						name: "storage"
						persistentVolumeClaim: claimName: #config._storageClaimName
					}]
				}
			}
		}
	}
}
