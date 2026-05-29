package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SecretSupersetConfig: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.fullname)-config"
		namespace: #config.metadata.namespace
		labels: {
			app:      #config.name
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
	}
	type: "Opaque"
	stringData: {
		"superset_config.py":    #config.supersetConfig
		"superset_init.sh":      #config.init.initscript
		"superset_bootstrap.sh": #config.bootstrapScript
	} & #config.extraSecrets
}
