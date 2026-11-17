package templates

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"strconv"
	"strings"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

// #Deployment mirrors templates/deployment.yaml.
#Deployment: appsv1.#Deployment & {
	#config: #Config
	#cmData: [string]: string

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		strategy: type:        "Recreate"
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels & #config.podLabels & {
					"app.kubernetes.io/component": "server"
				}
				annotations: {
					"checksum/config": hex.Encode(sha256.Sum256(json.Marshal(#cmData)))
					"checksum/secret": hex.Encode(sha256.Sum256(json.Marshal({
						database:        #config.ntfy.database
						admin:           #config.ntfy.admin
						oidc:            #config.oidc
						smtp:            #config.smtp
						externalSecrets: #config.externalSecrets
					})))
					#config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName:           #config._saName
				automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				securityContext:               #config.podSecurityContext
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				if #config._dbEnabled || #config.ntfy.admin.enabled {
					initContainers: [
						if #config._dbEnabled {
							name:            "wait-for-db"
							image:           #config.ntfy.database.waitImage.reference
							imagePullPolicy: #config.ntfy.database.waitImage.pullPolicy
							command: [
								"sh",
								"-c",
								"""
								echo "Waiting for database at \(#config._dbHost):\(#config._dbPort)..."
								until nc -z -w2 \(#config._dbHost) \(#config._dbPort); do
								  echo "Database not ready, retrying in 2s..."
								  sleep 2
								done
								echo "Database is ready."
								""",
							]
							resources: {
								limits: {
									cpu:    "50m"
									memory: "32Mi"
								}
								requests: {
									cpu:    "10m"
									memory: "16Mi"
								}
							}
							securityContext: #config.securityContext
						},
						if #config.ntfy.admin.enabled {
							name:            "init-admin"
							image:           #config.image.reference
							imagePullPolicy: #config.image.pullPolicy
							command: [
								"/bin/sh",
								"-c",
								"""
								AUTH_FILE="/var/cache/ntfy/auth.db"
								mkdir -p /var/cache/ntfy
								if [ ! -f "$AUTH_FILE" ]; then
								  ntfy serve --auth-file=/var/cache/ntfy/auth.db --listen-http=:18080 &
								  PID=$!
								  for i in $(seq 1 30); do
								    if [ -f "$AUTH_FILE" ]; then break; fi
								    sleep 1
								  done
								  kill -TERM $PID 2>/dev/null || true
								  wait $PID 2>/dev/null || true
								fi
								if [ ! -f "$AUTH_FILE" ]; then
								  echo "ERROR: Failed to initialize $AUTH_FILE within timeout" >&2
								  exit 1
								fi
								echo "Bootstrapping admin user '$ADMIN_USER'..."
								NTFY_AUTH_FILE="$AUTH_FILE" ntfy user add --role="\(#config.ntfy.admin.role)" --ignore-exists "$ADMIN_USER"
								""",
							]
							env: [
								{
									name: "ADMIN_USER"
									if #config.ntfy.admin.existingSecret != "" && #config.ntfy.admin.existingSecretUsernameKey != "" {
										valueFrom: secretKeyRef: {
											name: #config._adminSecretName
											key:  #config.ntfy.admin.existingSecretUsernameKey
										}
									}
									if !(#config.ntfy.admin.existingSecret != "" && #config.ntfy.admin.existingSecretUsernameKey != "") {
										value: #config.ntfy.admin.username
									}
								},
								{
									name: "NTFY_PASSWORD"
									valueFrom: secretKeyRef: {
										name: #config._adminSecretName
										key:  #config._adminPassKey
									}
								},
							]
							volumeMounts: [
								{name: "data", mountPath: "/var/cache/ntfy"},
								{name: "tmp", mountPath: "/tmp"},
							]
							resources: {
								limits: {
									cpu:    "50m"
									memory: "64Mi"
								}
								requests: {
									cpu:    "10m"
									memory: "32Mi"
								}
							}
							securityContext: #config.securityContext
						},
					]
				}
				containers: [{
					name:            "ntfy"
					image:           #config.image.reference
					imagePullPolicy: #config.image.pullPolicy
					args: ["serve"]
					ports: [
						{
							name:          "http"
							containerPort: #config.containerPorts.http
							protocol:      "TCP"
						},
						if #config.ntfy.enableMetrics && #config.ntfy.metricsListenHttp != "" {
							let _parts = strings.Split(#config.ntfy.metricsListenHttp, ":")
							{
								name:          "metrics"
								containerPort: strconv.Atoi(_parts[len(_parts)-1])
								protocol:      "TCP"
							}
						},
					]
					env: [
						if #config._dbEnabled {
							name: "NTFY_DATABASE_URL"
							valueFrom: secretKeyRef: {
								name: #config._dbSecretName
								key:  #config._dbSecretKey
							}
						},
						if #config.smtp.enabled && (#config.smtp.senderPass != "" || #config.smtp.existingSecret != "") {
							name: "NTFY_SMTP_SENDER_PASS"
							valueFrom: secretKeyRef: {
								name: #config._smtpSecretName
								key:  #config.smtp.existingSecretPasswordKey
							}
						},
						if #config.oidc.enabled && (#config.oidc.clientSecret != "" || #config.oidc.existingSecret != "") {
							name: "NTFY_OIDC_CLIENT_SECRET"
							valueFrom: secretKeyRef: {
								name: #config._oidcSecretName
								key:  #config.oidc.existingSecretKey
							}
						},
						for e in #config.ntfy.extraEnv {e},
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
						{name: "config", mountPath: "/etc/ntfy", readOnly: true},
						{name: "data", mountPath: "/var/cache/ntfy"},
						{name: "tmp", mountPath: "/tmp"},
						for vm in #config.extraVolumeMounts {vm},
					]
				}]
				volumes: [
					{name: "config", configMap: name: #config.metadata.name},
					{
						name: "data"
						if #config.persistence.enabled {
							persistentVolumeClaim: claimName: #config._pvcName
						}
						if !#config.persistence.enabled {
							emptyDir: sizeLimit: #config.persistence.emptyDirSizeLimit
						}
					},
					{name: "tmp", emptyDir: sizeLimit: #config.runtimeStorage.tmpSizeLimit},
					for v in #config.extraVolumes {v},
				]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if #config.affinity.nodeAffinity != _|_ || #config.affinity.podAffinity != _|_ || #config.affinity.podAntiAffinity != _|_ {
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
