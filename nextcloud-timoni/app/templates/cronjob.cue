package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#CronJob: batchv1.#CronJob & {
	#in: #Config
	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		for k, v in #in.metadata if k != "name" {
			"\(k)": v
		}
		name:      "\(#in.metadata.name)-cron"
	}
	spec: {
		schedule: #in.cronjob.schedule
		concurrencyPolicy: batchv1.#ConcurrencyPolicy & #in.cronjob.concurrencyPolicy
		successfulJobsHistoryLimit: #in.cronjob.successfulJobsHistoryLimit
		failedJobsHistoryLimit:     #in.cronjob.failedJobsHistoryLimit
 
		jobTemplate: {
			metadata: {
				for k, v in #in.metadata if k != "name" {
					"\(k)": v
				}
				labels: #in.metadata.labels
			}
			spec: {
				backoffLimit: #in.cronjob.backoffLimit
				template: {
					metadata: {
						labels: #in.metadata.labels
						if #in.podAnnotations != _|_ {
							annotations: #in.podAnnotations
						}
					}
					spec: {
						restartPolicy: corev1.#RestartPolicyNever
 						
						if #in.imagePullSecrets != _|_ {
							imagePullSecrets: #in.imagePullSecrets
						}
 
						containers: [
							{
								name:            "\(#in.metadata.name)-cron"
								image:           #in.image.reference
								imagePullPolicy: #in.image.pullPolicy
								command: ["/cron.sh"]
 								
								// Reuse the exact same environment variables as the main container
								_in: #in
								env: (#NextcloudEnv & {#in: _in}).out

								resources: #in.resources

								// Volume Mounts mirroring the main container
								volumeMounts: (#NextcloudVolumeMounts & {#in: _in}).out

								// Security context matches main container logic
								securityContext: corev1.#SecurityContext & {
									if #in.nginx.enabled {
										runAsUser: 82
									}
									if !#in.nginx.enabled {
										runAsUser: 33
									}
								}
							}
						]

						_in: #in
						// Reuse the exact same volumes as the main container
						volumes: (#NextcloudVolumes & {#in: _in}).out

						if #in.rbac.enabled {
							serviceAccountName: #in.rbac.serviceAccount.name
						}

						// Scheduling
						if #in.nodeSelector != _|_ {
							nodeSelector: #in.nodeSelector
						}
						if #in.priorityClassName != "" {
							priorityClassName: #in.priorityClassName
						}
						if #in.affinity != _|_ {
							affinity: #in.affinity
						}
						if #in.tolerations != _|_ {
							tolerations: #in.tolerations
						}
						if #in.topologySpreadConstraints != _|_ {
							topologySpreadConstraints: #in.topologySpreadConstraints
						}
						if #in.dnsConfig != _|_ {
							dnsConfig: #in.dnsConfig
						}
						
						// Pod security context
						securityContext: corev1.#PodSecurityContext & {
							if #in.podSecurityContext != _|_ {
								#in.podSecurityContext
							}
							if #in.podSecurityContext == _|_ {
								if #in.nginx.enabled {
									fsGroup: 82
								}
								if !#in.nginx.enabled {
									fsGroup: 33
								}
							}
						}
					}
				}
			}
		}
	}
}
