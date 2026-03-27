package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	"list"
)

#ReconfigureJob: batchv1.#Job & {
	#config: #Config
	#cmName: string

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-reconfigure"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: batchv1.#JobSpec & {
		backoffLimit:            #config.drupal.backoffLimitReconfigure
		ttlSecondsAfterFinished: 600
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
							"""
							}, "" ][0] )
							mkdir -p /var/www/html/drush
							cat <<EOF > /var/www/html/drush/drush.yml
							command:
							  sql:
							\#( [ if #config.mysql.enabled { """
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
							"""
							}, "" ][0] )
							EOF
							"""#
							,
						]
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
							runAsUser:  33
							runAsGroup: 33
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

							# SSL / client config
							if [ "\#(#config.mysql.enabled)" = "true" ]; then
							echo "Fixing MariaDB client SSL defaults"
							cat <<EOF > /tmp/.my.cnf
							[client]
							ssl = false
							ssl-verify-server-cert = false
							EOF
							export HOME=/tmp
							fi

							# Wait for DB to be available
							\#(#config.drupal.dbAvailabilityScript)

							if [ "\#(#config.redis.enabled)" = "true" ]; then
							until nc -z -w 5 \#(#config.metadata.name)-redis 6379; do echo Waiting for Redis; sleep 3; done
							echo Redis available
							fi

							# Check Drush status
							drush status || true

							# Run database updates
							if [ "\#(#config.drupal.cacheRebuildBeforeDatabaseMigration)" = "true" ]; then
							drush -y cache:rebuild
							fi
							if [ "\#(#config.drupal.updateDBBeforeDatabaseMigration)" = "true" ]; then
							drush -y updatedb
							fi

							# Rebuild caches
							drush -y cache:rebuild

							# Post Upgrade scripts
							\#(#config.drupal.postUpgradeScripts)
							"""#
							,
						]
						securityContext: #config.securityContext
						env: list.Concat([#config.#env, [
							{
								name:  "HOME"
								value: "/tmp"
							},
						]])
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
						]
						securityContext: #config.securityContext
					},
					if #config.proxysql.enabled {
						{
							name:            "proxysql"
							image:           "proxysql/proxysql:2.1.0"
							imagePullPolicy: "Always"
							ports: [
								{containerPort: 6032},
								{containerPort: 6033},
							]
							volumeMounts: [{
								name:      "configfiles"
								mountPath: "/etc/proxysql"
								readOnly:  true
							}]
							livenessProbe: {
								tcpSocket: port: 6032
								periodSeconds: 60
							}
							command: ["/usr/bin/proxysql", "--initial", "-f", "-c", "/etc/proxysql/proxysql.conf"]
							securityContext: {
								allowPrivilegeEscalation: false
								runAsUser:                999
								runAsGroup:               999
								runAsNonRoot:             true
							}
						}
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
					if #config.proxysql.enabled || #config.pgbouncer.enabled {
						{
							name: "configfiles"
							secret: secretName: #config.metadata.name + "-proxysql"
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
