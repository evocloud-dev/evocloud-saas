package templates

import (
	appsv1 "k8s.io/api/apps/v1"
)

#WorkerDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config._workerName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "worker"
		}
	}
	spec: {
		replicas: #config.worker.replicaCount
		selector: matchLabels: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "worker"
		}
		template: {
			metadata: {
				labels: #config._baseLabels & {
					"app.kubernetes.io/component": "worker"
					for k, v in #config.podLabels {(k): v}
				}
				if len(#config._podAnnotations) > 0 {
					annotations: #config._podAnnotations
				}
			}
			spec: {
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName:            #config._saName
				terminationGracePeriodSeconds: #config.worker.terminationGracePeriodSeconds
				if len(#config.worker.podSecurityContext) > 0 {
					securityContext: #config.worker.podSecurityContext
				}
				if len(#config.worker.podSecurityContext) == 0 && len(#config.backend.podSecurityContext) > 0 {
					securityContext: #config.backend.podSecurityContext
				}
				
				if #config.initContainers.postgresql.enabled || #config.initContainers.redis.enabled {
					initContainers: [
						if #config.initContainers.postgresql.enabled {
							#config._postgresInitContainer
						},
						if #config.initContainers.redis.enabled {
							#config._redisInitContainer
						},
					]
				}
				
				containers: [{
					name:            "worker"
					image:           #config._backendImageRef
					imagePullPolicy: #config.backend.image.pullPolicy
					if len(#config.worker.command) > 0 {
						command: #config.worker.command
					}
					if len(#config.worker.args) > 0 {
						args: #config.worker.args
					}
					env: #config._appEnv
					
					if len(#config.worker.securityContext) > 0 {
						securityContext: #config.worker.securityContext
					}
					if len(#config.worker.securityContext) == 0 && len(#config.backend.securityContext) > 0 {
						securityContext: #config.backend.securityContext
					}
					if len(#config.worker.resources) > 0 {
						resources: #config.worker.resources
					}
					volumeMounts: [
						if #config.backend.persistence.enabled && #config.hieventsConfig.storage.driver == "local" {
							{
								name:      "storage"
								mountPath: #config.backend.persistence.mountPath
							}
						},
						if #config.backend.securityContext.readOnlyRootFilesystem != _|_ && #config.backend.securityContext.readOnlyRootFilesystem == true {
							{
								name:      "tmp"
								mountPath: "/tmp"
							}
						},
						if #config.backend.securityContext.readOnlyRootFilesystem != _|_ && #config.backend.securityContext.readOnlyRootFilesystem == true {
							{
								name:      "storage-framework"
								mountPath: "/var/www/html/storage/framework"
							}
						},
						if #config.backend.securityContext.readOnlyRootFilesystem != _|_ && #config.backend.securityContext.readOnlyRootFilesystem == true {
							{
								name:      "storage-logs"
								mountPath: "/var/www/html/storage/logs"
							}
						},
					]
				}]
				volumes: [
					if #config.backend.persistence.enabled && #config.hieventsConfig.storage.driver == "local" {
						{
							name: "storage"
							persistentVolumeClaim: claimName: #config._storageClaimName
						}
					},
					if #config.backend.securityContext.readOnlyRootFilesystem != _|_ && #config.backend.securityContext.readOnlyRootFilesystem == true {
						{
							name: "tmp"
							emptyDir: {}
						}
					},
					if #config.backend.securityContext.readOnlyRootFilesystem != _|_ && #config.backend.securityContext.readOnlyRootFilesystem == true {
						{
							name: "storage-framework"
							emptyDir: {}
						}
					},
					if #config.backend.securityContext.readOnlyRootFilesystem != _|_ && #config.backend.securityContext.readOnlyRootFilesystem == true {
						{
							name: "storage-logs"
							emptyDir: {}
						}
					},
				]
				
				if len(#config.worker.nodeSelector) > 0 {
					nodeSelector: #config.worker.nodeSelector
				}
				if len(#config.worker.affinity) > 0 {
					affinity: #config.worker.affinity
				}
				if len(#config.worker.tolerations) > 0 {
					tolerations: #config.worker.tolerations
				}
				if len(#config.worker.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.worker.topologySpreadConstraints
				}
			}
		}
	}
}
