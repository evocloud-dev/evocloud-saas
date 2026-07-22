package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#YProviderConverterDeployment: appsv1.#Deployment & {
	#config: #Config
	let yProvider = #config.yProvider
	let converter = yProvider.converter

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-y-provider-converter"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "yProvider-converter"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: converter.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "yProvider-converter"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "yProvider-converter"
				}
				if yProvider.podAnnotations != _|_ {
					annotations: yProvider.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				shareProcessNamespace:        yProvider.shareProcessNamespace
				automountServiceAccountToken: yProvider.automountServiceAccountToken
				serviceAccountName:           yProvider.serviceAccountName

				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}

				containers: [
					{
						name:            #config.chartName
						let imageRepo = converter.image.repository | *yProvider.image.repository | *#config.image.repository
						let imageTag = converter.image.tag | *yProvider.image.tag | *#config.image.tag
						let imagePull = converter.image.pullPolicy | *yProvider.image.pullPolicy | *#config.image.pullPolicy
						image:           "\(imageRepo):\(imageTag)"
						imagePullPolicy: imagePull

						let cmd = converter.command | yProvider.command
						if cmd != _|_ { command: cmd }

						let convArgs = converter.args | yProvider.args
						if convArgs != _|_ { args: convArgs }

						ports: [{
							name:          "http"
							containerPort: converter.service.targetPort
							protocol:      "TCP"
						}]

						// Environment variables
						if yProvider.envVars != _|_ {
							env: [
								for k, v in yProvider.envVars {
									name: k
									if (v & string) != _|_ {
										value: v
									}
									if (v & string) == _|_ {
										valueFrom: v
									}
								}
							]
						}

						// Resources and SecurityContext
						let convResources = converter.resources | yProvider.resources
						if convResources != _|_ {
							resources: convResources
						}

						let secCtx = converter.securityContext | yProvider.securityContext
						if secCtx != _|_ { securityContext: secCtx }

						volumeMounts: [
							if #config.mountFiles != _|_ for idx, val in #config.mountFiles {
								name:      "files-\(idx)"
								mountPath: val.path
								subPath:   "content"
							},
							if yProvider.persistence != _|_ for name, vol in yProvider.persistence {
								name:      name
								mountPath: vol.mountPath
							},
							if converter.extraVolumeMounts != _|_ for vol in converter.extraVolumeMounts {
								name:      vol.name
								mountPath: vol.mountPath
								subPath:   vol.subPath
								readOnly:  vol.readOnly
							},
						]
					}
				]

				volumes: [
					if #config.mountFiles != _|_ for idx, _ in #config.mountFiles {
						name: "files-\(idx)"
						configMap: name: "\(#config.metadata.name)-files-\(idx)"
					},
					if yProvider.persistence != _|_ for name, vol in yProvider.persistence {
						name: name
						if vol.type == "emptyDir" {
							emptyDir: {}
						}
						if vol.type != "emptyDir" {
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-\(name)"
						}
					},
					if converter.extraVolumes != _|_ for vol in converter.extraVolumes {
						name: vol.name
						if vol.existingClaim != _|_ {
							persistentVolumeClaim: claimName: vol.existingClaim
						}
						if vol.existingClaim == _|_ {
							if vol.hostPath != _|_ { hostPath: vol.hostPath }
							if vol.csi != _|_ { csi: vol.csi }
							if vol.configMap != _|_ { configMap: vol.configMap }
							if vol.emptyDir != _|_ { emptyDir: vol.emptyDir }
							if vol.secret != _|_ { secret: vol.secret }
							if vol.hostPath == _|_ && vol.csi == _|_ && vol.configMap == _|_ && vol.emptyDir == _|_ && vol.secret == _|_ {
								emptyDir: {}
							}
						}
					},
				]
			}
		}
	}
}

#YProviderConverterPDB: policyv1.#PodDisruptionBudget & {
	#config: #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-y-provider-converter"
		namespace: #config.metadata.namespace
	}
	spec: policyv1.#PodDisruptionBudgetSpec & {
		maxUnavailable: 1
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "yProvider-converter"
		}
	}
}
