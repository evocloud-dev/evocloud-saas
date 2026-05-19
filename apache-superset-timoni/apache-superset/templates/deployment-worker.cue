package templates

import (
	"encoding/json"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"crypto/sha256"
	"encoding/hex"
)

#DeploymentWorker: {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-worker"
		namespace: #config.metadata.namespace
		labels: {
			app:      "\(#config.name)-worker"
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels & #config.supersetWorker.deploymentLabels
		if #config.supersetWorker.deploymentAnnotations != _|_ {
			annotations: #config.supersetWorker.deploymentAnnotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.supersetWorker.replicas.replicaCount
		if len(#config.supersetWorker.strategy) > 0 {
			strategy: #config.supersetWorker.strategy
		}
		selector: matchLabels: {
			app:     "\(#config.name)-worker"
			release: #config.metadata.name
		}
		template: {
			metadata: {
				annotations: {
					"checksum/superset_config.py":   hex.Encode(sha256.Sum256(json.Marshal(#config.supersetConfig)))
					"checksum/superset_bootstrap.sh": hex.Encode(sha256.Sum256(json.Marshal(#config.bootstrapScript)))
					"checksum/connections":          hex.Encode(sha256.Sum256(json.Marshal(#config.supersetNode.connections)))
					"checksum/extraConfigs":         hex.Encode(sha256.Sum256(json.Marshal(#config.extraConfigs)))
					"checksum/extraSecrets":         hex.Encode(sha256.Sum256(json.Marshal(#config.extraSecrets)))
					"checksum/extraSecretEnv":      hex.Encode(sha256.Sum256(json.Marshal(#config.extraSecretEnv)))
					"checksum/configOverrides":      hex.Encode(sha256.Sum256(json.Marshal(#config.configOverrides)))
					"checksum/configOverridesFiles": hex.Encode(sha256.Sum256(json.Marshal(#config.configOverridesFiles)))
				} & #config.supersetWorker.podAnnotations
				labels: {
					app:     "\(#config.name)-worker"
					release: #config.metadata.name
				} & #config.extraLabels & #config.supersetWorker.podLabels
			}
			spec: corev1.#PodSpec & {
				if #config.serviceAccount.create || #config.serviceAccountName != null {
					serviceAccountName: {
						if #config.serviceAccount.create {
							if #config.serviceAccountName != null {
								#config.serviceAccountName
							}
							if #config.serviceAccountName == null {
								#config.metadata.name
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
				} & #config.supersetWorker.podSecurityContext
				initContainers: [
					for ic in #config.supersetWorker.initContainers {
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
					name:            "\(#config.name)-worker"
					image:           "\(#config.image.repository):\(#config.image.tag)"
					imagePullPolicy: #config.image.pullPolicy
					if #config.supersetWorker.containerSecurityContext != _|_ {
						securityContext: #config.supersetWorker.containerSecurityContext
					}
					command: #config.supersetWorker.command
					env: [
						{
							name:  "SUPERSET_PORT"
							value: "\(#config.service.port)"
						},
						for k, v in #config.extraEnv {
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
									"\(#config.metadata.name)-env"
								}
							}
						},
						for s in #config.envFromSecrets {
							secretRef: name: s
						},
					]
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
					if #config.supersetWorker.startupProbe != _|_ && len(#config.supersetWorker.startupProbe) > 0 {
						startupProbe: #config.supersetWorker.startupProbe
					}
					if #config.supersetWorker.readinessProbe != _|_ && len(#config.supersetWorker.readinessProbe) > 0 {
						readinessProbe: #config.supersetWorker.readinessProbe
					}
					if #config.supersetWorker.livenessProbe != _|_ && len(#config.supersetWorker.livenessProbe) > 0 {
						livenessProbe: #config.supersetWorker.livenessProbe
					}
					if #config.supersetWorker.resources != _|_ && len(#config.supersetWorker.resources) > 0 {
						resources: #config.supersetWorker.resources
					}
				},
					for ec in #config.supersetWorker.extraContainers {
						ec
					},
				]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 || len(#config.supersetWorker.affinity) > 0 {
					affinity: #config.affinity & #config.supersetWorker.affinity
				}
				if #config.supersetWorker.priorityClassName != null {priorityClassName: #config.supersetWorker.priorityClassName}
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
								"\(#config.metadata.name)-config"
							}
						}
					},
					if len(#config.extraConfigs) > 0 {
						{
							name: "superset-extra-config"
							configMap: name: "\(#config.metadata.name)-extra-config"
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
