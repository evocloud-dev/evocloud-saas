package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	"encoding/json"
	corev1 "k8s.io/api/core/v1"
	"crypto/sha256"
	"encoding/hex"
)

#DeploymentFlower: {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-flower"
		namespace: #config.metadata.namespace
		labels: {
			app:      "\(#config.name)-flower"
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
		if #config.supersetCeleryFlower.deploymentAnnotations != _|_ {
			annotations: #config.supersetCeleryFlower.deploymentAnnotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.supersetCeleryFlower.replicaCount
		selector: matchLabels: {
			app:     "\(#config.name)-flower"
			release: #config.metadata.name
		}
		template: {
			metadata: {
				annotations: {
					"checksum/config":  hex.Encode(sha256.Sum256(json.Marshal(#config.supersetConfig)))
					"checksum/secrets": hex.Encode(sha256.Sum256(json.Marshal(#config.extraSecretEnv)))
				} & #config.supersetCeleryFlower.podAnnotations
				labels: {
					app:     "\(#config.name)-flower"
					release: #config.metadata.name
				} & #config.extraLabels & #config.supersetCeleryFlower.podLabels
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
				} & #config.supersetCeleryFlower.podSecurityContext
				initContainers: [
					for ic in #config.supersetCeleryFlower.initContainers {
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
					name:            "\(#config.name)-flower"
					image:           "\(#config.image.repository):\(#config.image.tag)"
					imagePullPolicy: #config.image.pullPolicy
					if #config.supersetCeleryFlower.containerSecurityContext != _|_ {
						securityContext: #config.supersetCeleryFlower.containerSecurityContext
					}
					command: #config.supersetCeleryFlower.command
					env: [
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
					ports: [{name: "flower", containerPort: 5555, protocol: "TCP"}]
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
					if #config.supersetCeleryFlower.startupProbe != _|_ && len(#config.supersetCeleryFlower.startupProbe) > 0 {
						startupProbe: #config.supersetCeleryFlower.startupProbe
					}
					if #config.supersetCeleryFlower.readinessProbe != _|_ && len(#config.supersetCeleryFlower.readinessProbe) > 0 {
						readinessProbe: #config.supersetCeleryFlower.readinessProbe
					}
					if #config.supersetCeleryFlower.livenessProbe != _|_ && len(#config.supersetCeleryFlower.livenessProbe) > 0 {
						livenessProbe: #config.supersetCeleryFlower.livenessProbe
					}
					if #config.supersetCeleryFlower.resources != _|_ && len(#config.supersetCeleryFlower.resources) > 0 {
						resources: #config.supersetCeleryFlower.resources
					}
				},
					for ec in #config.supersetCeleryFlower.extraContainers {
						ec
					},
				]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 || len(#config.supersetCeleryFlower.affinity) > 0 {
					affinity: #config.affinity & #config.supersetCeleryFlower.affinity
				}
				if #config.supersetCeleryFlower.priorityClassName != null {priorityClassName: #config.supersetCeleryFlower.priorityClassName}
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
							configMap: name: "\(#config.metadata.name)-config"
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
