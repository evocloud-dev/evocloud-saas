package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#JobMaintenance: batchv1.#Job & {
	#config: #Config

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(#config.#fullname)-maint-\(#config.maintenance.runId)"
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: batchv1.#JobSpec & {
		backoffLimit:          0
		activeDeadlineSeconds: #config.maintenance.activeDeadlineSeconds
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "\(#config.#name)-maintenance"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            #config.#serviceAccountName
				automountServiceAccountToken: false
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				securityContext:               #config.podSecurityContext
				restartPolicy:                 "Never"

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

				// Only the first init container (prepare-code)
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
				]

				// Derived container: moodle container with maintenance action and initResources, without probes/ports
				containers: [
					{
						name:            "maintenance"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["php", "/opt/helmforge/maintenance.php", #config.maintenance.action]
						securityContext: #config.securityContext
						resources:       #config.initResources
						env:             #config.#env
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
