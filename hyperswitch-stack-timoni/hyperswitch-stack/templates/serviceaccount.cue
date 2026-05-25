package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	let app = #config."hyperswitch-app"
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      "\(#config.metadata.name)-router-sa"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if app.server.serviceAccount.annotations != _|_ {
			annotations: app.server.serviceAccount.annotations
		}
		if app.server.serviceAccount.labels != _|_ {
			labels: app.server.serviceAccount.labels
		}
	}
}
