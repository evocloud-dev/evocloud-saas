package templates

import (
	"list"
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#CustomJob: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		if #config.jobs.custom.jobName != _|_ {
			name: #config.jobs.custom.jobName
		}
		if #config.jobs.custom.jobName == _|_ {
			name: "\(#config.metadata.name)-custom"
		}
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name": "\(#config.metadata.name)-custom"
		}
	}
	spec: batchv1.#JobSpec & {
		backoffLimit: #config.jobs.custom.backoffLimit
		template: {
			metadata: {
				labels: {
					for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
						"\(k)": v
					}
					"app.kubernetes.io/name": "\(#config.metadata.name)-custom"
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
						name:            "custom"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						if #config.jobs.custom.command != _|_ {
							command: #config.jobs.custom.command
						}
						if #config.jobs.custom.command == _|_ {
							command: ["bash", "-c"]
						}
						if #config.jobs.custom.args != _|_ {
							args: #config.jobs.custom.args
						}
						env: list.Concat([
							[
								{
									name:  "DB_HOST"
									value: #config._dbHost
								},
								{
									name:  "DB_PORT"
									value: "\(#config._dbPort)"
								},
								{
									name:  "REDIS_CACHE"
									value: #config.externalRedis.cache
								},
								{
									name:  "REDIS_QUEUE"
									value: #config.externalRedis.queue
								},
							],
							#config.jobs.custom.envVars,
						])
						resources:       #config.jobs.custom.resources
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
				if #config.jobs.custom.nodeSelector != _|_ {
					nodeSelector: #config.jobs.custom.nodeSelector
				}
				if #config.jobs.custom.affinity != _|_ {
					affinity: #config.jobs.custom.affinity
				}
				if #config.jobs.custom.tolerations != _|_ {
					tolerations: #config.jobs.custom.tolerations
				}
			}
		}
	}
}
