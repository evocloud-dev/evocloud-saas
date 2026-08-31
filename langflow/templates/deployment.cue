// SPDX-License-Identifier: Apache-2.0
package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#DeploymentBuilder: {
	_config:             #Config
	_fullname:           string
	_serviceAccountName: string
	_authSecretName:     string
	_dbSecretName:       string

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      _fullname
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels & _config.commonLabels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: _config.replicaCount
		selector: matchLabels: _config.metadata.labels
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: _config.metadata.labels & _config.commonLabels & _config.podLabels
				if _config.podAnnotations != _|_ {
					annotations: _config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _serviceAccountName
				automountServiceAccountToken: _config.serviceAccount.automountServiceAccountToken
				if len(_config.imagePullSecrets) > 0 {
					imagePullSecrets: _config.imagePullSecrets
				}
				if _config.podSecurityContext != _|_ {
					securityContext: _config.podSecurityContext
				}
				if _config.priorityClassName != "" {
					priorityClassName: _config.priorityClassName
				}
				terminationGracePeriodSeconds: _config.terminationGracePeriodSeconds
				containers: [{
					name:            _config.metadata.name
					image:           "\(_config.image.repository):\(_config.image.tag)"
					imagePullPolicy: _config.image.pullPolicy
					if len(_config.app.command) > 0 {
						command: _config.app.command
					}
					if len(_config.app.args) > 0 {
						args: _config.app.args
					}
					ports: [{
						name:          "http"
						containerPort: _config.app.port
						protocol:      "TCP"
					}]
					env: [
						{name: "LANGFLOW_HOST", value: "0.0.0.0"},
						{name: "LANGFLOW_PORT", value: "\(_config.app.port)"},
						{name: "LANGFLOW_CONFIG_DIR", value: _config.persistence.mountPath},
						{name: "LANGFLOW_SAVE_DB_IN_CONFIG_DIR", value: "true"},
						{name: "LANGFLOW_OPEN_BROWSER", value: "false"},
						{
							name: "LANGFLOW_SECRET_KEY"
							valueFrom: secretKeyRef: {
								name: _authSecretName
								key:  _config.auth.secretKeyKey
							}
						},
						{
							name: "LANGFLOW_SUPERUSER"
							valueFrom: secretKeyRef: {
								name: _authSecretName
								key:  _config.auth.superuserKey
							}
						},
						{
							name: "LANGFLOW_SUPERUSER_PASSWORD"
							valueFrom: secretKeyRef: {
								name: _authSecretName
								key:  _config.auth.superuserPasswordKey
							}
						},
						if _config.database.url != "" || _config.database.existingSecret != "" {
							{
								name: "LANGFLOW_DATABASE_URL"
								valueFrom: secretKeyRef: {
									name: _dbSecretName
									key:  _config.database.urlKey
								}
							}
						},
						for e in _config.app.env {e},
						for e in _config.app.extraEnv {e},
					]
					if len(_config.app.envFrom) > 0 {
						envFrom: _config.app.envFrom
					}
					if _config.probes.startup.enabled {
						startupProbe: {
							httpGet: {
								path: _config.probes.startup.path
								port: "http"
							}
							initialDelaySeconds: _config.probes.startup.initialDelaySeconds
							failureThreshold:    _config.probes.startup.failureThreshold
							periodSeconds:       _config.probes.startup.periodSeconds
							timeoutSeconds:      _config.probes.startup.timeoutSeconds
						}
					}
					if _config.probes.liveness.enabled {
						livenessProbe: {
							httpGet: {
								path: _config.probes.liveness.path
								port: "http"
							}
							initialDelaySeconds: _config.probes.liveness.initialDelaySeconds
							periodSeconds:       _config.probes.liveness.periodSeconds
							timeoutSeconds:      _config.probes.liveness.timeoutSeconds
							failureThreshold:    _config.probes.liveness.failureThreshold
						}
					}
					if _config.probes.readiness.enabled {
						readinessProbe: {
							httpGet: {
								path: _config.probes.readiness.path
								port: "http"
							}
							initialDelaySeconds: _config.probes.readiness.initialDelaySeconds
							periodSeconds:       _config.probes.readiness.periodSeconds
							timeoutSeconds:      _config.probes.readiness.timeoutSeconds
							failureThreshold:    _config.probes.readiness.failureThreshold
						}
					}
					if _config.securityContext != _|_ {
						securityContext: _config.securityContext
					}
					if _config.resources != _|_ {
						resources: _config.resources
					}
					volumeMounts: [
						{
							name:      "data"
							mountPath: _config.persistence.mountPath
						},
						for vm in _config.extraVolumeMounts {vm},
					]
				}]
				if len(_config.nodeSelector) > 0 {
					nodeSelector: _config.nodeSelector
				}
				if _config.affinity != _|_ {
					affinity: _config.affinity
				}
				if len(_config.tolerations) > 0 {
					tolerations: _config.tolerations
				}
				if len(_config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: _config.topologySpreadConstraints
				}
				volumes: [
					{
						name: "data"
						if _config.persistence.existingClaim != "" {
							persistentVolumeClaim: claimName: _config.persistence.existingClaim
						}
						if _config.persistence.existingClaim == "" && _config.persistence.enabled {
							persistentVolumeClaim: claimName: _fullname
						}
						if _config.persistence.existingClaim == "" && !_config.persistence.enabled {
							emptyDir: {}
						}
					},
					for v in _config.extraVolumes {v},
				]
			}
		}
	}
}
