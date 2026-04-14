package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#HocuspocusSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-hocuspocus"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "hocuspocus"
		}
		annotations: {
			"helm.sh/resource-policy": "keep"
			if #config.metadata.annotations != _|_ {
				#config.metadata.annotations
			}
		}
	}
	type: "Opaque"
	stringData: {
		secret: #config.hocuspocus.auth.secret
	}
}
