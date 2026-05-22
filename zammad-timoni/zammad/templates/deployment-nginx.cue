package templates

import (
	"list"

	appsv1 "k8s.io/api/apps/v1"
)

#DeploymentNginx: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-nginx"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zammad-nginx"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}

	spec: {
		replicas: #config.zammadConfig.nginx.replicas
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "zammad-nginx"
		}
		template: {
			metadata: {
				annotations: {
					if #config.podAnnotations != _|_ {
						#config.podAnnotations
					}
					if #config.zammadConfig.nginx.podAnnotations != _|_ {
						#config.zammadConfig.nginx.podAnnotations
					}
				}
				labels: #config.metadata.labels & {
					"app.kubernetes.io/component": "zammad-nginx"
					if #config.zammadConfig.nginx.podLabels != _|_ {
						#config.zammadConfig.nginx.podLabels
					}
				}
			}
			spec: #config._zammadPodSpecDeployment & {
				// 1. Nginx Deployment Specific Properties (Overrides global zammad.podSpec)
				if #config.zammadConfig.nginx.nodeSelector != _|_ {
					nodeSelector: #config.zammadConfig.nginx.nodeSelector
				}
				if #config.zammadConfig.nginx.nodeSelector == _|_ && #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}

				if #config.zammadConfig.nginx.affinity != _|_ {
					affinity: #config.zammadConfig.nginx.affinity
				}
				if #config.zammadConfig.nginx.affinity == _|_ && #config.affinity != _|_ {
					affinity: #config.affinity
				}

				if #config.zammadConfig.nginx.tolerations != _|_ {
					tolerations: #config.zammadConfig.nginx.tolerations
				}
				if #config.zammadConfig.nginx.tolerations == _|_ && #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}

				if #config.zammadConfig.nginx.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.zammadConfig.nginx.topologySpreadConstraints
				}
				if #config.zammadConfig.nginx.topologySpreadConstraints == _|_ && #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}

				// 2. Containers
				containers: [
					// Sidecars loop
					if #config.zammadConfig.nginx.sidecars != _|_ for sc in #config.zammadConfig.nginx.sidecars {sc},
					{
						name:            "zammad-nginx"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy

						command: [
							"/usr/sbin/nginx",
							"-g",
							"daemon off;",
						]

						// Container Config (startupProbe, livenessProbe, readinessProbe, resources, securityContext)
						if #config.zammadConfig.nginx.startupProbe != _|_ {
							startupProbe: #config.zammadConfig.nginx.startupProbe
						}
						if #config.zammadConfig.nginx.livenessProbe != _|_ {
							livenessProbe: #config.zammadConfig.nginx.livenessProbe
						}
						if #config.zammadConfig.nginx.readinessProbe != _|_ {
							readinessProbe: #config.zammadConfig.nginx.readinessProbe
						}
						if #config.zammadConfig.nginx.resources != _|_ {
							resources: #config.zammadConfig.nginx.resources
						}
						if #config.zammadConfig.nginx.securityContext != _|_ {
							securityContext: #config.zammadConfig.nginx.securityContext
						}

						// Resolving zammad.env + failOnPendingMigrations + extraEnv
						env: list.Concat([#config._zammadEnv, [
							{
								name:  "RAILS_CHECK_PENDING_MIGRATIONS"
								value: "true"
							},
						], [
							if #config.zammadConfig.nginx.extraEnv != _|_ for ee in #config.zammadConfig.nginx.extraEnv {ee},
						]])

						ports: [{
							name:          "http"
							containerPort: 8080
						}]

						// Resolving zammad.volumeMounts + nginx-specific mounts
						volumeMounts: list.Concat([#config._zammadVolumeMounts, [
							{
								name:      "\(#config.metadata.name)-nginx"
								mountPath: "/etc/nginx/nginx.conf"
								subPath:   "nginx.conf"
								readOnly:  true
							},
							{
								name:      "\(#config.metadata.name)-nginx"
								mountPath: "/etc/nginx/sites-enabled/default"
								subPath:   "default"
								readOnly:  true
							},
							{
								name:      "\(#config.metadata.name)-tmp"
								mountPath: "/var/log/nginx"
							},
						]])
					},
				]

				// 3. Volumes (zammad.volumes + nginx-specific volumes)
				volumes: list.Concat([#config._zammadVolumes, [
					{
						name: "\(#config.metadata.name)-init"
						configMap: {
							name:        "\(#config.metadata.name)-init"
							defaultMode: 493 // 0755
						}
					},
					{
						name: "\(#config.metadata.name)-nginx"
						configMap: name: "\(#config.metadata.name)-nginx"
					},
				]])
			}
		}
	}
}
