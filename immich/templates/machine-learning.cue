package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MLServiceBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(_config.fullname)-machine-learning"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels & {
			"app.kubernetes.io/component": "machine-learning"
		}
	}
	spec: {
		ports: [{
			name:       "http"
			port:       _config.machineLearning.service.port
			targetPort: "http"
		}]
		selector: _config.metadata.labels & {
			"app.kubernetes.io/component": "machine-learning"
		}
	}
}

#MLDeploymentBuilder: {
	_config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(_config.fullname)-machine-learning"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels & {
			"app.kubernetes.io/component": "machine-learning"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: _config.machineLearning.replicaCount
		if _config.machineLearning.strategy.type != "" {
			strategy: type: _config.machineLearning.strategy.type
		}
		if _config.machineLearning.strategy.type == "" && _config.machineLearning.persistence.enabled {
			strategy: type: "Recreate"
		}
		selector: matchLabels: _config.metadata.labels & {
			"app.kubernetes.io/component": "machine-learning"
		}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: _config.metadata.labels & _config.commonLabels & _config.podLabels & {
					"app.kubernetes.io/component": "machine-learning"
				}
				if _config.podAnnotations != _|_ {
					annotations: _config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _config.serviceAccountName
				automountServiceAccountToken: _config.serviceAccount.automountServiceAccountToken
				if len(_config.imagePullSecrets) > 0 {
					imagePullSecrets: _config.imagePullSecrets
				}
				if _config.priorityClassName != "" {
					priorityClassName: _config.priorityClassName
				}
				securityContext: _config.podSecurityContext

				containers: [{
					name:            "machine-learning"
					image:           "\(_config.machineLearning.image.repository):\(_config.machineLearning.image.tag)"
					imagePullPolicy: _config.machineLearning.image.pullPolicy
					ports: [{
						name:          "http"
						containerPort: _config.machineLearning.service.port
					}]
					if _config.machineLearning.probes.readiness.enabled {
						readinessProbe: {
							httpGet: {
								path: _config.machineLearning.probes.readiness.path
								port: "http"
							}
							initialDelaySeconds: _config.machineLearning.probes.readiness.initialDelaySeconds
							periodSeconds:       _config.machineLearning.probes.readiness.periodSeconds
							timeoutSeconds:      _config.machineLearning.probes.readiness.timeoutSeconds
							failureThreshold:    _config.machineLearning.probes.readiness.failureThreshold
						}
					}
					if _config.machineLearning.probes.liveness.enabled {
						livenessProbe: {
							httpGet: {
								path: _config.machineLearning.probes.liveness.path
								port: "http"
							}
							initialDelaySeconds: _config.machineLearning.probes.liveness.initialDelaySeconds
							periodSeconds:       _config.machineLearning.probes.liveness.periodSeconds
							timeoutSeconds:      _config.machineLearning.probes.liveness.timeoutSeconds
							failureThreshold:    _config.machineLearning.probes.liveness.failureThreshold
						}
					}
					env: [
						{name: "IMMICH_ENV", value: "production"},
						{name: "IMMICH_HOST", value: "0.0.0.0"},
						{name: "IMMICH_PORT", value: "\(_config.machineLearning.service.port)"},
						{name: "MACHINE_LEARNING_CACHE_FOLDER", value: "/cache"},
						for e in _config.machineLearning.extraEnv {e},
					]
					if _config.machineLearning.resources != _|_ {
						resources: _config.machineLearning.resources
					}
					securityContext: _config.machineLearning.securityContext
					volumeMounts: [{
						name:      "cache"
						mountPath: "/cache"
					}]
				}]

				volumes: [{
					name: "cache"
					if _config.machineLearning.persistence.enabled {
						persistentVolumeClaim: claimName: _config.mlCachePvcName
					}
					if !_config.machineLearning.persistence.enabled {
						emptyDir: {}
					}
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
			}
		}
	}
}
