package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigMapFrontend: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-frontend"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {
		if #config.frontend.config.additionalModules != "" {
			"ADDITIONAL_MODULES": "\(#config.frontend.config.additionalModules)"
		}
		if #config.frontend.config.disablePublicUrlCheck != "" {
			"BASEROW_DISABLE_PUBLIC_URL_CHECK": "\(#config.frontend.config.disablePublicUrlCheck)"
		}
		if #config.frontend.config.disableGoogleDocsFilePreview != "" {
			"BASEROW_DISABLE_GOOGLE_DOCS_FILE_PREVIEW": "\(#config.frontend.config.disableGoogleDocsFilePreview)"
		}
		"DOWNLOAD_FILE_VIA_XHR": "\(#config.frontend.config.downloadFileViaXhr)"
	}
}
