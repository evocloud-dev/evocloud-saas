package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#MigrationJob: batchv1.#Job & {
	#config:    #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      #config.metadata.name + "-migration-v1-to-v2"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
		annotations: "helm.sh/hook": "pre-install, pre-upgrade"
	}
	spec: batchv1.#JobSpec & {
		template: spec: corev1.#PodSpec & {
			containers: [
				{
					name:            "migrate-v1-to-v2"
					image:           #config.#imageRef
					imagePullPolicy: #config.image.pullPolicy
					command: [
						"/bin/sh",
						"-c",
						"npx @umami/migrate-v1-v2@latest",
					]
					env: [
						{
							name: "DATABASE_URL"
							valueFrom: secretKeyRef: {
								name: #config.metadata.name + "-db"
								key:  "database-url"
							}
						},
					]
				},
			]
			restartPolicy: "OnFailure"
		}
	}
}
