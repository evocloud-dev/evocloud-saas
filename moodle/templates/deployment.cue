package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if #config.maintenance.enabled {
			replicas: 0
		}
		if !#config.maintenance.enabled && !#config.autoscaling.enabled {
			replicas: #config.replicaCount
		}
		strategy: {
			if #config.#hasRWX {
				type: "RollingUpdate"
				rollingUpdate: {
					maxSurge:       1
					maxUnavailable: 0
				}
			}
			if !#config.#hasRWX {
				type: "Recreate"
			}
		}
		selector: matchLabels: #config.#selectorLabels
		template: {
			metadata: {
				labels: #config.#selectorLabels & {
					for k, v in #config.podLabels {
						"\(k)": v
					}
				}
				if len(#config.podAnnotations) > 0 {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            #config.#serviceAccountName
				automountServiceAccountToken: false
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				securityContext:               #config.podSecurityContext

				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				if #config.affinity != _|_ && len(#config.affinity) > 0 {
					affinity: #config.affinity
				}
				if len(#config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}

				initContainers: [
					{
						name:            "prepare-code"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["sh", "/opt/helmforge/prepare.sh"]
						securityContext: #config.securityContext
						resources:       #config.initResources
						env: [
							{name: "SOURCE_MODE", value: #config.source.mode},
							{name: "SOURCE_URL", value: #config.source.url},
							{name: "SOURCE_SHA256", value: #config.source.sha256},
							{name: "SOURCE_IMAGE_PATH", value: #config.source.imagePath},
							{name: "DOWNLOAD_TIMEOUT", value: "\(#config.source.downloadTimeout)"},
							{name: "METRICS_ENABLED", value: "\(#config.metrics.enabled)"},
							{name: "METRICS_PLUGIN_MODE", value: #config.metrics.plugin.mode},
							{name: "METRICS_PLUGIN_URL", value: #config.metrics.plugin.url},
							{name: "METRICS_PLUGIN_SHA256", value: #config.metrics.plugin.sha256},
						]
						volumeMounts: [
							{
								name:      "code"
								mountPath: "/var/www/html"
							},
							{
								name:      "config"
								mountPath: "/opt/helmforge"
								readOnly:  true
							},
							{
								name:      "init-tmp"
								mountPath: "/tmp"
							},
						]
					},
					{
						name:            "install-database"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["php", "/opt/helmforge/bootstrap.php"]
						securityContext: #config.securityContext
						resources:       #config.initResources
						env: [
							for e in #config.#env {e},
							{
								name: "ADMIN_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#secretName
									key:  #config.moodle.existingSecretPasswordKey
								}
							},
						]
						if len(#config.moodle.extraEnvFrom) > 0 {
							envFrom: #config.moodle.extraEnvFrom
						}
						volumeMounts: [
							for m in #config.#mounts {m},
							{
								name:      "init-tmp"
								mountPath: "/tmp"
							},
						]
					},
				]

				containers: [
					{
						name:            "moodle"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["apache2", "-f", "/opt/helmforge/apache.conf", "-DFOREGROUND"]
						securityContext: #config.securityContext
						env:             #config.#env
						if len(#config.moodle.extraEnvFrom) > 0 {
							envFrom: #config.moodle.extraEnvFrom
						}
						ports: [
							{
								name:          "http"
								containerPort: 8080
								protocol:      "TCP"
							},
							if #config.metrics.enabled {
								{
									name:          "metrics"
									containerPort: 9090
									protocol:      "TCP"
								}
							},
						]
						startupProbe: {
							httpGet: {path: "/healthz.php", port: "http"}
							periodSeconds:    5
							timeoutSeconds:   3
							failureThreshold: 60
						}
						livenessProbe: {
							httpGet: {path: "/healthz.php", port: "http"}
							periodSeconds:    15
							timeoutSeconds:   5
							failureThreshold: 3
						}
						readinessProbe: {
							httpGet: {path: "/readyz.php", port: "http"}
							periodSeconds:    10
							timeoutSeconds:   8
							failureThreshold: 3
						}
						resources: #config.resources
						volumeMounts: [
							for m in #config.#mounts {m},
							{
								name:      "web-tmp"
								mountPath: "/tmp"
							},
						]
					},
					if #config.cron.enabled {
						{
							name:            "cron"
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
							command: ["sh", "/opt/helmforge/runner.sh", "cron", "\(#config.cron.interval)"]
							securityContext: #config.securityContext
							env:             #config.#env
							if len(#config.moodle.extraEnvFrom) > 0 {
								envFrom: #config.moodle.extraEnvFrom
							}
							resources: #config.cron.resources
							volumeMounts: [
								for m in #config.#mounts {m},
								{
									name:      "cron-tmp"
									mountPath: "/tmp"
								},
							]
						}
					},
					if #config.adhoc.enabled {
						{
							name:            "adhoc"
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
							command: ["sh", "/opt/helmforge/runner.sh", "adhoc", "\(#config.adhoc.keepAlive)"]
							securityContext: #config.securityContext
							env:             #config.#env
							if len(#config.moodle.extraEnvFrom) > 0 {
								envFrom: #config.moodle.extraEnvFrom
							}
							resources: #config.adhoc.resources
							volumeMounts: [
								for m in #config.#mounts {m},
								{
									name:      "adhoc-tmp"
									mountPath: "/tmp"
								},
							]
						}
					},
				]

				volumes: [
					if #config.metrics.enabled {
						{
							name: "metrics-token"
							secret: {
								secretName:  #config.#metricsSecret
								defaultMode: 0o440
								items: [{
									key:  #config.metrics.existingSecretTokenKey
									path: "token"
								}]
							}
						}
					},
					{
						name: "code"
						emptyDir: {}
					},
					{
						name: "data"
						if #config.persistence.enabled {
							persistentVolumeClaim: claimName: #config.#dataClaim
						}
						if !#config.persistence.enabled {
							emptyDir: {}
						}
					},
					{
						name: "config"
						configMap: {
							name:        #config.#cmName
							defaultMode: 0o444
						}
					},
					{name: "init-tmp", emptyDir: {}},
					{name: "web-tmp", emptyDir: {}},
					{name: "cron-tmp", emptyDir: {}},
					{name: "adhoc-tmp", emptyDir: {}},
					if #config.database.tlsSecret != "" {
						{
							name: "database-tls"
							secret: {
								secretName: #config.database.tlsSecret
								items: [{
									key:  #config.database.tlsCAKey
									path: "ca.crt"
								}]
							}
						}
					},
					if #config.sessions.tlsSecret != "" {
						{
							name: "redis-tls"
							secret: {
								secretName: #config.sessions.tlsSecret
								items: [{
									key:  #config.sessions.tlsCAKey
									path: "ca.crt"
								}]
							}
						}
					},
					for v in #config.extraVolumes {
						v
					},
				]
			}
		}
	}
}
