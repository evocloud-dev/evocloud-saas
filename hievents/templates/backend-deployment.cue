package templates

import (
	"list"
	"strconv"

	appsv1 "k8s.io/api/apps/v1"
)

#BackendDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config._backendName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels & {
			"app.kubernetes.io/component": "backend"
		}
	}
	spec: {
		if !#config.backend.autoscaling.enabled {
			replicas: #config.backend.replicaCount
		}
		selector: matchLabels: {
			"app.kubernetes.io/name":      #config._appName
			"app.kubernetes.io/instance":   #config.metadata.name
			"app.kubernetes.io/component": "backend"
		}
		template: {
			metadata: {
				labels: #config._baseLabels & {
					"app.kubernetes.io/component": "backend"
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
				serviceAccountName: #config._saName
				if len(#config.backend.podSecurityContext) > 0 {
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
					name:            "backend"
					image:           #config._backendImageRef
					imagePullPolicy: #config.backend.image.pullPolicy
					lifecycle: {
						postStart: exec: command: [
							"/bin/sh",
							"-c",
							"php artisan storage:link || true",
						]
					}
					if len(#config.backend.command) > 0 {
						command: #config.backend.command
					}
					if len(#config.backend.args) > 0 {
						args: #config.backend.args
					}
					ports: [{
						name:          "http"
						containerPort: #config.backend.service.targetPort
					}]
					env: list.Concat([#config._appEnv, [
						{name: "PORT", value:     strconv.FormatInt(#config.backend.service.targetPort, 10)},
					]])
					
					startupProbe: {
						if #config.backend.probes.type == "tcpSocket" {
							tcpSocket: port: "http"
						}
						if #config.backend.probes.type == "httpGet" {
							httpGet: {path: "/", port: "http"}
						}
						periodSeconds:    #config.backend.probes.startup.periodSeconds
						timeoutSeconds:   #config.backend.probes.startup.timeoutSeconds
						failureThreshold: #config.backend.probes.startup.failureThreshold
					}
					livenessProbe: {
						if #config.backend.probes.type == "tcpSocket" {
							tcpSocket: port: "http"
						}
						if #config.backend.probes.type == "httpGet" {
							httpGet: {path: "/", port: "http"}
						}
						initialDelaySeconds: #config.backend.probes.liveness.initialDelaySeconds
						periodSeconds:       #config.backend.probes.liveness.periodSeconds
						timeoutSeconds:      #config.backend.probes.liveness.timeoutSeconds
						failureThreshold:    #config.backend.probes.liveness.failureThreshold
					}
					readinessProbe: {
						if #config.backend.probes.type == "tcpSocket" {
							tcpSocket: port: "http"
						}
						if #config.backend.probes.type == "httpGet" {
							httpGet: {path: "/", port: "http"}
						}
						initialDelaySeconds: #config.backend.probes.readiness.initialDelaySeconds
						periodSeconds:       #config.backend.probes.readiness.periodSeconds
						timeoutSeconds:      #config.backend.probes.readiness.timeoutSeconds
						failureThreshold:    #config.backend.probes.readiness.failureThreshold
					}
					
					if len(#config.backend.securityContext) > 0 {
						securityContext: #config.backend.securityContext
					}
					if len(#config.backend.resources) > 0 {
						resources: #config.backend.resources
					}
					if #config.backend.persistence.enabled && #config.hieventsConfig.storage.driver == "local" {
						volumeMounts: [{
							name:      "storage"
							mountPath: #config.backend.persistence.mountPath
						}]
					}
				}]
				if #config.backend.persistence.enabled && #config.hieventsConfig.storage.driver == "local" {
					volumes: [{
						name: "storage"
						persistentVolumeClaim: claimName: #config._storageClaimName
					}]
				}
				
				if len(#config.backend.nodeSelector) > 0 {
					nodeSelector: #config.backend.nodeSelector
				}
				if len(#config.backend.affinity) > 0 {
					affinity: #config.backend.affinity
				}
				if len(#config.backend.tolerations) > 0 {
					tolerations: #config.backend.tolerations
				}
				if len(#config.backend.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.backend.topologySpreadConstraints
				}
			}
		}
	}
}
