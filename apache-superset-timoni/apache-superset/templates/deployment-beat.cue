package templates

import (
	"encoding/json"
	"crypto/sha256"
	"encoding/hex"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#DeploymentBeat: {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-beat"
		namespace: #config.metadata.namespace
		labels: {
			app:      "\(#config.name)-celerybeat"
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
		if #config.supersetCeleryBeat.deploymentAnnotations != _|_ {
			annotations: #config.supersetCeleryBeat.deploymentAnnotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		strategy: {
			type: "Recreate"
		}
		selector: matchLabels: {
			app:     "\(#config.name)-celerybeat"
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
				} & #config.supersetCeleryBeat.podAnnotations
				labels: {
					app:     "\(#config.name)-celerybeat"
					release: #config.metadata.name
				} & #config.extraLabels & #config.supersetCeleryBeat.podLabels
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
				} & #config.supersetCeleryBeat.podSecurityContext
				initContainers: [
					for ic in #config.supersetCeleryBeat.initContainers {
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
					name:            "\(#config.name)-beat"
					image:           "\(#config.image.repository):\(#config.image.tag)"
					imagePullPolicy: #config.image.pullPolicy
					if #config.supersetCeleryBeat.containerSecurityContext != _|_ {
						securityContext: #config.supersetCeleryBeat.containerSecurityContext
					}
					command: #config.supersetCeleryBeat.command
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
					if #config.supersetCeleryBeat.resources != _|_ && len(#config.supersetCeleryBeat.resources) > 0 {
						resources: #config.supersetCeleryBeat.resources
					}
				},
					for ec in #config.supersetCeleryBeat.extraContainers {
						ec
					},
				]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 || len(#config.supersetCeleryBeat.affinity) > 0 {
					affinity: #config.affinity & #config.supersetCeleryBeat.affinity
				}
				if #config.supersetCeleryBeat.priorityClassName != null {priorityClassName: #config.supersetCeleryBeat.priorityClassName}
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
