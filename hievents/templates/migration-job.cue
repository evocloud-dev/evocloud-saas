package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

#MigrationJob: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      #config._migrationName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "migration"
		}
		if #config.migration.useHelmHooks {
			annotations: {
				"helm.sh/hook":               "post-install,post-upgrade"
				"helm.sh/hook-weight":        "-1"
				"helm.sh/hook-delete-policy": #config.migration.hookDeletePolicy
			}
		}
	}
	spec: {
		template: {
			metadata: labels: #config._baseLabels & {
				"app.kubernetes.io/component": "migration"
			}
			spec: {
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: #config._saName
				restartPolicy:      "OnFailure"
				if len(#config.migration.podSecurityContext) > 0 {
					securityContext: #config.migration.podSecurityContext
				}
				if len(#config.migration.podSecurityContext) == 0 && len(#config.backend.podSecurityContext) > 0 {
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
					name:            "migration"
					image:           #config._backendImageRef
					imagePullPolicy: #config.backend.image.pullPolicy
					if len(#config.migration.command) > 0 {
						command: #config.migration.command
					}
					if len(#config.migration.args) > 0 {
						args: #config.migration.args
					}
					env: #config._appEnv
					
					if len(#config.migration.securityContext) > 0 {
						securityContext: #config.migration.securityContext
					}
					if len(#config.migration.securityContext) == 0 && len(#config.backend.securityContext) > 0 {
						securityContext: #config.backend.securityContext
					}
					if len(#config.migration.resources) > 0 {
						resources: #config.migration.resources
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
