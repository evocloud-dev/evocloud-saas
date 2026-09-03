package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#SecretInitializeDotenv: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-initialize-dotenv"
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
		if #config.pvc.data.composerAuth != "" {
			COMPOSER_AUTH: #config.pvc.data.composerAuth
		}
		if #config.pvc.data.gitExtraHeader.host != "" {
			GIT_CONFIG_COUNT: "1"
			GIT_CONFIG_KEY_0: "http.\(#config.pvc.data.gitExtraHeader.host).extraheader"
			GIT_CONFIG_VALUE_0: #config.pvc.data.gitExtraHeader.value
		}
	}
}
