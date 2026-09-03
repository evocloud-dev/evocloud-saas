package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)



#DeploymentShell: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-maintenance-shell"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		replicas: #config.maintenance.shell.replicas
		selector: matchLabels: {
			"app.kubernetes.io/name":     #config.metadata.name
			"app.kubernetes.io/instance": "\(#config.metadata.name)-maintenance-shell"
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     #config.metadata.name
					"app.kubernetes.io/instance": "\(#config.metadata.name)-maintenance-shell"
				}
				annotations: {
					"checksum/php-env-vars":                  "fake-checksum"
					"checksum/secret-env-vars":               "fake-checksum"
					"checksum/php-fpm-conf":                  "fake-checksum"
					"checksum/php-fpm-d-zzzz-www-pool-conf": "fake-checksum"
					"checksum/php-ini":                       "fake-checksum"
					"checksum/php-conf-d-30-pimcore-ini":     "fake-checksum"
					for k, v in #config.podAnnotations {
						"\(k)": v
					}
				}
			}
			spec: {
				if #config.php.imagePullSecrets != _|_ && len(#config.php.imagePullSecrets) > 0 {
					imagePullSecrets: #config.php.imagePullSecrets
				}
				serviceAccountName: #saName
				if #config.podSecurityContext != _|_ && #config.podSecurityContext != {} {
					securityContext: #config.podSecurityContext
				}
				initContainers: [
					{
						name:  "wait-for-pimcore-installed"
						image: "busybox:latest"
						command: [
							"sh",
							"-c",
							"until [ -f /var/www/\(#config.pvc.data.subPath)/var/installed ]; do echo wait-for-pimcore-installed; sleep 5; done;",
						]
						volumeMounts: [
							{
								name:      "pimcore-data"
								mountPath: "/var/www"
							},
						]
					},
				]
				containers: [
					{
						name:            "maintenance-shell"
						image:           "\(#config.php.image.registry):\(#config.php.image.tag)"
						imagePullPolicy: #config.php.image.pullPolicy
						tty:             true
						stdin:           true
						command: ["/bin/bash", "/opt/maintenance-scripts/entrypoint.sh"]
						readinessProbe: {
							exec: command: [
								"cat",
								"/tmp/entrypoint_done",
							]
							initialDelaySeconds: 5
							periodSeconds:       5
						}
						resources: #config.maintenance.shell.resources
						envFrom: [
							{
								configMapRef: name: "\(#config.metadata.name)-maintenance-shell-env"
							},
							{
								secretRef: name: "\(#config.metadata.name)-dotenv"
							},
							{
								secretRef: name: "\(#config.metadata.name)-maintenance-dotenv"
							},
						]
						securityContext: {
							runAsUser:  0
							runAsGroup: 0
						}
						volumeMounts: [
							{
								name:      "scripts"
								mountPath: "/opt/maintenance-scripts"
							},
							{
								name:      "php-ini"
								mountPath: "/usr/local/etc/php/php.ini"
								subPath:   "php.ini"
							},
							{
								name:      "php-conf-d-30-pimcore-ini"
								mountPath: "/usr/local/etc/php/conf.d/30-pimcore.ini"
								subPath:   "30-pimcore.ini"
							},
							{
								name:      "php-fpm-conf"
								mountPath: "/usr/local/etc/php-fpm.conf"
								subPath:   "php-fpm.conf"
							},
							{
								name:      "php-fpm-d-zzzz-www-pool-conf"
								mountPath: "/usr/local/etc/php-fpm.d/zzzz-www.conf"
								subPath:   "zzzz-www-pool.conf"
							},
							{
								name:      "pimcore-data"
								mountPath: "/var/www/pimcore"
								subPath:   #config.pvc.data.subPath
							},
							for k, v in #config.pvc.data.sharedSubPaths {
								{
									name:      "pimcore-data"
									mountPath: v.mountPath
									subPath:   v.subPath
								}
							},
							{
								name:      #backupVolumeName
								mountPath: "/backup"
								readOnly:  true
								subPath:   #config.pvc.mysqlBackup.subPath
							},
							for k, v in #config.pimcore.customConfigFiles {
								if v.enabled {
									{
										name:      k
										mountPath: "/var/www/pimcore/\(v.containerPath)"
										subPath:   k
									}
								}
							},
							for k, v in #config.pimcore.mountedConfigDirs {
								if v.enabled {
									{
										name:      k
										mountPath: "/var/www/pimcore/\(v.containerPath)"
										readOnly:  true
									}
								}
							},
							for m in #config.maintenance.shell.extraVolumeMounts {
								m
							},
						]
					},
				]
				volumes: [
					{
						name: "scripts"
						configMap: name: "\(#config.metadata.name)-maintenance-shell-init"
					},
					{
						name: "pimcore-data"
						persistentVolumeClaim: claimName: #dataClaimName
					},
					{
						name: "php-ini"
						configMap: name: "\(#config.metadata.name)-php-ini"
					},
					{
						name: "php-conf-d-30-pimcore-ini"
						configMap: name: "\(#config.metadata.name)-php-conf-d-30-pimcore-ini"
					},
					{
						name: "php-fpm-conf"
						configMap: name: "\(#config.metadata.name)-php-fpm-conf"
					},
					{
						name: "php-fpm-d-zzzz-www-pool-conf"
						configMap: name: "\(#config.metadata.name)-php-fpm-d-zzzz-www-pool-conf"
					},
					if #dataClaimName != #backupClaimName {
						{
							name: "pimcore-mysql-backup"
							persistentVolumeClaim: claimName: #backupClaimName
						}
					},
					for k, v in #config.pimcore.customConfigFiles {
						if v.enabled {
							{
								name: k
								configMap: name: "\(#config.metadata.name)-\(k)"
							}
						}
					},
					for k, v in #config.pimcore.mountedConfigDirs {
						if v.enabled {
							{
								name: k
								configMap: name: "\(#config.metadata.name)-\(k)"
							}
						}
					},
				]
				if #config.nodeSelector != _|_ && #config.nodeSelector != {} {
					nodeSelector: #config.nodeSelector
				}
				if #config.affinity != _|_ && #config.affinity != {} {
					affinity: #config.affinity
				}
				if #config.tolerations.maintenance != _|_ {
					tolerations: #config.tolerations.maintenance
				}
			}
		}
	}

	#dataClaimName: {
		if #config.pvc.data.existingClaim != "" {
			#config.pvc.data.existingClaim
		}
		if #config.pvc.data.existingClaim == "" {
			"\(#config.metadata.name)-\(#config.pvc.data.name)"
		}
	}

	#backupClaimName: {
		if #config.pvc.mysqlBackup.existingClaim != "" {
			#config.pvc.mysqlBackup.existingClaim
		}
		if #config.pvc.mysqlBackup.existingClaim == "" {
			"\(#config.metadata.name)-\(#config.pvc.mysqlBackup.name)"
		}
	}

	#backupVolumeName: {
		if #dataClaimName == #backupClaimName {
			"pimcore-data"
		}
		if #dataClaimName != #backupClaimName {
			"pimcore-mysql-backup"
		}
	}

	#saName: {
		if #config.serviceAccount.name != "" {
			#config.serviceAccount.name
		}
		if #config.serviceAccount.name == "" {
			#config.metadata.name
		}
	}
}


