package templates

import (
	"encoding/json"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#ConsoleConfigMap: corev1.#ConfigMap & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "console-config"
	}

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata:   #meta
	data: {
		"fleetbase.config.json": json.Marshal({
			API_HOST: #config.console.apiHost
			if #config.console.socketHost != _|_ {
				SOCKETCLUSTER_HOST: #config.console.socketHost
			}
			if #config.console.socketPort != _|_ {
				SOCKETCLUSTER_PORT: #config.console.socketPort
			}
		})
	}
}

#ConsoleDeployment: appsv1.#Deployment & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "console"
	}

	_affinity: timoniv1.#Affinity & {
		#Values:      #config.affinity
		#MatchLabels: #meta.#LabelSelector
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #meta
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.console.replicas
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
						name:            "console"
						image:           #config.images.console.reference
						imagePullPolicy: #config.images.console.pullPolicy
						ports: [
							{
								name:          "http"
								containerPort: 4200
								protocol:      "TCP"
							},
						]
						volumeMounts: [
							{
								name:      "runtime-config"
								mountPath: "/usr/share/nginx/html/fleetbase.config.json"
								subPath:   "fleetbase.config.json"
								readOnly:  true
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
						resources:       #config.console.resources
						if #config.console.securityContext != _|_ {
							securityContext: #config.console.securityContext
						}
					},
				]
				volumes: [
					{
						name: "runtime-config"
						configMap: name: #config.metadata.name + "-console-config"
					},
				]
				if #config.console.podSecurityContext != _|_ {
					securityContext: #config.console.podSecurityContext
				}
				if #config.console.podSecurityContext == _|_ && #config.podSecurityContext != _|_ {
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

#ConsoleService: corev1.#Service & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "console"
	}

	apiVersion: "v1"
	kind:       "Service"
	metadata:   #meta
	spec: corev1.#ServiceSpec & {
		type: [
			if #config.console.service != _|_ { #config.console.service.type },
			corev1.#ServiceTypeClusterIP,
		][0]
		selector: #meta.#LabelSelector
		ports: [
			{
				name:       "http"
				port: [
					if #config.console.service != _|_ { #config.console.service.port },
					#config.console.port,
				][0]
				targetPort: "http"
				protocol:   "TCP"
			},
		]
	}
}