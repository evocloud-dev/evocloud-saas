package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"list"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#APIDeployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-api"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "api"
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.api.autoscaling.enabled {
			replicas: #config.api.replicaCount
		}
		selector: matchLabels: (timoniv1.#Selector & {#Name: "\(#config.metadata.name)-api"}).labels & {
			"app.kubernetes.io/component": "api"
		}
		template: {
			metadata: {
				labels: (timoniv1.#Selector & {#Name: "\(#config.metadata.name)-api"}).labels & {
					"app.kubernetes.io/component": "api"
				}
				if #config.api.podAnnotations != _|_ {
					annotations: #config.api.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if #config.api.imagePullSecrets != _|_ {
					imagePullSecrets: #config.api.imagePullSecrets
				}
				serviceAccountName: #config.metadata.name
				if #config.api.podSecurityContext != _|_ {
					securityContext: #config.api.podSecurityContext
				}
				if #config.api.replicaCount > 1 {
					affinity: podAntiAffinity: preferredDuringSchedulingIgnoredDuringExecution: [
						{
							weight: 100
							podAffinityTerm: {
								labelSelector: matchExpressions: [
									{
										key:      "app.kubernetes.io/component"
										operator: "In"
										values: ["api"]
									},
								]
								topologyKey: "kubernetes.io/hostname"
							}
						},
					]
				}
				containers: [
					{
						name: "api"
						if #config.api.securityContext != _|_ {
							securityContext: #config.api.securityContext
						}
						image:           "\(#config.global.image.repository):\(#config.global.image.tag)"
						imagePullPolicy: #config.global.image.pullPolicy
						ports: [{
							name:          "http"
							containerPort: #config.api.service.port
							protocol:      "TCP"
						}]
						startupProbe: {
							httpGet: {
								path: "/health/"
								port: "http"
							}
							initialDelaySeconds: 10
							periodSeconds:       5
							timeoutSeconds:      5
							failureThreshold:    30
						}
						livenessProbe: {
							httpGet: {
								path: "/health/"
								port: "http"
							}
							initialDelaySeconds: 30
							periodSeconds:       10
							timeoutSeconds:      5
							successThreshold:    1
							failureThreshold:    3
						}
						readinessProbe: {
							httpGet: {
								path: "/health/"
								port: "http"
							}
							initialDelaySeconds: 30
							periodSeconds:       10
							timeoutSeconds:      5
							successThreshold:    1
							failureThreshold:    3
						}
						resources: #config.api.resources
						volumeMounts: [
							if #config.#internal.readReplicaEnabled {
								{
									name:      "settings"
									mountPath: "/app/saleor/settings.py"
									subPath:   "settings.py"
								}
							},
							if #config.storage.gcs.enabled {
								{
									name:      "gcs-credentials"
									mountPath: "/var/secrets/google"
									readOnly:  true
								}
							},
						]
						_publicUrlProtocol: string | *"http"
						if #config.ingress.api.tls != [] {
							_publicUrlProtocol: "https"
						}
						env: list.Concat([
							[
								{
									name:  "PORT"
									value: "\(#config.api.service.port)"
								},
								if #config.ingress.api.enabled && #config.ingress.api.hosts != [] {
									{
										name:  "PUBLIC_URL"
										value: "\(_publicUrlProtocol)://\(#config.ingress.api.hosts[0].host)"
									}
								},
								{
									name: "DATABASE_URL"
									valueFrom: secretKeyRef: {
										name: "\(#config.metadata.name)-secrets"
										key:  "database-url"
									}
								},
								{
									name: "DATABASE_URL_REPLICA"
									if #config.global.database.replicaUrl != "" {
										value: #config.global.database.replicaUrl
									}
									if #config.global.database.replicaUrl == "" {
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-secrets"
											key:  "database-url-replica"
										}
									}
								},
								{
									name:  "DB_CONN_MAX_AGE"
									value: "\(#config.global.database.connMaxAge)"
								},
								if #config.global.jwtRsaPrivateKey != _|_ {
									{
										name: "RSA_PRIVATE_KEY"
										valueFrom: secretKeyRef: {
											name: "\(#config.metadata.name)-secrets"
											key:  "jwt-private-key"
										}
									}
								},
								{
									name:  "DATABASE_CONNECTION_TIMEOUT"
									value: "\(#config.global.database.connectionTimeout)"
								},
								{
									name:  "DATABASE_MAX_CONNECTIONS"
									value: "\(#config.global.database.maxConnections)"
								},
								{
									name: "REDIS_URL"
									valueFrom: secretKeyRef: {
										name: "\(#config.metadata.name)-secrets"
										key:  "redis-url"
									}
								},
								{
									name: "CELERY_BROKER_URL"
									valueFrom: secretKeyRef: {
										name: "\(#config.metadata.name)-secrets"
										key:  "celery-redis-url"
									}
								},
								{
									name: "SECRET_KEY"
									valueFrom: secretKeyRef: {
										name: "\(#config.metadata.name)-secrets"
										key:  "secret-key"
									}
								},
							],
							#config.api.extraEnv,
							#config.#internal.s3Env,
							#config.#internal.gcsEnv,
						])
					},
				]
				volumes: [
					if #config.#internal.readReplicaEnabled {
						{
							name: "settings"
							configMap: name: "\(#config.metadata.name)-settings"
						}
					},
					if #config.storage.gcs.enabled && #config.storage.gcs.credentials.jsonKey != "" {
						{
							name: "gcs-credentials"
							secret: secretName: "\(#config.metadata.name)-gcs-credentials"
						}
					},
				]
				if #config.api.nodeSelector != _|_ {
					nodeSelector: #config.api.nodeSelector
				}
				if #config.api.tolerations != _|_ {
					tolerations: #config.api.tolerations
				}
				if #config.api.affinity != _|_ {
					affinity: #config.api.affinity
				}
			}
		}
	}
}
