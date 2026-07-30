package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SecretMaintenanceDotenv: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-maintenance-dotenv"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		PIMCORE_INIT_REPO_GIT_USER:  #config.pvc.data.initFromRepo.gitUserName
		PIMCORE_INIT_REPO_GIT_TOKEN: #config.pvc.data.initFromRepo.gitPersonalAccessToken
	}
}
