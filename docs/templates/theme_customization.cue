package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ThemeCustomizationConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "docs-theme-customization"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {
		"default.json": #config.backend.themeCustomization.file_content
	}
}
