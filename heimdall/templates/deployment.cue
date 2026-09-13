package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#DeploymentBuilder: appsv1.#Deployment & {
	_config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      _config.fullname
		namespace: _config.namespace
		labels:    _config.standardLabels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		if _config.persistence.enabled {
			strategy: type: "Recreate"
		}
		selector: matchLabels: _config.selectorLabels
		template: {
			metadata: {
				labels: _config.selectorLabels & _config.podLabels
				if len(_config.podAnnotations) > 0 {
					annotations: _config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if len(_config.imagePullSecrets) > 0 {
					imagePullSecrets: _config.imagePullSecrets
				}
				automountServiceAccountToken: _config.serviceAccount.automountServiceAccountToken
				serviceAccountName:           _config.serviceAccountName
				if _config.podSecurityContext != _|_ && len(_config.podSecurityContext) > 0 {
					securityContext: _config.podSecurityContext
				}
				terminationGracePeriodSeconds: _config.terminationGracePeriodSeconds
				if _config.priorityClassName != "" {
					priorityClassName: _config.priorityClassName
				}
				containers: [{
					name:            "heimdall"
					image:           "\(_config.image.repository):\(_config.image.tag)"
					imagePullPolicy: _config.image.pullPolicy
					if _config.securityContext != _|_ && len(_config.securityContext) > 0 {
						securityContext: _config.securityContext
					}
					ports: [{
						name:          "http"
						containerPort: 80
						protocol:      "TCP"
					}]
					env: [
						{name: "PUID", value: "\(_config.heimdall.puid)"},
						{name: "PGID", value: "\(_config.heimdall.pgid)"},
						{name: "TZ", value: _config.heimdall.timezone},
						for ev in _config.heimdall.extraEnv {ev},
					]
					if _config.startupProbe.enabled {
						startupProbe: {
							httpGet: {
								path: _config.startupProbe.path
								port: "http"
							}
							initialDelaySeconds: _config.startupProbe.initialDelaySeconds
							periodSeconds:       _config.startupProbe.periodSeconds
							timeoutSeconds:      _config.startupProbe.timeoutSeconds
							failureThreshold:    _config.startupProbe.failureThreshold
						}
					}
					if _config.livenessProbe.enabled {
						livenessProbe: {
							httpGet: {
								path: _config.livenessProbe.path
								port: "http"
							}
							initialDelaySeconds: _config.livenessProbe.initialDelaySeconds
							periodSeconds:       _config.livenessProbe.periodSeconds
							timeoutSeconds:      _config.livenessProbe.timeoutSeconds
							failureThreshold:    _config.livenessProbe.failureThreshold
						}
					}
					if _config.readinessProbe.enabled {
						readinessProbe: {
							httpGet: {
								path: _config.readinessProbe.path
								port: "http"
							}
							initialDelaySeconds: _config.readinessProbe.initialDelaySeconds
							periodSeconds:       _config.readinessProbe.periodSeconds
							timeoutSeconds:      _config.readinessProbe.timeoutSeconds
							failureThreshold:    _config.readinessProbe.failureThreshold
						}
					}
					if _config.resources != _|_ && len(_config.resources) > 0 {
						resources: _config.resources
					}
					if _config.persistence.enabled || len(_config.extraVolumeMounts) > 0 {
						volumeMounts: [
							if _config.persistence.enabled {
								name:      "config"
								mountPath: "/config"
							},
							for vm in _config.extraVolumeMounts {vm},
						]
					}
				}]
				if _config.persistence.enabled || len(_config.extraVolumes) > 0 {
					volumes: [
						if _config.persistence.enabled {
							name: "config"
							persistentVolumeClaim: claimName: _config.pvcName
						},
						for v in _config.extraVolumes {v},
					]
				}
				if len(_config.nodeSelector) > 0 {
					nodeSelector: _config.nodeSelector
				}
				if _config.affinity != _|_ && len(_config.affinity) > 0 {
					affinity: _config.affinity
				}
				if len(_config.tolerations) > 0 {
					tolerations: _config.tolerations
				}
				if len(_config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: _config.topologySpreadConstraints
				}
			}
		}
	}
}
