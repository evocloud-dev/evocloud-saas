package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#EnvSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-env"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "Opaque"
	stringData: {
		#config.envSecret

		HOST_URL:            #config.config.publicUrl
		PUBLIC_URL:          #config.config.publicUrl
		REACT_APP_SERVERURL: #config.config.apiUrl
		SERVER_URL:          #config.config.apiUrl
	}
}
