package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#AppDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.#appServiceName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "app"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.app.replicaCount
		strategy: {
			type: "RollingUpdate"
			rollingUpdate: {
				maxSurge:       0
				maxUnavailable: 1
			}
		}
		selector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "app"
		}
		template: {
			metadata: {
				labels: #config.selector.labels & {
					"app.kubernetes.io/component": "app"
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            #config.#serviceAccountName
				automountServiceAccountToken: #config.serviceAccount.create
				securityContext:              #config.app.podSecurityContext
				initContainers: [{
					name:            "wait-dependencies"
					image:           "busybox:\(#config.app.busyboxTag)"
					imagePullPolicy: "IfNotPresent"
					securityContext: #config.app.initSecurityContext
					command: [
						"/bin/sh",
						"-c",
						"""
							until nc -z \(#config.#mysqlServiceName) \(#config.mysql.service.port); do
							  echo "waiting for mysql";
							  sleep 2;
							done
							until nc -z \(#config.#redisServiceName) \(#config.redis.service.port); do
							  echo "waiting for redis";
							  sleep 2;
							done
							""",
					]
				}]
				containers: [{
					name:            "app"
					image:           "\(#config.app.image.repository):\(#config.app.image.tag)"
					imagePullPolicy: #config.app.image.pullPolicy
					ports: [{
						name:          "fpm"
						containerPort: 9000
						protocol:      "TCP"
					}]
					envFrom: [{
						configMapRef: name: #config.#configName
					}]
					env: [
						{
							name: "APP_KEY"
							valueFrom: secretKeyRef: {
								name: #config.#secretName
								key:  "APP_KEY"
							}
						},
						{
							name: "DB_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #config.#secretName
								key:  "DB_PASSWORD"
							}
						},
						{
							name: "REDIS_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #config.#secretName
								key:  "REDIS_PASSWORD"
							}
						},
						{
							name: "IN_USER_EMAIL"
							valueFrom: secretKeyRef: {
								name: #config.#secretName
								key:  "IN_USER_EMAIL"
							}
						},
						{
							name: "IN_PASSWORD"
							valueFrom: secretKeyRef: {
								name: #config.#secretName
								key:  "IN_PASSWORD"
							}
						},
					]
					livenessProbe: {
						exec: command: [
							"/bin/sh",
							"-c",
							"REMOTE_ADDR=127.0.0.1 REQUEST_URI=/health REQUEST_METHOD=GET SCRIPT_FILENAME=/var/www/html/public/index.php cgi-fcgi -bind -connect 127.0.0.1:9000 | grep -q \"{\\\"status\\\":\\\"ok\\\",\\\"message\\\":\\\"API is healthy\\\"}\"",
						]
						initialDelaySeconds: 120
						timeoutSeconds:      10
						periodSeconds:       30
						failureThreshold:    5
					}
					readinessProbe: {
						exec: command: [
							"/bin/sh",
							"-c",
							"REMOTE_ADDR=127.0.0.1 REQUEST_URI=/health REQUEST_METHOD=GET SCRIPT_FILENAME=/var/www/html/public/index.php cgi-fcgi -bind -connect 127.0.0.1:9000 | grep -q \"{\\\"status\\\":\\\"ok\\\",\\\"message\\\":\\\"API is healthy\\\"}\"",
						]
						initialDelaySeconds: 40
						timeoutSeconds:      10
						periodSeconds:       20
						failureThreshold:    6
					}
					resources:       #config.app.resources
					securityContext: #config.app.securityContext
					volumeMounts: [
						{
							name:      "app-public"
							mountPath: "/var/www/html/public"
						},
						{
							name:      "app-storage"
							mountPath: "/var/www/html/storage"
						},
					]
				}]
				volumes: [
					{
						name: "app-public"
						if #config.persistence.appPublic.enabled {
							persistentVolumeClaim: claimName: "\(#config.#fullname)-app-public"
						}
						if !#config.persistence.appPublic.enabled {
							emptyDir: {}
						}
					},
					{
						name: "app-storage"
						if #config.persistence.appStorage.enabled {
							persistentVolumeClaim: claimName: "\(#config.#fullname)-app-storage"
						}
						if !#config.persistence.appStorage.enabled {
							emptyDir: {}
						}
					},
				]
				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
			}
		}
	}
}

#AppService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#appServiceName
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "app"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [{
			name:       "fpm"
			port:       9000
			targetPort: "fpm"
			protocol:   "TCP"
		}]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "app"
		}
	}
}
