package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DaemonSetServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      #config._daemonSetServiceAccountName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.daemonSetServiceAccount.annotations != _|_ {
			annotations: #config.daemonSetServiceAccount.annotations
		}
	}
}

