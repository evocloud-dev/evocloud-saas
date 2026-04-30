package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#DockerRegistrySecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-docker-registry-credentials"
	}
	type: "kubernetes.io/dockerconfigjson"
	data: {
		// Literal translation of the Helm 'imagePullSecret' helper
		".dockerconfigjson": '{"auths":{"\(#config.registry.url)":{"username":"\(#config.registry.user)","password":"\(#config.registry.password)"}}}'
	}
}
