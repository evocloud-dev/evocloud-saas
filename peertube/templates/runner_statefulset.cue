package templates

import (
	"strings"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#RunnerStatefulSet: appsv1.#StatefulSet & {
	#config:    #Config
	#group:     _
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      *"\((#config.metadata.name))-runner-\(#group.id)" | string
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "runner"
			"peertube.runner/group":       #group.id
		}
		if #config.runner.annotations != _|_ {
			annotations: #config.runner.annotations
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: *"\((#config.metadata.name))-runner-headless" | string
		replicas:    #group.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "runner"
			"peertube.runner/group":       #group.id
		}
		template: {
			metadata: {
				labels: #config.metadata.labels & #config.runner.podLabels & {
					"app.kubernetes.io/component": "runner"
					"peertube.runner/group":       #group.id
				}
				if #config.runner.podAnnotations != _|_ {
					annotations: #config.runner.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.runner.podSecurityContext != _|_ {
					securityContext: #config.runner.podSecurityContext
				}
				serviceAccountName: *"\((#config.metadata.name))-runner" | string
				if !#config.runner.serviceAccount.create && #config.runner.serviceAccount.name != "" {
					serviceAccountName: #config.runner.serviceAccount.name
				}
				if !#config.runner.serviceAccount.create && #config.runner.serviceAccount.name == "" {
					serviceAccountName: "default"
				}
				automountServiceAccountToken: false
				enableServiceLinks:           false

				if #config.runner.dnsPolicy != null {
					dnsPolicy: #config.runner.dnsPolicy
				}
				if #config.runner.dnsConfig != null {
					dnsConfig: #config.runner.dnsConfig
				}
				if #config.runner.hostNetwork {
					hostNetwork: true
				}

				#realRegistry: {
					if #config.global.image.registry != null && #config.global.image.registry != "" {
						#config.global.image.registry
					}
					if #config.global.image.registry == null || #config.global.image.registry == "" {
						#config.runner.container.image.registry
					}
				}
				#realTag: {
					if #config.runner.container.image.tag != "" {
						#config.runner.container.image.tag
					}
					if #config.runner.container.image.tag == "" {
						#config.moduleVersion
					}
				}
				#imageRef: "\(#realRegistry)/\(#config.runner.container.image.repository):\(#realTag)"
				#runnerSecretName: {
					if #group.config.existingSecret != "" {
						#group.config.existingSecret
					}
					if #group.config.existingSecret == "" {
						"\(#config.metadata.name)-runner-\(#group.id)-secret"
					}
				}

				#realPullPolicy: {
					if #config.global.image.pullPolicy != null && #config.global.image.pullPolicy != "" {
						#config.global.image.pullPolicy
					}
					if #config.global.image.pullPolicy == null || #config.global.image.pullPolicy == "" {
						if #config.runner.container.image.pullPolicy != _|_ && #config.runner.container.image.pullPolicy != "" {
							#config.runner.container.image.pullPolicy
						}
						if #config.runner.container.image.pullPolicy == _|_ || #config.runner.container.image.pullPolicy == "" {
							"IfNotPresent"
						}
					}
				}

				#realImagePullSecrets: {
					if len(#config.runner.imagePullSecrets) > 0 {
						#config.runner.imagePullSecrets
					}
					if len(#config.runner.imagePullSecrets) == 0 {
						#config.global.imagePullSecrets
					}
				}
				if len(#realImagePullSecrets) > 0 {
					imagePullSecrets: #realImagePullSecrets
				}

				if #config.runner.nodeSelector != _|_ && len(#config.runner.nodeSelector) > 0 {
					nodeSelector: #config.runner.nodeSelector
				}
				if (#config.runner.nodeSelector == _|_ || len(#config.runner.nodeSelector) == 0) && len(#config.global.nodeSelector) > 0 {
					nodeSelector: #config.global.nodeSelector
				}

				if #config.runner.tolerations != _|_ && len(#config.runner.tolerations) > 0 {
					tolerations: #config.runner.tolerations
				}
				if (#config.runner.tolerations == _|_ || len(#config.runner.tolerations) == 0) && len(#config.global.tolerations) > 0 {
					tolerations: #config.global.tolerations
				}

				if #config.runner.antiAffinity.enabled || #config.runner.podAntiAffinity != _|_ || #config.runner.podAffinity != _|_ || #config.runner.nodeAffinity != _|_ {
					affinity: {
						if #config.runner.antiAffinity.enabled && #config.runner.podAntiAffinity != _|_ {
							podAntiAffinity: #config.runner.podAntiAffinity
						}
						if #config.runner.podAffinity != _|_ {
							podAffinity: #config.runner.podAffinity
						}
						if #config.runner.nodeAffinity != _|_ {
							nodeAffinity: #config.runner.nodeAffinity
						}
					}
				}

				#jobTypesStr: strings.Join(#group.jobTypes, ",")

				#unregisterStr: *"false" | string
				if #group.config.unregisterOnExit {
					#unregisterStr: "true"
				}

				initContainers: [
					for ic in #config.runner.extraInitContainers {ic},
					{
						name:  "register"
						image: #imageRef
						if #config.runner.initContainer.resources != _|_ {
							resources: #config.runner.initContainer.resources
						}
						imagePullPolicy: #realPullPolicy
						args: ["bootstrap"]
						env: [
							{
								name:  "HOME"
								value: "/home/peertube"
							},
							{
								name:  "XDG_CONFIG_HOME"
								value: "/home/peertube/.config"
							},
							{
								name:  "XDG_CACHE_HOME"
								value: "/home/peertube/.cache"
							},
							{
								name:  "XDG_DATA_HOME"
								value: "/home/peertube/.local/share"
							},
							{
								name: "POD_NAME"
								valueFrom: fieldRef: fieldPath: "metadata.name"
							},
							{
								name:  "RUNNER_GROUP_ID"
								value: #group.id
							},
							{
								name: "PEERTUBE_URL"
								valueFrom: secretKeyRef: {
									name: #runnerSecretName
									key:  "runner-url"
								}
							},
							{
								name: "REGISTRATION_TOKEN"
								valueFrom: secretKeyRef: {
									name: #runnerSecretName
									key:  "registration-token"
								}
							},
							{
								name:  "ENABLE_JOBS"
								value: #jobTypesStr
							},
							{
								name:  "UNREGISTER_ON_EXIT"
								value: #unregisterStr
							},
							for e in #config.global.extraEnvVars {e},
							for e in #config.runner.initContainer.extraEnvVars {e},
						]
						volumeMounts: [
							{
								name:      "home"
								mountPath: "/home/peertube"
							},
							{
								name:      "runner-config"
								mountPath: "/bootstrap"
								readOnly:  true
							},
						]
					},
				]

				containers: [
					for c in #config.runner.extraContainers {c},
					{
						name:            "runner"
						image:           #imageRef
						imagePullPolicy: #realPullPolicy
						env: [
							{
								name:  "HOME"
								value: "/home/peertube"
							},
							{
								name:  "XDG_CONFIG_HOME"
								value: "/home/peertube/.config"
							},
							{
								name:  "XDG_CACHE_HOME"
								value: "/home/peertube/.cache"
							},
							{
								name:  "XDG_DATA_HOME"
								value: "/home/peertube/.local/share"
							},
							{
								name: "POD_NAME"
								valueFrom: fieldRef: fieldPath: "metadata.name"
							},
							{
								name:  "RUNNER_GROUP_ID"
								value: #group.id
							},
							{
								name: "PEERTUBE_URL"
								valueFrom: secretKeyRef: {
									name: #runnerSecretName
									key:  "runner-url"
								}
							},
							{
								name: "REGISTRATION_TOKEN"
								valueFrom: secretKeyRef: {
									name: #runnerSecretName
									key:  "registration-token"
								}
							},
							{
								name:  "ENABLE_JOBS"
								value: #jobTypesStr
							},
							{
								name:  "UNREGISTER_ON_EXIT"
								value: #unregisterStr
							},
							for e in #config.global.extraEnvVars {e},
							for e in #config.runner.container.extraEnvVars {e},
						]
						if #config.runner.container.resources != _|_ {
							resources: #config.runner.container.resources
						}
						if #config.runner.startupProbe != _|_ {
							startupProbe: #config.runner.startupProbe
						}
						if #config.runner.livenessProbe != _|_ {
							livenessProbe: #config.runner.livenessProbe
						}
						if #config.runner.readinessProbe != _|_ {
							readinessProbe: #config.runner.readinessProbe
						}
						volumeMounts: [
							{
								name:      "home"
								mountPath: "/home/peertube"
							},
						]
					},
				]

				#configMapName: *"\((#config.metadata.name))-runner-\(#group.id)-config" | string
				if #group.config.configMapName != _|_ && #group.config.configMapName != null {
					#configMapName: #group.config.configMapName
				}

				volumes: [
					{
						name: "runner-config"
						configMap: name: #configMapName
					},
				]
			}
		}
		volumeClaimTemplates: [
			if #config.runner.persistence.enabled {
				{
					metadata: {
						name: "home"
						if #config.runner.persistence.annotations != _|_ {
							annotations: #config.runner.persistence.annotations
						}
					}
					spec: {
						accessModes: [#config.runner.persistence.accessMode]
						resources: requests: storage: #config.runner.persistence.size
						if #config.runner.persistence.storageClass != "" {
							storageClassName: #config.runner.persistence.storageClass
						}
					}
				}
			}
		]
	}
}
