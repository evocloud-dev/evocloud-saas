package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#WorkerDeploymentBuilder: appsv1.#Deployment & {
	_config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(_config.fullname)-worker"
		namespace: _config.namespace
		labels: _config.metadata.labels & _config.commonLabels & {
			"app.kubernetes.io/component": "worker"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: _config.queue.workers
		selector: matchLabels: _config.selector.labels & {
			"app.kubernetes.io/component": "worker"
		}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: _config.selector.labels & _config.podLabels & {
					"app.kubernetes.io/component": "worker"
				}
				if len(_config.podAnnotations) > 0 {
					annotations: _config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if len(_config.imagePullSecrets) > 0 {
					imagePullSecrets: _config.imagePullSecrets
				}
				automountServiceAccountToken: _config.serviceAccount.automountServiceAccountToken
				if _config.serviceAccount.create {
					serviceAccountName: _config.serviceAccountName
				}
				securityContext:               _config.podSecurityContext
				terminationGracePeriodSeconds: _config.terminationGracePeriodSeconds
				if len(_config.nodeSelector) > 0 {
					nodeSelector: _config.nodeSelector
				}
				if _config.affinity != _|_ {
					affinity: _config.affinity
				}
				if len(_config.tolerations) > 0 {
					tolerations: _config.tolerations
				}

				// Init containers
				initContainers: [
					if _config.dbMode != "sqlite" {
						name:            "wait-for-db"
						image:           "docker.io/library/busybox:1.37"
						imagePullPolicy: "IfNotPresent"
						securityContext: _config.securityContext
						command: [
							"sh",
							"-c",
							"""
							echo "Waiting for \(_config.dbHost):\(_config.dbPort) ..."
							until nc -z -w2 \(_config.dbHost) \(_config.dbPort); do
							  sleep 2
							done
							echo "Database is reachable."
							""",
						]
					},
					{
						name:            "wait-for-redis"
						image:           "docker.io/library/busybox:1.37"
						imagePullPolicy: "IfNotPresent"
						securityContext: _config.securityContext
						command: [
							"sh",
							"-c",
							"""
							echo "Waiting for \(_config.redisHost):\(_config.redisPort) ..."
							until nc -z -w2 \(_config.redisHost) \(_config.redisPort); do
							  sleep 2
							done
							echo "Redis is reachable."
							""",
						]
					},
					{
						name:            "wait-for-main"
						image:           "docker.io/library/busybox:1.37"
						imagePullPolicy: "IfNotPresent"
						securityContext: _config.securityContext
						command: [
							"sh",
							"-c",
							"""
							echo "Waiting for n8n main readiness..."
							until wget -qO- http://\(_config.fullname):\(_config.service.port)/healthz/readiness >/dev/null 2>&1; do
							  sleep 2
							done
							echo "n8n main is ready."
							""",
						]
					},
				]

				// Containers
				containers: [
					{
						name:            "worker"
						image:           "\(_config.image.repository):\(_config.image.tag)"
						imagePullPolicy: _config.image.pullPolicy
						command: ["n8n", "worker", "--concurrency=\(_config.queue.concurrency)"]
						securityContext: _config.securityContext
						env: [
							{name: "DB_TYPE", value: _config.dbType},
							if _config.dbMode != "sqlite" && _config.dbVendor == "postgres" {
								name:  "DB_POSTGRESDB_HOST"
								value: _config.dbHost
							},
							if _config.dbMode != "sqlite" && _config.dbVendor == "postgres" {
								name:  "DB_POSTGRESDB_PORT"
								value: _config.dbPort
							},
							if _config.dbMode != "sqlite" && _config.dbVendor == "postgres" {
								name:  "DB_POSTGRESDB_DATABASE"
								value: _config.dbName
							},
							if _config.dbMode != "sqlite" && _config.dbVendor == "postgres" {
								name:  "DB_POSTGRESDB_USER"
								value: _config.dbUsername
							},
							if _config.dbMode != "sqlite" && _config.dbVendor == "postgres" {
								name: "DB_POSTGRESDB_PASSWORD"
								valueFrom: secretKeyRef: {
									name: _config.dbSecretName
									key:  _config.dbSecretKey
								}
							},
							if _config.dbMode != "sqlite" && _config.dbVendor == "mysql" {
								name:  "DB_MYSQLDB_HOST"
								value: _config.dbHost
							},
							if _config.dbMode != "sqlite" && _config.dbVendor == "mysql" {
								name:  "DB_MYSQLDB_PORT"
								value: _config.dbPort
							},
							if _config.dbMode != "sqlite" && _config.dbVendor == "mysql" {
								name:  "DB_MYSQLDB_DATABASE"
								value: _config.dbName
							},
							if _config.dbMode != "sqlite" && _config.dbVendor == "mysql" {
								name:  "DB_MYSQLDB_USER"
								value: _config.dbUsername
							},
							if _config.dbMode != "sqlite" && _config.dbVendor == "mysql" {
								name: "DB_MYSQLDB_PASSWORD"
								valueFrom: secretKeyRef: {
									name: _config.dbSecretName
									key:  _config.dbSecretKey
								}
							},
							if _config.dbMode == "sqlite" {
								name:  "DB_SQLITE_PATH"
								value: _config.database.sqlite.file
							},
							{
								name: "N8N_ENCRYPTION_KEY"
								valueFrom: secretKeyRef: {
									name: _config.encryptionKeySecretName
									key:  _config.encryptionKeySecretKey
								}
							},
							{name: "N8N_DIAGNOSTICS_ENABLED", value: "\(_config.n8n.diagnosticsEnabled)"},
							{name: "N8N_GRACEFUL_SHUTDOWN_TIMEOUT", value: "\(_config.n8n.gracefulShutdownTimeout)"},
							{name: "N8N_RUNNERS_MODE", value: _config.taskRunners.mode},
							if _config.taskRunners.mode == "external" {
								name: "N8N_RUNNERS_AUTH_TOKEN"
								valueFrom: secretKeyRef: {
									name: _config.taskRunnerSecretName
									key:  _config.taskRunnerSecretKey
								}
							},
							{name: "N8N_NATIVE_PYTHON_RUNNER", value: "\(_config.taskRunners.nativePython.enabled)"},
							{name: "EXECUTIONS_MODE", value: "queue"},
							{name: "QUEUE_BULL_REDIS_HOST", value: _config.redisHost},
							{name: "QUEUE_BULL_REDIS_PORT", value: _config.redisPort},
							if _config.hasRedisPassword {
								name: "QUEUE_BULL_REDIS_PASSWORD"
								valueFrom: secretKeyRef: {
									name: _config.redisSecretName
									key:  _config.redisSecretKey
								}
							},
							for e in _config.n8n.extraEnv {e},
						]
						resources: _config.queue.resources
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/home/node/.n8n"
							},
						]
					},
					if _config.taskRunners.mode == "external" {
						name:            "task-runners"
						image:           "\(_config.taskRunners.image.repository):\(_config.runnerImageTag)"
						imagePullPolicy: _config.taskRunners.image.pullPolicy
						securityContext: _config.securityContext
						ports: [{
							name:          "runner-health"
							containerPort: 5680
							protocol:      "TCP"
						}]
						env: [
							{name: "N8N_RUNNERS_TASK_BROKER_URI", value: "http://127.0.0.1:5679"},
							{
								name: "N8N_RUNNERS_AUTH_TOKEN"
								valueFrom: secretKeyRef: {
									name: _config.taskRunnerSecretName
									key:  _config.taskRunnerSecretKey
								}
							},
							{name: "N8N_RUNNERS_LAUNCHER_LOG_LEVEL", value: _config.n8n.logLevel},
							{name: "N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT", value: "\(_config.taskRunners.autoShutdownTimeout)"},
							{name: "N8N_RUNNERS_LAUNCHER_HEALTH_CHECK_PORT", value: "5680"},
						]
						resources: _config.taskRunners.resources
					},
				]

				// Volumes
				volumes: [
					{
						name: "data"
						if _config.queue.persistence.shareMainVolume && _config.persistence.enabled {
							persistentVolumeClaim: claimName: [
								if _config.persistence.existingClaim != "" {_config.persistence.existingClaim},
								"\(_config.fullname)-data",
							][0]
						}
						if !_config.queue.persistence.shareMainVolume || !_config.persistence.enabled {
							emptyDir: {}
						}
					},
				]
			}
		}
	}
}
