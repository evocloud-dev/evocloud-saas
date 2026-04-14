package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#WorkerDeployment: appsv1.#Deployment & {
	#config:     #Config
	#workerName: string
	#worker:     #config.workers[#workerName]

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-worker-\(#workerName)"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & #worker.labels & {
			"openproject/process":        "worker-\(#workerName)"
			"app.kubernetes.io/component": "worker-\(#workerName)"
		}
		if #worker.annotations != _|_ {
			annotations: #worker.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #worker.replicaCount
		strategy: type: #worker.strategy.type
		selector: matchLabels: {
			#config.selector.labels
			"openproject/process":     "worker-\(#workerName)"
			"openproject/worker-name": #workerName
		}
		template: {
			metadata: {
				annotations: {
					if #config.podAnnotations != _|_ {
						#config.podAnnotations
					}
					"checksum/env-core":        "parity-checksum"
					"checksum/env-memcached":   "parity-checksum"
					"checksum/env-oidc":        "parity-checksum"
					"checksum/env-s3":          "parity-checksum"
					"checksum/env-environment": "parity-checksum"
				}
				labels: #config.metadata.labels & {
					"openproject/process":        "worker-\(#workerName)"
					"app.kubernetes.io/component": "worker-\(#workerName)"
					"openproject/worker-name":    #workerName
				}
			}
			spec: corev1.#PodSpec & {
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #worker.nodeSelector != _|_ {
					nodeSelector: #worker.nodeSelector
				}
				if #worker.nodeSelector == _|_ && #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
				if #worker.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #worker.topologySpreadConstraints
				}
				if #worker.topologySpreadConstraints == _|_ && #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.podSecurityContext.enabled {
					securityContext: {
						fsGroup: #config.podSecurityContext.fsGroup
					}
				}
				if #config.runtimeClassName != "" {
					runtimeClassName: #config.runtimeClassName
				}
				serviceAccountName: #config.metadata.name
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
					if #config.egress.tls.rootCA.fileName != "" {
						{
							name: "ca-pemstore"
							configMap: name: #config.egress.tls.rootCA.configMap
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
						name: "wait-for-db"
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
						image:           #config.image.reference
						imagePullPolicy: #config.image.imagePullPolicy
						envFrom: [
							{secretRef: name: "\(#config.metadata.name)-core"},
							if #config.openproject.environment != _|_ {
								{secretRef: name: "\(#config.metadata.name)-environment"}
							},
						]
						env: [
							if #config.postgresql.auth.password != "" {
								{name: "OPENPROJECT_DB_PASSWORD", value: #config.postgresql.auth.password}
							},
						]
						args: [
							"bash",
							"/app/docker/prod/wait-for-db",
						]
						if #config.appInit.resources != _|_ || #config.appInit.resourcesPreset != "none" {
							resources: {
								if #config.appInit.resources != _|_ {
									#config.appInit.resources
								}
							}
						}
						volumeMounts: [
							if #config.openproject.useTmpVolumes {
								{name: "tmp", mountPath: "/tmp"}
							},
							if #config.openproject.useTmpVolumes {
								{name: "app-tmp", mountPath: "/app/tmp"}
							},
						]
					},
				]
				containers: [
					{
						name: "openproject"
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
						image:           #config.image.reference
						imagePullPolicy: #config.image.imagePullPolicy
						envFrom: [
							{secretRef: name: "\(#config.metadata.name)-core"},
							if #config.openproject.environment != _|_ {
								{secretRef: name: "\(#config.metadata.name)-environment"}
							},
						]
						args: [
							"bash",
							"/app/docker/prod/worker",
						]
						env: [
							{name: "OPENPROJECT_GOOD_JOB_QUEUES", value: #worker.queues},
							if #worker.maxThreads != _|_ {
								{name: "OPENPROJECT_GOOD_JOB_MAX_THREADS", value: "\(#worker.maxThreads)"}
								{name: "RAILS_MAX_THREADS", value:               "\(#worker.maxThreads + 3)"}
							},
							if #config.postgresql.auth.password != "" {
								{name: "OPENPROJECT_DB_PASSWORD", value: #config.postgresql.auth.password}
							},
						]
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
							if #config.egress.tls.rootCA.fileName != "" {
								{
									name:      "ca-pemstore"
									mountPath: "/etc/ssl/certs/custom-ca.pem"
									subPath:   #config.egress.tls.rootCA.fileName
									readOnly:  false
								}
							},
							for vm in #config.openproject.extraVolumeMounts {
								vm
							},
						]
						if #worker.resources != _|_ || #config.resources != _|_ {
							resources: {
								if #worker.resources != _|_ {
									#worker.resources
								}
								if #worker.resources == _|_ && #config.resources != _|_ {
									#config.resources
								}
							}
						}
					},
				]
			}
		}
	}
}
