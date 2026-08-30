package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	autoscalingv2 "k8s.io/api/autoscaling/v2"
	"list"
)

// 1. /charts/redis/templates/sentinel/statefulset.yaml
#RedisSentinelStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	let redisLabels = (#RedisLabels & {#config: #config}).result
	let nodeLabels = redisLabels & {"app.kubernetes.io/component": "node"}
	let podLabels = redis.replica.podLabels & redis.commonLabels & nodeLabels

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(redisName)-node"
		namespace: #config.metadata.namespace
		labels:    nodeLabels
		if len(redis.commonAnnotations) > 0 || len(redis.sentinel.annotations) > 0 {
			annotations: redis.commonAnnotations & redis.sentinel.annotations
		}
	}
	spec: {
		replicas: redis.replica.replicaCount
		selector: matchLabels: {
			"app.kubernetes.io/name":      "redis"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "node"
		}
		serviceName: "\(redisName)-headless"
		if len(redis.replica.updateStrategy) > 0 {updateStrategy: redis.replica.updateStrategy}
		if redis.replica.minReadySeconds > 0 {minReadySeconds: redis.replica.minReadySeconds}
		if redis.replica.podManagementPolicy != "" {podManagementPolicy: redis.replica.podManagementPolicy}
		template: {
			metadata: {
				labels: podLabels
				annotations: redis.replica.podAnnotations & {
					"checksum/configmap": "dynamic-checksum-by-timoni"
					"checksum/health":    "dynamic-checksum-by-timoni"
					"checksum/scripts":   "dynamic-checksum-by-timoni"
					"checksum/secret":    "dynamic-checksum-by-timoni"
				}
				if redis.metrics.enabled {
					labels:      redis.metrics.podLabels
					annotations: redis.metrics.podAnnotations
				}
			}
			spec: {
				if len(#config.global.imagePullSecrets) > 0 {
					imagePullSecrets: [for ips in #config.global.imagePullSecrets {name: ips}]
				}
				if len(redis.replica.hostAliases) > 0 {hostAliases: redis.replica.hostAliases}
				if redis.replica.podSecurityContext.enabled {
					securityContext: {
						fsGroup: redis.replica.podSecurityContext.fsGroup
					}
				}
				automountServiceAccountToken: redis.serviceAccount.automountServiceAccountToken
				serviceAccountName: (#RedisServiceAccountName & {#config: #config}).result
				if redis.replica.priorityClassName != "" {priorityClassName: redis.replica.priorityClassName}
				if redis.replica.affinity != _|_ {affinity: redis.replica.affinity}
				if redis.replica.nodeSelector != _|_ {nodeSelector: redis.replica.nodeSelector}
				if len(redis.replica.tolerations) > 0 {tolerations: redis.replica.tolerations}
				if len(redis.replica.topologySpreadConstraints) > 0 {topologySpreadConstraints: redis.replica.topologySpreadConstraints}
				if redis.replica.shareProcessNamespace {shareProcessNamespace: redis.replica.shareProcessNamespace}
				if redis.replica.schedulerName != "" {schedulerName: redis.replica.schedulerName}
				if redis.replica.dnsPolicy != "" {dnsPolicy: redis.replica.dnsPolicy}
				if redis.replica.dnsConfig != _|_ {dnsConfig: redis.replica.dnsConfig}
				enableServiceLinks:            redis.sentinel.enableServiceLinks
				terminationGracePeriodSeconds: redis.sentinel.terminationGracePeriodSeconds

				containers: [
					{
						name:            "redis"
						image:           "\(redis.image.registry)/\(redis.image.repository):\(redis.image.tag)"
						imagePullPolicy: redis.image.pullPolicy
						if len(redis.replica.lifecycleHooks) > 0 {
							lifecycle: redis.replica.lifecycleHooks
						}
						if len(redis.replica.lifecycleHooks) == 0 {
							lifecycle: preStop: exec: command: ["/bin/bash", "-c", "/opt/bitnami/scripts/start-scripts/prestop-redis.sh"]
						}
						if redis.replica.containerSecurityContext.enabled {
							securityContext: {
								runAsUser:                redis.replica.containerSecurityContext.runAsUser
								runAsGroup:               redis.replica.containerSecurityContext.runAsGroup
								runAsNonRoot:             redis.replica.containerSecurityContext.runAsNonRoot
								allowPrivilegeEscalation: redis.replica.containerSecurityContext.allowPrivilegeEscalation
								readOnlyRootFilesystem:   redis.replica.containerSecurityContext.readOnlyRootFilesystem
							}
						}
						command: ["/bin/bash"]
						args: ["-c", "/opt/bitnami/scripts/start-scripts/start-node.sh"]
						env: [
							{name: "BITNAMI_DEBUG", value: [if redis.image.debug {"true"}, "false"][0]},
							{name: "REDIS_MASTER_PORT_NUMBER", value: "\(redis.replica.containerPorts.redis)"},
							{name: "ALLOW_EMPTY_PASSWORD", value: [if redis.auth.enabled {"no"}, "yes"][0]},
							if redis.auth.enabled {
								if redis.auth.usePasswordFiles {
									{name: "REDIS_PASSWORD_FILE", value: "/opt/bitnami/redis/secrets/redis-password"}
									{name: "REDIS_MASTER_PASSWORD_FILE", value: "/opt/bitnami/redis/secrets/redis-password"}
								}
								if !redis.auth.usePasswordFiles {
									{name: "REDIS_PASSWORD", valueFrom: secretKeyRef: {name: [if redis.auth.existingSecret != "" {redis.auth.existingSecret}, redisName][0], key: redis.auth.secretKeys.userPasswordKey}}
									{name: "REDIS_MASTER_PASSWORD", valueFrom: secretKeyRef: {name: [if redis.auth.existingSecret != "" {redis.auth.existingSecret}, redisName][0], key: redis.auth.secretKeys.userPasswordKey}}
								}
							},
							{name: "REDIS_TLS_ENABLED", value: [if redis.tls.enabled {"yes"}, "no"][0]},
							if redis.tls.enabled {
								{name: "REDIS_TLS_PORT", value: "\(redis.replica.containerPorts.redis)"}
								{name: "REDIS_TLS_AUTH_CLIENTS", value: [if redis.tls.authClients {"yes"}, "no"][0]}
								{name: "REDIS_TLS_CERT_FILE", value: "/opt/bitnami/redis/certs/tls.crt"}
								{name: "REDIS_TLS_KEY_FILE", value: "/opt/bitnami/redis/certs/tls.key"}
								{name: "REDIS_TLS_CA_FILE", value: "/opt/bitnami/redis/certs/ca.crt"}
							},
							if !redis.tls.enabled {name: "REDIS_PORT", value: "\(redis.replica.containerPorts.redis)"},
							{name: "REDIS_SENTINEL_TLS_ENABLED", value: [if redis.tls.enabled {"yes"}, "no"][0]},
							if redis.tls.enabled {
								{name: "REDIS_SENTINEL_TLS_PORT_NUMBER", value: "\(redis.sentinel.containerPorts.sentinel)"}
								{name: "REDIS_SENTINEL_TLS_AUTH_CLIENTS", value: [if redis.tls.authClients {"yes"}, "no"][0]}
								{name: "REDIS_SENTINEL_TLS_CERT_FILE", value: "/opt/bitnami/redis/certs/tls.crt"}
								{name: "REDIS_SENTINEL_TLS_KEY_FILE", value: "/opt/bitnami/redis/certs/tls.key"}
								{name: "REDIS_SENTINEL_TLS_CA_FILE", value: "/opt/bitnami/redis/certs/ca.crt"}
							},
							if !redis.tls.enabled {name: "REDIS_SENTINEL_PORT", value: "\(redis.sentinel.containerPorts.sentinel)"},
							{name: "REDIS_DATA_DIR", value: redis.replica.persistence.path},
							if redis.replica.externalMaster.enabled {
								{name: "REDIS_EXTERNAL_MASTER_HOST", value: redis.replica.externalMaster.host}
								{name: "REDIS_EXTERNAL_MASTER_PORT", value: "\(redis.replica.externalMaster.port)"}
							},
							for e in redis.replica.extraEnvVars {e},
						]
						ports: [{name: "redis", containerPort: redis.replica.containerPorts.redis}]
						if redis.replica.startupProbe.enabled {
							startupProbe: redis.replica.startupProbe & {
								exec: command: ["sh", "-c", "/health/ping_liveness_local.sh \(redis.replica.livenessProbe.timeoutSeconds)"]
							}
						}
						livenessProbe: redis.replica.livenessProbe & {
							exec: command: ["sh", "-c", "/health/ping_liveness_local.sh \(redis.replica.livenessProbe.timeoutSeconds)"]
						}
						readinessProbe: redis.replica.readinessProbe & {
							exec: command: ["sh", "-c", "/health/ping_readiness_local.sh \(redis.replica.readinessProbe.timeoutSeconds)"]
						}
						resources: redis.replica.resources
						volumeMounts: [
							{name: "start-scripts", mountPath: "/opt/bitnami/scripts/start-scripts"},
							{name: "health", mountPath: "/health"},
							if redis.sentinel.persistence.enabled {name: "sentinel-data", mountPath: "/opt/bitnami/redis-sentinel/etc"},
							if redis.auth.usePasswordFiles {name: "redis-password", mountPath: "/opt/bitnami/redis/secrets/"},
							{name: "redis-data", mountPath: redis.replica.persistence.path},
							{name: "config", mountPath: "/opt/bitnami/redis/mounted-etc"},
							{name: "redis-tmp-conf", mountPath: "/opt/bitnami/redis/etc"},
							{name: "tmp", mountPath: "/tmp"},
							if redis.tls.enabled {name: "redis-certificates", mountPath: "/opt/bitnami/redis/certs", readOnly: true},
							for vm in redis.replica.extraVolumeMounts {vm},
						]
					},
					{
						name:            "sentinel"
						image:           "\(redis.sentinel.image.registry)/\(redis.sentinel.image.repository):\(redis.sentinel.image.tag)"
						imagePullPolicy: redis.sentinel.image.pullPolicy
						if len(redis.sentinel.lifecycleHooks) > 0 {
							lifecycle: redis.sentinel.lifecycleHooks
						}
						if len(redis.sentinel.lifecycleHooks) == 0 {
							lifecycle: preStop: exec: command: ["/bin/bash", "-c", "/opt/bitnami/scripts/start-scripts/prestop-sentinel.sh"]
						}
						if redis.sentinel.containerSecurityContext.enabled {
							securityContext: {
								runAsUser:                redis.sentinel.containerSecurityContext.runAsUser
								runAsGroup:               redis.sentinel.containerSecurityContext.runAsGroup
								runAsNonRoot:             redis.sentinel.containerSecurityContext.runAsNonRoot
								allowPrivilegeEscalation: redis.sentinel.containerSecurityContext.allowPrivilegeEscalation
								readOnlyRootFilesystem:   redis.sentinel.containerSecurityContext.readOnlyRootFilesystem
							}
						}
						command: ["/bin/bash"]
						args: ["-c", "/opt/bitnami/scripts/start-scripts/start-sentinel.sh"]
						env: [
							{name: "BITNAMI_DEBUG", value: [if redis.sentinel.image.debug {"true"}, "false"][0]},
							if redis.auth.enabled {
								if redis.auth.usePasswordFiles {
									{name: "REDIS_PASSWORD_FILE", value: "/opt/bitnami/redis/secrets/redis-password"}
								}
								if !redis.auth.usePasswordFiles {
									{name: "REDIS_PASSWORD", valueFrom: secretKeyRef: {name: [if redis.auth.existingSecret != "" {redis.auth.existingSecret}, redisName][0], key: redis.auth.secretKeys.userPasswordKey}}
								}
							},
							if !redis.auth.enabled {name: "ALLOW_EMPTY_PASSWORD", value: "yes"},
							{name: "REDIS_SENTINEL_TLS_ENABLED", value: [if redis.tls.enabled {"yes"}, "no"][0]},
							if redis.tls.enabled {
								{name: "REDIS_SENTINEL_TLS_PORT_NUMBER", value: "\(redis.sentinel.containerPorts.sentinel)"}
								{name: "REDIS_SENTINEL_TLS_AUTH_CLIENTS", value: [if redis.tls.authClients {"yes"}, "no"][0]}
								{name: "REDIS_SENTINEL_TLS_CERT_FILE", value: "/opt/bitnami/redis/certs/tls.crt"}
								{name: "REDIS_SENTINEL_TLS_KEY_FILE", value: "/opt/bitnami/redis/certs/tls.key"}
								{name: "REDIS_SENTINEL_TLS_CA_FILE", value: "/opt/bitnami/redis/certs/ca.crt"}
							},
							if !redis.tls.enabled {name: "REDIS_SENTINEL_PORT", value: "\(redis.sentinel.containerPorts.sentinel)"},
							if redis.sentinel.externalMaster.enabled {
								{name: "REDIS_EXTERNAL_MASTER_HOST", value: redis.sentinel.externalMaster.host}
								{name: "REDIS_EXTERNAL_MASTER_PORT", value: "\(redis.sentinel.externalMaster.port)"}
							},
							for e in redis.sentinel.extraEnvVars {e},
						]
						ports: [{name: "redis-sentinel", containerPort: redis.sentinel.containerPorts.sentinel}]
						if redis.sentinel.startupProbe.enabled {
							startupProbe: redis.sentinel.startupProbe & {
								exec: command: ["sh", "-c", "/health/ping_sentinel.sh \(redis.sentinel.livenessProbe.timeoutSeconds)"]
							}
						}
						livenessProbe: redis.sentinel.livenessProbe & {
							exec: command: ["sh", "-c", "/health/ping_sentinel.sh \(redis.sentinel.livenessProbe.timeoutSeconds)"]
						}
						readinessProbe: redis.sentinel.readinessProbe & {
							exec: command: ["sh", "-c", "/health/ping_sentinel.sh \(redis.sentinel.readinessProbe.timeoutSeconds)"]
						}
						resources: redis.sentinel.resources
						volumeMounts: [
							{name: "start-scripts", mountPath: "/opt/bitnami/scripts/start-scripts"},
							{name: "health", mountPath: "/health"},
							{name: "sentinel-data", mountPath: "/opt/bitnami/redis-sentinel/etc"},
							if redis.auth.usePasswordFiles {name: "redis-password", mountPath: "/opt/bitnami/redis/secrets/"},
							{name: "redis-data", mountPath: redis.replica.persistence.path},
							{name: "config", mountPath: "/opt/bitnami/redis-sentinel/mounted-etc"},
							if redis.tls.enabled {name: "redis-certificates", mountPath: "/opt/bitnami/redis/certs", readOnly: true},
							for vm in redis.sentinel.extraVolumeMounts {vm},
						]
					},
					if redis.metrics.enabled {
						{
							name:            "metrics"
							image:           "\(redis.metrics.image.registry)/\(redis.metrics.image.repository):\(redis.metrics.image.tag)"
							imagePullPolicy: redis.metrics.image.pullPolicy
							if redis.metrics.containerSecurityContext.enabled {
								securityContext: {
									runAsUser:                redis.metrics.containerSecurityContext.runAsUser
									runAsNonRoot:             redis.metrics.containerSecurityContext.runAsNonRoot
									allowPrivilegeEscalation: redis.metrics.containerSecurityContext.allowPrivilegeEscalation
									readOnlyRootFilesystem:   redis.metrics.containerSecurityContext.readOnlyRootFilesystem
								}
							}
							command: ["/bin/bash", "-c", "if [[ -f '/secrets/redis-password' ]]; then export REDIS_PASSWORD=$(cat /secrets/redis-password); fi; redis_exporter"]
							env: [
								{name: "REDIS_ALIAS", value: redisName},
								if redis.auth.enabled {name: "REDIS_USER", value: "default"},
								if redis.auth.enabled && !redis.auth.usePasswordFiles {name: "REDIS_PASSWORD", valueFrom: secretKeyRef: {name: [if redis.auth.existingSecret != "" {redis.auth.existingSecret}, redisName][0], key: redis.auth.secretKeys.userPasswordKey}},
								if redis.tls.enabled {
									{name: "REDIS_ADDR", value: "rediss://localhost:\(redis.replica.containerPorts.redis)"}
									if redis.tls.authClients {
										{name: "REDIS_EXPORTER_TLS_CLIENT_KEY_FILE", value: "/opt/bitnami/redis/certs/tls.key"}
										{name: "REDIS_EXPORTER_TLS_CLIENT_CERT_FILE", value: "/opt/bitnami/redis/certs/tls.crt"}
									}
									{name: "REDIS_EXPORTER_TLS_CA_CERT_FILE", value: "/opt/bitnami/redis/certs/ca.crt"}
								},
								for e in redis.metrics.extraEnvVars {e},
							]
							ports: [{name: "metrics", containerPort: 9121}]
							livenessProbe: redis.metrics.livenessProbe & {
								tcpSocket: port: "metrics"
							}
							readinessProbe: redis.metrics.readinessProbe & {
								httpGet: {path: "/", port: "metrics"}
							}
							resources: redis.metrics.resources
							volumeMounts: [
								if redis.auth.usePasswordFiles {name: "redis-password", mountPath: "/secrets/"},
								if redis.tls.enabled {name: "redis-certificates", mountPath: "/opt/bitnami/redis/certs", readOnly: true},
								for vm in redis.metrics.extraVolumeMounts {vm},
							]
						}
					},
					for c in redis.replica.sidecars {c},
				]
				initContainers: list.Concat([
					if redis.replica.initContainers != _|_ {redis.replica.initContainers},
					[
						if redis.volumePermissions.enabled && redis.replica.persistence.enabled && redis.replica.podSecurityContext.enabled && redis.replica.containerSecurityContext.enabled {
							{
								name:            "volume-permissions"
								image:           "\(redis.volumePermissions.image.registry)/\(redis.volumePermissions.image.repository):\(redis.volumePermissions.image.tag)"
								imagePullPolicy: redis.volumePermissions.image.pullPolicy
								command: ["/bin/bash", "-ec", "chown -R \(redis.replica.containerSecurityContext.runAsUser):\(redis.replica.podSecurityContext.fsGroup) \(redis.replica.persistence.path)"]
								securityContext: runAsUser: 0
								resources: redis.volumePermissions.resources
								volumeMounts: [{name: "redis-data", mountPath: redis.replica.persistence.path}]
							}
						},
						if redis.sysctl.enabled {
							{
								name:            "init-sysctl"
								image:           "\(redis.sysctl.image.registry)/\(redis.sysctl.image.repository):\(redis.sysctl.image.tag)"
								imagePullPolicy: redis.sysctl.image.pullPolicy
								securityContext: privileged: true
								if len(redis.sysctl.command) > 0 {command: redis.sysctl.command}
								resources: redis.sysctl.resources
								if redis.sysctl.mountHostSys {volumeMounts: [{name: "host-sys", mountPath: "/host-sys"}]}
							}
						},
					],
				])
				volumes: [
					{name: "start-scripts", configMap: {name: "\(redisName)-scripts", defaultMode: 493}},
					{name: "health", configMap: {name: "\(redisName)-health", defaultMode: 493}},
					if redis.auth.usePasswordFiles {name: "redis-password", secret: {secretName: [if redis.auth.existingSecret != "" {redis.auth.existingSecret}, redisName][0], items: [{key: redis.auth.secretKeys.userPasswordKey, path: "redis-password"}]}},
					{name: "config", configMap: {name: "\(redisName)-configuration"}},
					if redis.sysctl.enabled && redis.sysctl.mountHostSys {
						{name: "host-sys", hostPath: path: "/sys"}
					},
					if !redis.sentinel.persistence.enabled {
						{name: "sentinel-data", emptyDir: {}}
					},
					{name: "redis-tmp-conf", emptyDir: {}},
					{name: "tmp", emptyDir: {}},
					if redis.tls.enabled {
						{name: "redis-certificates", secret: {secretName: [if redis.tls.existingSecret != "" {redis.tls.existingSecret}, "\(redisName)-crt"][0], defaultMode: 256}}
					},
					if !redis.replica.persistence.enabled {
						{name: "redis-data", emptyDir: {}}
					},
					if redis.replica.persistence.enabled && redis.replica.persistence.existingClaim != "" {
						{name: "redis-data", persistentVolumeClaim: claimName: redis.replica.persistence.existingClaim}
					},
					for v in redis.replica.extraVolumes {v},
					for v in redis.metrics.extraVolumes {v},
					for v in redis.sentinel.extraVolumes {v},
				]
			}
		}
		if redis.replica.persistence.enabled && redis.replica.persistence.existingClaim == "" {
			if redis.sentinel.persistentVolumeClaimRetentionPolicy.enabled {
				persistentVolumeClaimRetentionPolicy: {
					whenDeleted: redis.sentinel.persistentVolumeClaimRetentionPolicy.whenDeleted
					whenScaled:  redis.sentinel.persistentVolumeClaimRetentionPolicy.whenScaled
				}
			}
			volumeClaimTemplates: [
				{
					metadata: {
						name:   "redis-data"
						labels: nodeLabels
						if len(redis.replica.persistence.annotations) > 0 {annotations: redis.replica.persistence.annotations}
					}
					spec: {
						accessModes: redis.replica.persistence.accessModes
						resources: requests: storage: redis.replica.persistence.size
						if len(redis.replica.persistence.selector) > 0 {selector: redis.replica.persistence.selector}
						if redis.replica.persistence.storageClass != "" {storageClassName: redis.replica.persistence.storageClass}
					}
				},
				if redis.sentinel.persistence.enabled {
					{
						metadata: {
							name:   "sentinel-data"
							labels: nodeLabels
							if len(redis.sentinel.persistence.annotations) > 0 {annotations: redis.sentinel.persistence.annotations}
						}
						spec: {
							accessModes: redis.sentinel.persistence.accessModes
							resources: requests: storage: redis.sentinel.persistence.size
							if len(redis.sentinel.persistence.selector) > 0 {selector: redis.sentinel.persistence.selector}
							if len(redis.sentinel.persistence.dataSource) > 0 {dataSource: redis.sentinel.persistence.dataSource}
							if redis.sentinel.persistence.storageClass != "" {storageClassName: redis.sentinel.persistence.storageClass}
						}
					}
				},
			]
		}
	}
}

// 2. /charts/redis/templates/sentinel/service.yaml
#RedisSentinelService: corev1.#Service & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	let redisLabels = (#RedisLabels & {#config: #config}).result

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      redisName
		namespace: #config.metadata.namespace
		labels: redisLabels & {"app.kubernetes.io/component": "node"}
		if len(redis.commonAnnotations) > 0 || len(redis.sentinel.service.annotations) > 0 {
			annotations: redis.commonAnnotations & redis.sentinel.service.annotations
		}
	}
	spec: {
		type: redis.sentinel.service.type
		if redis.sentinel.service.type == "LoadBalancer" || redis.sentinel.service.type == "NodePort" {
			externalTrafficPolicy: redis.sentinel.service.externalTrafficPolicy
		}
		if redis.sentinel.service.type == "LoadBalancer" && redis.sentinel.service.loadBalancerIP != "" {
			loadBalancerIP: redis.sentinel.service.loadBalancerIP
		}
		if redis.sentinel.service.type == "LoadBalancer" && redis.sentinel.service.loadBalancerClass != "" {
			loadBalancerClass: redis.sentinel.service.loadBalancerClass
		}
		if redis.sentinel.service.type == "LoadBalancer" && len(redis.sentinel.service.loadBalancerSourceRanges) > 0 {
			loadBalancerSourceRanges: redis.sentinel.service.loadBalancerSourceRanges
		}
		if redis.sentinel.service.type == "ClusterIP" && redis.sentinel.service.clusterIP != "" {
			clusterIP: redis.sentinel.service.clusterIP
		}
		sessionAffinity: redis.sentinel.service.sessionAffinity
		if redis.sentinel.service.sessionAffinity == "ClientIP" {
			sessionAffinityConfig: redis.sentinel.service.sessionAffinityConfig
		}
		ports: [
			{
				name:       "tcp-redis"
				port:       redis.sentinel.service.ports.redis
				targetPort: redis.replica.containerPorts.redis
				if redis.sentinel.service.type == "NodePort" && redis.sentinel.service.nodePorts.redis != "" {
					nodePort: redis.sentinel.service.nodePorts.redis
				}
			},
			{
				name:       "tcp-sentinel"
				port:       redis.sentinel.service.ports.sentinel
				targetPort: redis.sentinel.containerPorts.sentinel
				if redis.sentinel.service.type == "NodePort" && redis.sentinel.service.nodePorts.sentinel != "" {
					nodePort: redis.sentinel.service.nodePorts.sentinel
				}
			},
			if redis.sentinel.service.type == "NodePort" {
				{
					name:       "sentinel-internal"
					port:       redis.sentinel.containerPorts.sentinel
					targetPort: redis.sentinel.containerPorts.sentinel
				}
			},
			if redis.sentinel.service.type == "NodePort" {
				{
					name:       "redis-internal"
					port:       redis.replica.containerPorts.redis
					targetPort: redis.replica.containerPorts.redis
				}
			},
			for p in redis.sentinel.service.extraPorts {p},
		]
		selector: redisLabels & {"app.kubernetes.io/component": "node"}
	}
}

// 3. /charts/redis/templates/sentinel/hpa.yaml
#RedisSentinelHPA: autoscalingv2.#HorizontalPodAutoscaler & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	let redisLabels = (#RedisLabels & {#config: #config}).result

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      "\(redisName)-node"
		namespace: #config.metadata.namespace
		labels: redisLabels & {"app.kubernetes.io/component": "replica"}
		if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}
	}
	spec: {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			name:       "\(redisName)-node"
		}
		minReplicas: redis.replica.autoscaling.minReplicas
		maxReplicas: redis.replica.autoscaling.maxReplicas
		metrics: [
			if redis.replica.autoscaling.targetCPU > 0 {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: redis.replica.autoscaling.targetCPU
						}
					}
				}
			},
			if redis.replica.autoscaling.targetMemory > 0 {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: redis.replica.autoscaling.targetMemory
						}
					}
				}
			},
		]
	}
}

// 4. /charts/redis/templates/sentinel/node-services.yaml
#RedisSentinelNodeService: corev1.#Service & {
	#config: #Config
	#index:  int
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	let redisLabels = (#RedisLabels & {#config: #config}).result

	// Deterministic port calculation (Parity with PortsConfigMap logic)
	let _basePort = 30000
	let _sentinelPort = [if redis.sentinel.service.nodePorts.sentinel != "" {redis.sentinel.service.nodePorts.sentinel + #index + 1}, _basePort + 2 + #index*2][0]
	let _redisPort = [if redis.sentinel.service.nodePorts.redis != "" {redis.sentinel.service.nodePorts.redis + #index + 1}, _basePort + 3 + #index*2][0]

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(redisName)-node-\(#index)"
		namespace: #config.metadata.namespace
		labels: redisLabels & {"app.kubernetes.io/component": "node"}
		if len(redis.commonAnnotations) > 0 || len(redis.sentinel.service.annotations) > 0 {
			annotations: redis.commonAnnotations & redis.sentinel.service.annotations
		}
	}
	spec: {
		type: "NodePort"
		ports: [
			{
				name:       "sentinel"
				port:       _sentinelPort
				nodePort:   _sentinelPort
				targetPort: redis.sentinel.containerPorts.sentinel
			},
			{
				name:       "redis"
				port:       _redisPort
				nodePort:   _redisPort
				targetPort: redis.replica.containerPorts.redis
			},
			{
				name:       "sentinel-internal"
				port:       redis.sentinel.containerPorts.sentinel
				targetPort: redis.sentinel.containerPorts.sentinel
			},
			{
				name:       "redis-internal"
				port:       redis.replica.containerPorts.redis
				targetPort: redis.replica.containerPorts.redis
			},
		]
		selector: "statefulset.kubernetes.io/pod-name": "\(redisName)-node-\(#index)"
	}
}

// 5. /charts/redis/templates/sentinel/ports-configmap.yaml
#RedisSentinelPortsConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	let redisLabels = (#RedisLabels & {#config: #config}).result

	// Deterministic port calculation (Parity with Helm sentinel/ports-configmap.yaml lines 1-65)
	// Helm logic: starts at 30000 and increments for each required port (2 per node).
	// Since Timoni cannot perform 'lookup' on the cluster, we use a fixed offset.
	let _basePort = 30000
	let _chosenPorts = [
		for j in list.Range(0, (redis.replica.replicaCount*2)+2, 1) {
			_basePort + j
		},
	]

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(redisName)-ports-configmap"
		namespace: #config.metadata.namespace
		labels: redisLabels & {"app.kubernetes.io/component": "node"}
		if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}
	}
	data: {
		"\(redisName)-sentinel": "\(_chosenPorts[0])"
		"\(redisName)-redis":    "\(_chosenPorts[1])"
		for i in list.Range(0, redis.replica.replicaCount, 1) {
			"\(redisName)-node-\(i)-sentinel": "\(_chosenPorts[2+i*2])"
			"\(redisName)-node-\(i)-redis":    "\(_chosenPorts[2+i*2+1])"
		}
	}
}
