package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#CaddyConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-caddy"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-caddy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	data: {
		"Caddyfile": """
		http://\(#config.global.baserow.backendDomain) {
			reverse_proxy /ws/* http://\(#config.metadata.name)-asgi:\(#config.backend.asgi.service.port)
			reverse_proxy /mcp/* http://\(#config.metadata.name)-asgi:\(#config.backend.asgi.service.port)
			reverse_proxy /assistant/* http://\(#config.metadata.name)-asgi:\(#config.backend.asgi.service.port)
			reverse_proxy * http://\(#config.metadata.name)-wsgi:\(#config.backend.wsgi.service.port)
		}

		http://\(#config.global.baserow.objectsDomain) {
			reverse_proxy * http://\(#config.metadata.name)-minio:\(#config.minio.service.port)
		}

		http://\(#config.global.baserow.domain) {
			reverse_proxy * http://\(#config.metadata.name)-frontend:\(#config.frontend.service.port)
		}
		"""
	}
}

#CaddyService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-caddy"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-caddy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		type: "ClusterIP"
		selector: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-caddy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		ports: [
			{
				name:       "http"
				port:       8080
				targetPort: 8080
			},
		]
	}
}

#CaddyDeployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-caddy"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-caddy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
	spec: {
		replicas: 1
		selector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-caddy"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/name":     "\(#config.metadata.name)-caddy"
				"app.kubernetes.io/instance": #config.metadata.name
			}
			spec: {
				automountServiceAccountToken: true
				serviceAccountName: "\(#config.metadata.name)-caddy"
				containers: [
					{
						name:            "caddy"
						image:           "\(#config.caddy.image.registry)/\(#config.caddy.image.repository):\(#config.caddy.image.tag)"
						imagePullPolicy: "IfNotPresent"
						ports: [
							{
								name:          "http"
								containerPort: 8080
							},
						]
						volumeMounts: [
							{
								name:      "caddy-config"
								mountPath: "/etc/caddy/Caddyfile"
								subPath:   "Caddyfile"
							},
						]
						if #config.caddy.resources != _|_ {
							resources: #config.caddy.resources
						}
					},
				]
				volumes: [
					{
						name: "caddy-config"
						configMap: name: "\(#config.metadata.name)-caddy"
					},
				]
			}
		}
	}
}

#CaddyServiceAccount: corev1.#ServiceAccount & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      "\(#config.metadata.name)-caddy"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
}
