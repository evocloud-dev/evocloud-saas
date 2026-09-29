package templates

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/yaml"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#RedisHttpDeployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.#redisHttpName
		namespace: #config.metadata.namespace
		labels: #config.#allLabels & {
			"app.kubernetes.io/component": "redis-http"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: 1
		selector: matchLabels: #config.#redisHttpSelectorLabels
		template: corev1.#PodTemplateSpec & {
			let _secretObj = #Secret & {#config: #config}
			let _secretChecksum = hex.Encode(sha256.Sum256(yaml.Marshal(_secretObj.stringData)))

			metadata: {
				labels: #config.#redisHttpSelectorLabels
				annotations: {
					"checksum/secret": _secretChecksum
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config.#serviceAccountName
				automountServiceAccountToken: false
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				securityContext: {
					seccompProfile: type: "RuntimeDefault"
				}

				let _srhScript = """
					url_encode() {
					  printf '%s' "$1" | sed -e 's/%/%25/g' -e 's/:/%3A/g' -e 's/@/%40/g' -e 's#/#%2F#g' -e 's/?/%3F/g' -e 's/#/%23/g' -e 's/ /%20/g' -e 's/&/%26/g' -e 's/=/%3D/g' -e 's/+/%2B/g' -e 's/\\[/%5B/g' -e 's/\\]/%5D/g'
					}
					if [ -n "${REDIS_PASSWORD:-}" ]; then
					  redis_password="$(url_encode "$REDIS_PASSWORD")"
					  export SRH_CONNECTION_STRING="redis://:${redis_password}@${REDIS_HOST}:${REDIS_PORT}"
					  unset redis_password
					else
					  export SRH_CONNECTION_STRING="redis://${REDIS_HOST}:${REDIS_PORT}"
					fi
					exec _build/prod/rel/prod/bin/prod start
					"""

				containers: [
					{
						name:            "redis-http"
						image:           #config.redisHttp.image.reference
						imagePullPolicy: #config.redisHttp.image.pullPolicy
						command: ["/bin/sh", "-ec"]
						args: [_srhScript]
						env: [
							{name: "SRH_MODE", value: "env"},
							{
								name: "SRH_TOKEN"
								valueFrom: secretKeyRef: {
									name: #config.#secretName
									key:  "redis-rest-token"
								}
							},
							if #config.#redisAuthEnabled {
								name: "REDIS_PASSWORD"
								valueFrom: secretKeyRef: {
									name: #config.#redisSecretName
									key:  #config.#redisSecretKey
								}
							},
							{name: "REDIS_HOST", value: #config.#redisHost},
							{name: "REDIS_PORT", value: "\(#config.#redisPort)"},
						]
						ports: [{
							name:          "http"
							containerPort: 80
							protocol:      "TCP"
						}]

						if #config.redisHttp.probes.startup.enabled {
							startupProbe: {
								httpGet: {
									path: #config.redisHttp.probes.startup.path
									port: "http"
								}
								initialDelaySeconds: #config.redisHttp.probes.startup.initialDelaySeconds
								periodSeconds:       #config.redisHttp.probes.startup.periodSeconds
								timeoutSeconds:      #config.redisHttp.probes.startup.timeoutSeconds
								failureThreshold:    #config.redisHttp.probes.startup.failureThreshold
							}
						}

						if #config.redisHttp.probes.readiness.enabled {
							readinessProbe: {
								httpGet: {
									path: #config.redisHttp.probes.readiness.path
									port: "http"
								}
								initialDelaySeconds: #config.redisHttp.probes.readiness.initialDelaySeconds
								periodSeconds:       #config.redisHttp.probes.readiness.periodSeconds
								timeoutSeconds:      #config.redisHttp.probes.readiness.timeoutSeconds
								failureThreshold:    #config.redisHttp.probes.readiness.failureThreshold
							}
						}

						if #config.redisHttp.probes.liveness.enabled {
							livenessProbe: {
								httpGet: {
									path: #config.redisHttp.probes.liveness.path
									port: "http"
								}
								initialDelaySeconds: #config.redisHttp.probes.liveness.initialDelaySeconds
								periodSeconds:       #config.redisHttp.probes.liveness.periodSeconds
								timeoutSeconds:      #config.redisHttp.probes.liveness.timeoutSeconds
								failureThreshold:    #config.redisHttp.probes.liveness.failureThreshold
							}
						}

						resources:       #config.redisHttp.resources
						securityContext: #config.redisHttp.securityContext
					},
				]
			}
		}
	}
}

#RedisHttpService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#redisHttpName
		namespace: #config.metadata.namespace
		labels: #config.#allLabels & {
			"app.kubernetes.io/component": "redis-http"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		ports: [
			{
				name:        "http"
				port:        #config.redisHttp.service.port
				targetPort:  80
				protocol:    "TCP"
				appProtocol: "http"
			},
		]
		selector: #config.#redisHttpSelectorLabels
	}
}
