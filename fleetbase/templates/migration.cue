package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#MigrationJob: batchv1.#Job & {
	#config: #Config

	#meta: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "migration"
	}

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata:   #meta
	metadata: annotations: timoniv1.Action.Force
	spec: batchv1.#JobSpec & {
		backoffLimit: 6
		template: corev1.#PodTemplateSpec & {
			spec: corev1.#PodSpec & {
				restartPolicy:                corev1.#RestartPolicyNever
				serviceAccountName:           #config.serviceAccountName
				automountServiceAccountToken: #config.automountServiceAccountToken
				containers: [
					{
						name:            "migration"
						image:           #config.images.api.reference
						imagePullPolicy: #config.images.api.pullPolicy
						command: [
							"sh",
							"-c",
							"""
							echo "Waiting for database connection..."
							until php -r '
							$url = parse_url(getenv("DATABASE_URL") ?: "");
							$host = $url["host"] ?? "localhost";
							$port = isset($url["port"]) ? (int)$url["port"] : 3306;
							$fp = @fsockopen($host, $port, $errno, $errstr, 2);
							if ($fp) { fclose($fp); exit(0); }
							exit(1);
							'; do
							  echo "Database is not ready yet, retrying in 3 seconds..."
							  sleep 3
							done
							echo "Database is reachable! Running deploy script..."
							exec ./deploy.sh
							""",
						]
						// Environment variables matching application
						env: [
							{name: "ENVIRONMENT", value: #config.app.environment},
							{name: "APP_KEY", value:     #config.app.key},
							if #config.database.enabled {
								name: "DATABASE_URL"
								if #config.database.allowEmptyPassword {
									value: "mysql://" + #config.database.user + "@" + #config.metadata.name + "-mysql:3306/" + #config.database.name
								}
								if !#config.database.allowEmptyPassword {
									value: "mysql://" + #config.database.user + ":" + #config.database.password + "@" + #config.metadata.name + "-mysql:3306/" + #config.database.name
								}
							},
							if !#config.database.enabled && #config.database.url != _|_ {
								name:  "DATABASE_URL"
								value: #config.database.url
							},
							if !#config.database.enabled && #config.database.urlSecretRef != _|_ {
								name: "DATABASE_URL"
								valueFrom: secretKeyRef: {
									name: #config.database.urlSecretRef.name
									key:  #config.database.urlSecretRef.key
								}
							},
							{name: "QUEUE_CONNECTION", value: "redis"},
							{name: "CACHE_DRIVER", value: "redis"},
							{name: "CACHE_PATH", value: "/fleetbase/api/storage/framework/cache"},
							if #config.cache.enabled {
								name:  "CACHE_URL"
								value: "tcp://" + #config.metadata.name + "-redis:6379"
							},
							if #config.cache.enabled {
								name:  "REDIS_URL"
								value: "tcp://" + #config.metadata.name + "-redis:6379"
							},
							if !#config.cache.enabled && #config.cache.url != _|_ {
								name:  "CACHE_URL"
								value: #config.cache.url
							},
							if !#config.cache.enabled && #config.cache.url != _|_ {
								name:  "REDIS_URL"
								value: #config.cache.url
							},
							if !#config.cache.enabled && #config.cache.urlSecretRef != _|_ {
								name: "CACHE_URL"
								valueFrom: secretKeyRef: {
									name: #config.cache.urlSecretRef.name
									key:  #config.cache.urlSecretRef.key
								}
							},
							if !#config.cache.enabled && #config.cache.urlSecretRef != _|_ {
								name: "REDIS_URL"
								valueFrom: secretKeyRef: {
									name: #config.cache.urlSecretRef.name
									key:  #config.cache.urlSecretRef.key
								}
							},
							{name: "SESSION_DOMAIN", value: "localhost"},
							{name: "BROADCAST_DRIVER", value: "socketcluster"},
							{name: "MAIL_FROM_NAME", value: "Fleetbase"},
							{name: "APP_NAME", value: "Fleetbase"},
							{name: "LOG_CHANNEL", value: "daily"},
							{name: "REGISTRY_HOST", value: "https://registry.fleetbase.io"},
							{name: "REGISTRY_PREINSTALLED_EXTENSIONS", value: "true"},
							{name: "OSRM_HOST", value: "https://router.project-osrm.org"},
							if #config.socket.enabled {
								name:  "SOCKETCLUSTER_HOST"
								value: #config.metadata.name + "-socket"
							},
							if #config.socket.enabled {
								name:  "SOCKETCLUSTER_PORT"
								value: "\(#config.socket.port)"
							},
							if #config.migration.extraEnv != _|_ {
								for e in #config.migration.extraEnv {e}
							},
							if #config.migration.extraEnv == _|_ && #config.app.extraEnv != _|_ {
								for e in #config.app.extraEnv {e}
							},
						]
						envFrom: [
							if #config.migration.secretRef != _|_ {
								secretRef: name: #config.migration.secretRef
							},
							if #config.migration.secretRef == _|_ && #config.app.secretRef != _|_ {
								secretRef: name: #config.app.secretRef
							},
						]
						resources: #config.migration.resources
						if #config.migration.securityContext != _|_ {
							securityContext: #config.migration.securityContext
						}
					},
				]
				if #config.podSecurityContext != _|_ {
					securityContext: #config.podSecurityContext
				}
				nodeSelector: #config.nodeSelector
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
			}
		}
	}
}