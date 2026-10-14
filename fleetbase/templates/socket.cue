package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#SocketDeployment: appsv1.#Deployment & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "socket"
	}

	_affinity: timoniv1.#Affinity & {
		#Values:      #config.affinity
		#MatchLabels: #meta.#LabelSelector
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #meta
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.socket.replicas
		selector: matchLabels: #meta.#LabelSelector
		template: {
			metadata: {
				labels: #meta.#LabelSelector
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.serviceAccountName
				automountServiceAccountToken: #config.automountServiceAccountToken
				containers: [
					{
						name:            "socket"
						image:           #config.images.socket.reference
						imagePullPolicy: #config.images.socket.pullPolicy
						ports: [
							{
								name:          "http"
								containerPort: #config.socket.port
								protocol:      "TCP"
							},
						]
						env: [
							{
								name:  "SOCKETCLUSTER_PORT"
								value: "\(#config.socket.port)"
							},
							{
								name:  "SOCKETCLUSTER_WORKERS"
								value: "\(#config.socket.workers)"
							},
							{
								name:  "SOCKETCLUSTER_BROKERS"
								value: "\(#config.socket.brokers)"
							},
							if #config.socket.options != _|_ {
								name:  "SOCKETCLUSTER_OPTIONS"
								value: #config.socket.options
							},
						]
						livenessProbe: {
							httpGet: {
								path: "/"
								port: "http"
							}
							initialDelaySeconds: 15
							periodSeconds:       10
						}
						readinessProbe: {
							httpGet: {
								path: "/"
								port: "http"
							}
							initialDelaySeconds: 5
							periodSeconds:       5
						}
						resources:       #config.socket.resources
						if #config.socket.securityContext != _|_ {
							securityContext: #config.socket.securityContext
						}
					},
				]
				if #config.socket.podSecurityContext != _|_ {
					securityContext: #config.socket.podSecurityContext
				}
				if #config.socket.podSecurityContext == _|_ && #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				nodeSelector: #config.nodeSelector
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				affinity: _affinity
			}
		}
	}
}

#SocketService: corev1.#Service & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "socket"
	}

	apiVersion: "v1"
	kind:       "Service"
	metadata:   #meta
	spec: corev1.#ServiceSpec & {
		type: [
			if #config.socket.service != _|_ { #config.socket.service.type },
			corev1.#ServiceTypeClusterIP,
		][0]
		selector: #meta.#LabelSelector
		ports: [
			{
				name:       "http"
				port: [
					if #config.socket.service != _|_ { #config.socket.service.port },
					#config.socket.port,
				][0]
				targetPort: "http"
				protocol:   "TCP"
			},
		]
	}
}

