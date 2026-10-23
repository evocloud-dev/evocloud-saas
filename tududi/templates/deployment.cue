package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config
	#cmName: string

	// The affinity rules generated from the affinity values;
	// the anti-affinity presets match the instance selector labels.
	_affinity: timoniv1.#Affinity & {
		#Values:      #config.affinity
		#MatchLabels: #config.selector.labels
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicas
		strategy: #config.strategy
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.metadata.name
				automountServiceAccountToken: #config.automountServiceAccountToken
				containers: [
					{
						name:            #config.metadata.name
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						ports: [
							{
								name:          "http"
								containerPort: 3002
								protocol:      "TCP"
							},
						]
						envFrom: [
							{
								configMapRef: name: #cmName
							},
						]
						livenessProbe: {
							httpGet: {
								path: "/api/health"
								port: "http"
							}
							initialDelaySeconds: 10
							periodSeconds:       60
							timeoutSeconds:      3
							failureThreshold:    2
						}
						readinessProbe: {
							httpGet: {
								path: "/api/health"
								port: "http"
							}
							initialDelaySeconds: 5
							periodSeconds:       10
							timeoutSeconds:      3
							failureThreshold:    3
						}
						volumeMounts: [
							if !#config.postgres.enabled {
								{
									name:      "db"
									mountPath: "/app/db"
								}
							},
							{
								name:      "uploads"
								mountPath: "/app/uploads"
							},
							{
								name:      "backups"
								mountPath: "/app/backups"
							},
						]
						resources:       #config.resources
						securityContext: #config.securityContext
					},
				]
				volumes: [
					if !#config.postgres.enabled {
						{
							name: "db"
							if #config.persistence.db.enabled {
								persistentVolumeClaim: {
									if #config.persistence.db.existingClaim != _|_ {
										claimName: #config.persistence.db.existingClaim
									}
									if #config.persistence.db.existingClaim == _|_ {
										claimName: "\(#config.metadata.name)-db"
									}
								}
							}
							if !#config.persistence.db.enabled {
								emptyDir: {}
							}
						}
					},
					{
						name: "uploads"
						if #config.persistence.uploads.enabled {
							persistentVolumeClaim: {
								if #config.persistence.uploads.existingClaim != _|_ {
									claimName: #config.persistence.uploads.existingClaim
								}
								if #config.persistence.uploads.existingClaim == _|_ {
									claimName: "\(#config.metadata.name)-uploads"
								}
							}
						}
						if !#config.persistence.uploads.enabled {
							emptyDir: {}
						}
					},
					{
						name: "backups"
						if #config.persistence.backups.enabled {
							persistentVolumeClaim: {
								if #config.persistence.backups.existingClaim != _|_ {
									claimName: #config.persistence.backups.existingClaim
								}
								if #config.persistence.backups.existingClaim == _|_ {
									claimName: "\(#config.metadata.name)-backups"
								}
							}
						}
						if !#config.persistence.backups.enabled {
							emptyDir: {}
						}
					},
				]
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				nodeSelector: #config.nodeSelector
				if _affinity.#Enabled {
					affinity: _affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
			}
		}
	}
}
