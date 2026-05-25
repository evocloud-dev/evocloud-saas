package templates

import (
	"list"

	appsv1 "k8s.io/api/apps/v1"
)

#DeploymentScheduler: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-scheduler"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zammad-scheduler"
		}
		annotations: {
			"checkov.io/skip1": "CKV_K8S_8=Liveness Probe Should be Configured - not possible with scheduler"
			"checkov.io/skip2": "CKV_K8S_9=Readiness Probe Should be Configured - not possible with scheduler"
			if #config.metadata.annotations != _|_ {
				#config.metadata.annotations
			}
		}
	}

	spec: {
		replicas: 1 // Not scalable, may only run once per cluster.
		strategy: type: "Recreate"
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "zammad-scheduler"
		}
		template: {
			metadata: {
				annotations: {
					if #config.podAnnotations != _|_ {
						#config.podAnnotations
					}
					if #config.zammadConfig.scheduler.podAnnotations != _|_ {
						#config.zammadConfig.scheduler.podAnnotations
					}
				}
				labels: #config.metadata.labels & {
					"app.kubernetes.io/component": "zammad-scheduler"
					if #config.zammadConfig.scheduler.podLabels != _|_ {
						#config.zammadConfig.scheduler.podLabels
					}
				}
			}
			spec: #config._zammadPodSpecDeployment & {
				// 1. Scheduler Deployment Specific Properties (Overrides global zammad.podSpec)
				if #config.zammadConfig.scheduler.nodeSelector != _|_ {
					nodeSelector: #config.zammadConfig.scheduler.nodeSelector
				}
				if #config.zammadConfig.scheduler.nodeSelector == _|_ && #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}

				if #config.zammadConfig.scheduler.affinity != _|_ {
					affinity: #config.zammadConfig.scheduler.affinity
				}
				if #config.zammadConfig.scheduler.affinity == _|_ && #config.affinity != _|_ {
					affinity: #config.affinity
				}

				if #config.zammadConfig.scheduler.tolerations != _|_ {
					tolerations: #config.zammadConfig.scheduler.tolerations
				}
				if #config.zammadConfig.scheduler.tolerations == _|_ && #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}

				if #config.zammadConfig.scheduler.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.zammadConfig.scheduler.topologySpreadConstraints
				}
				if #config.zammadConfig.scheduler.topologySpreadConstraints == _|_ && #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}

				// 2. Containers
				containers: [
					// Sidecars loop
					if #config.zammadConfig.scheduler.sidecars != _|_ for sc in #config.zammadConfig.scheduler.sidecars {sc},
					{
						name:            "zammad-scheduler"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy

						// Container Config (startupProbe, resources, etc.)
						if #config.zammadConfig.scheduler.startupProbe != _|_ {
							startupProbe: #config.zammadConfig.scheduler.startupProbe
						}
						if #config.zammadConfig.scheduler.livenessProbe != _|_ {
							livenessProbe: #config.zammadConfig.scheduler.livenessProbe
						}
						if #config.zammadConfig.scheduler.readinessProbe != _|_ {
							readinessProbe: #config.zammadConfig.scheduler.readinessProbe
						}
						if #config.zammadConfig.scheduler.resources != _|_ {
							resources: #config.zammadConfig.scheduler.resources
						}
						if #config.zammadConfig.scheduler.securityContext != _|_ {
							securityContext: #config.zammadConfig.scheduler.securityContext
						}

						command: [
							"bundle",
							"exec",
							"script/background-worker.rb",
							"start",
						]

						// Resolving zammad.env + failOnPendingMigrations + extraEnv
						env: list.Concat([#config._zammadEnv, [
							{
								name:  "RAILS_CHECK_PENDING_MIGRATIONS"
								value: "true"
							},
						], [
							if #config.zammadConfig.scheduler.extraEnv != _|_ for ee in #config.zammadConfig.scheduler.extraEnv {ee},
						]])

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
