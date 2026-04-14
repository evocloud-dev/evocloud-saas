package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#SeederJob: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.metadata.name)-seeder"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "seeder"
		}
		if #config.seederJob.annotations != _|_ {
			annotations: #config.seederJob.annotations
		}
	}
	spec: batchv1.#JobSpec & {
		if #config.cleanup.deletePodsOnSuccess {
			ttlSecondsAfterFinished: #config.cleanup.deletePodsOnSuccessTimeout
		}
		template: {
			metadata: {
				labels: #config.metadata.labels & {
					"openproject/process":        "seeder"
					"app.kubernetes.io/component": "seeder"
				}
				if #config.seederJob.annotations != _|_ {
					annotations: #config.seederJob.annotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: #config.metadata.name
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.podSecurityContext.enabled {
					securityContext: {
						fsGroup: #config.podSecurityContext.fsGroup
					}
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.seeder.nodeSelector != _|_ || #config.nodeSelector != _|_ {
					nodeSelector: {
						if #config.seeder.nodeSelector != _|_ {
							#config.seeder.nodeSelector
						}
						if #config.seeder.nodeSelector == _|_ && #config.nodeSelector != _|_ {
							#config.nodeSelector
						}
					}
				}
				volumes: [
					if #config.openproject.useTmpVolumes {
						{
							name: "tmp"
							ephemeral: volumeClaimTemplate: {
								spec: {
									accessModes: #config.persistence.accessModes
									if #config.openproject.tmpVolumesStorageClassName != "" {
										storageClassName: #config.openproject.tmpVolumesStorageClassName
									}
									if #config.openproject.tmpVolumesStorageClassName == "" && #config.persistence.storageClassName != "" {
										storageClassName: #config.persistence.storageClassName
									}
									resources: requests: storage: #config.openproject.tmpVolumesStorage
								}
							}
						}
					},
					if #config.openproject.useTmpVolumes {
						{
							name: "app-tmp"
							ephemeral: volumeClaimTemplate: {
								spec: {
									accessModes: #config.persistence.accessModes
									if #config.openproject.tmpVolumesStorageClassName != "" {
										storageClassName: #config.openproject.tmpVolumesStorageClassName
									}
									if #config.openproject.tmpVolumesStorageClassName == "" && #config.persistence.storageClassName != "" {
										storageClassName: #config.persistence.storageClassName
									}
									resources: requests: storage: #config.openproject.tmpVolumesStorage
								}
							}
						}
					},
					if #config.persistence.enabled {
						{
							name: "data"
							persistentVolumeClaim: {
								if #config.persistence.existingClaim != "" {
									claimName: #config.persistence.existingClaim
								}
								if #config.persistence.existingClaim == "" {
									claimName: #config.metadata.name
								}
							}
						}
					},
					for v in #config.openproject.extraVolumes {
						v
					},
				]
				initContainers: [
					{
						name:            "check-db-ready"
						image:           "\(#config.dbInit.image.registry)/\(#config.dbInit.image.repository):\(#config.dbInit.image.tag)"
						imagePullPolicy: #config.dbInit.image.imagePullPolicy
						command: [
							"sh",
							"-c",
							"until pg_isready -h $DATABASE_HOST -p $DATABASE_PORT -U \(#config.postgresql.auth.username); do echo \"waiting for database $DATABASE_HOST:$DATABASE_PORT\"; sleep 2; done;",
						]
						envFrom: [
							{secretRef: name: "\(#config.metadata.name)-core"},
						]
						env: [
							if #config.postgresql.auth.password != null {
								{name: "OPENPROJECT_DB_PASSWORD", value: #config.postgresql.auth.password}
							},
						]
						if #config.dbInit.resources != _|_ {
							resources: #config.dbInit.resources
						}
						volumeMounts: [
							if #config.openproject.useTmpVolumes {
								{name: "tmp", mountPath: "/tmp"}
							},
							if #config.openproject.useTmpVolumes {
								{name: "app-tmp", mountPath: "/app/tmp"}
							},
						]
						if #config.containerSecurityContext.enabled {
							securityContext: {
								runAsUser:                #config.containerSecurityContext.runAsUser
								runAsGroup:               #config.containerSecurityContext.runAsGroup
								allowPrivilegeEscalation: #config.containerSecurityContext.allowPrivilegeEscalation
								capabilities:             #config.containerSecurityContext.capabilities
								seccompProfile: type:   #config.containerSecurityContext.seccompProfile.type
								readOnlyRootFilesystem: ( !#config.develop && #config.containerSecurityContext.readOnlyRootFilesystem)
								runAsNonRoot:           #config.containerSecurityContext.runAsNonRoot
							}
						}
					},
				]
				containers: [
					{
						name:            "seeder"
						image:           #config.image.reference
						imagePullPolicy: #config.image.imagePullPolicy
						args: [
							"bash",
							"/app/docker/prod/seeder",
						]
						envFrom: [
							{secretRef: name: "\(#config.metadata.name)-core"},
							if #config.openproject.environment != _|_ {
								{secretRef: name: "\(#config.metadata.name)-environment"}
							},
						]
						env: [
							if #config.postgresql.auth.password != null {
								{name: "OPENPROJECT_DB_PASSWORD", value: #config.postgresql.auth.password}
							},
						]
						if #config.seederJob.resources != _|_ {
							resources: #config.seederJob.resources
						}
						volumeMounts: [
							if #config.openproject.useTmpVolumes {
								{name: "tmp", mountPath: "/tmp"}
							},
							if #config.openproject.useTmpVolumes {
								{name: "app-tmp", mountPath: "/app/tmp"}
							},
							if #config.persistence.enabled {
								{
									name:      "data"
									mountPath: "/var/openproject/assets"
								}
							},
							for vm in #config.openproject.extraVolumeMounts {
								vm
							},
						]
						if #config.containerSecurityContext.enabled {
							securityContext: {
								runAsUser:                #config.containerSecurityContext.runAsUser
								runAsGroup:               #config.containerSecurityContext.runAsGroup
								allowPrivilegeEscalation: #config.containerSecurityContext.allowPrivilegeEscalation
								capabilities:             #config.containerSecurityContext.capabilities
								seccompProfile: type:   #config.containerSecurityContext.seccompProfile.type
								readOnlyRootFilesystem: ( !#config.develop && #config.containerSecurityContext.readOnlyRootFilesystem)
								runAsNonRoot:           #config.containerSecurityContext.runAsNonRoot
							}
						}
					},
				]
				restartPolicy: "OnFailure"
			}
		}
	}
}
