package templates

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/yaml"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels: #config.#allLabels & {
			"app.kubernetes.io/component": "web"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.autoscaling.enabled {
			replicas: #config.replicaCount
		}
		revisionHistoryLimit: #config.revisionHistoryLimit
		selector: matchLabels: #config.#webSelectorLabels
		template: corev1.#PodTemplateSpec & {
			let _secretObj = #Secret & {#config: #config}
			let _secretChecksum = hex.Encode(sha256.Sum256(yaml.Marshal(_secretObj.stringData)))

			metadata: {
				labels: #config.#webSelectorLabels & {
					for k, v in #config.podLabels {
						(k): v
					}
				}
				annotations: {
					"checksum/secret": _secretChecksum
					for k, v in #config.podAnnotations {
						(k): v
					}
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
						name:            "prepare-runtime-app"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["/bin/sh", "-ec", "cp -R /app/. /app-runtime/\n"]
						securityContext: #config.securityContext
						volumeMounts: [
							{name: "runtime-app", mountPath: "/app-runtime"},
							{name: "tmp", mountPath: "/tmp"},
						]
					},
					{
						name:  "wait-for-postgresql"
						image: "docker.io/library/busybox:1.37.0"
						command: ["sh", "-ec", "until nc -z -w2 \(#config.#databaseHost) \(#config.#databasePort) >/dev/null 2>&1; do sleep 2; done\n"]
						securityContext: {
							allowPrivilegeEscalation: false
							readOnlyRootFilesystem:   true
							runAsNonRoot:             true
							runAsUser:                65534
							runAsGroup:               65534
							capabilities: drop: ["ALL"]
							seccompProfile: type: "RuntimeDefault"
						}
					},
					if #config.redisHttp.enabled {
						{
							name:  "wait-for-redis-http"
							image: "docker.io/library/busybox:1.37.0"
							command: ["sh", "-ec", "until wget -qO- http://\(#config.#redisHttpName):\(#config.redisHttp.service.port)/ >/dev/null 2>&1; do sleep 2; done\n"]
							securityContext: {
								allowPrivilegeEscalation: false
								readOnlyRootFilesystem:   true
								runAsNonRoot:             true
								runAsUser:                65534
								runAsGroup:               65534
								capabilities: drop: ["ALL"]
								seccompProfile: type: "RuntimeDefault"
							}
						}
					},
				]

				let _entrypointScript = """
					url_encode() {
					  node -e 'process.stdout.write(encodeURIComponent(process.argv[1] || ""))' "$1"
					}
					database_username="$(url_encode "$DATABASE_USERNAME")"
					database_password="$(url_encode "$DATABASE_PASSWORD")"
					database_name="$(url_encode "$DATABASE_NAME")"
					export DATABASE_URL="postgresql://${database_username}:${database_password}@${DATABASE_HOST}:${DATABASE_PORT}/${database_name}"
					unset database_username database_password database_name
					site_url_replacement="$(printf '%s' "$NEXT_PUBLIC_SITE_URL" | sed -e 's/[\\/&|]/\\\\&/g')"
					marble_api_url_replacement="$(printf '%s' "$NEXT_PUBLIC_MARBLE_API_URL" | sed -e 's/[\\/&|]/\\\\&/g')"
					for public_env_dir in apps/web/.next apps/web/public; do
					  if [ -d "$public_env_dir" ]; then
					    find "$public_env_dir" -type f \\( -name '*.js' -o -name '*.mjs' -o -name '*.html' -o -name '*.json' -o -name '*.css' \\) \\
					      -exec sed -i \\
					        -e "s|http://localhost:3000|${site_url_replacement}|g" \\
					        -e "s|https://api.marblecms.com|${marble_api_url_replacement}|g" \\
					        {} +
					  fi
					done
					unset site_url_replacement marble_api_url_replacement public_env_dir
					exec docker-entrypoint.sh node apps/web/server.js
					"""

				containers: [
					{
						name:            "opencut"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["/bin/sh", "-ec"]
						args: [_entrypointScript]
						ports: [{
							name:          "http"
							containerPort: 3000
							protocol:      "TCP"
						}]
						env: [
							{name: "NODE_ENV", value: "production"},
							{name: "PORT", value: "3000"},
							{name: "HOSTNAME", value: "0.0.0.0"},
							{name: "NEXT_PUBLIC_SITE_URL", value: #config.#siteUrl},
							{name: "BETTER_AUTH_URL", value: #config.#siteUrl},
							{name: "NEXT_PUBLIC_MARBLE_API_URL", value: #config.opencut.marbleApiUrl},
							{name: "DATABASE_USERNAME", value: #config.#databaseUsername},
							{
								name: "DATABASE_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#databaseSecretName
									key:  #config.#databaseSecretKey
								}
							},
							{name: "DATABASE_HOST", value: #config.#databaseHost},
							{name: "DATABASE_PORT", value: "\(#config.#databasePort)"},
							{name: "DATABASE_NAME", value: #config.#databaseName},
							{
								name: "BETTER_AUTH_SECRET"
								valueFrom: secretKeyRef: {
									name: #config.#secretName
									key:  "better-auth-secret"
								}
							},
							if #config.redisHttp.enabled {
								name:  "UPSTASH_REDIS_REST_URL"
								value: "http://\(#config.#redisHttpName):\(#config.redisHttp.service.port)"
							},
							if #config.redisHttp.enabled {
								name: "UPSTASH_REDIS_REST_TOKEN"
								valueFrom: secretKeyRef: {
									name: #config.#secretName
									key:  "redis-rest-token"
								}
							},
							if !#config.redisHttp.enabled {
								name:  "UPSTASH_REDIS_REST_URL"
								value: #config.redisHttp.external.url
							},
							if !#config.redisHttp.enabled {
								name: "UPSTASH_REDIS_REST_TOKEN"
								valueFrom: secretKeyRef: {
									name: #config.#redisRestExternalSecretName
									key:  #config.#redisRestExternalSecretKey
								}
							},
							{
								name: "MARBLE_WORKSPACE_KEY"
								valueFrom: secretKeyRef: {
									name: #config.#secretName
									key:  "marble-workspace-key"
								}
							},
							{
								name: "FREESOUND_CLIENT_ID"
								valueFrom: secretKeyRef: {
									name: #config.#secretName
									key:  "freesound-client-id"
								}
							},
							{
								name: "FREESOUND_API_KEY"
								valueFrom: secretKeyRef: {
									name: #config.#secretName
									key:  "freesound-api-key"
								}
							},
							for ev in #config.opencut.extraEnv {
								ev
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

						resources:       #config.resources
						securityContext: #config.securityContext
						volumeMounts: [
							{name: "runtime-app", mountPath: "/app"},
							{name: "tmp", mountPath: "/tmp"},
							for vm in #config.extraVolumeMounts {
								vm
							},
						]
					},
				]

				volumes: [
					{name: "runtime-app", emptyDir: {}},
					{name: "tmp", emptyDir: {}},
					for v in #config.extraVolumes {
						v
					},
				]

				nodeSelector: #config.nodeSelector
				if #config.affinity != {} {
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
