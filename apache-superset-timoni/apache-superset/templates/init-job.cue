package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#InitJob: {
	#config:    #Config
	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.fullname)-init-db"
		namespace: #config.metadata.namespace
		labels: {
			app:      #config.name
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
		if #config.init.jobAnnotations != _|_ {
			annotations: #config.init.jobAnnotations
		}
	}
	spec: batchv1.#JobSpec & {
		template: {
			metadata: {
				if #config.init.podAnnotations != _|_ {
					annotations: #config.init.podAnnotations
				}
				labels: {
					app:     #config.name
					release: #config.metadata.name
				} & #config.extraLabels & #config.init.podLabels
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
				} & #config.init.podSecurityContext
				initContainers: [
					for ic in #config.init.initContainers {
						{
							for k, v in ic {
								if k == "envFrom" {
									envFrom: [
										for ef in v {
											if ef.secretRef != _|_ && (ef.secretRef.name == "superset-env" || ef.secretRef.name == "as-env" || ef.secretRef.name == "superset") {
												secretRef: name: "\(#config.fullname)-\(#config.secretEnv.name)"
											}
											if ef.secretRef == _|_ || (ef.secretRef.name != "superset-env" && ef.secretRef.name != "as-env" && ef.secretRef.name != "superset") {
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
				containers: [{
					name: "\(#config.name)-init-db"
					image: "\(#config.image.repository):\(#config.image.tag)"
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
									"\(#config.fullname)-env"
								}
							}
						},
						for s in #config.envFromSecrets {
							secretRef: name: s
						},
					]
					imagePullPolicy: #config.image.pullPolicy
					if #config.init.containerSecurityContext != _|_ {
						securityContext: #config.init.containerSecurityContext
					}
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
					command: #config.init.command
					if #config.init.resources != _|_ {
						resources: #config.init.resources
					}
				},
					for ec in #config.init.extraContainers {
						ec
					},
				]
				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
				if #config.affinity != _|_ || #config.init.affinity != _|_ {
					affinity: #config.affinity & #config.init.affinity
				}
				if #config.init.priorityClassName != null {priorityClassName: #config.init.priorityClassName}
				if #config.tolerations != _|_ && #config.tolerations != [] {tolerations: #config.tolerations}
				if #config.imagePullSecrets != [] {imagePullSecrets: #config.imagePullSecrets}
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
				restartPolicy: "Never"
			}
		}
	}
}
