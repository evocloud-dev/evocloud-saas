package templates

import (
	"strings"
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#BackupMultipleSitesJob: batchv1.#Job & {
	#config: #Config

	_backup_cmd: [ if #config.jobs.backupMultiple.withFiles { "backup --with-files" }, "backup"][0]
	_scripts: [
		for site in #config.jobs.backupMultiple.sites {
			"bench --site=\(site) \(_backup_cmd)"
		},
	]
	_full_script: strings.Join(_scripts, "; ")

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		if #config.jobs.backupMultiple.jobName != _|_ {
			name: #config.jobs.backupMultiple.jobName
		}
		if #config.jobs.backupMultiple.jobName == _|_ {
			name: "\(#config.metadata.name)-backup-sites"
		}
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name": "\(#config.metadata.name)-backup-sites"
		}
	}
	spec: batchv1.#JobSpec & {
		backoffLimit: #config.jobs.backupMultiple.backoffLimit
		template: {
			metadata: {
				labels: {
					for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
						"\(k)": v
					}
					"app.kubernetes.io/name": "\(#config.metadata.name)-backup-sites"
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
						name:            "backup-sites"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["bash", "-c"]
						args: [_full_script]
						resources:       #config.jobs.backupMultiple.resources
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
				if #config.jobs.backupMultiple.nodeSelector != _|_ {
					nodeSelector: #config.jobs.backupMultiple.nodeSelector
				}
				if #config.jobs.backupMultiple.affinity != _|_ {
					affinity: #config.jobs.backupMultiple.affinity
				}
				if #config.jobs.backupMultiple.tolerations != _|_ {
					tolerations: #config.jobs.backupMultiple.tolerations
				}
			}
		}
	}
}
