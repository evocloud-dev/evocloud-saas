package templates

import (
	batchv1 "k8s.io/api/batch/v1"
)

#JobInstall: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-install"
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
					"app.kubernetes.io/instance": "\(#config.metadata.name)-install"
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
						name:  "wait-for-pimcore-initialized"
						image: "busybox:latest"
						command: [
							"sh",
							"-c",
							"until [ -f /var/www/pimcore/vendor/bin/pimcore-install ]; do echo wait-for-pimcore-initialized; sleep 5; done;",
						]
						volumeMounts: [
							{
								name:      "pimcore-data"
								mountPath: "/var/www/pimcore"
								subPath:   #config.pvc.data.subPath
							},
						]
					},
					{
						name:  "wait-for-mysql"
						image: "divante/mysql-client:1.0.0"
						command: [
							"sh",
							"-c",
							"until mysql -u \"\(#config.pimcore.db.username)\" -p\"\(#config.pimcore.db.password)\" -h \"\(#config.pimcore.db.host)\" \"\(#config.pimcore.db.name)\" -e \"SELECT 1\"; do echo wait-for-mysql; sleep 5; done;",
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
							set -e
							
							if [ -e "/var/www/pimcore/var/installed" ]; then
							  echo "Pimcore is already installed. Skipping installation.";
							  exit 0;
							fi
							
							cd /var/www/pimcore
							
							echo "Clearing stale container cache prior to installation..."
							rm -rf /var/www/pimcore/var/cache/* 2>/dev/null || true

							echo "Running console assets:install ..."
							./bin/console assets:install --symlink --relative
							
							echo "Running pimcore-install ..."
							./vendor/bin/pimcore-install --install-profile='App\\Installer\\SkeletonProfile' --no-interaction

							echo "Initializing OpenSearch generic-data-index mappings ..."
							./bin/console generic-data-index:update:index || true

							echo "Clearing cache ..."
							./bin/console cache:clear
							
							date --rfc-2822 > /var/www/pimcore/var/installed
							echo "Done."
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
