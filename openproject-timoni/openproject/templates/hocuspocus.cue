package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#HocuspocusDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-hocuspocus"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"openproject/process":        "hocuspocus"
			"app.kubernetes.io/component": "hocuspocus"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		strategy: type: #config.hocuspocus.strategy.type
		selector: matchLabels: {
			#config.selector.labels
			"openproject/process": "hocuspocus"
		}
		template: {
			metadata: {
				annotations: {
					if #config.podAnnotations != _|_ {
						#config.podAnnotations
					}
					"checksum/env-core":        "parity-checksum"
					"checksum/env-memcached":   "parity-checksum"
					"checksum/env-oidc":        "parity-checksum"
					"checksum/env-s3":          "parity-checksum"
					"checksum/env-environment": "parity-checksum"
				}
				labels: #config.metadata.labels & {
					"openproject/process":        "hocuspocus"
					"app.kubernetes.io/component": "hocuspocus"
				}
			}
			spec: corev1.#PodSpec & {
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.hocuspocus.nodeSelector != _|_ {
					nodeSelector: #config.hocuspocus.nodeSelector
				}
				if #config.podSecurityContext.enabled {
					securityContext: {
						fsGroup: #config.podSecurityContext.fsGroup
					}
				}
				if #config.runtimeClassName != "" {
					runtimeClassName: #config.runtimeClassName
				}
				serviceAccountName: #config.metadata.name
				volumes: [
					{
						name: "tmp"
						emptyDir: {}
					},
					if #config.egress.tls.rootCA.fileName != "" {
						{
							name: "ca-pemstore"
							configMap: name: #config.egress.tls.rootCA.configMap
						}
					},
				]
				containers: [{
					name: "hocuspocus"
					if #config.containerSecurityContext.enabled {
						securityContext: {
							runAsUser:                #config.containerSecurityContext.runAsUser
							runAsGroup:               #config.containerSecurityContext.runAsGroup
							allowPrivilegeEscalation: #config.containerSecurityContext.allowPrivilegeEscalation
							capabilities:             #config.containerSecurityContext.capabilities
							seccompProfile: type:   #config.containerSecurityContext.seccompProfile.type
							readOnlyRootFilesystem: ( !#config.develop && #config.containerSecurityContext.readOnlyRootFilesystem)
							runAsNonRoot:           #config.containerSecurityContext.runAsNonRoot
						}
					}
					image:           #config.hocuspocus.image.reference
					imagePullPolicy: #config.hocuspocus.image.imagePullPolicy
					env: [
						{
							name: "SECRET"
							valueFrom: secretKeyRef: {
								if #config.hocuspocus.auth.existingSecret != "" {
									name: #config.hocuspocus.auth.existingSecret
								}
								if #config.hocuspocus.auth.existingSecret == "" {
									name: "\(#config.metadata.name)-hocuspocus"
								}
								key: #config.hocuspocus.auth.secretKey
							}
						},
						{
							name:  "OPENPROJECT_URL"
							value: #config.hocuspocus.openproject_url
						},
						{
							name:  "OPENPROJECT_HTTPS"
							value: "\(#config.hocuspocus.https)"
						},
						{
							name:  "NODE_OPTIONS"
							value: "--dns-result-order=ipv4first"
						},
						if #config.egress.tls.rootCA.fileName != "" {
							{name: "NODE_EXTRA_CA_CERTS", value: "/etc/ssl/certs/custom-ca.pem"}
						},
					]
					volumeMounts: [
						{name: "tmp", mountPath: "/tmp"},
						if #config.egress.tls.rootCA.fileName != "" {
							{
								name:      "ca-pemstore"
								mountPath: "/etc/ssl/certs/custom-ca.pem"
								subPath:   #config.egress.tls.rootCA.fileName
								readOnly:  false
							}
						},
					]
					ports: [{
						name:          "http"
						containerPort: 1234
						protocol:      "TCP"
					}]
					resources: #config.hocuspocus.resources
				}]
			}
		}
	}
}
