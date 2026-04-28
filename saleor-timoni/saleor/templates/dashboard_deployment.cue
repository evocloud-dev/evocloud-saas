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
				serviceAccountName: #config.metadata.name
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
							containerPort: 80
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
						if #config.dashboard.volumeMounts != [] {
							volumeMounts: #config.dashboard.volumeMounts
						}
					},
				]
				if #config.dashboard.volumes != [] {
					volumes: #config.dashboard.volumes
				}
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
