package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#CronEnvironmentSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-cron-environment"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "cron"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		for k, v in #config.cron.environment {
			if k != "IMAP_USERNAME" && k != "IMAP_PASSWORD" {
				"\(k)": "\(v)"
			}
		}
		IMAP_USERNAME: #config.cron.environment.IMAP_USERNAME
		IMAP_PASSWORD: #config.cron.environment.IMAP_PASSWORD
	}
}
