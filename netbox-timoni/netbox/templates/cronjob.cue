package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#CronJob: batchv1.#CronJob & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "\(#config._fullname)-housekeeping"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "housekeeping"
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	spec: batchv1.#CronJobSpec & {
		concurrencyPolicy:          #config.housekeeping.concurrencyPolicy
		failedJobsHistoryLimit:     #config.housekeeping.failedJobsHistoryLimit
		schedule:                   #config.housekeeping.schedule
		successfulJobsHistoryLimit: #config.housekeeping.successfulJobsHistoryLimit
		suspend:                    #config.housekeeping.suspend
		if #config.housekeeping.timezone != "" {
			timeZone: #config.housekeeping.timezone
		}
		jobTemplate: spec: {
			template: {
				metadata: {
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "housekeeping"
					}
					if #config.housekeeping.podLabels != _|_ {
						labels: #config.housekeeping.podLabels
					}
					if #config.housekeeping.podAnnotations != _|_ {
						annotations: #config.housekeeping.podAnnotations
					}
				}
				spec: corev1.#PodSpec & {
					if #config.image.pullSecrets != _|_ {
						imagePullSecrets: [ for s in #config.image.pullSecrets {name: s}]
					}
					serviceAccountName: {
						if #config.serviceAccount.create {
							if #config.serviceAccount.name != "" {
								#config.serviceAccount.name
							}
							if #config.serviceAccount.name == "" {
								#config._fullname
							}
						}
						if !#config.serviceAccount.create {
							if #config.serviceAccount.name != "" {
								#config.serviceAccount.name
							}
							if #config.serviceAccount.name == "" {
								"default"
							}
						}
					}
					if #config.housekeeping.podSecurityContext.enabled {
						securityContext: {
							fsGroup:             #config.housekeeping.podSecurityContext.fsGroup
							fsGroupChangePolicy: #config.housekeeping.podSecurityContext.fsGroupChangePolicy
							if #config.housekeeping.podSecurityContext.sysctls != _|_ {
								sysctls: #config.housekeeping.podSecurityContext.sysctls
							}
							if #config.housekeeping.podSecurityContext.supplementalGroups != _|_ {
								supplementalGroups: #config.housekeeping.podSecurityContext.supplementalGroups
							}
						}
					}
					if #config.housekeeping.affinity != _|_ {
						affinity: #config.housekeeping.affinity
					}
					if #config.housekeeping.nodeSelector != _|_ {
						nodeSelector: #config.housekeeping.nodeSelector
					}
					if #config.housekeeping.tolerations != _|_ {
						tolerations: #config.housekeeping.tolerations
					}
					if #config.hostAliases != _|_ {
						hostAliases: #config.hostAliases
					}
					if #config.housekeeping.automountServiceAccountToken != _|_ {
						automountServiceAccountToken: #config.housekeeping.automountServiceAccountToken
					}

					if #config.housekeeping.initContainers != _|_ {
						initContainers: #config.housekeeping.initContainers
					}

					containers: [
						{
							name: "netbox-housekeeping"
							image: {
								#registry: {
									if #config.global.imageRegistry != "" { #config.global.imageRegistry }
									if #config.global.imageRegistry == "" { #config.image.registry }
								}
								#tag: {
									if #config.image.tag != "" { #config.image.tag }
									if #config.image.tag == "" { #config.moduleVersion }
								}
								if #config.image.digest != "" { "\(#registry)/\(#config.image.repository)@\(#config.image.digest)" }
								if #config.image.digest == "" { "\(#registry)/\(#config.image.repository):\(#tag)" }
							}
							imagePullPolicy: #config.image.pullPolicy
							command:         #config.housekeeping.command
							if #config.housekeeping.args != _|_ {
								args: #config.housekeeping.args
							}
							if #config.housekeeping.securityContext.enabled {
								securityContext: {
									runAsUser:                #config.housekeeping.securityContext.runAsUser
									runAsGroup:               #config.housekeeping.securityContext.runAsGroup
									runAsNonRoot:             #config.housekeeping.securityContext.runAsNonRoot
									readOnlyRootFilesystem:   #config.housekeeping.securityContext.readOnlyRootFilesystem
									allowPrivilegeEscalation: #config.housekeeping.securityContext.allowPrivilegeEscalation
									privileged:               #config.housekeeping.securityContext.privileged
									if #config.housekeeping.securityContext.capabilities != _|_ {
										capabilities: #config.housekeeping.securityContext.capabilities
									}
									if #config.housekeeping.securityContext.seccompProfile != _|_ {
										seccompProfile: #config.housekeeping.securityContext.seccompProfile
									}
									if #config.housekeeping.securityContext.seLinuxOptions != _|_ {
										seLinuxOptions: #config.housekeeping.securityContext.seLinuxOptions
									}
								}
							}
							if #config.housekeeping.resources != _|_ {
								resources: #config.housekeeping.resources
							}
							volumeMounts: [
								{
									name:      "config"
									mountPath: "/etc/netbox/config/configuration.py"
									subPath:   "configuration.py"
									readOnly:  true
								},
								if #config.remoteAuth.enabled && #config.remoteAuth.ldap.serverUri != "" {
									{
										name:      "config"
										mountPath: "/etc/netbox/config/ldap/ldap_config.py"
										subPath:   "ldap_config.py"
										readOnly:  true
									}
								},
								if #config.remoteAuth.enabled && #config.remoteAuth.ldap.caCertData != "" {
									{
										name:      "config"
										mountPath: "/etc/netbox/config/ldap/ldap_ca.crt"
										subPath:   "ldap_ca.crt"
										readOnly:  true
									}
								},
								{
									name:      "config"
									mountPath: "/run/config/netbox"
									readOnly:  true
								},
								{
									name:      "secrets"
									mountPath: "/run/secrets/netbox"
									readOnly:  true
								},
								for vm in #config.housekeeping.extraVolumeMounts {
									vm
								},
								{
									name:      "netbox-tmp"
									mountPath: "/tmp"
								},
								if #config.persistence.enabled {
									{
										name:      "media"
										mountPath: "/opt/netbox/netbox/media"
										readOnly:  #config.housekeeping.readOnlyPersistence
										if #config.persistence.subPath != "" {
											subPath: #config.persistence.subPath
										}
									}
								},
								if #config.reportsPersistence.enabled {
									{
										name:      "reports"
										mountPath: "/opt/netbox/netbox/reports"
										readOnly:  #config.housekeeping.readOnlyPersistence
										if #config.reportsPersistence.subPath != "" {
											subPath: #config.reportsPersistence.subPath
										}
									}
								},
								if #config.scriptsPersistence.enabled {
									{
										name:      "scripts"
										mountPath: "/opt/netbox/netbox/scripts"
										readOnly:  #config.housekeeping.readOnlyPersistence
										if #config.scriptsPersistence.subPath != "" {
											subPath: #config.scriptsPersistence.subPath
										}
									}
								},
							]
							if #config.housekeeping.extraEnvs != _|_ {
								env: #config.housekeeping.extraEnvs
							}
							if #config.housekeeping.extraEnvVarsCM != "" || #config.housekeeping.extraEnvVarsSecret != "" {
								envFrom: [
									if #config.housekeeping.extraEnvVarsCM != "" {
										configMapRef: name: #config.housekeeping.extraEnvVarsCM
									},
									if #config.housekeeping.extraEnvVarsSecret != "" {
										secretRef: name: #config.housekeeping.extraEnvVarsSecret
									},
								]
							}
						},
						for s in #config.housekeeping.sidecars {
							s
						},
					]
					volumes: [
						{
							name: "config"
							configMap: name: #config._fullname
						},
						{
							name: "secrets"
							projected: sources: [
								{
									secret: {
										name: #config._configSecretName
										items: [
											{
												key:  "secret_key"
												path: "secret_key"
											},
											if #config.remoteAuth.enabled && #config.remoteAuth.ldap.serverUri != "" {
												{
													key:  "ldap_bind_password"
													path: "ldap_bind_password"
												}
											},
										]
									}
								},
								{
									secret: {
										name: {
											if #config.email.existingSecretName != "" { #config.email.existingSecretName }
											if #config.email.existingSecretName == "" { #config._configSecretName }
										}
										items: [{
											key:  #config.email.existingSecretKey
											path: "email_password"
										}]
									}
								},
								{
									secret: {
										name: {
											if #config.postgresql.enabled {
												"\(#config._fullname)-postgresql"
											}
											if !#config.postgresql.enabled {
												#config.externalDatabase.existingSecretName
											}
										}
										items: [{
											key: {
												if #config.postgresql.enabled { "postgres-password" }
												if !#config.postgresql.enabled { #config.externalDatabase.existingSecretKey }
											}
											path: "db_password"
										}]
									}
								},
								{
									secret: {
										name: {
											if #config.tasksDatabase.existingSecretName != "" { #config.tasksDatabase.existingSecretName }
											if #config.tasksDatabase.existingSecretName == "" { #config._configSecretName }
										}
										items: [{
											key:  #config.tasksDatabase.existingSecretKey
											path: "tasks_password"
										}]
									}
								},
								{
									secret: {
										name: {
											if #config.cachingDatabase.existingSecretName != "" { #config.cachingDatabase.existingSecretName }
											if #config.cachingDatabase.existingSecretName == "" { #config._configSecretName }
										}
										items: [{
											key:  #config.cachingDatabase.existingSecretKey
											path: "cache_password"
										}]
									}
								},
							]
						},
						{
							name: "netbox-tmp"
							emptyDir: medium: "Memory"
						},
						{
							name: "media"
							if #config.persistence.enabled {
								persistentVolumeClaim: {
									claimName: {
										if #config.persistence.existingClaim != "" {
											#config.persistence.existingClaim
										}
										if #config.persistence.existingClaim == "" {
											"\(#config._fullname)-media"
										}
									}
									readOnly: #config.housekeeping.readOnlyPersistence
								}
							}
							if !#config.persistence.enabled {
								emptyDir: {}
							}
						},
						if #config.reportsPersistence.enabled {
							{
								name: "reports"
								persistentVolumeClaim: {
									claimName: {
										if #config.reportsPersistence.existingClaim != "" {
											#config.reportsPersistence.existingClaim
										}
										if #config.reportsPersistence.existingClaim == "" {
											"\(#config._fullname)-reports"
										}
									}
									readOnly: #config.housekeeping.readOnlyPersistence
								}
							}
						},
						if #config.scriptsPersistence.enabled {
							{
								name: "scripts"
								persistentVolumeClaim: {
									claimName: {
										if #config.scriptsPersistence.existingClaim != "" {
											#config.scriptsPersistence.existingClaim
										}
										if #config.scriptsPersistence.existingClaim == "" {
											"\(#config._fullname)-scripts"
										}
									}
									readOnly: #config.housekeeping.readOnlyPersistence
								}
							}
						},
						for v in #config.housekeeping.extraVolumes {
							v
						},
					]
					restartPolicy: #config.housekeeping.restartPolicy
				}
			}
		}
	}
}
