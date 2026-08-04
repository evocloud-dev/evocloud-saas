// SPDX-License-Identifier: Apache-2.0

package templates

import (
	"struct"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

// #Deployment mirrors templates/deployment.yaml from the Countly Helm chart.
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
		replicas: 1
		strategy: type:        "RollingUpdate"
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels & #config.podLabels
				if struct.MinFields(#config.podAnnotations, 1) {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.serviceAccount.create {
					serviceAccountName: #config.serviceAccountName
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				if struct.MinFields(#config.podSecurityContext, 1) {
					securityContext: #config.podSecurityContext
				}
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds

				if #config.mongodb.enabled && !#config.externalMongodb.enabled {
					initContainers: [{
						name:  "wait-for-mongodb"
						image: "docker.io/library/busybox:1.37"
						command: [
							"sh",
							"-c",
							"until nc -z \(#config.mongodbHost) 27017; do echo waiting for mongodb; sleep 2; done",
						]
					}]
				}

				containers: [{
					name:            "countly"
					image:           #config.image.reference
					imagePullPolicy: #config.image.pullPolicy
					command: ["/bin/sh", "-c"]
					args: ["touch /etc/service/mongodb/down && exec /sbin/my_init"]
					ports: [
						{
							name:          "api"
							containerPort: #config.countly.apiPort
							protocol:      "TCP"
						},
						{
							name:          "dashboard"
							containerPort: #config.countly.dashboardPort
							protocol:      "TCP"
						},
					]
					env: [
						if !#config.externalMongodb.enabled {
							{
								name: "MONGODB_ROOT_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.mongodbSecretName
									key:  "mongodb-root-password"
								}
							}
						},
						if !#config.externalMongodb.enabled {
							{
								name:  "COUNTLY_CONFIG__MONGODB"
								value: #config.mongodbURI
							}
						},
						if #config.externalMongodb.enabled && #config.externalMongodb.existingSecret != "" {
							{
								name: "COUNTLY_CONFIG__MONGODB"
								valueFrom: secretKeyRef: {
									name: #config.externalMongodb.existingSecret
									key:  #config.externalMongodb.existingSecretUriKey
								}
							}
						},
						if #config.externalMongodb.enabled && #config.externalMongodb.existingSecret == "" {
							{
								name:  "COUNTLY_CONFIG__MONGODB"
								value: #config.externalMongodb.uri
							}
						},
						{name: "COUNTLY_CONFIG_API_API_HOST", value: "0.0.0.0"},
						{name: "COUNTLY_CONFIG_API_API_PORT", value: "\(#config.countly.apiPort)"},
						{name: "COUNTLY_CONFIG_FRONTEND_WEB_HOST", value: "0.0.0.0"},
						{name: "COUNTLY_CONFIG_FRONTEND_WEB_PORT", value: "\(#config.countly.dashboardPort)"},
						{name: "COUNTLY_CONFIG_API_API_WORKERS", value: "\(#config.countly.apiWorkers)"},
						{name: "TZ", value: #config.countly.timezone},
						if #config.countly.plugins != "" {
							{name: "COUNTLY_PLUGINS", value: #config.countly.plugins}
						},
						for envVar in #config.countly.extraEnv {
							envVar
						},
					]

					if #config.probes.startup.enabled {
						startupProbe: {
							tcpSocket: port: "dashboard"
							initialDelaySeconds: #config.probes.startup.initialDelaySeconds
							periodSeconds:       #config.probes.startup.periodSeconds
							timeoutSeconds:      #config.probes.startup.timeoutSeconds
							failureThreshold:    #config.probes.startup.failureThreshold
						}
					}
					if #config.probes.liveness.enabled {
						livenessProbe: {
							tcpSocket: port: "dashboard"
							initialDelaySeconds: #config.probes.liveness.initialDelaySeconds
							periodSeconds:       #config.probes.liveness.periodSeconds
							timeoutSeconds:      #config.probes.liveness.timeoutSeconds
							failureThreshold:    #config.probes.liveness.failureThreshold
						}
					}
					if #config.probes.readiness.enabled {
						readinessProbe: {
							tcpSocket: port: "dashboard"
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
					if len(#config.extraVolumeMounts) > 0 {
						volumeMounts: #config.extraVolumeMounts
					}
				}]

				if len(#config.extraVolumes) > 0 {
					volumes: #config.extraVolumes
				}
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
