package templates

import (
	"list"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#NginxDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-nginx"
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
				"\(k)": v
			}
			"app.kubernetes.io/name":     "\(#config.metadata.name)-nginx"
			"app.kubernetes.io/instance": #config.metadata.name
			"app.kubernetes.io/app":      "frappe"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.nginx.autoscaling.enabled {
			replicas: #config.nginx.replicaCount
		}
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-nginx"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: {
				labels: {
					for k, v in #config.metadata.labels if k != "app.kubernetes.io/name" {
						"\(k)": v
					}
					"app.kubernetes.io/name":     "\(#config.metadata.name)-nginx"
					"app.kubernetes.io/instance": #config.metadata.name

					"app.kubernetes.io/app":      "frappe"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: #config.metadata.name
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.nginx.initContainers != _|_ {
					initContainers: #config.nginx.initContainers
				}
				containers: [
					{
						name:            "nginx"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						if #config.nginx.config != _|_ && #config.nginx.config != "" {
							args: ["nginx", "-g", "daemon off;"]
						}
						if #config.nginx.config == _|_ || #config.nginx.config == "" {
							args: ["nginx-entrypoint.sh"]
						}
						env: list.Concat([
							[
								{
									name:  "BACKEND"
									value: "\(#config.metadata.name)-gunicorn:8000"
								},
								{
									name:  "SOCKETIO"
									value: "\(#config.metadata.name)-socketio:9000"
								},
								{
									name:  "UPSTREAM_REAL_IP_ADDRESS"
									value: #config.nginx.environment.upstreamRealIPAddress
								},
								{
									name:  "UPSTREAM_REAL_IP_RECURSIVE"
									value: #config.nginx.environment.upstreamRealIPRecursive
								},
								{
									name:  "UPSTREAM_REAL_IP_HEADER"
									value: #config.nginx.environment.upstreamRealIPHeader
								},
								{
									name:  "FRAPPE_SITE_NAME_HEADER"
									value: #config.nginx.environment.frappeSiteNameHeader
								},
								{
									name:  "PROXY_READ_TIMEOUT"
									value: #config.nginx.environment.proxyReadTimeout
								},
								{
									name:  "CLIENT_MAX_BODY_SIZE"
									value: #config.nginx.environment.clientMaxBodySize
								},
							],
							#config.nginx.envVars,
						])
						ports: [
							{
								name:          "http"
								containerPort: #config.nginx.service.port
								protocol:      "TCP"
							},
						]
						livenessProbe:  #config.nginx.livenessProbe
						readinessProbe: #config.nginx.readinessProbe
						volumeMounts: list.Concat([
							[
								{
									mountPath: "/home/frappe/frappe-bench/sites"
									name:      "sites-dir"
								},
							],
							if #config.nginx.config != _|_ && #config.nginx.config != "" {
								[
									{
										mountPath: "/etc/nginx/conf.d"
										name:      "config"
									},
								]
							},
							if #config.nginx.config == _|_ || #config.nginx.config == "" {
								[]
							},
						])
						resources:       #config.nginx.resources
						securityContext: #config.securityContext
					},
				]
				volumes: list.Concat([
					[
						{
							name: "sites-dir"
							if #config.persistence.worker.enabled {
								persistentVolumeClaim: {
									if #config.persistence.worker.existingClaim != "" {
										claimName: #config.persistence.worker.existingClaim
									}
									if #config.persistence.worker.existingClaim == "" {
										claimName: #config.metadata.name
									}
									readOnly: false
								}
							}
							if !#config.persistence.worker.enabled {
								emptyDir: {}
							}
						},
					],
					if #config.nginx.config != _|_ && #config.nginx.config != "" {
						[
							{
								name: "config"
								configMap: {
									name: "\(#config.metadata.name)-nginx-config"
									items: [{
										key:  "default.conf"
										path: "default.conf"
									}]
								}
							},
						]
					},
					if #config.nginx.config == _|_ || #config.nginx.config == "" {
						[]
					},
				])
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
			}
		}
	}
}
