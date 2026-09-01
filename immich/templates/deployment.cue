package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#ServerDeploymentBuilder: {
	_config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      _config.fullname
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels & {
			"app.kubernetes.io/component": "server"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !_config.autoscaling.enabled {
			replicas: _config.server.replicaCount
		}
		revisionHistoryLimit: _config.server.revisionHistoryLimit
		if _config.server.strategy.type != "" {
			strategy: type: _config.server.strategy.type
		}
		if _config.server.strategy.type == "" && _config.server.persistence.enabled {
			strategy: type: "Recreate"
		}
		selector: matchLabels: _config.metadata.labels & {
			"app.kubernetes.io/component": "server"
		}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: _config.metadata.labels & _config.commonLabels & _config.podLabels & {
					"app.kubernetes.io/component": "server"
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

				initContainers: [
					{
						name:            "wait-for-postgresql"
						image:           "\(_config.wait.image.repository):\(_config.wait.image.tag)"
						imagePullPolicy: _config.wait.image.pullPolicy
						command: [
							"sh",
							"-ec",
							"""
							until nc -z \(_config.dbHost) \(_config.dbPort); do
							  sleep 2
							done
							""",
						]
						securityContext: _config.wait.securityContext
					},
					{
						name:            "wait-for-valkey"
						image:           "\(_config.wait.image.repository):\(_config.wait.image.tag)"
						imagePullPolicy: _config.wait.image.pullPolicy
						command: [
							"sh",
							"-ec",
							"""
							until nc -z \(_config.valkeyHost) \(_config.valkeyPort); do
							  sleep 2
							done
							""",
						]
						securityContext: _config.wait.securityContext
					},
				]

				containers: [{
					name:            "immich"
					image:           "\(_config.image.repository):\(_config.image.tag)"
					imagePullPolicy: _config.image.pullPolicy
					ports: [{
						name:          "http"
						containerPort: _config.service.targetPort
					}]
					env: [
						{name: "IMMICH_ENV", value: "production"},
						{name: "IMMICH_LOG_LEVEL", value: _config.server.logLevel},
						{name: "IMMICH_LOG_FORMAT", value: _config.server.logFormat},
						{name: "IMMICH_HOST", value: "0.0.0.0"},
						{name: "IMMICH_PORT", value: "\(_config.service.targetPort)"},
						{name: "TZ", value: _config.server.timezone},
						{name: "UPLOAD_LOCATION", value: "/data"},
						{name: "DB_HOSTNAME", value: _config.dbHost},
						{name: "DB_PORT", value: "\(_config.dbPort)"},
						{name: "DB_DATABASE_NAME", value: _config.dbName},
						{name: "DB_USERNAME", value: _config.dbUser},
						{
							name: "DB_PASSWORD"
							valueFrom: secretKeyRef: {
								name: _config.dbSecretName
								key:  _config.dbSecretKey
							}
						},
						{name: "REDIS_HOSTNAME", value: _config.valkeyHost},
						{name: "REDIS_PORT", value: "\(_config.valkeyPort)"},
						if _config.hasRedisPassword {
							name: "REDIS_PASSWORD"
							valueFrom: secretKeyRef: {
								name: _config.redisSecretName
								key:  _config.redisSecretKey
							}
						},
						if _config.machineLearning.enabled {
							name:  "IMMICH_MACHINE_LEARNING_URL"
							value: _config.mlUrl
						},
						for e in _config.server.extraEnv {e},
					]
					livenessProbe: {
						httpGet: {
							path: _config.probes.path
							port: "http"
						}
						initialDelaySeconds: _config.probes.livenessInitialDelaySeconds
						periodSeconds:       20
						timeoutSeconds:      5
						failureThreshold:    6
					}
					readinessProbe: {
						httpGet: {
							path: _config.probes.path
							port: "http"
						}
						initialDelaySeconds: _config.probes.readinessInitialDelaySeconds
						periodSeconds:       10
						timeoutSeconds:      5
						failureThreshold:    12
					}
					if _config.resources != _|_ {
						resources: _config.resources
					}
					securityContext: _config.securityContext
					volumeMounts: [
						{
							name:      "uploads"
							mountPath: "/data"
						},
						for vm in _config.extraVolumeMounts {vm},
					]
				}]

				volumes: [
					{
						name: "uploads"
						if _config.server.persistence.enabled {
							persistentVolumeClaim: claimName: _config.uploadsPvcName
						}
						if !_config.server.persistence.enabled {
							emptyDir: {}
						}
					},
					for v in _config.extraVolumes {v},
				]

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
				terminationGracePeriodSeconds: _config.terminationGracePeriodSeconds
			}
		}
	}
}
