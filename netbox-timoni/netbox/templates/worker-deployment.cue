package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#WorkerDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config._fullname)-worker"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "worker"
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.worker.autoscaling.enabled {
			replicas: #config.worker.replicaCount
		}
		revisionHistoryLimit: #config.revisionHistoryLimit
		selector: matchLabels: #config.worker.podLabels & {
			"app.kubernetes.io/component": "worker"
		}
		if #config.worker.updateStrategy != _|_ {
			strategy: #config.worker.updateStrategy
		}
		template: {
			metadata: {
				labels: #config.worker.podLabels & {
					"app.kubernetes.io/component": "worker"
				}
				annotations: {
					if #config.worker.podAnnotations != _|_ {
						for k, v in #config.worker.podAnnotations {
							"\(k)": v
						}
					}
					"checksum/config": "placeholder"
					if #config.existingSecret == "" {
						"checksum/secret": "placeholder"
					}
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
				automountServiceAccountToken: #config.worker.automountServiceAccountToken
				if #config.worker.podSecurityContext.enabled {
					securityContext: {
						fsGroup:             #config.worker.podSecurityContext.fsGroup
						fsGroupChangePolicy: #config.worker.podSecurityContext.fsGroupChangePolicy
						if #config.worker.podSecurityContext.supplementalGroups != _|_ {
							supplementalGroups: #config.worker.podSecurityContext.supplementalGroups
						}
						if #config.worker.podSecurityContext.sysctls != _|_ {
							sysctls: #config.worker.podSecurityContext.sysctls
						}
					}
				}
				initContainers: [
					if #config.worker.waitForBackend.enabled {
						{
							name: "wait-for-backend"
							image: {
								#registry: #config.init.image.registry
								"\(#registry)/\(#config.worker.waitForBackend.image.repository):\(#config.worker.waitForBackend.image.tag)"
							}
							imagePullPolicy: #config.worker.waitForBackend.image.pullPolicy
							if #config.worker.waitForBackend.command != [] {
								command: #config.worker.waitForBackend.command
							}
							if #config.worker.waitForBackend.args != [] {
								args: #config.worker.waitForBackend.args
							}
							if #config.worker.waitForBackend.containerSecurityContext.enabled {
								securityContext: {
									runAsUser:                #config.worker.waitForBackend.containerSecurityContext.runAsUser
									runAsGroup:               #config.worker.waitForBackend.containerSecurityContext.runAsGroup
									runAsNonRoot:             #config.worker.waitForBackend.containerSecurityContext.runAsNonRoot
									readOnlyRootFilesystem:   #config.worker.waitForBackend.containerSecurityContext.readOnlyRootFilesystem
									allowPrivilegeEscalation: #config.worker.waitForBackend.containerSecurityContext.allowPrivilegeEscalation
									if #config.worker.waitForBackend.containerSecurityContext.capabilities != _|_ {
										capabilities: #config.worker.waitForBackend.containerSecurityContext.capabilities
									}
									if #config.worker.waitForBackend.containerSecurityContext.seccompProfile != _|_ {
										seccompProfile: #config.worker.waitForBackend.containerSecurityContext.seccompProfile
									}
									if #config.worker.waitForBackend.containerSecurityContext.seLinuxOptions != _|_ {
										seLinuxOptions: #config.worker.waitForBackend.containerSecurityContext.seLinuxOptions
									}
								}
							}
							resources: #config.worker.waitForBackend.resources
							env: [
								{
									name:  "DEPLOYMENT_NAME"
									value: #config._fullname
								},
							]
						}
					},
					for ic in #config.worker.initContainers {ic},
				]
				containers: [
					{
						name: "netbox-worker"
						if #config.worker.securityContext.enabled {
							securityContext: {
								runAsUser:                #config.worker.securityContext.runAsUser
								runAsGroup:               #config.worker.securityContext.runAsGroup
								runAsNonRoot:             #config.worker.securityContext.runAsNonRoot
								readOnlyRootFilesystem:   #config.worker.securityContext.readOnlyRootFilesystem
								allowPrivilegeEscalation: #config.worker.securityContext.allowPrivilegeEscalation
								privileged:               #config.worker.securityContext.privileged
								if #config.worker.securityContext.capabilities != _|_ {
									capabilities: #config.worker.securityContext.capabilities
								}
								if #config.worker.securityContext.seccompProfile != _|_ {
									seccompProfile: #config.worker.securityContext.seccompProfile
								}
								if #config.worker.securityContext.seLinuxOptions != _|_ {
									seLinuxOptions: #config.worker.securityContext.seLinuxOptions
								}
							}
						}
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
						if #config.worker.command != [] {
							command: #config.worker.command
						}
						if #config.worker.args != [] {
							args: #config.worker.args
						}
						if len(#config.worker.extraEnvs) > 0 {
							env: #config.worker.extraEnvs
						}
						if #config.worker.extraEnvVarsCM != "" || #config.worker.extraEnvVarsSecret != "" {
							envFrom: [
								if #config.worker.extraEnvVarsCM != "" {
									{configMapRef: name: #config.worker.extraEnvVarsCM}
								},
								if #config.worker.extraEnvVarsSecret != "" {
									{secretRef: name: #config.worker.extraEnvVarsSecret}
								},
							]
						}
						volumeMounts: [
							{
								name:      "config"
								mountPath: "/etc/netbox/config/configuration.py"
								subPath:   "configuration.py"
								readOnly:  true
							},
							if [ for b in #config.remoteAuth.backends if b == "netbox.authentication.LDAPBackend" {b}] != [] {
								{
									name:      "config"
									mountPath: "/etc/netbox/config/ldap/ldap_config.py"
									subPath:   "ldap_config.py"
									readOnly:  true
								}
							},
							if [ for b in #config.remoteAuth.backends if b == "netbox.authentication.LDAPBackend" {b}] != [] && #config.remoteAuth.ldap.caCertData != "" {
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
							{
								name:      "netbox-tmp"
								mountPath: "/tmp"
							},
							{
								name:      "media"
								mountPath: "/opt/netbox/netbox/media"
								if #config.persistence.subPath != "" {
									subPath: #config.persistence.subPath
								}
								readOnly: #config.worker.readOnlyPersistence
							},
							if #config.reportsPersistence.enabled {
								{
									name:      "reports"
									mountPath: "/opt/netbox/netbox/reports"
									if #config.reportsPersistence.subPath != "" {
										subPath: #config.reportsPersistence.subPath
									}
									readOnly: #config.worker.readOnlyPersistence
								}
							},
							if #config.scriptsPersistence.enabled {
								{
									name:      "scripts"
									mountPath: "/opt/netbox/netbox/scripts"
									if #config.scriptsPersistence.subPath != "" {
										subPath: #config.scriptsPersistence.subPath
									}
									readOnly: #config.worker.readOnlyPersistence
								}
							},
							for vm in #config.worker.extraVolumeMounts {vm},
							for vm in #config._extraVolumeMounts {vm},
						]
						resources: #config.worker.resources
					},
					for sc in #config.worker.sidecars {sc},
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
										if [ for b in #config.remoteAuth.backends if b == "netbox.authentication.LDAPBackend" {b}] != [] {
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
									#secretName: {
										if #config.existingSecret != "" { #config.existingSecret }
										if #config.existingSecret == "" {
											if #config.email.existingSecretName != "" { #config.email.existingSecretName }
											if #config.email.existingSecretName == "" { #config._configSecretName }
										}
									}
									name: #secretName
									items: [{
										key:  #config.email.existingSecretKey
										path: "email_password"
									}]
								}
							},
							{
								secret: {
									name: #config._superuserSecretName
									items: [
										{key: "password", path:  "superuser_password"},
										{key: "api_token", path: "superuser_api_token"},
									]
								}
							},
							{
								secret: {
									#dbSecret: {
										if #config.postgresql.enabled {
											"\(#config._fullname)-postgresql"
										}
										if !#config.postgresql.enabled {
											if #config.externalDatabase.existingSecretName != "" { #config.externalDatabase.existingSecretName }
											if #config.externalDatabase.existingSecretName == "" { "#config._fullname-postgresql" }
										}
									}
									name: #dbSecret
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
									#tasksSecretName: {
										if #config.valkey.enabled {
											"\(#config._fullname)-valkey"
										}
										if !#config.valkey.enabled {
											if #config.tasksDatabase.existingSecretName != "" { #config.tasksDatabase.existingSecretName }
											if #config.tasksDatabase.existingSecretName == "" { "\(#config._fullname)-valkey" }
										}
									}
									name: #tasksSecretName
									items: [{
										key: {
											if #config.valkey.enabled { "tasks-password" }
											if !#config.valkey.enabled { #config.tasksDatabase.existingSecretKey }
										}
										path: "tasks_password"
									}]
								}
							},
							{
								secret: {
									#cacheSecretName: {
										if #config.valkey.enabled {
											"\(#config._fullname)-valkey"
										}
										if !#config.valkey.enabled {
											if #config.cachingDatabase.existingSecretName != "" { #config.cachingDatabase.existingSecretName }
											if #config.cachingDatabase.existingSecretName == "" { "\(#config._fullname)-valkey" }
										}
									}
									name: #cacheSecretName
									items: [{
										key: {
											if #config.valkey.enabled { "cache-password" }
											if !#config.valkey.enabled { #config.cachingDatabase.existingSecretKey }
										}
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
									if #config.persistence.existingClaim != "" { #config.persistence.existingClaim }
									if #config.persistence.existingClaim == "" { "\(#config._fullname)-media" }
								}
								readOnly: #config.worker.readOnlyPersistence
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
									if #config.reportsPersistence.existingClaim != "" { #config.reportsPersistence.existingClaim }
									if #config.reportsPersistence.existingClaim == "" { "\(#config._fullname)-reports" }
								}
								readOnly: #config.worker.readOnlyPersistence
							}
						}
					},
					if #config.scriptsPersistence.enabled {
						{
							name: "scripts"
							persistentVolumeClaim: {
								claimName: {
									if #config.scriptsPersistence.existingClaim != "" { #config.scriptsPersistence.existingClaim }
									if #config.scriptsPersistence.existingClaim == "" { "\(#config._fullname)-scripts" }
								}
								readOnly: #config.worker.readOnlyPersistence
							}
						}
					},
					for v in #config.worker.extraVolumes {v},
					for v in #config._extraVolumes {v},
				]
				if len(#config.worker.nodeSelector) > 0 {
					nodeSelector: #config.worker.nodeSelector
				}
				if len(#config.worker.affinity) > 0 {
					affinity: #config.worker.affinity
				}
				if len(#config.worker.tolerations) > 0 {
					tolerations: #config.worker.tolerations
				}
				if len(#config.worker.hostAliases) > 0 {
					hostAliases: #config.worker.hostAliases
				}
				if #config.worker.priorityClassName != "" {
					priorityClassName: #config.worker.priorityClassName
				}
				if #config.worker.schedulerName != "" {
					schedulerName: #config.worker.schedulerName
				}
				if len(#config.worker.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.worker.topologySpreadConstraints
				}
				if #config.worker.terminationGracePeriodSeconds != null {
					terminationGracePeriodSeconds: #config.worker.terminationGracePeriodSeconds
				}
				restartPolicy: "Always"
			}
		}
	}
}
