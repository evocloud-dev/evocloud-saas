package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels: {
			#config.metadata.labels
			"app.kubernetes.io/component": "discourse"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas:                #config.replicaCount
		progressDeadlineSeconds: #config.progressDeadlineSeconds
		strategy: type:        appsv1.#RecreateDeploymentStrategyType
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if #config.podLabels != _|_ {
					labels: #config.podLabels
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.#serviceAccountName
				automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				securityContext:               #config.podSecurityContext
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				initContainers: [
					{
						name:            "wait-for-services"
						image:           #config.waitForServices.image.reference
						imagePullPolicy: #config.waitForServices.image.pullPolicy
						securityContext: #config.waitForServices.securityContext
						resources:       #config.waitForServices.resources
						command: [
							"sh",
							"-ec",
							"""
							until nc -z -w 2 \(#config.#dbHost) \(#config.#dbPort); do sleep 2; done
							until nc -z -w 2 \(#config.#redisHost) \(#config.#redisPort); do sleep 2; done

							""",
						]
					},
				]
				containers: [
					{
						name:            "discourse"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						securityContext: #config.securityContext
						ports: [
							{
								name:          "http"
								containerPort: 80
								protocol:      corev1.#ProtocolTCP
							},
						]
						env: [
							{
								name:  "DISCOURSE_HOSTNAME"
								value: #config.discourse.hostname
							},
							{
								name:  "DISCOURSE_DEVELOPER_EMAILS"
								value: #config.discourse.developerEmails
							},
							{
								name: "DISCOURSE_SECRET_KEY_BASE"
								valueFrom: secretKeyRef: {
									name: #config.#secretName
									key:  #config.#secretKey
								}
							},
							{
								name:  "DISCOURSE_DB_HOST"
								value: #config.#dbHost
							},
							{
								name:  "DISCOURSE_DB_PORT"
								value: "\(#config.#dbPort)"
							},
							{
								name:  "DISCOURSE_DB_NAME"
								value: #config.#dbName
							},
							{
								name:  "DISCOURSE_DB_USERNAME"
								value: #config.#dbUser
							},
							{
								name: "DISCOURSE_DB_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#dbSecretName
									key:  #config.#dbSecretKey
								}
							},
							{
								name:  "DISCOURSE_REDIS_HOST"
								value: #config.#redisHost
							},
							{
								name:  "DISCOURSE_REDIS_PORT"
								value: "\(#config.#redisPort)"
							},
							if !#config.redis.enabled && (#config.redis.external.password != "" || #config.redis.external.existingSecret != "") {
								name: "DISCOURSE_REDIS_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#redisSecretName
									key:  #config.#redisSecretKey
								}
							},
							{
								name: "DISCOURSE_SKIP_EMAIL_SETUP"
								if #config.discourse.skipEmailSetup {
									value: "1"
								}
								if !#config.discourse.skipEmailSetup {
									value: "0"
								}
							},
							{
								name:  "UNICORN_WORKERS"
								value: "\(#config.discourse.unicornWorkers)"
							},
							{
								name:  "UNICORN_SIDEKIQS"
								value: "\(#config.discourse.unicornSidekiqs)"
							},
							{
								name:  "MIGRATE_ON_BOOT"
								value: "1"
							},
							{
								name:  "PRECOMPILE_ON_BOOT"
								value: "1"
							},
							{
								name:  "CREATE_DB_ON_BOOT"
								value: "0"
							},
							for envVar in #config.discourse.extraEnv {
								envVar
							},
						]
						if len(#config.discourse.extraEnvFrom) > 0 {
							envFrom: #config.discourse.extraEnvFrom
						}
						if #config.startupProbe.enabled {
							startupProbe: {
								httpGet: {
									path: #config.startupProbe.path
									port: intstr.#IntOrString & "http"
									httpHeaders: [
										{
											name:  "Host"
											value: #config.discourse.hostname
										},
									]
								}
								periodSeconds:    #config.startupProbe.periodSeconds
								timeoutSeconds:   #config.startupProbe.timeoutSeconds
								failureThreshold: #config.startupProbe.failureThreshold
							}
						}
						if #config.livenessProbe.enabled {
							livenessProbe: {
								httpGet: {
									path: #config.livenessProbe.path
									port: intstr.#IntOrString & "http"
									httpHeaders: [
										{
											name:  "Host"
											value: #config.discourse.hostname
										},
									]
								}
								periodSeconds:    #config.livenessProbe.periodSeconds
								timeoutSeconds:   #config.livenessProbe.timeoutSeconds
								failureThreshold: #config.livenessProbe.failureThreshold
							}
						}
						if #config.readinessProbe.enabled {
							readinessProbe: {
								httpGet: {
									path: #config.readinessProbe.path
									port: intstr.#IntOrString & "http"
									httpHeaders: [
										{
											name:  "Host"
											value: #config.discourse.hostname
										},
									]
								}
								periodSeconds:    #config.readinessProbe.periodSeconds
								timeoutSeconds:   #config.readinessProbe.timeoutSeconds
								failureThreshold: #config.readinessProbe.failureThreshold
							}
						}
						resources: #config.resources
						volumeMounts: [
							{
								name:      "shared"
								mountPath: "/shared"
							},
							for vm in #config.extraVolumeMounts {
								vm
							},
						]
					},
				]
				volumes: [
					{
						name: "shared"
						persistentVolumeClaim: claimName: #config.#sharedClaimName
					},
					for v in #config.extraVolumes {
						v
					},
				]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 {
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
