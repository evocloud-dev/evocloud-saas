package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#NocodbConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-configmap"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		NC_DB:  "pg://\(#config.metadata.name)-cnpg-main-rw:5432?u=\(#config.cnpg.main.user)&p=\(#config.cnpg.main.password)&d=\(#config.cnpg.main.database)"
		NC_MIN: ""
	}
}
