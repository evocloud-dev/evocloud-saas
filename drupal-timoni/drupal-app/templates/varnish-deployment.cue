package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"list"
)

#VarnishDeployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "varnish"
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.varnish.replicaCount
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "varnish"
		}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "varnish"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.varnish.nodeSelector != _|_ {
					nodeSelector: #config.varnish.nodeSelector
				}
				if #config.varnish.tolerations != _|_ {
					tolerations: #config.varnish.tolerations
				}
				if #config.varnish.affinity != _|_ {
					affinity: #config.varnish.affinity
				}
				if #config.varnish.varnishd.imagePullSecrets != _|_ {
					imagePullSecrets: #config.varnish.varnishd.imagePullSecrets
				}
				containers: [
					{
						name:  "varnish"
						image: #config.varnish.varnishd.image + ":" + [ if #config.varnish.varnishd.tag != "" { #config.varnish.varnishd.tag }, #config.moduleVersion ][0]
						imagePullPolicy: #config.varnish.varnishd.imagePullPolicy
						command: [
							"varnishd",
							"-F",
							"-f",
							"/etc/varnish/default.vcl",
							"-a",
							"http=:\(#config.varnish.service.port),HTTP",
							if #config.varnish.admin.enabled {
								"-T"
							},
							if #config.varnish.admin.enabled {
								"0.0.0.0:\(#config.varnish.admin.port)"
							},
							if #config.varnish.admin.enabled {
								"-S"
							},
							if #config.varnish.admin.enabled {
								"/etc/varnish/secret"
							},
							"-p",
							"feature=+http2",
							"-s",
							"malloc,\(#config.varnish.memorySize)",
							"-n",
							"/tmp/varnish_workdir",
						]
						volumeMounts: list.Concat([
							[
								{
									name:      "varnish-config"
									mountPath: "/etc/varnish/default.vcl"
									subPath:   "default.vcl"
								},
								if #config.varnish.admin.enabled {
									{
										name:      "varnish-secret"
										mountPath: "/etc/varnish/secret"
										subPath:   "secret"
									}
								},
								{
									name:      "tmp"
									mountPath: "/tmp"
								},
							],
							#config.varnish.volumeMounts,
						])
						ports: [
							{
								name:          "http"
								containerPort: #config.varnish.service.port
								protocol:      "TCP"
							},
							if #config.varnish.admin.enabled {
								{
									name:          "tcp-admin"
									containerPort: #config.varnish.admin.port
									protocol:      "TCP"
								}
							},
						]
						resources: #config.varnish.resources
						securityContext: {
							runAsUser:    999
							runAsGroup:   999
							runAsNonRoot: true
						}
					},
				]
				volumes: list.Concat([
					[
						{
							name: "varnish-config"
							configMap: name: #config.metadata.name + "-varnish"
						},
						if #config.varnish.admin.enabled {
							{
								name: "varnish-secret"
								secret: secretName: #config.metadata.name + "-varnish"
							}
						},
						{
							name: "tmp"
							emptyDir: {}
						},
					],
					#config.varnish.volumes,
				])
			}
		}
	}
}
