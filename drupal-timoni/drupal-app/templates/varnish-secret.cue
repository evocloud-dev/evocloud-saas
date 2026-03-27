package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#VarnishSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "varnish"
	}
	type: "Opaque"
	data: {
		if #config.varnish.admin.secret != "" {
			secret: #config.varnish.admin.secret
		}
		// In a real environment, you'd use a secret generator or inject this.
		// For literal parity, we assume the user provides it or it stays empty.
		if #config.varnish.admin.secret == "" {
			secret: "cmVwbGFjZW1l" // b64 "replaceme"
		}
	}
}
