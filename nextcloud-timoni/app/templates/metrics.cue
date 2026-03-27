package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MetricsDeployment: appsv1.#Deployment & {
	#in:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		for k, v in #in.metadata if k != "name" {
			"\(k)": v
		}
		name:      "\(#in.metadata.name)-metrics"
		labels: {
			"app.kubernetes.io/component": "metrics"
		}
	}
	spec: {
		replicas: #in.metrics.replicaCount
		selector: matchLabels: #in.selector.labels & {
			"app.kubernetes.io/component": "metrics"
		}
		template: {
			metadata: {
				labels: #in.metadata.labels & {
					"app.kubernetes.io/component": "metrics"
					if #in.metrics.podLabels != _|_ {
						for k, v in #in.metrics.podLabels {"\(k)": v}
					}
				}
				if #in.metrics.podAnnotations != _|_ {
					annotations: #in.metrics.podAnnotations
				}
			}
			spec: {
				if #in.imagePullSecrets != _|_ {
					imagePullSecrets: #in.imagePullSecrets
				}
				let _serverUrl = [
					if #in.metrics.server != "" {#in.metrics.server},
					if #in.metrics.server == "" && #in.metrics.https {"https://\(#in.metadata.name).\(#in.metadata.namespace).svc.cluster.local:\(#in.service.port)"},
					if #in.metrics.server == "" && !#in.metrics.https {"http://\(#in.metadata.name).\(#in.metadata.namespace).svc.cluster.local:\(#in.service.port)"},
				][0]

				let _authSecretName = [
					if #in.nextcloud.existingSecret.enabled {#in.nextcloud.existingSecret.secretName},
					if !#in.nextcloud.existingSecret.enabled {#in.metadata.name},
				][0]

				containers: [
					{
						name:            "metrics-exporter"
						image:           #in.metrics.image.reference
						imagePullPolicy: #in.metrics.image.pullPolicy
						env: [
							if #in.metrics.token != "" || #in.nextcloud.existingSecret.tokenKey != "" {
								{
									name: "NEXTCLOUD_AUTH_TOKEN"
									valueFrom: secretKeyRef: {
										name: _authSecretName
										if #in.nextcloud.existingSecret.enabled {
											key: #in.nextcloud.existingSecret.tokenKey
										}
										if !#in.nextcloud.existingSecret.enabled {
											key: "nextcloud-token"
										}
									}
								}
							},
							if #in.metrics.token == "" && #in.nextcloud.existingSecret.tokenKey == "" {
								{
									name: "NEXTCLOUD_USERNAME"
									valueFrom: secretKeyRef: {
										name: _authSecretName
										if #in.nextcloud.existingSecret.enabled {
											key: #in.nextcloud.existingSecret.usernameKey
										}
										if !#in.nextcloud.existingSecret.enabled {
											key: "nextcloud-username"
										}
									}
								}
							},
							if #in.metrics.token == "" && #in.nextcloud.existingSecret.tokenKey == "" {
								{
									name: "NEXTCLOUD_PASSWORD"
									valueFrom: secretKeyRef: {
										name: _authSecretName
										if #in.nextcloud.existingSecret.enabled {
											key: #in.nextcloud.existingSecret.passwordKey
										}
										if !#in.nextcloud.existingSecret.enabled {
											key: "nextcloud-password"
										}
									}
								}
							},
							{
								name:  "NEXTCLOUD_SERVER"
								value: _serverUrl
							},
							{
								name:  "NEXTCLOUD_TIMEOUT"
								value: #in.metrics.timeout
							},
							{
								name:  "NEXTCLOUD_TLS_SKIP_VERIFY"
								value: "\(#in.metrics.tlsSkipVerify)"
							},
							{
								name:  "NEXTCLOUD_INFO_APPS"
								value: "\(#in.metrics.info.apps)"
							},
							{
								name:  "NEXTCLOUD_INFO_UPDATE"
								value: "\(#in.metrics.info.update)"
							},
						]
						ports: [
							{
								name:          "metrics"
								containerPort: 9205
							},
						]
						if #in.metrics.resources != _|_ {
							resources: #in.metrics.resources
						}
						if #in.metrics.securityContext != _|_ {
							securityContext: #in.metrics.securityContext
						}
					},
				]
				if #in.metrics.podSecurityContext != _|_ {
					securityContext: #in.metrics.podSecurityContext
				}
				if #in.metrics.nodeSelector != _|_ {
					nodeSelector: #in.metrics.nodeSelector
				}
				if #in.metrics.tolerations != _|_ {
					tolerations: #in.metrics.tolerations
				}
				if #in.metrics.affinity != _|_ {
					affinity: #in.metrics.affinity
				}
			}
		}
	}
}

#MetricsService: corev1.#Service & {
	#in:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		for k, v in #in.metadata if k != "name" {
			"\(k)": v
		}
		name:      "\(#in.metadata.name)-metrics"
		labels: {
			"app.kubernetes.io/component": "metrics"
			if #in.metrics.service.labels != _|_ {
				for k, v in #in.metrics.service.labels {"\(k)": v}
			}
		}
		if #in.metrics.service.annotations != _|_ {
			annotations: #in.metrics.service.annotations
		}
	}
	spec: {
		type: #in.metrics.service.type
		if #in.metrics.service.type == "LoadBalancer" && #in.metrics.service.loadBalancerIP != "" {
			loadBalancerIP: #in.metrics.service.loadBalancerIP
		}
		ports: [
			{
				name:       "metrics"
				port:       9205
				targetPort: "metrics"
			},
		]
		selector: #in.selector.labels & {
			"app.kubernetes.io/component": "metrics"
		}
	}
}
