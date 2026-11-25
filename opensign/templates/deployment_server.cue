package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

#ServerDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-server"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.server.replicas
		selector: metav1.#LabelSelector & {
			matchLabels: {
				"app.kubernetes.io/name":     "opensign-server"
				"app.kubernetes.io/instance": #config.metadata.name
			}
		}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: {
					"app.kubernetes.io/name":     "opensign-server"
					"app.kubernetes.io/instance": #config.metadata.name
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: false
				serviceAccountName: [
					if #config.server.serviceAccount.name != "" {#config.server.serviceAccount.name},
					"\(#config.metadata.name)-server",
				][0]
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				containers: [{
					name:            "server"
					image:           #config.server.image.reference
					imagePullPolicy: #config.server.image.pullPolicy
					ports: [{
						name:          "http"
						containerPort: #config.server.port
						protocol:      "TCP"
					}]
					env: [
						{
							name:  "NODE_ENV"
							value: #config.server.env.NODE_ENV
						},
						{
							name: "HOST_URL"
							valueFrom: secretKeyRef: {
								name: [
									if #config.existingSecret != "" {#config.existingSecret},
									"\(#config.metadata.name)-env",
								][0]
								key: "HOST_URL"
							}
						},
						{
							name: "SERVER_URL"
							valueFrom: secretKeyRef: {
								name: [
									if #config.existingSecret != "" {#config.existingSecret},
									"\(#config.metadata.name)-env",
								][0]
								key: "SERVER_URL"
							}
						},
						{
							name: "PUBLIC_URL"
							valueFrom: secretKeyRef: {
								name: [
									if #config.existingSecret != "" {#config.existingSecret},
									"\(#config.metadata.name)-env",
								][0]
								key: "PUBLIC_URL"
							}
						},
						if #config.externalMongodb.enabled && #config.externalMongodb.existingSecret != "" {
							name: "MONGO_URI"
							valueFrom: secretKeyRef: {
								name: #config.externalMongodb.existingSecret
								key: [
									if #config.externalMongodb.existingSecretUriKey != "" {#config.externalMongodb.existingSecretUriKey},
									#config.externalMongodb.existingSecretKey,
								][0]
							}
						},
						if #config.externalMongodb.enabled && #config.externalMongodb.existingSecret != "" {
							name: "MONGODB_URI"
							valueFrom: secretKeyRef: {
								name: #config.externalMongodb.existingSecret
								key: [
									if #config.externalMongodb.existingSecretUriKey != "" {#config.externalMongodb.existingSecretUriKey},
									#config.externalMongodb.existingSecretKey,
								][0]
							}
						},
						if #config.externalMongodb.enabled && #config.externalMongodb.existingSecret == "" && #config.externalMongodb.uri != "" {
							name:  "MONGO_URI"
							value: #config.externalMongodb.uri
						},
						if #config.externalMongodb.enabled && #config.externalMongodb.existingSecret == "" && #config.externalMongodb.uri != "" {
							name:  "MONGODB_URI"
							value: #config.externalMongodb.uri
						},
						if !#config.externalMongodb.enabled && #config.mongodb.enabled {
							name:  "MONGO_URI"
							value: "mongodb://\(#config.metadata.name)-mongo:\(#config.mongodb.port)/opensign"
						},
						if !#config.externalMongodb.enabled && #config.mongodb.enabled {
							name:  "MONGODB_URI"
							value: "mongodb://\(#config.metadata.name)-mongo:\(#config.mongodb.port)/opensign"
						},
					]
					envFrom: [{
						secretRef: name: [
							if #config.existingSecret != "" {#config.existingSecret},
							"\(#config.metadata.name)-env",
						][0]
					}]
					resources:       #config.server.resources
					securityContext: #config.server.securityContext
					if #config.server.probes.readiness.enabled {
						readinessProbe: {
							tcpSocket: port: #config.server.port
							initialDelaySeconds: #config.server.probes.readiness.initialDelaySeconds
							periodSeconds:       #config.server.probes.readiness.periodSeconds
							timeoutSeconds:      #config.server.probes.readiness.timeoutSeconds
							failureThreshold:    #config.server.probes.readiness.failureThreshold
						}
					}
					if #config.server.probes.liveness.enabled {
						livenessProbe: {
							tcpSocket: port: #config.server.port
							initialDelaySeconds: #config.server.probes.liveness.initialDelaySeconds
							periodSeconds:       #config.server.probes.liveness.periodSeconds
							timeoutSeconds:      #config.server.probes.liveness.timeoutSeconds
							failureThreshold:    #config.server.probes.liveness.failureThreshold
						}
					}
					if #config.server.probes.startup.enabled {
						startupProbe: {
							tcpSocket: port: #config.server.port
							initialDelaySeconds: #config.server.probes.startup.initialDelaySeconds
							periodSeconds:       #config.server.probes.startup.periodSeconds
							timeoutSeconds:      #config.server.probes.startup.timeoutSeconds
							failureThreshold:    #config.server.probes.startup.failureThreshold
						}
					}
					volumeMounts: [{
						name:      "files"
						mountPath: "/usr/src/app/files"
					}]
				}]
				volumes: [
					if #config.server.persistence.enabled {
						name: "files"
						persistentVolumeClaim: claimName: "\(#config.metadata.name)-files"
					},
					if !#config.server.persistence.enabled {
						name: "files"
						emptyDir: {}
					},
				]
			}
		}
	}
}
