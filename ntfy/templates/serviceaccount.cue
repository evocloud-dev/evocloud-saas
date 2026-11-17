package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// #ServiceAccount mirrors templates/serviceaccount.yaml.
#ServiceAccount: corev1.#ServiceAccount & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      #config._saName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.commonAnnotations) > 0 || len(#config.serviceAccount.annotations) > 0 {
			annotations: {
				for k, v in #config.commonAnnotations if #config.serviceAccount.annotations[k] == _|_ {(k): v}
				#config.serviceAccount.annotations
			}
		}
	}
}

// #BackupServiceAccount mirrors templates/backup-serviceaccount.yaml.
#BackupServiceAccount: corev1.#ServiceAccount & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      #config._backupSaName
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "backup"
		}
		if len(#config.commonAnnotations) > 0 || len(#config.backup.serviceAccount.annotations) > 0 {
			annotations: {
				for k, v in #config.commonAnnotations if #config.backup.serviceAccount.annotations[k] == _|_ {(k): v}
				#config.backup.serviceAccount.annotations
			}
		}
	}
	automountServiceAccountToken: #config.backup.serviceAccount.automountServiceAccountToken
}
