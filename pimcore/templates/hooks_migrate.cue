package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

#JobMigrate: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-migrate"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.metadata.annotations != _|_ {
				#config.metadata.annotations
			}
		}
	}
	spec: {
		template: {
			metadata: {
				name: "\(#config.metadata.name)"
				labels: {
					"app.kubernetes.io/name":     #config.metadata.name
					"app.kubernetes.io/instance": "\(#config.metadata.name)-migrate"
				}
			}
			spec: {
				if #config.php.imagePullSecrets != _|_ && len(#config.php.imagePullSecrets) > 0 {
					imagePullSecrets: #config.php.imagePullSecrets
				}
				serviceAccountName: #saName
				restartPolicy:      "Never"
				initContainers: [
					{
						name:  "wait-for-mysql"
						image: "divante/mysql-client:1.0.0"
						command: [
							"sh",
							"-c",
							"until mysql -u \"\(#config.pimcore.db.username)\" -p\"\(#config.pimcore.db.password)\" -h \"\(#config.pimcore.db.host)\" \"\(#config.pimcore.db.name)\" -e \"SELECT 1\"; do echo wait-for-mysql; sleep 5; done;",
						]
					},
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
						name:            "pimcore"
						image:           "\(#config.php.image.registry):\(#config.php.image.tag)"
						imagePullPolicy: #config.php.image.pullPolicy
						envFrom: [
							{
								configMapRef: name: "\(#config.metadata.name)-installation-env"
							},
							{
								secretRef: name: "\(#config.metadata.name)-dotenv"
							},
						]
						command: ["/bin/sh", "-c"]
						args: [
							"""
							cd /var/www/pimcore &&
							./bin/console doctrine:migrations:migrate --no-interaction &&
							./bin/console assets:install
							""",
						]
						securityContext: {
							runAsUser:  #config.php.phpUser.uid
							runAsGroup: #config.php.phpUser.gid
						}
						resources: #config.installation.resources
						volumeMounts: [
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
								for k, v in #config.pimcore.customConfigFiles if v.enabled {
									{
										name:      k
										mountPath: "/var/www/pimcore/\(v.containerPath)"
										subPath:   k
									}
								},
							]
						},
					]
					volumes: [
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
						for k, v in #config.pimcore.customConfigFiles if v.enabled {
							{
								name: k
								configMap: name: "\(#config.metadata.name)-\(k)"
							}
						},
					]
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

	#saName: {
		if #config.serviceAccount.name != "" {
			#config.serviceAccount.name
		}
		if #config.serviceAccount.name == "" {
			#config.metadata.name
		}
	}
}
