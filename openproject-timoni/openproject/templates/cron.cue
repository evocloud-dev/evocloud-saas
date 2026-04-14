package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#CronDeployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-cron"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"openproject/process":        "cron"
			"app.kubernetes.io/component": "cron"
		}
		if #config.cron.annotations != _|_ {
			annotations: #config.cron.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		strategy: type: "Recreate"
		selector: matchLabels: {
			#config.selector.labels
			"openproject/process": "cron"
		}
		template: {
			metadata: {
				labels: {
					#config.selector.labels
					"openproject/process":        "cron"
					"app.kubernetes.io/component": "cron"
				}
				if #config.cron.annotations != _|_ {
					annotations: #config.cron.annotations
				}
			}
			spec: corev1.#PodSpec & {
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: [
						for s in #config.imagePullSecrets {
							name: s
						},
					]
				}
				serviceAccountName: #config.metadata.name
				if #config.podSecurityContext.enabled {
					securityContext: fsGroup: #config.podSecurityContext.fsGroup
				}
				affinity:     #config.affinity
				tolerations:  #config.tolerations
				nodeSelector: #config.cron.nodeSelector
				initContainers: [
					{
						name:            "wait-for-db"
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
						args: ["/app/docker/prod/wait-for-db"]
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
						name:            "openproject"
						image:           #config.image.reference
						imagePullPolicy: #config.image.imagePullPolicy
						args: [
							"bash",
							"/app/docker/prod/cron",
						]
						envFrom: [
							{secretRef: name: "\(#config.metadata.name)-core"},
							if len(#config.environment) > 0 {
								{secretRef: name: "\(#config.metadata.name)-environment"}
							},
							if len(#config.cron.environment) > 0 {
								{secretRef: name: "\(#config.metadata.name)-cron-environment"}
							},
						]
						resources: #config.cron.resources
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
						]
						if #config.containerSecurityContext.enabled {
							securityContext: {
								runAsUser:                #config.containerSecurityContext.runAsUser
								runAsGroup:               #config.containerSecurityContext.runAsGroup
								allowPrivilegeEscalation: #config.containerSecurityContext.allowPrivilegeEscalation
								capabilities:             #config.containerSecurityContext.capabilities
								seccompProfile: type:   #config.containerSecurityContext.seccompProfile.type
								readOnlyRootFilesystem: #config.containerSecurityContext.readOnlyRootFilesystem
								runAsNonRoot:           #config.containerSecurityContext.runAsNonRoot
							}
						}
					},
				]
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
					if #config.egress.tls.rootCA.fileName != "" {
						{
							name: "ca-pemstore"
							configMap: name: #config.egress.tls.rootCA.configMap
						}
					},
					for v in #config.openproject.extraVolumes {
						v
					},
				]
			}
		}
	}
}
