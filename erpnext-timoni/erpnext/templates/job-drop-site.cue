package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#DropSiteJob: batchv1.#Job & {
	#config: #Config

	_force: *"" | string
	if #config.jobs.drop.force {
		_force: " --force"
	}

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		if #config.jobs.drop.jobName != _|_ {
			name: #config.jobs.drop.jobName
		}
		if #config.jobs.drop.jobName == _|_ {
			name: "\(#config.metadata.name)-drop"
		}
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name": "\(#config.metadata.name)-drop"
		}
	}
	spec: batchv1.#JobSpec & {
		backoffLimit: #config.jobs.drop.backoffLimit
		template: {
			metadata: {
				labels: {
					for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
						"\(k)": v
					}
					"app.kubernetes.io/name": "\(#config.metadata.name)-drop"
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
						name:            "drop"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["bash", "-c"]
						args: ["bench drop-site $(SITE_NAME) \(_force)"]
						env: [
							{
								name:  "SITE_NAME"
								value: #config.jobs.drop.siteName
							},
						]
						resources:       #config.jobs.drop.resources
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
				if #config.jobs.drop.nodeSelector != _|_ {
					nodeSelector: #config.jobs.drop.nodeSelector
				}
				if #config.jobs.drop.affinity != _|_ {
					affinity: #config.jobs.drop.affinity
				}
				if #config.jobs.drop.tolerations != _|_ {
					tolerations: #config.jobs.drop.tolerations
				}
			}
		}
	}
}
