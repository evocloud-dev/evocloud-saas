package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"list"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#DashboardDeployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-dashboard"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "dashboard"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.dashboard.autoscaling.enabled {
			replicas: #config.dashboard.replicaCount
		}
		selector: matchLabels: (timoniv1.#Selector & {#Name: "\(#config.metadata.name)-dashboard"}).labels & {
			"app.kubernetes.io/component": "dashboard"
		}
		template: {
			metadata: {
				labels: (timoniv1.#Selector & {#Name: "\(#config.metadata.name)-dashboard"}).labels & {
					"app.kubernetes.io/component": "dashboard"
				}
				if #config.dashboard.podAnnotations != _|_ {
					annotations: #config.dashboard.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.dashboard.imagePullSecrets != _|_ {
					imagePullSecrets: #config.dashboard.imagePullSecrets
				}
				serviceAccountName:           #config.metadata.name
				automountServiceAccountToken: false
				if #config.dashboard.podSecurityContext != _|_ {
					securityContext: #config.dashboard.podSecurityContext
				}
				if #config.dashboard.replicaCount > 1 {
					affinity: podAntiAffinity: preferredDuringSchedulingIgnoredDuringExecution: [
						{
							weight: 100
							podAffinityTerm: {
								labelSelector: matchExpressions: [
									{
										key:      "app.kubernetes.io/component"
										operator: "In"
										values: ["dashboard"]
									},
								]
								topologyKey: "kubernetes.io/hostname"
							}
						},
					]
				}
				initContainers: [
					{
						name: "copy-dashboard-files"
						image:           "\(#config.dashboard.image.repository):\(#config.dashboard.image.tag)"
						imagePullPolicy: #config.dashboard.image.pullPolicy
						command: ["sh", "-c", "cp -a /app/dashboard/. /mnt/dashboard/ && cp -a /etc/nginx/conf.d/. /mnt/nginx-conf/ && find /mnt/nginx-conf/ -type f -name '*.conf' -exec sed -i 's/80;/8080;/g' {} +"]
						securityContext: {
							allowPrivilegeEscalation: false
							capabilities: drop: ["ALL"]
							runAsNonRoot: true
							runAsUser:    10001
							runAsGroup:   10001
						}
						volumeMounts: [
							{
								name:      "dashboard-dir"
								mountPath: "/mnt/dashboard"
							},
							{
								name:      "nginx-conf"
								mountPath: "/mnt/nginx-conf"
							},
						]
					},
				]
				containers: [
					{
						name: "dashboard"
						if #config.dashboard.securityContext != _|_ {
							securityContext: #config.dashboard.securityContext
						}
						image:           "\(#config.dashboard.image.repository):\(#config.dashboard.image.tag)"
						imagePullPolicy: #config.dashboard.image.pullPolicy
						ports: [{
							name:          "http"
							containerPort: 8080
							protocol:      "TCP"
						}]
						livenessProbe: {
							httpGet: {
								path: "/"
								port: "http"
							}
							initialDelaySeconds: 30
							periodSeconds:       10
							timeoutSeconds:      5
							successThreshold:    1
							failureThreshold:    3
						}
						readinessProbe: {
							httpGet: {
								path: "/"
								port: "http"
							}
							initialDelaySeconds: 30
							periodSeconds:       10
							timeoutSeconds:      5
							successThreshold:    1
							failureThreshold:    3
						}
						resources: #config.dashboard.resources
						_tlsEnabled: #config.ingress.api.tls != []
						_protocol:   string | *"http"
						if _tlsEnabled {
							_protocol: "https"
						}
						env: list.Concat([
							[
								{
									name:  "API_URL"
									value: "\(_protocol)://\(#config.ingress.api.hosts[0].host)/graphql/"
								},
								{name: "APP_MOUNT_URI", value: "/dashboard/"},
								{name: "APPS_MARKETPLACE_API_URL", value: #config.dashboard.appsMarketplaceApiUrl},
								if #config.dashboard.appsExtensionsApiUrl != "" {
									{name: "EXTENSIONS_API_URL", value: #config.dashboard.appsExtensionsApiUrl}
								},
								{name: "IS_CLOUD_INSTANCE", value: "\(#config.#internal.isCloudInstance)"},
							],
							#config.dashboard.extraEnv,
						])
						volumeMounts: list.Concat([
							[
								{
									name:      "cache-dir"
									mountPath: "/var/cache/nginx"
								},
								{
									name:      "run-dir"
									mountPath: "/var/run"
								},
								{
									name:      "tmp-dir"
									mountPath: "/tmp"
								},
								{
									name:      "dashboard-dir"
									mountPath: "/app/dashboard"
								},
								{
									name:      "nginx-conf"
									mountPath: "/etc/nginx/conf.d"
								},
							],
							#config.dashboard.volumeMounts,
						])
					},
				]
				volumes: list.Concat([
					[
						{
							name: "cache-dir"
							emptyDir: {}
						},
						{
							name: "run-dir"
							emptyDir: {}
						},
						{
							name: "tmp-dir"
							emptyDir: {}
						},
						{
							name: "dashboard-dir"
							emptyDir: {}
						},
						{
							name: "nginx-conf"
							emptyDir: {}
						},
					],
					#config.dashboard.volumes,
				])
				if #config.dashboard.nodeSelector != _|_ {
					nodeSelector: #config.dashboard.nodeSelector
				}
				if #config.dashboard.tolerations != _|_ {
					tolerations: #config.dashboard.tolerations
				}
				if #config.dashboard.affinity != _|_ {
					affinity: #config.dashboard.affinity
				}
			}
		}
	}
}
