package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	"list"
)

#ExtraCronJob: batchv1.#CronJob & {
	#config: #Config
	#cmName: string
	#cronName: string
	#cron: {
		schedule:     string
		script:       string
		volumeMounts: [...corev1.#VolumeMount]
		volumes:      [...corev1.#Volume]
	}

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config.metadata.name)-extra-cron-\(#cronName)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: batchv1.#CronJobSpec & {
		schedule:                   #cron.schedule
		concurrencyPolicy:          "Replace"
		successfulJobsHistoryLimit: #config.drupal.cron.successfulJobsHistoryLimit
		failedJobsHistoryLimit:     #config.drupal.cron.failedJobsHistoryLimit
		jobTemplate: spec: template: {
			metadata: labels: #config.metadata.labels
			spec: corev1.#PodSpec & {
				serviceAccountName: #config.metadata.name
				restartPolicy:      "OnFailure"
				containers: [
					{
						name:            "drush"
						image:           #config.drupal.image + ":" + [ if #config.drupal.tag != "" { #config.drupal.tag }, #config.moduleVersion ][0]
						imagePullPolicy: #config.drupal.imagePullPolicy
						command: [
							"/bin/sh",
							"-c",
							#"""
								# Errors should fail the job
								set -e
								cd /var/www/html
								# SSL / client config
								if [ "\#(#config.mysql.enabled)" = "true" ]; then
								echo "Fixing MariaDB client SSL defaults"
								cat <<EOF > /tmp/.my.cnf
								[client]
								ssl = false
								ssl-verify-server-cert = false
								EOF
								export HOME=/tmp

								echo "Configuring Drush to disable MySQL SSL"
								mkdir -p /var/www/html/drush
								cat <<'EOF' > /var/www/html/drush/drush.yml
								command:
								  sql:
								    cli:
								      options:
								        extra: "--skip-ssl"
								    connect:
								      options:
								        extra: "--skip-ssl"
								    create:
								      options:
								        extra: "--skip-ssl"
								    drop:
								      options:
								        extra: "--skip-ssl"
								    dump:
								      options:
								        extra: "--skip-ssl"
								    query:
								      options:
								        extra: "--skip-ssl"
								EOF
								fi

								\#(#cron.script)
								"""#
								,
						]
						env: list.Concat([#config.#env, [
							{
								name:  "HOME"
								value: "/tmp"
							},
						]])
						volumeMounts: list.Concat([[
							{
								name:      "cm-drupal"
								mountPath: "/usr/local/etc/php/php.ini"
								subPath:   "php.ini"
								readOnly:  true
							},
							{
								name:      "cm-drupal"
								mountPath: "/usr/local/etc/php/conf.d/opcache-recommended.ini"
								subPath:   "opcache-recommended.ini"
								readOnly:  true
							},
							{
								name:      "cm-drupal"
								mountPath: "/usr/local/etc/php-fpm.d/www.conf"
								subPath:   "www.conf"
								readOnly:  true
							},
							{
								name:      "cm-drupal"
								mountPath: "/var/www/html/sites/default/settings.php"
								subPath:   "settings.php"
								readOnly:  true
							},
							{
								name:      "cm-drupal"
								mountPath: "/var/www/html/sites/default/extra.settings.php"
								subPath:   "extra.settings.php"
								readOnly:  true
							},
							{
								name:      "cm-drupal"
								mountPath: "/var/www/html/sites/default/services.yml"
								subPath:   "services.yml"
								readOnly:  true
							},
							{
								name:      "ssmtp"
								mountPath: "/etc/ssmtp/ssmtp.conf"
								subPath:   "ssmtp.conf"
								readOnly:  true
							},
							{
								name:      "twig-cache"
								mountPath: "/cache/twig"
							},
							if !#config.drupal.disableDefaultFilesMount {
								{
									name:      "files"
									mountPath: "/var/www/html/sites/default/files"
									subPath:   "public"
								}
							},
							if !#config.drupal.disableDefaultFilesMount {
								{
									name:      "files"
									mountPath: "/private"
									subPath:   "private"
								}
							},
							if #config.drupal.siteRoot != "/" {
								{
									name:      "webroot"
									mountPath: "/webroot"
								}
							},
							{
								name:      "tmp"
								mountPath: "/tmp"
							},
							{
								name:      "drush-config"
								mountPath: "/var/www/html/drush"
							},
						], #cron.volumeMounts])
						securityContext: #config.securityContext
					},
				]
				
				volumes: list.Concat([[
					{
						name: "cm-drupal"
						configMap: name: #cmName
					},
					{
						name: "ssmtp"
						secret: {
							secretName: #config.metadata.name + "-ssmtp"
							items: [{
								key:  "ssmtp.conf"
								path: "ssmtp.conf"
							}]
						}
					},
					{
						name: "twig-cache"
						emptyDir: {}
					},
					if #config.drupal.persistence.enabled {
						{
							name: "files"
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-drupal"
						}
					},
					if !#config.drupal.persistence.enabled && !#config.drupal.disableDefaultFilesMount {
						{
							name: "files"
							emptyDir: {}
						}
					},
					if #config.drupal.siteRoot != "/" {
						{
							name: "webroot"
							emptyDir: {}
						}
					},
					{
						name: "tmp"
						emptyDir: {}
					},
					{
						name: "drush-config"
						emptyDir: {}
					},
				], #cron.volumes])

				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
			}
		}
	}
}
