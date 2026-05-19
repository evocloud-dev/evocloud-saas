package templates

import (
	"encoding/json"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"crypto/sha256"
	"encoding/hex"
)

#Deployment: {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.fullname
		namespace: #config.metadata.namespace
		labels: {
			app:      #config.name
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels & #config.supersetNode.deploymentLabels
		if #config.supersetNode.deploymentAnnotations != _|_ {
			annotations: #config.supersetNode.deploymentAnnotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.supersetNode.replicas.replicaCount
		if len(#config.supersetNode.strategy) > 0 {
			strategy: #config.supersetNode.strategy
		}
		selector: matchLabels: {
			app:     #config.name
			release: #config.metadata.name
		}
		template: {
			metadata: {
				annotations: {
					"checksum/superset_config.py":   hex.Encode(sha256.Sum256(json.Marshal(#config.supersetConfig)))
					"checksum/superset_init.sh":     hex.Encode(sha256.Sum256(json.Marshal(#config.init.initscript)))
					"checksum/superset_bootstrap.sh": hex.Encode(sha256.Sum256(json.Marshal(#config.bootstrapScript)))
					"checksum/connections":          hex.Encode(sha256.Sum256(json.Marshal(#config.supersetNode.connections)))
					"checksum/extraConfigs":         hex.Encode(sha256.Sum256(json.Marshal(#config.extraConfigs)))
					"checksum/extraSecrets":         hex.Encode(sha256.Sum256(json.Marshal(#config.extraSecrets)))
					"checksum/extraSecretEnv":      hex.Encode(sha256.Sum256(json.Marshal(#config.extraSecretEnv)))
					"checksum/configOverrides":      hex.Encode(sha256.Sum256(json.Marshal(#config.configOverrides)))
					"checksum/configOverridesFiles": hex.Encode(sha256.Sum256(json.Marshal(#config.configOverridesFiles)))
				} & #config.supersetNode.podAnnotations
				labels: {
					app:     #config.name
					release: #config.metadata.name
				} & #config.extraLabels & #config.supersetNode.podLabels
			}
			spec: corev1.#PodSpec & {
				if #config.serviceAccount.create || #config.serviceAccountName != null {
					serviceAccountName: {
						if #config.serviceAccount.create {
							if #config.serviceAccountName != null {
								#config.serviceAccountName
							}
							if #config.serviceAccountName == null {
								#config.fullname
							}
						}
						if !#config.serviceAccount.create {
							if #config.serviceAccountName != null {
								#config.serviceAccountName
							}
							if #config.serviceAccountName == null {
								"default"
							}
						}
					}
				}
				securityContext: {
					runAsUser: #config.runAsUser
				} & #config.supersetNode.podSecurityContext
				initContainers: [
					for ic in #config.supersetNode.initContainers {
						{
							for k, v in ic {
								if k == "envFrom" {
									envFrom: [
										for ef in v {
											if ef.secretRef != _|_ && (ef.secretRef.name == "superset-env" || ef.secretRef.name == "as-env") {
												secretRef: name: "\(#config.fullname)-\(#config.secretEnv.name)"
											}
											if ef.secretRef == _|_ || (ef.secretRef.name != "superset-env" && ef.secretRef.name != "as-env") {
												ef
											}
										}
									]
								}
								if k != "envFrom" {
									"\(k)": v
								}
							}
						}
					}
				]
				if len(#config.hostAliases) > 0 {
					hostAliases: #config.hostAliases
				}
				containers: [{
					name:            #config.name
					_tag:            #config.image.tag
					image:           "\(#config.image.repository):\(_tag)"
					imagePullPolicy: #config.image.pullPolicy
					if #config.supersetNode.containerSecurityContext != _|_ {
						securityContext: #config.supersetNode.containerSecurityContext
					}
					command: #config.supersetNode.command
					env: [
						{
							name:  "SUPERSET_PORT"
							value: "\(#config.service.port)"
						},
						for k, v in #config.extraEnv {
							name:  k
							value: v
						},
						for k, v in #config.supersetNode.env {
							name:  k
							value: v
						},
						for e in #config.extraEnvRaw {e},
					]
					envFrom: [
						{
							secretRef: name: {
								if #config.envFromSecret != null {
									#config.envFromSecret
								}
								if #config.envFromSecret == null {
									"\(#config.fullname)-env"
								}
							}
						},
						for s in #config.envFromSecrets {
							secretRef: name: s
						},
					]
					ports: [{
						name:          "http"
						containerPort: #config.service.port
						protocol:      "TCP"
					}]
					volumeMounts: [
						{
							name:      "superset-config"
							mountPath: #config.configMountPath
							readOnly:  true
						},
						if len(#config.extraConfigs) > 0 {
							{
								name:      "superset-extra-config"
								mountPath: #config.extraConfigMountPath
								readOnly:  true
							}
						},
						for vm in #config.extraVolumeMounts {
							vm
						},
					]
					if #config.supersetNode.startupProbe != _|_ && len(#config.supersetNode.startupProbe) > 0 {
						startupProbe: #config.supersetNode.startupProbe
					}
					if #config.supersetNode.readinessProbe != _|_ && len(#config.supersetNode.readinessProbe) > 0 {
						readinessProbe: #config.supersetNode.readinessProbe
					}
					if #config.supersetNode.livenessProbe != _|_ && len(#config.supersetNode.livenessProbe) > 0 {
						livenessProbe: #config.supersetNode.livenessProbe
					}
					if #config.supersetNode.resources != _|_ && len(#config.supersetNode.resources) > 0 {
						resources: #config.supersetNode.resources
					}
				},
					for ec in #config.supersetNode.extraContainers {
						ec
					},
				]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 || len(#config.supersetNode.affinity) > 0 {
					affinity: #config.affinity & #config.supersetNode.affinity
				}
				if #config.priorityClassName != null {priorityClassName: #config.priorityClassName}
				if len(#config.tolerations) > 0 {tolerations: #config.tolerations}
				if len(#config.imagePullSecrets) > 0 {imagePullSecrets: #config.imagePullSecrets}
				volumes: [
					{
						name: "superset-config"
						secret: secretName: {
							if #config.configFromSecret != null {
								#config.configFromSecret
							}
							if #config.configFromSecret == null {
								"\(#config.fullname)-config"
							}
						}
					},
					if len(#config.extraConfigs) > 0 {
						{
							name: "superset-extra-config"
							configMap: name: "\(#config.fullname)-extra-config"
						}
					},
					for v in #config.extraVolumes {
						v
					},
				]
			}
		}
	}
}
