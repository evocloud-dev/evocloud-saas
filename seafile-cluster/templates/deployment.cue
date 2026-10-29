package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#DeploymentFrontend: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-frontend"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.configs.seafileFrontendReplicas
		selector: matchLabels: app: "\(#config.metadata.name)-frontend"
		template: {
			metadata: {
				labels: {
					app: "\(#config.metadata.name)-frontend"
					if #config.podLabels != _|_ {
						for k, v in #config.podLabels {
							"\(k)": v
						}
					}
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				enableServiceLinks: false
				if #config.serviceAccountName != _|_ {
					serviceAccountName: #config.serviceAccountName
				}
				if #config.automountServiceAccountToken != _|_ {
					automountServiceAccountToken: #config.automountServiceAccountToken
				}
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.#dataVolumeEnabled {
					initContainers: [{
						name:    "set-ownership"
						image:   #config.initContainerImage
						command: ["sh", "-c", "chown -R root:root /shared"]
						volumeMounts: [{
							name:      "seafile-data"
							mountPath: "/shared"
						}]
					}]
				}
				containers: [{
					name:  "seafile-frontend"
					image: #config.configs.image | #config.image
					if #config.securityContext != _|_ {
						securityContext: #config.securityContext
					}
					env: [
						{
							name:  "CLUSTER_INIT_MODE"
							value: "\(#config.initMode)"
						},
						{
							name:  "CLUSTER_SERVER"
							value: "true"
						},
						{
							name:  "CLUSTER_MODE"
							value: "frontend"
						},
						{
							name: "SEAFILE_AI_SECRET_KEY"
							valueFrom: secretKeyRef: {
								name: "\(#config.metadata.name)-secret"
								key:  "JWT_PRIVATE_KEY"
							}
						},
						for e in #config.extraEnv.frontend {e},
					]
					envFrom: [
						{configMapRef: name: "\(#config.metadata.name)-env"},
						{secretRef: name: "\(#config.metadata.name)-secret"},
					]
					ports: [{
						containerPort: 80
					}]
					if #config.#dataVolumeEnabled {
						volumeMounts: [
							{
								name:      "seafile-data"
								mountPath: "/shared"
							},
							for v in #config.extraVolumes.frontend {
								name:      v.name
								mountPath: v.mountPath
								if v.subPath != _|_ {
									subPath: v.subPath
								}
								if v.readOnly != _|_ {
									readOnly: v.readOnly
								}
							},
						]
					}
					resources: #config.extraResources.frontend
				}]
				if #config.#dataVolumeEnabled {
					volumes: [
						{
							name: "seafile-data"
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-data"
						},
						for v in #config.extraVolumes.frontend {
							v.volumeInfo & {name: v.name}
						},
					]
				}
				restartPolicy:    "Always"
				imagePullSecrets: #config.imagePullSecrets
				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
			}
		}
	}
}

#DeploymentBackend: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-backend"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: app: "\(#config.metadata.name)-backend"
		template: {
			metadata: {
				labels: {
					app: "\(#config.metadata.name)-backend"
					if #config.podLabels != _|_ {
						for k, v in #config.podLabels {
							"\(k)": v
						}
					}
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				enableServiceLinks: false
				if #config.serviceAccountName != _|_ {
					serviceAccountName: #config.serviceAccountName
				}
				if #config.automountServiceAccountToken != _|_ {
					automountServiceAccountToken: #config.automountServiceAccountToken
				}
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.#dataVolumeEnabled {
					initContainers: [{
						name:    "set-ownership"
						image:   #config.initContainerImage
						command: ["sh", "-c", "chown -R root:root /shared"]
						volumeMounts: [{
							name:      "seafile-data"
							mountPath: "/shared"
						}]
					}]
				}
				containers: [{
					name:  "seafile-backend"
					image: #config.configs.image | #config.image
					if #config.securityContext != _|_ {
						securityContext: #config.securityContext
					}
					env: [
						{
							name:  "CLUSTER_INIT_MODE"
							value: "\(#config.initMode)"
						},
						{
							name:  "CLUSTER_SERVER"
							value: "true"
						},
						{
							name:  "CLUSTER_MODE"
							value: "backend"
						},
						{
							name: "SEAFILE_AI_SECRET_KEY"
							valueFrom: secretKeyRef: {
								name: "\(#config.metadata.name)-secret"
								key:  "JWT_PRIVATE_KEY"
							}
						},
						for e in #config.extraEnv.backend {e},
					]
					envFrom: [
						{configMapRef: name: "\(#config.metadata.name)-env"},
						{secretRef: name: "\(#config.metadata.name)-secret"},
					]
					if #config.#dataVolumeEnabled {
						volumeMounts: [
							{
								name:      "seafile-data"
								mountPath: "/shared"
							},
							for v in #config.extraVolumes.backend {
								name:      v.name
								mountPath: v.mountPath
								if v.subPath != _|_ {
									subPath: v.subPath
								}
								if v.readOnly != _|_ {
									readOnly: v.readOnly
								}
							},
						]
					}
					resources: #config.extraResources.backend
				}]
				if #config.#dataVolumeEnabled {
					volumes: [
						{
							name: "seafile-data"
							persistentVolumeClaim: claimName: "\(#config.metadata.name)-data"
						},
						for v in #config.extraVolumes.backend {
							v.volumeInfo & {name: v.name}
						},
					]
				}
				restartPolicy:    "Always"
				imagePullSecrets: #config.imagePullSecrets
				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
			}
		}
	}
}
