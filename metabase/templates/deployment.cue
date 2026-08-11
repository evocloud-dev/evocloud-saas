package templates

import (
	"struct"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicas
		strategy: type: "RollingUpdate"
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels & #config.podLabels
				if struct.MinFields(#config.podAnnotations, 1) {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: false
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: #config.serviceAccountName
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				if struct.MinFields(#config.podSecurityContext, 1) {
					securityContext: #config.podSecurityContext
				}
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds

				initContainers: [
					{
						name:            "wait-for-db"
						image:           #config.waitForDatabase.image.reference
						imagePullPolicy: #config.waitForDatabase.image.pullPolicy
						command: [
							"sh",
							"-c",
							"echo \"Waiting for database at \(#config.dbHost):\(#config.dbPort)...\"\nuntil nc -z -w2 \(#config.dbHost) \(#config.dbPort); do\n  echo \"Database not ready, retrying in 2s...\"\n  sleep 2\ndone\necho \"Database is ready.\"\n",
						]
						if struct.MinFields(#config.securityContext, 1) {
							securityContext: #config.securityContext
						}
					},
					for ic in #config.extraInitContainers {
						ic
					},
				]

				containers: [
					{
						name:            "metabase"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						ports: [
							{
								name:          "http"
								containerPort: #config.metabase.port
								protocol:      "TCP"
							},
						]
						env: [
							{
								name:  "MB_DB_TYPE"
								value: "postgres"
							},
							{
								name:  "MB_DB_HOST"
								value: #config.dbHost
							},
							{
								name:  "MB_DB_PORT"
								value: #config.dbPort
							},
							{
								name:  "MB_DB_DBNAME"
								value: #config.dbName
							},
							{
								name:  "MB_DB_USER"
								value: #config.dbUsername
							},
							{
								name: "MB_DB_PASS"
								valueFrom: secretKeyRef: {
									name: #config.dbSecretName
									key:  #config.dbSecretPasswordKey
								}
							},
							{
								name:  "MB_JETTY_PORT"
								value: "\(#config.metabase.port)"
							},
							{
								name:  "MB_AI_FEATURES_ENABLED"
								value: "\(#config.metabase.aiFeaturesEnabled)"
							},
							{
								name: "MB_ENCRYPTION_SECRET_KEY"
								valueFrom: secretKeyRef: {
									name: #config.encryptionSecretName
									key:  #config.encryptionSecretKey
								}
							},
							if #config.metabase.siteUrl != "" {
								{
									name:  "MB_SITE_URL"
									value: #config.metabase.siteUrl
								}
							},
							{
								name:  "JAVA_TIMEZONE"
								value: #config.metabase.javaTimezone
							},
							if #config.metabase.javaOpts != "" {
								{
									name:  "JAVA_OPTS"
									value: #config.metabase.javaOpts
								}
							},
							for envVar in #config.metabase.extraEnv {
								envVar
							},
						]
						if #config.probes.startup.enabled {
							startupProbe: {
								httpGet: {
									path: #config.probes.startup.path
									port: "http"
								}
								initialDelaySeconds: #config.probes.startup.initialDelaySeconds
								periodSeconds:       #config.probes.startup.periodSeconds
								timeoutSeconds:      #config.probes.startup.timeoutSeconds
								failureThreshold:    #config.probes.startup.failureThreshold
							}
						}
						if #config.probes.liveness.enabled {
							livenessProbe: {
								httpGet: {
									path: #config.probes.liveness.path
									port: "http"
								}
								initialDelaySeconds: #config.probes.liveness.initialDelaySeconds
								periodSeconds:       #config.probes.liveness.periodSeconds
								timeoutSeconds:      #config.probes.liveness.timeoutSeconds
								failureThreshold:    #config.probes.liveness.failureThreshold
							}
						}
						if #config.probes.readiness.enabled {
							readinessProbe: {
								httpGet: {
									path: #config.probes.readiness.path
									port: "http"
								}
								initialDelaySeconds: #config.probes.readiness.initialDelaySeconds
								periodSeconds:       #config.probes.readiness.periodSeconds
								timeoutSeconds:      #config.probes.readiness.timeoutSeconds
								failureThreshold:    #config.probes.readiness.failureThreshold
							}
						}
						if struct.MinFields(#config.resources, 1) {
							resources: #config.resources
						}
						if struct.MinFields(#config.securityContext, 1) {
							securityContext: #config.securityContext
						}
						volumeMounts: [
							{
								name:      "tmp"
								mountPath: "/tmp"
							},
							for vm in #config.extraVolumeMounts {
								vm
							},
						]
					},
				]

				volumes: [
					{
						name: "tmp"
						emptyDir: {}
					},
					for v in #config.extraVolumes {
						v
					},
				]
				if struct.MinFields(#config.nodeSelector, 1) {
					nodeSelector: #config.nodeSelector
				}
				if struct.MinFields(#config.affinity, 1) {
					affinity: #config.affinity
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				if len(#config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
			}
		}
	}
}
