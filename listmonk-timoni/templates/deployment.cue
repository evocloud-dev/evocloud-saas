package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: {
	#config: #Config
	#helpers: #Helpers

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #helpers.fullname
		namespace: #config.metadata.namespace
		labels:    #helpers.labels
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.autoscaling.enabled {
			replicas: #config.replicaCount
		}
		selector: matchLabels: #helpers.selectorLabels
		template: {
			metadata: {
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
				labels: #helpers.selectorLabels
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: false
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.postgres.enabled && #config.postgres.waitForDatabase {
					initContainers: [{
						name:            "wait-for-db"
						image:           "\(#config.postgres.image.repository):\(#config.postgres.image.tag)"
						imagePullPolicy: "IfNotPresent"
						command: ["pg_isready", "-h", #config.database.host, "-p", "\(#config.database.port)", "-U", #config.database.user]
						env: [{
							name: "PGPASSWORD"
							valueFrom: secretKeyRef: {
								name: #helpers.dbSecretName
								key:  #config.database.passwordKey
							}
						}]
						securityContext: #config.securityContext
					}]
				}
				serviceAccountName: #helpers.serviceAccountName
				securityContext:    #config.podSecurityContext
				containers: [{
					name:            "listmonk"
					securityContext: #config.securityContext
					image:           "\(#config.image.repository):\(#config.image.tag)"
					imagePullPolicy: #config.image.pullPolicy
					volumeMounts: [{
						name:      "listmonk-config"
						mountPath: "/listmonk/config.toml"
						subPath:   "config.toml"
					}, {
						name:      "uploads"
						mountPath: "/listmonk/uploads"
					}, if #config.securityContext.readOnlyRootFilesystem != _|_ && #config.securityContext.readOnlyRootFilesystem == true {
						{
							name:      "tmp"
							mountPath: "/tmp"
						}
					}]
					ports: [{
						name:          "http"
						containerPort: 9000
						protocol:      "TCP"
					}]
					envFrom: [{
						configMapRef: name: #helpers.fullname
					}]
					env: [{
						name: "LISTMONK_db__password"
						valueFrom: secretKeyRef: {
							name: #helpers.dbSecretName
							key:  #config.database.passwordKey
						}
					}]
					if #config.livenessProbe.enabled {
						livenessProbe: {
							httpGet: {
								path: #config.livenessProbe.httpGet.path
								port: #config.livenessProbe.httpGet.port
							}
							initialDelaySeconds: #config.livenessProbe.initialDelaySeconds
							periodSeconds:       #config.livenessProbe.periodSeconds
							timeoutSeconds:      #config.livenessProbe.timeoutSeconds
							failureThreshold:    #config.livenessProbe.failureThreshold
						}
					}
					if #config.readinessProbe.enabled {
						readinessProbe: {
							httpGet: {
								path: #config.readinessProbe.httpGet.path
								port: #config.readinessProbe.httpGet.port
							}
							initialDelaySeconds: #config.readinessProbe.initialDelaySeconds
							periodSeconds:       #config.readinessProbe.periodSeconds
							timeoutSeconds:      #config.readinessProbe.timeoutSeconds
							failureThreshold:    #config.readinessProbe.failureThreshold
						}
					}
					if #config.startupProbe.enabled {
						startupProbe: {
							httpGet: {
								path: #config.startupProbe.httpGet.path
								port: #config.startupProbe.httpGet.port
							}
							initialDelaySeconds: #config.startupProbe.initialDelaySeconds
							periodSeconds:       #config.startupProbe.periodSeconds
							timeoutSeconds:      #config.startupProbe.timeoutSeconds
							failureThreshold:    #config.startupProbe.failureThreshold
						}
					}
					resources: #config.resources
				}]
				volumes: [{
					name: "listmonk-config"
					configMap: {
						name: #helpers.fullname
						items: [{
							key:  "config.toml"
							path: "config.toml"
						}]
					}
				}, {
					name: "uploads"
					if #config.storage.existingClaim != "" {
						persistentVolumeClaim: claimName: #config.storage.existingClaim
					}
					if #config.storage.existingClaim == "" {
						if #config.storage.enabled {
							persistentVolumeClaim: claimName: "\(#helpers.fullname)-uploads"
						}
						if !#config.storage.enabled {
							emptyDir: {}
						}
					}
				}, if #config.securityContext.readOnlyRootFilesystem != _|_ && #config.securityContext.readOnlyRootFilesystem == true {
					{
						name: "tmp"
						emptyDir: {}
					}
				}]
				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
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
