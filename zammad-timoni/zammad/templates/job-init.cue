package templates

import (
	"list"

	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#InitJob: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		if #config.zammadConfig.initJob.randomName {
			name: "\(#config.metadata.name)-init"
		}
		if !#config.zammadConfig.initJob.randomName {
			name: "\(#config.metadata.name)-init"
		}
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zammad-init"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations & #config.zammadConfig.initJob.annotations
		}
		if #config.metadata.annotations == _|_ {
			annotations: #config.zammadConfig.initJob.annotations
		}
	}
	spec: batchv1.#JobSpec & {
		ttlSecondsAfterFinished: #config.zammadConfig.initJob.ttlSecondsAfterFinished
		template: corev1.#PodTemplateSpec & {
			metadata: {
				annotations: #config.podAnnotations & #config.zammadConfig.initJob.podAnnotations
				labels: #config.metadata.labels & #config.podLabels & #config.zammadConfig.initJob.podLabels & {
					"app.kubernetes.io/component": "zammad-init"
				}
			}
			spec: corev1.#PodSpec & {
				if #config.image.imagePullSecrets != _|_ {
					imagePullSecrets: #config.image.imagePullSecrets
				}
				if #config.serviceAccount.create {
					serviceAccountName: #config.serviceAccount.name
				}
				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				securityContext: #config.securityContext
				if #config.zammadConfig.initJob.nodeSelector != _|_ {
					nodeSelector: #config.zammadConfig.initJob.nodeSelector
				}
				if #config.zammadConfig.initJob.affinity != _|_ {
					affinity: #config.zammadConfig.initJob.affinity
				}
				if #config.zammadConfig.initJob.tolerations != _|_ {
					tolerations: #config.zammadConfig.initJob.tolerations
				}
				if #config.zammadConfig.initJob.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.zammadConfig.initJob.topologySpreadConstraints
				}
				#config.zammadConfig.initJob.podSpec
				restartPolicy: "OnFailure"
				initContainers: list.Concat([#config.initContainers, [
					if #config.zammadConfig.initContainers.volumePermissions.enabled {
						#config._zammadVolumePermissionsInitContainer
					},
					{
						name:            "postgresql-init"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						resources:       #config.zammadConfig.initContainers.postgresql.resources
						securityContext: #config.zammadConfig.initContainers.postgresql.securityContext
						env:             #config._zammadEnv
						volumeMounts: list.Concat([#config._zammadVolumeMounts, [
							{
								name:      "\(#config.metadata.name)-init"
								mountPath: "/docker-entrypoint.sh"
								readOnly:  true
								subPath:   "postgresql-init"
							},
						]])
					},
					if #config.zammadConfig.initContainers.zammad.customInit != "" {
						{
							name:            "zammad-init"
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
							resources:       #config.zammadConfig.initContainers.zammad.resources
							securityContext: #config.zammadConfig.initContainers.zammad.securityContext
							env: list.Concat([#config._zammadEnv, #config._zammadEnvFailOnPendingMigrations])
							volumeMounts: list.Concat([#config._zammadVolumeMounts, [
								{
									name:      "\(#config.metadata.name)-init"
									mountPath: "/docker-entrypoint.sh"
									readOnly:  true
									subPath:   "zammad-init"
								},
							]])
						}
					},
					if #config.zammadConfig.elasticsearch.initialisation {
						{
							name:            "elasticsearch-init"
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
							resources:       #config.zammadConfig.initContainers.elasticsearch.resources
							securityContext: #config.zammadConfig.initContainers.elasticsearch.securityContext
							env: list.Concat([#config._zammadEnv, #config._zammadEnvFailOnPendingMigrations, [
								if #config.zammadConfig.elasticsearch.pass != "" || #config.secrets.elasticsearch.useExisting {
									{
										name: "ELASTICSEARCH_PASSWORD"
										valueFrom: secretKeyRef: {
											name: #config._elasticsearchSecretName
											key:  #config.secrets.elasticsearch.secretKey
										}
									}
								},
							]])
							volumeMounts: list.Concat([#config._zammadVolumeMounts, [
								{
									name:      "\(#config.metadata.name)-init"
									mountPath: "/docker-entrypoint.sh"
									readOnly:  true
									subPath:   "elasticsearch-init"
								},
							]])
						}
					},
				]])
				containers: [
					{
						name:            "postgresql-init-post"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						resources:       #config.zammadConfig.initContainers.postgresql.resources
						securityContext: #config.zammadConfig.initContainers.postgresql.securityContext
						env: list.Concat([#config._zammadEnv, #config._zammadEnvFailOnPendingMigrations])
						volumeMounts: list.Concat([#config._zammadVolumeMounts, [
							{
								name:      "\(#config.metadata.name)-init"
								mountPath: "/docker-entrypoint.sh"
								readOnly:  true
								subPath:   "postgresql-init-post"
							},
						]])
					},
				]
				volumes: list.Concat([#config._zammadVolumes, [
					{
						name: "\(#config.metadata.name)-init"
						configMap: {
							name:        "\(#config.metadata.name)-init"
							defaultMode: 493
						}
					},
				]])
			}
		}
	}
}
