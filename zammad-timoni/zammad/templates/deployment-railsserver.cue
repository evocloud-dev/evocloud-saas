package templates

import (
	"list"

	appsv1 "k8s.io/api/apps/v1"
)

#DeploymentRailsserver: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-railsserver"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zammad-railsserver"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}

	spec: {
		replicas: #config.zammadConfig.railsserver.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "zammad-railsserver"
		}
		template: {
			metadata: {
				annotations: {
					if #config.podAnnotations != _|_ {
						#config.podAnnotations
					}
					if #config.zammadConfig.railsserver.podAnnotations != _|_ {
						#config.zammadConfig.railsserver.podAnnotations
					}
				}
				labels: #config.metadata.labels & {
					"app.kubernetes.io/component": "zammad-railsserver"
					if #config.zammadConfig.railsserver.podLabels != _|_ {
						#config.zammadConfig.railsserver.podLabels
					}
				}
			}
			spec: #config._zammadPodSpecDeployment & {
				// 1. Railsserver Deployment Specific Properties (Overrides global zammad.podSpec)
				if #config.zammadConfig.railsserver.nodeSelector != _|_ {
					nodeSelector: #config.zammadConfig.railsserver.nodeSelector
				}
				if #config.zammadConfig.railsserver.nodeSelector == _|_ && #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}

				if #config.zammadConfig.railsserver.affinity != _|_ {
					affinity: #config.zammadConfig.railsserver.affinity
				}
				if #config.zammadConfig.railsserver.affinity == _|_ && #config.affinity != _|_ {
					affinity: #config.affinity
				}

				if #config.zammadConfig.railsserver.tolerations != _|_ {
					tolerations: #config.zammadConfig.railsserver.tolerations
				}
				if #config.zammadConfig.railsserver.tolerations == _|_ && #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}

				if #config.zammadConfig.railsserver.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.zammadConfig.railsserver.topologySpreadConstraints
				}
				if #config.zammadConfig.railsserver.topologySpreadConstraints == _|_ && #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}

				// 2. Containers
				containers: [
					// Sidecars loop
					if #config.zammadConfig.railsserver.sidecars != _|_ for sc in #config.zammadConfig.railsserver.sidecars {sc},
					{
						name:            "zammad-railsserver"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy

						// Container Config (startupProbe, resources, etc.)
						if #config.zammadConfig.railsserver.startupProbe != _|_ {
							startupProbe: #config.zammadConfig.railsserver.startupProbe
						}
						if #config.zammadConfig.railsserver.livenessProbe != _|_ {
							livenessProbe: #config.zammadConfig.railsserver.livenessProbe
						}
						if #config.zammadConfig.railsserver.readinessProbe != _|_ {
							readinessProbe: #config.zammadConfig.railsserver.readinessProbe
						}
						if #config.zammadConfig.railsserver.resources != _|_ {
							resources: #config.zammadConfig.railsserver.resources
						}
						if #config.zammadConfig.railsserver.securityContext != _|_ {
							securityContext: #config.zammadConfig.railsserver.securityContext
						}

						command: [
							"bundle",
							"exec",
							"puma",
							"-b",
							"tcp://\(#config.zammadConfig.railsserver.listenAddress):3000",
							"-w",
							"\(#config.zammadConfig.railsserver.webConcurrency)",
							"-e",
							"production",
						]

						// Resolving zammad.env + failOnPendingMigrations + extraEnv
						env: list.Concat([#config._zammadEnv, [
							{
								name:  "RAILS_CHECK_PENDING_MIGRATIONS"
								value: "true"
							},
						], [
							if #config.zammadConfig.railsserver.extraEnv != _|_ for ee in #config.zammadConfig.railsserver.extraEnv {ee},
						]])

						ports: [{
							name:          "railsserver"
							containerPort: 3000
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
