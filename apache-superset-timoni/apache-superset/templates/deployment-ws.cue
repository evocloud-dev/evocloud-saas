package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
)

#DeploymentWs: {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-ws"
		namespace: #config.metadata.namespace
		labels: {
			app:      "\(#config.name)-ws"
			chart:    #config.metadata.labels.chart
			release:  #config.metadata.labels.release
			heritage: #config.metadata.labels.heritage
		} & #config.extraLabels
		if #config.supersetWebsockets.deploymentAnnotations != _|_ {
			annotations: #config.supersetWebsockets.deploymentAnnotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.supersetWebsockets.replicaCount
		if len(#config.supersetWebsockets.strategy) > 0 {
			strategy: #config.supersetWebsockets.strategy
		}
		selector: matchLabels: {
			app:     "\(#config.name)-ws"
			release: #config.metadata.name
		}
		template: {
			metadata: {
				annotations: {
					"checksum/config":  hex.Encode(sha256.Sum256(#config.supersetConfig))
					"checksum/secrets": hex.Encode(sha256.Sum256(json.Marshal(#config.supersetWebsockets.config)))
				} & #config.supersetWebsockets.podAnnotations
				labels: {
					app:     "\(#config.name)-ws"
					release: #config.metadata.name
				} & #config.extraLabels & #config.supersetWebsockets.podLabels
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
				} & #config.supersetWebsockets.podSecurityContext
				if len(#config.hostAliases) > 0 {
					hostAliases: #config.hostAliases
				}
				containers: [{
					name:            "\(#config.name)-ws"
					image:           "\(#config.supersetWebsockets.image.repository):\(#config.supersetWebsockets.image.tag)"
					imagePullPolicy: #config.supersetWebsockets.image.pullPolicy
					if #config.supersetWebsockets.containerSecurityContext != _|_ {
						securityContext: #config.supersetWebsockets.containerSecurityContext
					}
					if len(#config.supersetWebsockets.command) > 0 {
						command: #config.supersetWebsockets.command
					}
					env: [
						for k, v in #config.extraEnv {
							name:  k
							value: v
						},
						for e in #config.extraEnvRaw {e},
					]
					ports: [{name: "ws", containerPort: #config.supersetWebsockets.config.port, protocol: "TCP"}]
					volumeMounts: [{
						name:      "config"
						mountPath: "/home/superset-websocket/config.json"
						subPath:   "config.json"
						readOnly:  true
					}]
					if #config.supersetWebsockets.startupProbe != _|_ && len(#config.supersetWebsockets.startupProbe) > 0 {
						startupProbe: #config.supersetWebsockets.startupProbe
					}
					if #config.supersetWebsockets.readinessProbe != _|_ && len(#config.supersetWebsockets.readinessProbe) > 0 {
						readinessProbe: #config.supersetWebsockets.readinessProbe
					}
					if #config.supersetWebsockets.livenessProbe != _|_ && len(#config.supersetWebsockets.livenessProbe) > 0 {
						livenessProbe: #config.supersetWebsockets.livenessProbe
					}
					if #config.supersetWebsockets.resources != _|_ && len(#config.supersetWebsockets.resources) > 0 {
						resources: #config.supersetWebsockets.resources
					}
				}]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 || len(#config.supersetWebsockets.affinity) > 0 {
					affinity: #config.affinity & #config.supersetWebsockets.affinity
				}
				if #config.supersetWebsockets.priorityClassName != null {priorityClassName: #config.supersetWebsockets.priorityClassName}
				if len(#config.tolerations) > 0 {tolerations: #config.tolerations}
				if len(#config.imagePullSecrets) > 0 {imagePullSecrets: #config.imagePullSecrets}
				volumes: [{
					name: "config"
					secret: secretName: "\(#config.metadata.name)-ws-config"
				}]
			}
		}
	}
}
