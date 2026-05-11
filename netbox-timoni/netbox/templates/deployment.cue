package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.autoscaling.enabled {
			replicas: #config.replicaCount
		}
		revisionHistoryLimit: #config.revisionHistoryLimit
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.updateStrategy != _|_ {
			strategy: #config.updateStrategy
		}
		template: {
			metadata: {
				labels: #config.metadata.labels & {
					"app.kubernetes.io/component": "netbox"
				}
				annotations: {
					if #config.podAnnotations != _|_ {
						for k, v in #config.podAnnotations {
							"\(k)": v
						}
					}
					"checksum/config": "checksum-placeholder"
					if #config.existingSecret == "" {
						"checksum/secret": "checksum-placeholder"
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
				automountServiceAccountToken: #config.automountServiceAccountToken
				if #config.podSecurityContext.enabled {
					securityContext: {
						fsGroup:             #config.podSecurityContext.fsGroup
						fsGroupChangePolicy: #config.podSecurityContext.fsGroupChangePolicy
						if #config.podSecurityContext.supplementalGroups != _|_ {
							supplementalGroups: #config.podSecurityContext.supplementalGroups
						}
						if #config.podSecurityContext.sysctls != _|_ {
							sysctls: #config.podSecurityContext.sysctls
						}
					}
				}
				initContainers: [
					{
						name: "init-dirs"
						image: {
							#registry: {
								if #config.init.image.registry != "" { #config.init.image.registry }
								if #config.init.image.registry == "" { "docker.io" }
							}
							"\(#registry)/\(#config.init.image.repository):\(#config.init.image.tag)"
						}
						imagePullPolicy: #config.init.image.pullPolicy
						command: ["/bin/sh", "-c", "mkdir -p /opt/unit/state /opt/unit/tmp"]
						resources: #config.init.resources
						if #config.init.securityContext.enabled {
							securityContext: {
								runAsUser:                #config.init.securityContext.runAsUser
								runAsGroup:               #config.init.securityContext.runAsGroup
								runAsNonRoot:             #config.init.securityContext.runAsNonRoot
								readOnlyRootFilesystem:   #config.init.securityContext.readOnlyRootFilesystem
								allowPrivilegeEscalation: #config.init.securityContext.allowPrivilegeEscalation
								if #config.init.securityContext.capabilities != _|_ {
									capabilities: #config.init.securityContext.capabilities
								}
								if #config.init.securityContext.seccompProfile != _|_ {
									seccompProfile: #config.init.securityContext.seccompProfile
								}
								if #config.init.securityContext.seLinuxOptions != _|_ {
									seLinuxOptions: #config.init.securityContext.seLinuxOptions
								}
							}
						}
						volumeMounts: [
							{
								name:      "optunit"
								mountPath: "/opt/unit"
							},
						]
					},
					for ic in #config.initContainers {ic},
				]
				containers: [
					{
						name: "netbox"
						if #config.securityContext.enabled {
							securityContext: {
								runAsUser:                #config.securityContext.runAsUser
								runAsGroup:               #config.securityContext.runAsGroup
								runAsNonRoot:             #config.securityContext.runAsNonRoot
								readOnlyRootFilesystem:   #config.securityContext.readOnlyRootFilesystem
								allowPrivilegeEscalation: #config.securityContext.allowPrivilegeEscalation
								privileged:               #config.securityContext.privileged
								if #config.securityContext.capabilities != _|_ {
									capabilities: #config.securityContext.capabilities
								}
								if #config.securityContext.seccompProfile != _|_ {
									seccompProfile: #config.securityContext.seccompProfile
								}
								if #config.securityContext.seLinuxOptions != _|_ {
									seLinuxOptions: #config.securityContext.seLinuxOptions
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
						if #config.command != [] {
							command: #config.command
						}
						if #config.args != [] {
							args: #config.args
						}
						env: [
							{
								name: "SUPERUSER_NAME"
								valueFrom: secretKeyRef: {
									name: #config._superuserSecretName
									key:  "username"
								}
							},
							{
								name: "SUPERUSER_EMAIL"
								valueFrom: secretKeyRef: {
									name: #config._superuserSecretName
									key:  "email"
								}
							},
							{
								name: "SUPERUSER_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config._superuserSecretName
									key:  "password"
								}
							},
							if #config.dbWaitDebug {
								{
									name:  "DB_WAIT_DEBUG"
									value: "1"
								}
							},
							if #config.allowedHostsIncludesPodIP {
								{
									name: "POD_IP"
									valueFrom: fieldRef: {
										apiVersion: "v1"
										fieldPath:  "status.podIP"
									}
								}
							},
							for ev in #config.extraEnvs {ev},
						]
						if #config.extraEnvVarsCM != "" || #config.extraEnvVarsSecret != "" {
							envFrom: [
								if #config.extraEnvVarsCM != "" {
									{configMapRef: name: #config.extraEnvVarsCM}
								},
								if #config.extraEnvVarsSecret != "" {
									{secretRef: name: #config.extraEnvVarsSecret}
								},
							]
						}
						ports: [
							{
								name:          "http"
								containerPort: 8080
								protocol:      "TCP"
							},
							if #config.metrics.granian.enabled {
								{
									name:          "granian-metrics"
									containerPort: 9000
									protocol:      "TCP"
								}
							},
						]
						if len(#config.customLivenessProbe) > 0 {
							livenessProbe: #config.customLivenessProbe
						}
						if len(#config.customLivenessProbe) == 0 && #config.livenessProbe.enabled {
							livenessProbe: {
								initialDelaySeconds: #config.livenessProbe.initialDelaySeconds
								periodSeconds:        #config.livenessProbe.periodSeconds
								timeoutSeconds:       #config.livenessProbe.timeoutSeconds
								failureThreshold:     #config.livenessProbe.failureThreshold
								successThreshold:     #config.livenessProbe.successThreshold
								tcpSocket: port: "http"
							}
						}
						if len(#config.customReadinessProbe) > 0 {
							readinessProbe: #config.customReadinessProbe
						}
						if len(#config.customReadinessProbe) == 0 && #config.readinessProbe.enabled {
							readinessProbe: {
								initialDelaySeconds: #config.readinessProbe.initialDelaySeconds
								periodSeconds:        #config.readinessProbe.periodSeconds
								timeoutSeconds:       #config.readinessProbe.timeoutSeconds
								failureThreshold:     #config.readinessProbe.failureThreshold
								successThreshold:     #config.readinessProbe.successThreshold
								httpGet: {
									path: "/\(#config.basePath)login/"
									port: "http"
									// Note: Host header logic handled by Go templates in Helm,
									// CUE logic for host header if not "*"
									if #config.allowedHosts[0] != "*" {
										httpHeaders: [{
											name:  "Host"
											value: #config.allowedHosts[0]
										}]
									}
								}
							}
						}
						if len(#config.customStartupProbe) > 0 {
							startupProbe: #config.customStartupProbe
						}
						if len(#config.customStartupProbe) == 0 && #config.startupProbe.enabled {
							startupProbe: {
								initialDelaySeconds: #config.startupProbe.initialDelaySeconds
								periodSeconds:        #config.startupProbe.periodSeconds
								timeoutSeconds:       #config.startupProbe.timeoutSeconds
								failureThreshold:     #config.startupProbe.failureThreshold
								successThreshold:     #config.startupProbe.successThreshold
								httpGet: {
									path: "/\(#config.basePath)login/"
									port: "http"
									if #config.allowedHosts[0] != "*" {
										httpHeaders: [{
											name:  "Host"
											value: #config.allowedHosts[0]
										}]
									}
								}
							}
						}
						if len(#config.lifecycleHooks) > 0 {
							lifecycle: #config.lifecycleHooks
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
							},
							if #config.reportsPersistence.enabled {
								{
									name:      "reports"
									mountPath: "/opt/netbox/netbox/reports"
									if #config.reportsPersistence.subPath != "" {
										subPath: #config.reportsPersistence.subPath
									}
								}
							},
							if #config.scriptsPersistence.enabled {
								{
									name:      "scripts"
									mountPath: "/opt/netbox/netbox/scripts"
									if #config.scriptsPersistence.subPath != "" {
										subPath: #config.scriptsPersistence.subPath
									}
								}
							},
							{
								name:      "optunit"
								mountPath: "/opt/unit"
							},
							{
								name:      "secrets"
								mountPath: "/run/secrets/superuser_password"
								subPath:   "superuser_password"
								readOnly:  true
							},
							{
								name:      "secrets"
								mountPath: "/run/secrets/superuser_api_token"
								subPath:   "superuser_api_token"
								readOnly:  true
							},
							for vm in #config.extraVolumeMounts {vm},
							for vm in #config._extraVolumeMounts {vm},
						]
						resources: #config.resources
					},
					for sc in #config.sidecars {sc},
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
						name: "optunit"
						emptyDir: medium: "Memory"
					},
					{
						name: "media"
						if #config.persistence.enabled {
							persistentVolumeClaim: claimName: {
								if #config.persistence.existingClaim != "" { #config.persistence.existingClaim }
								if #config.persistence.existingClaim == "" { "\(#config._fullname)-media" }
							}
						}
						if !#config.persistence.enabled {
							emptyDir: {}
						}
					},
					if #config.reportsPersistence.enabled {
						{
							name: "reports"
							persistentVolumeClaim: claimName: {
								if #config.reportsPersistence.existingClaim != "" { #config.reportsPersistence.existingClaim }
								if #config.reportsPersistence.existingClaim == "" { "\(#config._fullname)-reports" }
							}
						}
					},
					if #config.scriptsPersistence.enabled {
						{
							name: "scripts"
							persistentVolumeClaim: claimName: {
								if #config.scriptsPersistence.existingClaim != "" { #config.scriptsPersistence.existingClaim }
								if #config.scriptsPersistence.existingClaim == "" { "\(#config._fullname)-scripts" }
							}
						}
					},
					for v in #config.extraVolumes {v},
					for v in #config._extraVolumes {v},
				]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 {
					affinity: #config.affinity
				}
				if #config.tolerations != [] {
					tolerations: #config.tolerations
				}
				if #config.hostAliases != [] {
					hostAliases: #config.hostAliases
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				if #config.schedulerName != "" {
					schedulerName: #config.schedulerName
				}
				if #config.topologySpreadConstraints != [] {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.terminationGracePeriodSeconds != null {
					terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				}
			}
		}
	}
}
