package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	networkingv1 "k8s.io/api/networking/v1"
)

#LivekitService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "livekit"
		namespace: #config.metadata.namespace
	}
	spec: corev1.#ServiceSpec & {
		ports: [{
			name:       "http"
			port:       7880
			targetPort: 7880
			protocol:   "TCP"
		}, {
			name:       "webrtc-tcp"
			port:       7881
			targetPort: 7881
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "livekit"
		}
		type: "ClusterIP"
	}
}

#LivekitConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "livekit-config"
		namespace: #config.metadata.namespace
	}
	data: {
		"config.yaml": """
			port: 7880
			redis:
			  address: redis-master:6379
			  password: pass
			keys:
			  \(#config.livekit.apiKey): \(#config.livekit.apiSecret)
			log_level: debug
			rtc:
			  use_external_ip: false
			  node_ip: \(#config.livekit.nodeIP)
			  port_range_start: 50000
			  port_range_end: 60000
			  tcp_port: 7881
			"""
	}
}

#LivekitDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "livekit"
		namespace: #config.metadata.namespace
		labels: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "livekit"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		selector: matchLabels: {
			"app.kubernetes.io/instance": "extra"
			"app.kubernetes.io/name":     "livekit"
		}
		replicas: 1
		template: {
			metadata: labels: {
				"app.kubernetes.io/instance": "extra"
				"app.kubernetes.io/name":     "livekit"
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: #config.livekit.automountServiceAccountToken
				serviceAccountName:           #config.livekit.serviceAccountName
				if #config.livekit.podSecurityContext != null {
					securityContext: #config.livekit.podSecurityContext
				}
				containers: [{
					name: "livekit"
					image:           #config.livekit.image.reference
					imagePullPolicy: "IfNotPresent"
					if #config.livekit.securityContext != null {
						securityContext: #config.livekit.securityContext
					}
					if #config.livekit.resources != null {
						resources: #config.livekit.resources
					}
					command: [
						"/livekit-server",
					]
					args: [
						"--config",
						"/etc/livekit/config.yaml",
					]
					env: [{
						name:  "LIVEKIT_PORT"
						value: "7880"
					}]
					ports: [{
						containerPort: 7880
						name:          "http"
					}, {
						containerPort: 7881
						name:          "webrtc-tcp"
					}]
					volumeMounts: [{
						name:      "config"
						mountPath: "/etc/livekit"
						readOnly:  true
					}]
				}]
				volumes: [{
					name: "config"
					configMap: name: "livekit-config"
				}]
			}
		}
	}
}

#LivekitIngress: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "livekit"
		namespace: #config.metadata.namespace
		if #config.livekit.ingress.className != null {
			annotations: "kubernetes.io/ingress.class": #config.livekit.ingress.className
		}
	}
	spec: networkingv1.#IngressSpec & {
		if #config.livekit.ingress.className != null {
			ingressClassName: #config.livekit.ingress.className
		}
		rules: [{
			host: #config.livekit.host
			http: paths: [{
				path:     "/"
				pathType: "Prefix"
				backend: service: {
					name: "livekit"
					port: number: 7880
				}
			}]
		}]
		tls: [{
			hosts: [#config.livekit.host]
			secretName: #config.livekit.ingress.secretName
		}]
	}
}
