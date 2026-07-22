package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#DocSpecDeployment: appsv1.#Deployment & {
	#config: #Config
	let docSpec = #config.docSpec

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-docspec"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "docspec"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: docSpec.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "docspec"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "docspec"
				}
				if docSpec.podAnnotations != _|_ {
					annotations: docSpec.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}

				containers: [
					{
						name:            "\(#config.chartName)-docspec"
						image:           "\(docSpec.image.repository):\(docSpec.image.tag)"
						imagePullPolicy: docSpec.image.pullPolicy

						if docSpec.command != _|_ { command: docSpec.command }
						if docSpec.args != _|_ { args: docSpec.args }

						ports: [{
							name:          "http"
							containerPort: docSpec.service.targetPort
							protocol:      "TCP"
						}]

						// Probes
						if docSpec.probes.liveness != _|_ {
							livenessProbe: {
								httpGet: {
									path: docSpec.probes.liveness.path
									port: docSpec.service.targetPort
								}
							}
						}
						if docSpec.probes.readiness != _|_ {
							readinessProbe: {
								httpGet: {
									path: docSpec.probes.readiness.path
									port: docSpec.service.targetPort
								}
							}
						}

						// Environment variables
						if docSpec.envVars != _|_ {
							env: [
								for k, v in docSpec.envVars {
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

						if docSpec.resources != _|_ { resources: docSpec.resources }
						if docSpec.securityContext != _|_ { securityContext: docSpec.securityContext }

						volumeMounts: [
							if docSpec.extraVolumeMounts != _|_ for vol in docSpec.extraVolumeMounts {
								name:      vol.name
								mountPath: vol.mountPath
								subPath:   vol.subPath
								readOnly:  vol.readOnly
							},
						]
					}
				]

				if docSpec.nodeSelector != _|_ { nodeSelector: docSpec.nodeSelector }
				if docSpec.tolerations != _|_ { tolerations: docSpec.tolerations }

				volumes: [
					if docSpec.extraVolumes != _|_ for vol in docSpec.extraVolumes {
						name: vol.name
						if vol.persistentVolumeClaim != _|_ {
							persistentVolumeClaim: claimName: vol.persistentVolumeClaim
						}
						if vol.persistentVolumeClaim == _|_ {
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
