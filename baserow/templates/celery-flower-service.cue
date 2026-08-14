package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceCeleryFlower: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-celery-flower"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-flower"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		type:     corev1.#ServiceType & #config.backend.celery.flower.service.type
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-celery-flower"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [
			{
				name:       "http"
				port:       #config.backend.celery.flower.service.port
				targetPort: "http"
				protocol:   "TCP"
			},
		]
	}
}
