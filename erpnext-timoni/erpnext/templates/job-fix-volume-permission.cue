package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#FixVolumeJob: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		if #config.jobs.volumePermissions.jobName != _|_ {
			name: #config.jobs.volumePermissions.jobName
		}
		if #config.jobs.volumePermissions.jobName == _|_ {
			name: "\(#config.metadata.name)-vol-fix"
		}
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name": "\(#config.metadata.name)-vol-fix"
		}
	}
	spec: batchv1.#JobSpec & {
		backoffLimit: #config.jobs.volumePermissions.backoffLimit
		template: {
			metadata: {
				labels: {
					for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
						"\(k)": v
					}
					"app.kubernetes.io/name": "\(#config.metadata.name)-vol-fix"
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
						name:            "frappe-bench-ownership"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["/bin/sh", "-c"]
						args: ["chown -R \"1000:1000\" /home/frappe/frappe-bench"]
						securityContext: {
							runAsNonRoot: false
							runAsUser:    0
						}
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
				if #config.jobs.volumePermissions.nodeSelector != _|_ {
					nodeSelector: #config.jobs.volumePermissions.nodeSelector
				}
				if #config.jobs.volumePermissions.affinity != _|_ {
					affinity: #config.jobs.volumePermissions.affinity
				}
				if #config.jobs.volumePermissions.tolerations != _|_ {
					tolerations: #config.jobs.volumePermissions.tolerations
				}
			}
		}
	}
}
