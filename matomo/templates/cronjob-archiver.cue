package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

#CronJobArchiver: batchv1.#CronJob & {
	#config: #Config
	if #config.archiver.enabled != _|_ && #config.archiver.enabled {
		apiVersion: "batch/v1"
		kind:       "CronJob"
		metadata: {
			name:      #config.fullname + "-archiver"
			namespace: #config.metadata.namespace
			labels:    #config.metadata.labels
		}
		spec: {
			schedule:                   #config.archiver.schedule
			concurrencyPolicy:          #config.archiver.concurrencyPolicy
			successfulJobsHistoryLimit: #config.archiver.successfulJobsHistoryLimit
			failedJobsHistoryLimit:     #config.archiver.failedJobsHistoryLimit
			jobTemplate: spec: {
				activeDeadlineSeconds: #config.archiver.activeDeadlineSeconds
				template: {
					metadata: labels: {
						#config.selector.labels
						"app.kubernetes.io/component": "archiver"
					}
					spec: {
						restartPolicy:                "OnFailure"
						serviceAccountName:           #config.serviceAccountName
						automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
						if #config.podSecurityContext != _|_ {
							securityContext: #config.podSecurityContext
						}
						containers: [{
							name:            "archive"
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
							if #config.securityContext != _|_ {
								securityContext: #config.securityContext
							}
							// Native CUE array concatenation for command and arguments
							command: ["sh", "-c", "if [ -f /var/www/html/config/config.ini.php ]; then php /var/www/html/console core:archive --url=\"${MATOMO_URL}\"; else echo 'Matomo is not initialized yet. Skipping archiver execution.'; fi"]
							args: #config.archiver.extraArgs
							env: [
								{name: "MATOMO_URL", value:               #config.matomo.siteUrl},
								{name: "MATOMO_DATABASE_HOST", value:     #config.database.external.host},
								{name: "MATOMO_DATABASE_USERNAME", value: #config.database.external.username},
								{name: "MATOMO_DATABASE_DBNAME", value:   #config.database.external.name},
								if #config.database.external.existingSecret != "" {
									{name: "MATOMO_DATABASE_PASSWORD", valueFrom: {
										secretKeyRef: {
											name: #config.database.external.existingSecret
											key:  "database-password"
										}
									}}
								},
								if #config.database.external.existingSecret == "" {
									{name: "MATOMO_DATABASE_PASSWORD", value: #config.mysql.auth.password}
								},
							]
							resources: #config.archiver.resources
							volumeMounts: [
								{name: "matomo-data", mountPath: "/var/www/html"},
								if #config.php.ini != _|_ {
									{name: "php-config", mountPath: "/usr/local/etc/php/conf.d/helmforge.ini", subPath: "custom.ini", readOnly: true}
								},
							]
						}]
						volumes: [
							{
								name: "matomo-data"
								if #config.persistence.enabled != _|_ && #config.persistence.enabled {
									persistentVolumeClaim: claimName: #config.metadata.name
								}
								if #config.persistence.enabled == _|_ || !#config.persistence.enabled {
									emptyDir: {}
								}
							},
							if #config.php.ini != _|_ {
								{name: "php-config", configMap: {name: "\(#config.metadata.name)-php-config"}}
							},
						]
					}
				}
			}
		}
	}
}
