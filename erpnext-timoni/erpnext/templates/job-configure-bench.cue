package templates

import (
	"list"
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#ConfigureBenchJob: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		if #config.jobs.configure.jobName != _|_ {
			name: #config.jobs.configure.jobName
		}
		if #config.jobs.configure.jobName == _|_ {
			name: "\(#config.metadata.name)-conf-bench"
		}
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name": "\(#config.metadata.name)-conf-bench"
		}
	}
	spec: batchv1.#JobSpec & {
		backoffLimit: #config.jobs.configure.backoffLimit
		template: {
			metadata: {
				labels: {
					for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
						"\(k)": v
					}
					"app.kubernetes.io/name": "\(#config.metadata.name)-conf-bench"
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
				if #config.jobs.configure.fixVolume {
					initContainers: [
						{
							name:            "frappe-bench-ownership"
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
							command: ["sh", "-c"]
							args: ["chown -R \"1000:1000\" /home/frappe/frappe-bench/sites /home/frappe/frappe-bench/logs"]
							securityContext: runAsUser: 0
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
				}
				containers: [
					{
						name:            "configure"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						if #config.jobs.configure.command != _|_ {
							command: #config.jobs.configure.command
						}
						if #config.jobs.configure.command == _|_ {
							command: ["bash", "-c"]
						}
						if #config.jobs.configure.args != _|_ {
							args: #config.jobs.configure.args
						}
						if #config.jobs.configure.args == _|_ {
							args: [
								"""
								ls -1 apps > sites/apps.txt;
								[[ -f sites/common_site_config.json ]] || echo \"{}\" > sites/common_site_config.json;
								bench set-config -gp db_port $DB_PORT;
								bench set-config -g db_host $DB_HOST;
								bench set-config -g redis_cache $REDIS_CACHE;
								bench set-config -g redis_queue $REDIS_QUEUE;
								bench set-config -g redis_socketio $REDIS_QUEUE;
								bench set-config -gp socketio_port $SOCKETIO_PORT;
								""",
							]
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
									value: #config._redisCache
								},
								{
									name:  "REDIS_QUEUE"
									value: #config._redisQueue
								},
								{
									name:  "SOCKETIO_PORT"
									value: "\(#config.socketio.service.port)"
								},
							],
							#config.jobs.configure.envVars,
						])
						resources:       #config.jobs.configure.resources
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
						workingDir: "/home/frappe/frappe-bench"
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

				if #config.jobs.configure.nodeSelector != _|_ {
					nodeSelector: #config.jobs.configure.nodeSelector
				}
				if #config.jobs.configure.affinity != _|_ {
					affinity: #config.jobs.configure.affinity
				}
				if #config.jobs.configure.tolerations != _|_ {
					tolerations: #config.jobs.configure.tolerations
				}
			}
		}
	}
}
