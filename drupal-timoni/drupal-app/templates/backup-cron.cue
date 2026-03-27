package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	"list"
)

#DrupalBackupCronJob: {
	#config: #Config
	#cmName: string

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config.metadata.name)-backup"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: batchv1.#CronJobSpec & {
		schedule:                   #config.drupal.backup.schedule
		successfulJobsHistoryLimit: #config.drupal.cron.successfulJobsHistoryLimit
		failedJobsHistoryLimit:     #config.drupal.cron.failedJobsHistoryLimit
		jobTemplate: spec: {
			template: {
				metadata: labels: #config.metadata.labels
				spec: corev1.#PodSpec & {
				serviceAccountName: [ if #config.drupal.serviceAccount.name != "" { #config.drupal.serviceAccount.name }, #config.metadata.name ][0]
				
				restartPolicy: "OnFailure"
				initContainers: [
					{
						name:  "init-drush-config"
						image: #config.drupal.initContainerImage
						command: [
							"/bin/sh",
							"-c",
							#"""
							\#( [ if #config.mysql.enabled { """
							cat <<EOF > /tmp/.my.cnf
							[client]
							ssl = false
							ssl-verify-server-cert = false
							EOF
							echo "Configuring Drush to disable MySQL SSL"
							mkdir -p /var/www/html/drush
							cat <<EOF > /var/www/html/drush/drush.yml
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
							"""
							}, "" ][0] )
							"""#
							],
						volumeMounts: [
							{
								name:      "tmp"
								mountPath: "/tmp"
							},
							{
								name:      "drush-config"
								mountPath: "/var/www/html/drush"
							},
						]
						securityContext: {
							allowPrivilegeEscalation: false
							runAsUser:                999
							runAsGroup:               999
							runAsNonRoot:             true
						}
					},
				]
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

								# Pre Install scripts
								\#(#config.drupal.cron.preInstallScripts)

								# Wait for DB to be available
								\#(#config.drupal.dbAvailabilityScript)

								# Check Drush status
								drush status

								# Cleanup old backups
								if [ "\#(#config.drupal.backup.cleanup.enabled)" = "true" ]; then
								find /backup/ -mindepth 1 -maxdepth 1 -type d -mtime +30 -exec echo "rm -rf " {} \; 2>&1;
								find /backup/ -mindepth 1 -maxdepth 1 -type d -mtime +30 -exec rm -rf {} \; 2>&1;
								fi

								# Run backup
								BACKUPNAME=$(date +%Y%m%d.%H%M%S)
								mkdir -p /backup/$BACKUPNAME
								echo "Backup DB"
								if [ "\#(#config.mysql.enabled)" = "true" ]; then
								drush -y sql-dump \#(#config.drupal.backup.sqlDumpArgs) --extra-dump=--no-tablespaces | gzip > /backup/$BACKUPNAME/db.sql.gz
								else
								drush -y sql-dump \#(#config.drupal.backup.sqlDumpArgs) | gzip > /backup/$BACKUPNAME/db.sql.gz
								fi
								echo "Backup public files"
								tar \#(#config.drupal.backup.filesArgs) -czvf /backup/$BACKUPNAME/files.tar.gz --directory=sites/default/files .
								echo "Backup private files"
								tar \#(#config.drupal.backup.privateArgs) -czvf /backup/$BACKUPNAME/private.tar.gz --directory=/private .
								"""#
								,
						]
						env: list.Concat([#config.#env, [
							{
								name:  "HOME"
								value: "/tmp"
							},
						]])
						if #config.drupal.cron.resources != _|_ {
							resources: #config.drupal.cron.resources
						}
						volumeMounts: [
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
							{
								name:      "backup-storage"
								mountPath: "/backup"
							},
						]
						securityContext: #config.securityContext
					},
				]
				
				volumes: [
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
					if #config.proxysql.enabled || #config.pgbouncer.enabled {
						{
							name: "configfiles"
							secret: secretName: #config.metadata.name + "-proxysql"
						}
					},
					if #config.drupal.backup.persistence.enabled {
						{
							name: "backup-storage"
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-backup"
						}
					},
					if !#config.drupal.backup.persistence.enabled {
						{
							name: "backup-storage"
							emptyDir: {}
						}
					},
				]

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
}
