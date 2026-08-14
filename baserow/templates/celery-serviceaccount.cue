package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccountCelery: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		if #config.backend.celery.worker.serviceAccount.name != "" {
			name: #config.backend.celery.worker.serviceAccount.name
		}
		if #config.backend.celery.worker.serviceAccount.name == "" {
			name: "\(#config.metadata.name)-celery"
		}
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.backend.celery.worker.serviceAccount.annotations != _|_ {
			annotations: #config.backend.celery.worker.serviceAccount.annotations
		}
	}
}
