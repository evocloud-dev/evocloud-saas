package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#DropMultipleSitesJob: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		if #config.jobs.dropMultiple.jobName != _|_ {
			name: #config.jobs.dropMultiple.jobName
		}
		if #config.jobs.dropMultiple.jobName == _|_ {
			name: "\(#config.metadata.name)-drop-multi"
		}
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name": "\(#config.metadata.name)-drop-multi"
		}
	}
	spec: batchv1.#JobSpec & {
		backoffLimit: #config.jobs.dropMultiple.backoffLimit
		template: {
			metadata: {
				labels: {
					for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
						"\(k)": v
					}
					"app.kubernetes.io/name": "\(#config.metadata.name)-drop-multi"
				}
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: #config.metadata.name
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				restartPolicy: "Never"
				containers: [
					{
						name:            "drop-multi"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["bash", "-c"]
						args: ["echo 'Drop multiple sites logic goes here'"]
						resources:       #config.jobs.dropMultiple.resources
						securityContext: #config.securityContext
						volumeMounts: [
							{
								name:      "sites-dir"
								mountPath: "/home/frappe/frappe-bench/sites"
							},
						]
					},
				]
				volumes: [
					{
						name: "sites-dir"
						emptyDir: {}
					},
				]
				if #config.jobs.dropMultiple.nodeSelector != _|_ {
					nodeSelector: #config.jobs.dropMultiple.nodeSelector
				}
				if #config.jobs.dropMultiple.affinity != _|_ {
					affinity: #config.jobs.dropMultiple.affinity
				}
				if #config.jobs.dropMultiple.tolerations != _|_ {
					tolerations: #config.jobs.dropMultiple.tolerations
				}
			}
		}
	}
}
