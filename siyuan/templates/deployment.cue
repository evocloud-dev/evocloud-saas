package templates

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"strings"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config: #Config

	_oidcChecksum: hex.Encode(sha256.Sum256(json.Marshal(#config.oidc)))
	_authChecksum: hex.Encode(sha256.Sum256(json.Marshal(#config.auth)))

	_baseEnv: [
		{name: "HOME", value: "/home/siyuan"},
		{name: "RUN_IN_CONTAINER", value: "true"},
		{name: "SIYUAN_ACCESS_AUTH_CODE_BYPASS", value: "false"},
		{name: "SIYUAN_OIDC_ENABLED", value: "\(#config.oidc.enabled)"},
	]

	_oidcEnv: [
		if #config.oidc.enabled {
			[
				{name: "SIYUAN_OIDC_PROVIDER", value: #config.oidc.provider},
				{name: "SIYUAN_OIDC_ISSUER_URL", value: #config.oidc.issuerURL},
				{name: "SIYUAN_OIDC_CLIENT_ID", value: #config.oidc.clientID},
				{name: "SIYUAN_OIDC_REDIRECT_URL", value: #config.oidc.redirectURL},
				{name: "SIYUAN_OIDC_ALLOW_ALL", value: "\(#config.oidc.allowAll)"},
				{name: "SIYUAN_OIDC_SCOPES", value: strings.Join(#config.oidc.scopes, " ")},
				{name: "SIYUAN_OIDC_CLAIM_RULES", value: json.Marshal(#config.oidc.claimRules)},
				{
					name: "SIYUAN_OIDC_CLIENT_SECRET"
					valueFrom: secretKeyRef: {
						name: #config.oidcSecretName
						key:  #config.oidc.clientSecretKey
					}
				},
			]
		},
	]

	_authEnv: [
		{
			name: "SIYUAN_ACCESS_AUTH_CODE"
			valueFrom: secretKeyRef: {
				name: #config.authSecretName
				key:  #config.auth.accessCodeKey
			}
		},
	]

	_allEnv: [
		for e in _baseEnv {e},
		for oGroup in _oidcEnv for e in oGroup {e},
		for e in _authEnv {e},
		for e in #config.extraEnv {e},
	]

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicas
		strategy: type: appsv1.#RecreateDeploymentStrategyType
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if len(#config.podLabels) > 0 {
					labels: #config.podLabels
				}
				annotations: {
					"checksum/oidc":        _oidcChecksum
					"checksum/credentials": _authChecksum
					for k, v in #config.podAnnotations {
						(k): v
					}
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:            #config.serviceAccountName
				automountServiceAccountToken:  #config.serviceAccount.automountServiceAccountToken
				terminationGracePeriodSeconds: #config.terminationGracePeriodSeconds
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				securityContext: #config.podSecurityContext
				if #config.priorityClassName != "" {
					priorityClassName: #config.priorityClassName
				}
				containers: [
					{
						name:            "siyuan"
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						securityContext: #config.securityContext
						command: ["/opt/siyuan/kernel"]
						args: [
							"serve",
							"--workspace=/siyuan/workspace",
							"--port=\(#config.server.port)",
						]
						ports: [
							{
								name:          "http"
								containerPort: #config.server.port
								protocol:      "TCP"
							},
						]
						env: _allEnv
						if len(#config.envFrom) > 0 {
							envFrom: #config.envFrom
						}
						resources: #config.resources
						if #config.probes.startup.enabled {
							startupProbe: {
								if #config.probes.startup.requireBootComplete != _|_ && #config.probes.startup.requireBootComplete {
									exec: command: [
										"/bin/sh",
										"-ec",
										"wget -q -T \(#config.probes.startup.timeoutSeconds) -O- http://127.0.0.1:\(#config.server.port)\(#config.probes.startup.path) | grep -Eq '\"progress\"[[:space:]]*:[[:space:]]*100([[:space:]]*[,}])'",
									]
								}
								if #config.probes.startup.requireBootComplete == _|_ || !#config.probes.startup.requireBootComplete {
									httpGet: {
										path: #config.probes.startup.path
										port: "http"
									}
								}
								periodSeconds:    #config.probes.startup.periodSeconds
								timeoutSeconds:   #config.probes.startup.timeoutSeconds
								failureThreshold: #config.probes.startup.failureThreshold
								if #config.probes.startup.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.probes.startup.initialDelaySeconds
								}
								if #config.probes.startup.successThreshold != _|_ {
									successThreshold: #config.probes.startup.successThreshold
								}
							}
						}
						if #config.probes.liveness.enabled {
							livenessProbe: {
								if #config.probes.liveness.requireBootComplete != _|_ && #config.probes.liveness.requireBootComplete {
									exec: command: [
										"/bin/sh",
										"-ec",
										"wget -q -T \(#config.probes.liveness.timeoutSeconds) -O- http://127.0.0.1:\(#config.server.port)\(#config.probes.liveness.path) | grep -Eq '\"progress\"[[:space:]]*:[[:space:]]*100([[:space:]]*[,}])'",
									]
								}
								if #config.probes.liveness.requireBootComplete == _|_ || !#config.probes.liveness.requireBootComplete {
									httpGet: {
										path: #config.probes.liveness.path
										port: "http"
									}
								}
								periodSeconds:    #config.probes.liveness.periodSeconds
								timeoutSeconds:   #config.probes.liveness.timeoutSeconds
								failureThreshold: #config.probes.liveness.failureThreshold
								if #config.probes.liveness.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.probes.liveness.initialDelaySeconds
								}
								if #config.probes.liveness.successThreshold != _|_ {
									successThreshold: #config.probes.liveness.successThreshold
								}
							}
						}
						if #config.probes.readiness.enabled {
							readinessProbe: {
								if #config.probes.readiness.requireBootComplete != _|_ && #config.probes.readiness.requireBootComplete {
									exec: command: [
										"/bin/sh",
										"-ec",
										"wget -q -T \(#config.probes.readiness.timeoutSeconds) -O- http://127.0.0.1:\(#config.server.port)\(#config.probes.readiness.path) | grep -Eq '\"progress\"[[:space:]]*:[[:space:]]*100([[:space:]]*[,}])'",
									]
								}
								if #config.probes.readiness.requireBootComplete == _|_ || !#config.probes.readiness.requireBootComplete {
									httpGet: {
										path: #config.probes.readiness.path
										port: "http"
									}
								}
								periodSeconds:    #config.probes.readiness.periodSeconds
								timeoutSeconds:   #config.probes.readiness.timeoutSeconds
								failureThreshold: #config.probes.readiness.failureThreshold
								if #config.probes.readiness.initialDelaySeconds != _|_ {
									initialDelaySeconds: #config.probes.readiness.initialDelaySeconds
								}
								if #config.probes.readiness.successThreshold != _|_ {
									successThreshold: #config.probes.readiness.successThreshold
								}
							}
						}
						volumeMounts: [
							{
								name:      "workspace"
								mountPath: "/siyuan/workspace"
							},
							{
								name:      "home"
								mountPath: "/home/siyuan"
							},
							{
								name:      "tmp"
								mountPath: "/tmp"
							},
						]
					},
					for c in #config.extraContainers {c},
				]
				volumes: [
					{
						name: "workspace"
						if #config.persistence.enabled {
							persistentVolumeClaim: claimName: #config.claimName
						}
						if !#config.persistence.enabled {
							emptyDir: {}
						}
					},
					{
						name:     "home"
						emptyDir: {}
					},
					{
						name: "tmp"
						emptyDir: sizeLimit: "1Gi"
					},
				]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if len(#config.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: #config.topologySpreadConstraints
				}
			}
		}
	}
}
