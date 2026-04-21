// This file provides custom Ruby initializers to patch Mastodon's behavior at runtime.
// Primarily used to manage internal HTTP traffic by bypassing Rails' default SSL enforcement.
package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigMapPatch: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-patch"
		labels:    #config.metadata.labels
	}
	data: {
		"zzz_disable_ssl.rb": """
			Rails.application.configure do
			  config.force_ssl = false
			end
			"""
	}
}
