package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#MigrateSiteJob: batchv1.#Job & {
	#config: #Config

	_skipFailing: *"" | string
	if #config.jobs.migrate.skipFailing {
		_skipFailing: " --skip-failing"
	}

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		if #config.jobs.migrate.jobName != _|_ {
			name: #config.jobs.migrate.jobName
		}
		if #config.jobs.migrate.jobName == _|_ {
			name: "\(#config.metadata.name)-migrate"
		}
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name": "\(#config.metadata.name)-migrate"
		}
	}
	spec: batchv1.#JobSpec & {
		backoffLimit: #config.jobs.migrate.backoffLimit
		template: {
			metadata: {
				labels: {
					for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
						"\(k)": v
					}
					"app.kubernetes.io/name": "\(#config.metadata.name)-migrate"
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
						name:            "migrate"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["bash", "-c"]
						args: [
							"bench --site $(SITE_NAME) set-maintenance-mode on; bench --site $(SITE_NAME) migrate \(_skipFailing); bench --site $(SITE_NAME) set-maintenance-mode off;",
						]
						env: [
							{
								name:  "SITE_NAME"
								value: #config.jobs.migrate.siteName
							},
						]
						resources:       #config.jobs.migrate.resources
						securityContext: #config.securityContext
						volumeMounts: [
							{
								name:      "sites-dir"
								mountPath: "/home/frappe/frappe-bench/sites"
							},
							{
								name:      "logs"
								mountPath: "/home/frappe/frappe-bench/logs"
							},
						]
					},
				]
				volumes: [
					{
						name: "sites-dir"
						if #config.persistence.worker.enabled {
							persistentVolumeClaim: {
								if #config.persistence.worker.existingClaim != "" {
									claimName: #config.persistence.worker.existingClaim
								}
								if #config.persistence.worker.existingClaim == "" {
									claimName: #config.metadata.name
								}
								readOnly: false
							}
						}
						if !#config.persistence.worker.enabled {
							emptyDir: {}
						}
					},
					{
						name: "logs"
						if #config.persistence.logs.enabled {
							persistentVolumeClaim: {
								if #config.persistence.logs.existingClaim != "" {
									claimName: #config.persistence.logs.existingClaim
								}
								if #config.persistence.logs.existingClaim == "" {
									claimName: "\(#config.metadata.name)-logs"
								}
								readOnly: false
							}
						}
						if !#config.persistence.logs.enabled {
							emptyDir: {}
						}
					},
				]

				if #config.jobs.migrate.nodeSelector != _|_ {
					nodeSelector: #config.jobs.migrate.nodeSelector
				}
				if #config.jobs.migrate.affinity != _|_ {
					affinity: #config.jobs.migrate.affinity
				}
				if #config.jobs.migrate.tolerations != _|_ {
					tolerations: #config.jobs.migrate.tolerations
				}
			}
		}
	}
}
