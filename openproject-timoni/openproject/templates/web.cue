package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#WebDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-web"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & #config.web.labels & {
			"openproject/process":        "web"
			"app.kubernetes.io/component": "web"
		}
		if #config.web.annotations != _|_ {
			annotations: #config.web.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.autoscaling.enabled {
			replicas: #config.replicaCount
		}
		strategy: type: #config.strategy.type
		selector: matchLabels: {
			#config.selector.labels
			"openproject/process": "web"
		}
		template: {
			metadata: {
				annotations: {
					if #config.podAnnotations != _|_ {
						#config.podAnnotations
					}
					if #config.metrics.enabled {
						"prometheus.io/scrape": "true"
						"prometheus.io/path":   #config.metrics.path
						"prometheus.io/port":   "\(#config.metrics.port)"
					}
					"checksum/env-core":        "parity-checksum"
					"checksum/env-memcached":   "parity-checksum"
					"checksum/env-oidc":        "parity-checksum"
					"checksum/env-s3":          "parity-checksum"
					"checksum/env-environment": "parity-checksum"
				}
				labels: #config.metadata.labels & {
					"openproject/process":        "web"
					"app.kubernetes.io/component": "web"
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
				if #config.web.nodeSelector != _|_ || #config.nodeSelector != _|_ {
					nodeSelector: {
						if #config.web.nodeSelector != _|_ {
							#config.web.nodeSelector
						}
						if #config.web.nodeSelector == _|_ && #config.nodeSelector != _|_ {
							#config.nodeSelector
						}
					}
				}
				if #config.web.topologySpreadConstraints != _|_ || #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: {
						if #config.web.topologySpreadConstraints != _|_ {
							#config.web.topologySpreadConstraints
						}
						if #config.web.topologySpreadConstraints == _|_ && #config.topologySpreadConstraints != _|_ {
							#config.topologySpreadConstraints
						}
					}
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
						env: [
							if #config.postgresql.auth.password != "" {
								{name: "OPENPROJECT_DB_PASSWORD", value: #config.postgresql.auth.password}
							},
						]
						args: [
							"/app/docker/prod/web",
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
						ports: [
							for name, p in #config.service.ports {
								"name":          name
								"containerPort": p.containerPort
								"protocol":      p.protocol
							},
							if #config.metrics.enabled {
								{
									name:          "metrics"
									containerPort: #config.metrics.port
									protocol:      "TCP"
								}
							},
						]
						if #config.probes.liveness.enabled {
							livenessProbe: {
								httpGet: {
									path: "\(#config.openproject.railsRelativeUrlRoot)/health_checks/default"
									port: 8080
									httpHeaders: [
										{name: "Host", value: "localhost"},
									]
								}
								initialDelaySeconds: #config.probes.liveness.initialDelaySeconds
								timeoutSeconds:      #config.probes.liveness.timeoutSeconds
								periodSeconds:       #config.probes.liveness.periodSeconds
								failureThreshold:    #config.probes.liveness.failureThreshold
								successThreshold:    #config.probes.liveness.successThreshold
							}
						}
						if #config.probes.readiness.enabled {
							readinessProbe: {
								httpGet: {
									path: "\(#config.openproject.railsRelativeUrlRoot)/health_checks/default"
									port: 8080
									httpHeaders: [
										{name: "Host", value: "localhost"},
									]
								}
								initialDelaySeconds: #config.probes.readiness.initialDelaySeconds
								timeoutSeconds:      #config.probes.readiness.timeoutSeconds
								periodSeconds:       #config.probes.readiness.periodSeconds
								failureThreshold:    #config.probes.readiness.failureThreshold
								successThreshold:    #config.probes.readiness.successThreshold
							}
						}
						if #config.probes.startup.enabled {
							startupProbe: {
								httpGet: {
									path: "\(#config.openproject.railsRelativeUrlRoot)/health_checks/default"
									port: 8080
									httpHeaders: [
										{name: "Host", value: "localhost"},
									]
								}
								initialDelaySeconds: #config.probes.startup.initialDelaySeconds
								timeoutSeconds:      #config.probes.startup.timeoutSeconds
								periodSeconds:       #config.probes.startup.periodSeconds
								failureThreshold:    #config.probes.startup.failureThreshold
								successThreshold:    #config.probes.startup.successThreshold
							}
						}
						if #config.resources != _|_ {
							resources: #config.resources
						}
					},
				]
			}
		}
	}
}
