package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name: {
			if #config.serviceAccount.name != "" {
				#config.serviceAccount.name
			}
			if #config.serviceAccount.name == "" {
				#config._fullname
			}
		}
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.serviceAccount.annotations != _|_ || #config.commonAnnotations != _|_ {
			annotations: {
				for k, v in #config.serviceAccount.annotations {
					"\(k)": v
				}
				for k, v in #config.commonAnnotations {
					"\(k)": v
				}
			}
		}
	}
	automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
}
