package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#RunnerSecret: corev1.#Secret & {
	#config:    #Config
	#group:     _
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      *"\((#config.metadata.name))-runner-\(#group.id)-secret" | string
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "runner"
			"peertube.runner/group":       #group.id
		}
	}
	type: "Opaque"
	stringData: {
		"runner-url":         "http://\((#config.metadata.name))-svc:\(#config.server.service.port)"
		"registration-token": #group.config.registrationToken
	}
}
