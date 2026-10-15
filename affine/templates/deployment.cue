package templates

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	_bootstrapJson:     json.Marshal(#config.bootstrap)
	_bootstrapChecksum: hex.Encode(sha256.Sum256(_bootstrapJson + _bootstrapMjs + _startMjs))

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels:    #config._labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicaCount
		strategy: type: "Recreate"
		selector: matchLabels: #config._selectorLabels
		template: {
			metadata: {
				labels: {
					for k, v in #config.podLabels {
						"\(k)": v
					}
					#config._selectorLabels
				}
				annotations: {
					"checksum/bootstrap": _bootstrapChecksum
					if #config.podAnnotations != _|_ {
						for k, v in #config.podAnnotations {
							"\(k)": v
						}
					}
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           #config._serviceAccountName
				automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
				securityContext:              #config.podSecurityContext
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds

				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}

				initContainers: [
					{
						name:            "bootstrap"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["node", "/helmforge/bootstrap.mjs"]
						securityContext: #config.securityContext
						resources:       #config.resources
						env: [
							for e in #config._environment {e},
							{name: "BOOTSTRAP_NAME", value: #config.bootstrap.name},
							{name: "BOOTSTRAP_EMAIL", value: #config.bootstrap.email},
						]
						volumeMounts: [
							for m in #config._mounts {m},
							{name: "bootstrap-auth", mountPath: "/bootstrap-auth", readOnly: true},
						]
					},
				]

				containers: [
					{
						name:            "affine"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						command: ["node", "/helmforge/start.mjs"]
						securityContext: #config.securityContext
						resources:       #config.resources
						ports: [
							{
								name:          "http"
								containerPort: #config.server.port
							},
							if #config.metrics.enabled {
								name:          "metrics"
								containerPort: #config.metrics.port
							},
						]
						env: [for e in #config._environment {e}]
						if #config.probes.startup.enabled {
							startupProbe: {
								httpGet: {
									path: "/info"
									port: "http"
								}
								failureThreshold: #config.probes.startup.failureThreshold
								periodSeconds:    #config.probes.startup.periodSeconds
								timeoutSeconds:   #config.probes.startup.timeoutSeconds
							}
						}
						if #config.probes.readiness.enabled {
							readinessProbe: {
								exec: command: ["node", "/helmforge/readiness.mjs"]
								failureThreshold: #config.probes.readiness.failureThreshold
								periodSeconds:    #config.probes.readiness.periodSeconds
								timeoutSeconds:   #config.probes.readiness.timeoutSeconds
							}
						}
						if #config.probes.liveness.enabled {
							livenessProbe: {
								httpGet: {
									path: "/info"
									port: "http"
								}
								failureThreshold: #config.probes.liveness.failureThreshold
								periodSeconds:    #config.probes.liveness.periodSeconds
								timeoutSeconds:   #config.probes.liveness.timeoutSeconds
							}
						}
						volumeMounts: [for m in #config._mounts {m}]
					},
				]

				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				if len(#config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				if len(#config.affinity) > 0 {
					affinity: #config.affinity
				}

				volumes: [
					if !#config.postgresql.enabled && #config.database.tls.caSecret != "" {
						name: "postgres-ca"
						secret: {
							secretName: #config.database.tls.caSecret
							items: [{key: #config.database.tls.caKey, path: "ca.crt"}]
						}
					},
					if !#config.redis.enabled && #config.cache.tls.caSecret != "" {
						name: "redis-ca"
						secret: {
							secretName: #config.cache.tls.caSecret
							items: [{key: #config.cache.tls.caKey, path: "ca.crt"}]
						}
					},
					{
						name: "workspace"
						if #config.persistence.enabled {
							persistentVolumeClaim: claimName: #config._claimName
						}
						if !#config.persistence.enabled {
							emptyDir: {}
						}
					},
					{
						name:     "tmp"
						emptyDir: sizeLimit: #config.runtime.temporarySize
					},
					{
						name:     "generated-schema"
						emptyDir: sizeLimit: "8Mi"
					},
					{
						name: "bootstrap-auth"
						secret: {
							secretName:  #config._bootstrapSecretName
							defaultMode: 288
							items: [{key: #config.bootstrap.passwordKey, path: "password"}]
						}
					},
					{
						name: "bootstrap-script"
						configMap: name: #config._bootstrapConfigMapName
					},
				]
			}
		}
	}
}
