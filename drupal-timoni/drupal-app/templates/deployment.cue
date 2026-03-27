package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#DrupalDeployment: appsv1.#Deployment & {
	#config: #Config
	#cmName: string

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.drupal.replicas
		strategy: {
			type: #config.drupal.strategy
			if type == "RollingUpdate" {
				rollingUpdate: {
					maxUnavailable: 1
					maxSurge:       1
				}
			}
		}
		selector: matchLabels: #config.selector.labels & {
			tier: "drupal"
		}
		template: {
			metadata: labels: #config.metadata.labels & {
				tier: "drupal"
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: [ if #config.drupal.serviceAccount.name != "" { #config.drupal.serviceAccount.name }, #config.metadata.name ][0]
				
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
							runAsUser:  33
							runAsGroup: 33
						}
					},
				]

				containers: [
					{
						name:            "drupal"
						image:           #config.drupal.image + ":" + [ if #config.drupal.tag != "" { #config.drupal.tag }, #config.moduleVersion ][0]
						imagePullPolicy: #config.drupal.imagePullPolicy
						
						if #config.drupal.command != _|_ {
							command: #config.drupal.command
						}
						if #config.drupal.args != _|_ {
							args: #config.drupal.args
						}

						env: #config.#env
						ports: [
							{
								name:          "tcp-php-fpm"
								containerPort: 9000
								protocol:      "TCP"
							},
						]

						if #config.drupal.healthcheck.enabled {
							if #config.drupal.healthcheck.probes != _|_ {
								if #config.drupal.healthcheck.probes.livenessProbe != _|_ {
									livenessProbe: #config.drupal.healthcheck.probes.livenessProbe
								}
								if #config.drupal.healthcheck.probes.readinessProbe != _|_ {
									readinessProbe: #config.drupal.healthcheck.probes.readinessProbe
								}
							}
							if #config.drupal.healthcheck.probes == _|_ {
								livenessProbe: {
									exec: command: ["php-fpm-healthcheck"]
									initialDelaySeconds: 1
									periodSeconds:       5
								}
								readinessProbe: {
									exec: command: ["php-fpm-healthcheck"]
									initialDelaySeconds: 1
									periodSeconds:       5
								}
							}
						}

						securityContext: #config.securityContext
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
						resources:       #config.resources
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
