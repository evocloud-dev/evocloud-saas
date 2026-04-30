package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ImagePullSecret: corev1.#Secret & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-registry"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	type: "kubernetes.io/dockerconfigjson"
	data: {
		".dockerconfigjson": '{"auths":{"\(#config.imageCredentials.registry)":{"auth":"\(#config.imageCredentials.username):\(#config.imageCredentials.password)"}}}'
	}
}
