package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigMapGeneral: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {
		// General Settings
		"BASEROW_MAX_IMPORT_FILE_SIZE_MB": "\(#config.config.maxImportFileSizeMb)"
		"BASEROW_MAX_SNAPSHOTS_PER_GROUP": "\(#config.config.maxSnapshotsPerGroup)"
		"PRIVATE_BACKEND_URL":             "http://\(#config.metadata.name)-wsgi:\(#config.backend.wsgi.service.port)"
		"PUBLIC_BACKEND_URL":              "http://\(#config.global.baserow.backendDomain)"
		"PUBLIC_WEB_FRONTEND_URL":         "http://\(#config.global.baserow.domain)"
	}
}
