package templates

import (
	"strings"

	batchv1 "k8s.io/api/batch/v1"
)

#JobInitialize: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-initialize"
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
								secretRef: name: "\(#config.metadata.name)-initialize-dotenv"
							},
						]
						command: ["/bin/sh", "-c"]
						args: [
							"""
							set -e
							USE_CUSTOM_CONFIG_FILES=\"\(#useCustomConfigFiles)\"
							if [ "$USE_CUSTOM_CONFIG_FILES" = "true" ]; then
							  echo "Using custom config files from ConfigMaps."
							else
							  echo "Using default config files."
							fi
							
							if [ -e "/var/www/pimcore/var/installed" ] || [ -f "/var/www/pimcore/vendor/bin/pimcore-install" ]; then
							  echo "Pimcore project directory is already initialized. Skipping initialization.";
							  exit 0;
							fi
							  
							echo "Initializing Pimcore project...";
							
							cd /var/www/pimcore
							
							INIT_FROM_REPOSITORY=\"\(#config.pvc.data.initFromRepo.enabled)\"
							INIT_REPOSITORY=\"\(#config.pvc.data.initFromRepo.gitRepositoryUrl)\"
							
							if [ "$INIT_FROM_REPOSITORY" = "true" ]; then
							  echo "Cloning Pimcore repository from $INIT_REPOSITORY";
							
							  if [ -n \"${PIMCORE_INIT_REPO_GIT_TOKEN}\" ]; then
							    echo "Using PIMCORE_INIT_REPO_GIT_TOKEN for authentication.";
							    INIT_REPO_HOST=$(printf '%s' "$INIT_REPOSITORY" | sed -E 's#^([a-zA-Z][a-zA-Z0-9+.-]*://[^/]+).*#\\1#')
							    export GIT_CONFIG_COUNT=1
							    export GIT_CONFIG_KEY_0=\"credential.${INIT_REPO_HOST}.helper\"
							    export GIT_CONFIG_VALUE_0=\"!f() { echo username=git; echo \\\"password=${PIMCORE_INIT_REPO_GIT_TOKEN}\\\"; }; f\"
							  else
							    echo "PIMCORE_INIT_REPO_GIT_TOKEN is not set. Cloning without authentication.";
							  fi
							
							  git clone --depth 1 \"$INIT_REPOSITORY\" --recurse-submodules --single-branch . || {
							    echo \"Failed to clone repository. Please check the repository URL and access permissions.\";
							    exit 1;
							  }
							
							  echo \"Running composer install...\";
							  composer install --no-scripts --no-cache --no-progress --no-interaction
							else
							  echo "Running composer create-project...";
							  composer create-project --no-scripts \((#config.pimcore.createProject)) . --no-cache --prefer-dist || {
							    echo "Composer create-project failed. Cleaning up incomplete installation...";
							    rm -rf /var/www/pimcore/* /var/www/pimcore/.[!.]* 2>/dev/null || true;
							    exit 1;
							  }
							fi
							
							\(#overrideConfigFilesShell)
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

	#useCustomConfigFiles: {
		#enabledList: [for k, v in #config.pimcore.customConfigFiles if v.enabled {v}]
		if len(#enabledList) > 0 {
			"true"
		}
		if len(#enabledList) == 0 {
			"false"
		}
	}

	#overrideConfigFilesShell: strings.Join([for k, v in #config.pimcore.customConfigFiles if v.enabled {
		"echo \"This file is managed by a ConfigMap\" > /var/www/pimcore/\(v.containerPath)\n"
	}], "")
}
