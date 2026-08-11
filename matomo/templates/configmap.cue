package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#PhpConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-php-config"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {
		"custom.ini": #config.php.ini
		"ports.conf": "Listen \(#config.apache.port)\n"
		"000-default.conf": """
			<VirtualHost *:\(#config.apache.port)>
			\tServerAdmin webmaster@localhost
			\tDocumentRoot /var/www/html
			\tErrorLog ${APACHE_LOG_DIR}/error.log
			\tCustomLog ${APACHE_LOG_DIR}/access.log combined
			</VirtualHost>
			"""
	}
}

