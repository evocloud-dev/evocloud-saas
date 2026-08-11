package templates

import (
	"list"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicaCount
		strategy: type: "Recreate"
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels & {
					if #config.podLabels != _|_ {
						#config.podLabels
					}
				}
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: false
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.serviceAccount.create {
					serviceAccountName: *#config.fullname | string
					if #config.serviceAccount.name != "" {
						serviceAccountName: #config.serviceAccount.name
					}
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds

				initContainers: [
					{
						name:            "init-assets"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["sh", "-c", "cp -r /var/www/wallabag/var/. /mnt/var/ && cp -r /var/www/wallabag/app/config/. /mnt/config/ && cp -r /etc/s6/. /mnt/s6/ && ([ \"$(ls -A /mnt/data-uploads 2>/dev/null)\" ] || cp -r /var/www/wallabag/web/uploads/. /mnt/data-uploads/) && (chmod -R 777 /mnt/var /mnt/config /mnt/s6 /mnt/data-uploads || true)"]
						volumeMounts: [
							{
								name:      "wallabag-var"
								mountPath: "/mnt/var"
							},
							{
								name:      "wallabag-config"
								mountPath: "/mnt/config"
							},
							{
								name:      "wallabag-s6"
								mountPath: "/mnt/s6"
							},
							{
								name:      "data"
								mountPath: "/mnt/data-uploads"
								subPath:   "uploads"
							},
						]
						if #config.securityContext != _|_ {
							securityContext: #config.securityContext
						}
					},
					{
						name:  "wait-for-db"
						image: "docker.io/library/busybox:1.37"
						command: [
							"sh",
							"-c",
							"echo \"Waiting for database at \(#config.dbHost):\(#config.dbPort)...\"\nuntil nc -z -w2 \(#config.dbHost) \(#config.dbPort); do\n  echo \"Database not ready, retrying in 2s...\"\n  sleep 2\ndone\necho \"Database is ready.\"\n",
						]
						if #config.securityContext != _|_ {
							securityContext: #config.securityContext
						}
					},
					{
						name:            "db-migrate"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["sh", "-c"]
						args: [
							"""
							envsubst < /etc/wallabag/parameters.template.yml > /var/www/wallabag/app/config/parameters.yml
							php bin/console doctrine:migrations:migrate --env=prod --no-interaction
							php bin/console fos:user:create "$ADMIN_USER" "$ADMIN_EMAIL" "$ADMIN_PASSWORD" --super-admin --env=prod -n || echo "Admin user already exists or failed to create"
							"""
						]
						env: list.Concat([
							containers[0].env,
							[
								{
									name: "ADMIN_USER"
									valueFrom: secretKeyRef: {
										name: #config.fullname
										key:  "wallabag-username"
									}
								},
								{
									name: "ADMIN_EMAIL"
									valueFrom: secretKeyRef: {
										name: #config.fullname
										key:  "wallabag-email"
									}
								},
								{
									name: "ADMIN_PASSWORD"
									valueFrom: secretKeyRef: {
										name: #config.fullname
										key:  "wallabag-password"
									}
								},
							]
						])
						volumeMounts: containers[0].volumeMounts
						if #config.securityContext != _|_ {
							securityContext: #config.securityContext
						}
					},
				]

				containers: [
					{
						name:            "wallabag"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["sh", "-c"]
						args: [
							"""
							mkdir -p /var/log/nginx /var/lib/nginx/tmp /var/lib/nginx/logs
							chmod -R 777 /var/log /var/lib/nginx /run /var/run /var/www/wallabag/var /var/www/wallabag/app/config /var/www/wallabag/web/uploads || true
							envsubst < /etc/wallabag/parameters.template.yml > /var/www/wallabag/app/config/parameters.yml
							exec s6-svscan /etc/s6
							"""
						]
						ports: [
							{
								name:          "http"
								containerPort: #config.wallabag.port
								protocol:      "TCP"
							},
						]
						env: list.Concat([
							[
								{
									name:  "SYMFONY__ENV__DATABASE_DRIVER"
									value: "pdo_pgsql"
								},
								{
									name:  "SYMFONY__ENV__DATABASE_HOST"
									value: #config.dbHost
								},
								{
									name:  "SYMFONY__ENV__DATABASE_PORT"
									value: #config.dbPort
								},
								{
									name:  "SYMFONY__ENV__DATABASE_NAME"
									value: #config.dbName
								},
								{
									name:  "SYMFONY__ENV__DATABASE_USER"
									value: #config.dbUsername
								},
								{
									name: "SYMFONY__ENV__DATABASE_PASSWORD"
									valueFrom: secretKeyRef: {
										name: #config.dbSecretName
										key:  #config.dbSecretPasswordKey
									}
								},
								{
									name:  "SYMFONY__ENV__DOMAIN_NAME"
									value: #config.wallabag.domainName
								},
								{
									name: "SYMFONY__ENV__SECRET"
									valueFrom: secretKeyRef: {
										name: #config.appSecretName
										key:  #config.appSecretKey
									}
								},
								{
									name:  "SYMFONY__ENV__FOSUSER_REGISTRATION"
									value: "\( #config.wallabag.registration )"
								},
								if #config.redis.enabled || #config.externalRedis.host != "" {
									{
										name:  "SYMFONY__ENV__REDIS_HOST"
										value: "redis://\(#config.redisHost):\(#config.redisPort)"
									}
								},
							],
							#config.wallabag.extraEnv,
						])

						if #config.probes.startup.enabled {
							startupProbe: {
								tcpSocket: port: "http"
								initialDelaySeconds: #config.probes.startup.initialDelaySeconds
								periodSeconds:       #config.probes.startup.periodSeconds
								timeoutSeconds:      #config.probes.startup.timeoutSeconds
								failureThreshold:    #config.probes.startup.failureThreshold
							}
						}
						if #config.probes.liveness.enabled {
							livenessProbe: {
								tcpSocket: port: "http"
								initialDelaySeconds: #config.probes.liveness.initialDelaySeconds
								periodSeconds:       #config.probes.liveness.periodSeconds
								timeoutSeconds:      #config.probes.liveness.timeoutSeconds
								failureThreshold:    #config.probes.liveness.failureThreshold
							}
						}
						if #config.probes.readiness.enabled {
							readinessProbe: {
								tcpSocket: port: "http"
								initialDelaySeconds: #config.probes.readiness.initialDelaySeconds
								periodSeconds:       #config.probes.readiness.periodSeconds
								timeoutSeconds:      #config.probes.readiness.timeoutSeconds
								failureThreshold:    #config.probes.readiness.failureThreshold
							}
						}

						if #config.resources != _|_ {
							resources: #config.resources
						}
						if #config.securityContext != _|_ {
							securityContext: #config.securityContext
						}

						volumeMounts: list.Concat([
							[
								{
									name:      "data"
									mountPath: "/var/www/wallabag/data"
								},
								{
									name:      "wallabag-var"
									mountPath: "/var/www/wallabag/var"
								},
								{
									name:      "wallabag-config"
									mountPath: "/var/www/wallabag/app/config"
								},
								{
									name:      "run"
									mountPath: "/var/run"
								},
								{
									name:      "run"
									mountPath: "/run"
								},
								{
									name:      "var-log"
									mountPath: "/var/log"
								},
								{
									name:      "nginx-lib"
									mountPath: "/var/lib/nginx"
								},
								{
									name:      "wallabag-s6"
									mountPath: "/etc/s6"
								},
								{
									name:      "data"
									mountPath: "/var/www/wallabag/web/uploads"
									subPath:   "uploads"
								},
							],
							#config.extraVolumeMounts,
						])
					},
				]

				volumes: list.Concat([
					[
						{
							name: "data"
							if #config.persistence.enabled {
								persistentVolumeClaim: claimName: #config.dataClaimName
							}
							if !#config.persistence.enabled {
								emptyDir: {}
							}
						},
						{
							name: "wallabag-var"
							emptyDir: {}
						},
						{
							name: "wallabag-config"
							emptyDir: {}
						},
						{
							name: "run"
							emptyDir: {}
						},
						{
							name: "var-log"
							emptyDir: {}
						},
						{
							name: "nginx-lib"
							emptyDir: {}
						},
						{
							name: "wallabag-s6"
							emptyDir: {}
						},
					],
					#config.extraVolumes,
				])

				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
			}
		}
	}
}
