package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#OutlookAddonManifestConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "outlook-addon-manifest"
		namespace: #config.metadata.namespace
	}
	data: {
		// Evaluates the raw template data from config strings, mimicking Helm's .Files.Get execution
		"manifest.xml": #config.frontend.outlookAddon.manifestTemplate
	}
}