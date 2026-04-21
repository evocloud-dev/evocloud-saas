package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#TestJob: corev1.#Pod & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Pod"
	metadata: {
		namespace: #config.#namespace
		name: "\(#config.metadata.name)-test-connection"
		labels: #config.metadata.labels
		annotations: "helm.sh/hook": "test-success"
	}
	spec: corev1.#PodSpec & {
		containers: [{
			name:  "wget"
			image: "busybox"
			command: ["wget"]
			args: ["\(#config.metadata.name)-web:8080"]
		}]
		restartPolicy: "Never"
	}
}
