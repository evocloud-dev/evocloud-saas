package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#OutlookAddonConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "outlook-addon-config"
		namespace: #config.metadata.namespace
	}
	data: {
		"config.js": """
			window.__APP_CONFIG__ = {
			  BASE_URL: "\(#config.frontend.outlookAddon.baseUrl)",
			  APP_NAME: "\(#config.frontend.outlookAddon.appName)",
			  ENABLE_SOURCE_TRACKING: "\(#config.frontend.outlookAddon.enableSourceTracking)",
			  FEEDBACK_FORM: "\(#config.frontend.outlookAddon.feedbackForm)"
			};
			"""
	}
}