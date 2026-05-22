package templates

import (
	"list"

	appsv1 "k8s.io/api/apps/v1"
)

#DeploymentWebsocket: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-websocket"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zammad-websocket"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}

	spec: {
		replicas: 1 // Not scalable, may only run once per cluster.
		strategy: type: "Recreate"
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "zammad-websocket"
		}
		template: {
			metadata: {
				annotations: {
					if #config.podAnnotations != _|_ {
						#config.podAnnotations
					}
					if #config.zammadConfig.websocket.podAnnotations != _|_ {
						#config.zammadConfig.websocket.podAnnotations
					}
				}
				labels: #config.metadata.labels & {
					"app.kubernetes.io/component": "zammad-websocket"
					if #config.zammadConfig.websocket.podLabels != _|_ {
						#config.zammadConfig.websocket.podLabels
					}
				}
			}
			spec: #config._zammadPodSpecDeployment & {
				// 1. Websocket Properties (Inherits globals directly, no specific overrides exist in YAML)
				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}

				if #config.affinity != _|_ {
					affinity: #config.affinity
				}

				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}

				if #config.zammadConfig.websocket.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.zammadConfig.websocket.topologySpreadConstraints
				}

				// 2. Containers
				containers: [
					// Sidecars loop
					if #config.zammadConfig.websocket.sidecars != _|_ for sc in #config.zammadConfig.websocket.sidecars {sc},
					{
						name:            "zammad-websocket"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy

						// Container Config (startupProbe, resources, etc.)
						if #config.zammadConfig.websocket.startupProbe != _|_ {
							startupProbe: #config.zammadConfig.websocket.startupProbe
						}
						if #config.zammadConfig.websocket.livenessProbe != _|_ {
							livenessProbe: #config.zammadConfig.websocket.livenessProbe
						}
						if #config.zammadConfig.websocket.readinessProbe != _|_ {
							readinessProbe: #config.zammadConfig.websocket.readinessProbe
						}
						if #config.zammadConfig.websocket.resources != _|_ {
							resources: #config.zammadConfig.websocket.resources
						}
						if #config.zammadConfig.websocket.securityContext != _|_ {
							securityContext: #config.zammadConfig.websocket.securityContext
						}

						command: [
							"bundle",
							"exec",
							"script/websocket-server.rb",
							"-b",
							"\(#config.zammadConfig.websocket.listenAddress)",
							"-p",
							"6042",
							"start",
						]

						// Resolving zammad.env + failOnPendingMigrations + extraEnv
						env: list.Concat([#config._zammadEnv, [
							{
								name:  "RAILS_CHECK_PENDING_MIGRATIONS"
								value: "true"
							},
						], [
							if #config.zammadConfig.websocket.extraEnv != _|_ for ee in #config.zammadConfig.websocket.extraEnv {ee},
						]])

						ports: [{
							name:          "websocket"
							containerPort: 6042
						}]

						// Resolving zammad.volumeMounts
						volumeMounts: #config._zammadVolumeMounts
					},
				]

				// 3. Volumes (zammad.volumes)
				volumes: #config._zammadVolumes
			}
		}
	}
}
