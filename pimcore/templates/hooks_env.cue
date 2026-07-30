package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigMapInstallationEnv: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-installation-env"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		PHP_MEMORY_LIMIT:              #config.php.ini.installation.phpMemoryLimit
		PHP_MAX_EXECUTION_TIME:        "\(#config.php.ini.installation.phpMaxExecutionTime)"
		PHP_ERROR_REPORTING:          #config.php.ini.pimcore.phpErrorReporting
		PHP_DISPLAY_ERRORS:            #config.php.ini.pimcore.phpDisplayErrors
		PHP_DISPLAY_STARTUP_ERRORS:    "\(#config.php.ini.pimcore.phpDisplayStartupErrors)"
		PHP_POST_MAX_SIZE:             #config.php.ini.pimcore.phpPostMaxSize
		PHP_UPLOAD_MAX_FILESIZE:       #config.php.ini.pimcore.phpUploadMaxFilesize
		OPCACHE_ENABLE:                "\(#config.php.ini.pimcore.opcacheEnable)"
		OPCACHE_ENABLE_CLI:            "\(#config.php.ini.pimcore.opcacheEnableCli)"
		OPCACHE_MEMORY_CONSUMPTION:    "\(#config.php.ini.pimcore.opcacheMemoryConsumption)"
		OPCACHE_MAX_ACCELERATED_FILES: "\(#config.php.ini.pimcore.opcacheMaxAcceleratedFiles)"
		OPCACHE_VALIDATE_TIMESTAMPS:   "\(#config.php.ini.pimcore.opcacheValidateTimestamps)"
		OPCACHE_CONSISTENCY_CHECKS:    "\(#config.php.ini.pimcore.opcacheConsistencyChecks)"
	}
}
