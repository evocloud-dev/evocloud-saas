package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#BackupSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind: "Secret"
	metadata: timoniv1.#MetaComponent & {
		#Meta: #config.metadata
		#Component: "backup"
	}
	type: "Opaque"
	stringData: {
		"access-key": #config.backup.s3.accessKey
		"secret-key": #config.backup.s3.secretKey
	}
}
