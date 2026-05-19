package templates

import (
	corev1 "k8s.io/api/core/v1"
	"encoding/json"
)

#SecretWs: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-ws-config"
		namespace: #config.metadata.namespace
		labels: {
			app:      #config.metadata.name
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
	}
	type: "Opaque"
	stringData: {
		"config.json": json.Marshal(#config.supersetWebsockets.config)
	}
}
