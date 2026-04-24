package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#MonitorConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-monitor-vars"
	}
	data: {
		PRIME_HOST:         "https://prime.plane.so"
		MACHINE_SIGNATURE:  *"ignored-in-timoni" | string // Literal parity placeholder
		APP_DOMAIN:         #config.license.licenseDomain
		APP_VERSION:        #config.planeVersion
		DEPLOY_PLATFORM:    "KUBERNETES"
		API_URL:            "http://\(#config.metadata.name)-api.\(#config.#namespace).svc.cluster.local:8000/"
		API_HOSTNAME:       "http://\(#config.metadata.name)-api.\(#config.#namespace).svc.cluster.local:8000/"
	}
}
