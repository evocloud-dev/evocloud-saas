package templates

import (
	"list"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
)

// 1. /charts/redis/templates/master/application.yaml
#RedisMasterApplication: appsv1.#StatefulSet & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	let redisLabels = (#RedisLabels & {#config: #config}).result
	let masterLabels = redisLabels & redis.master.podLabels & {"app.kubernetes.io/component": "master"}
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(redisName)-master"
		namespace: #config.metadata.namespace
		labels: redisLabels & {"app.kubernetes.io/component": "master"}
		if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}
	}
	spec: {
		replicas: redis.master.count
		selector: matchLabels: masterLabels
		serviceName: "\(redisName)-headless"
		if len(redis.master.updateStrategy) > 0 {updateStrategy: redis.master.updateStrategy}
		if redis.master.minReadySeconds > 0 {minReadySeconds: redis.master.minReadySeconds}
		if redis.master.podManagementPolicy != "" {podManagementPolicy: redis.master.podManagementPolicy}
		template: {
			metadata: {
				labels: masterLabels
				annotations: redis.master.podAnnotations & {
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
				if len(redis.master.hostAliases) > 0 {hostAliases: redis.master.hostAliases}
				if redis.master.podSecurityContext.enabled {
					securityContext: {
						fsGroup: redis.master.podSecurityContext.fsGroup
					}
				}
				serviceAccountName: (#RedisMasterServiceAccountName & {#config: #config}).result
				automountServiceAccountToken: redis.master.serviceAccount.automountServiceAccountToken
				if redis.master.priorityClassName != "" {priorityClassName: redis.master.priorityClassName}
				if len(redis.master.affinity) > 0 {affinity: redis.master.affinity}
				if len(redis.master.nodeSelector) > 0 {nodeSelector: redis.master.nodeSelector}
				if len(redis.master.tolerations) > 0 {tolerations: redis.master.tolerations}
				if len(redis.master.topologySpreadConstraints) > 0 {topologySpreadConstraints: redis.master.topologySpreadConstraints}
				if redis.master.shareProcessNamespace {shareProcessNamespace: redis.master.shareProcessNamespace}
				if redis.master.schedulerName != "" {schedulerName: redis.master.schedulerName}
				if redis.master.dnsPolicy != "" {dnsPolicy: redis.master.dnsPolicy}
				if len(redis.master.dnsConfig) > 0 {dnsConfig: redis.master.dnsConfig}
				enableServiceLinks:            redis.master.enableServiceLinks
				terminationGracePeriodSeconds: redis.master.terminationGracePeriodSeconds
				containers: list.Concat([
					[{
						name:            "redis"
						image:           "\(redis.image.registry)/\(redis.image.repository):\(redis.image.tag)"
						imagePullPolicy: redis.image.pullPolicy
						if redis.master.containerSecurityContext.enabled {
							securityContext: {
								runAsUser:                redis.master.containerSecurityContext.runAsUser
								runAsNonRoot:             redis.master.containerSecurityContext.runAsNonRoot
								allowPrivilegeEscalation: redis.master.containerSecurityContext.allowPrivilegeEscalation
								readOnlyRootFilesystem:   redis.master.containerSecurityContext.readOnlyRootFilesystem
							}
						}
						if len(redis.master.lifecycleHooks) > 0 {
							lifecycle: redis.master.lifecycleHooks
						}
						command: ["/bin/bash"]
						args: ["-c", "/opt/bitnami/scripts/start-scripts/start-master.sh"]
						env: list.Concat([
							[
								{name: "BITNAMI_DEBUG", value: "\(redis.image.debug)"},
								{name: "REDIS_REPLICATION_MODE", value: "master"},
								{name: "ALLOW_EMPTY_PASSWORD", value: [if redis.auth.enabled {"no"}, "yes"][0]},
							],
							[if redis.auth.enabled {
								list.Concat([
									[if redis.auth.usePasswordFiles {[{name: "REDIS_PASSWORD_FILE", value: "/opt/bitnami/redis/secrets/redis-password"}]}, []][0],
									[if !redis.auth.usePasswordFiles {[{name: "REDIS_PASSWORD", valueFrom: secretKeyRef: {name: [if redis.auth.existingSecret != "" {redis.auth.existingSecret}, redisName][0], key: redis.auth.secretKeys.userPasswordKey}}]}, []][0],
								])
							}, []][0],
							[
								{name: "REDIS_TLS_ENABLED", value: [if redis.tls.enabled {"yes"}, "no"][0]},
							],
							[if redis.tls.enabled {
								[
									{name: "REDIS_TLS_PORT", value: "\(redis.master.containerPorts.redis)"},
									{name: "REDIS_TLS_AUTH_CLIENTS", value: [if redis.tls.authClients {"yes"}, "no"][0]},
									{name: "REDIS_TLS_CERT_FILE", value: "/opt/bitnami/redis/certs/tls.crt"},
									{name: "REDIS_TLS_KEY_FILE", value: "/opt/bitnami/redis/certs/tls.key"},
									{name: "REDIS_TLS_CA_FILE", value: "/opt/bitnami/redis/certs/ca.crt"},
								]
							}, []][0],
							[if !redis.tls.enabled {[{name: "REDIS_PORT", value: "\(redis.master.containerPorts.redis)"}]}, []][0],
							[for e in redis.master.extraEnvVars {e}],
						])
						if redis.master.extraEnvVarsCM != "" || redis.master.extraEnvVarsSecret != "" {
							envFrom: list.Concat([
								[if redis.master.extraEnvVarsCM != "" {[{configMapRef: {name: redis.master.extraEnvVarsCM}}]}, []][0],
								[if redis.master.extraEnvVarsSecret != "" {[{secretRef: {name: redis.master.extraEnvVarsSecret}}]}, []][0],
							])
						}
						ports: [{name: "redis", containerPort: redis.master.containerPorts.redis}]
						if redis.master.startupProbe.enabled {
							startupProbe: {
								tcpSocket: port: "redis"
								initialDelaySeconds: redis.master.startupProbe.initialDelaySeconds
								periodSeconds:       redis.master.startupProbe.periodSeconds
								timeoutSeconds:      redis.master.startupProbe.timeoutSeconds
								successThreshold:    redis.master.startupProbe.successThreshold
								failureThreshold:    redis.master.startupProbe.failureThreshold
							}
						}
						if redis.master.livenessProbe.enabled {
							livenessProbe: {
								initialDelaySeconds: redis.master.livenessProbe.initialDelaySeconds
								periodSeconds:       redis.master.livenessProbe.periodSeconds
								timeoutSeconds:      redis.master.livenessProbe.timeoutSeconds + 1
								successThreshold:    redis.master.livenessProbe.successThreshold
								failureThreshold:    redis.master.livenessProbe.failureThreshold
								exec: command: ["sh", "-c", "/health/ping_liveness_local.sh \(redis.master.livenessProbe.timeoutSeconds)"]
							}
						}
						if redis.master.readinessProbe.enabled {
							readinessProbe: {
								initialDelaySeconds: redis.master.readinessProbe.initialDelaySeconds
								periodSeconds:       redis.master.readinessProbe.periodSeconds
								timeoutSeconds:      redis.master.readinessProbe.timeoutSeconds + 1
								successThreshold:    redis.master.readinessProbe.successThreshold
								failureThreshold:    redis.master.readinessProbe.failureThreshold
								exec: command: ["sh", "-c", "/health/ping_readiness_local.sh \(redis.master.readinessProbe.timeoutSeconds)"]
							}
						}
						resources: redis.master.resources
						volumeMounts: list.Concat([
							[
								{name: "start-scripts", mountPath: "/opt/bitnami/scripts/start-scripts"},
								{name: "health", mountPath: "/health"},
							],
							[if redis.auth.usePasswordFiles {[{name: "redis-password", mountPath: "/opt/bitnami/redis/secrets/"}]}, []][0],
							[{
								name:      "redis-data"
								mountPath: redis.master.persistence.path
								if redis.master.persistence.subPath != "" {subPath: redis.master.persistence.subPath}
								if redis.master.persistence.subPath == "" && redis.master.persistence.subPathExpr != "" {subPathExpr: redis.master.persistence.subPathExpr}
							}],
							[
								{name: "config", mountPath: "/opt/bitnami/redis/mounted-etc"},
								{name: "redis-tmp-conf", mountPath: "/opt/bitnami/redis/etc/"},
								{name: "tmp", mountPath: "/tmp"},
							],
							[if redis.tls.enabled {[{name: "redis-certificates", mountPath: "/opt/bitnami/redis/certs", readOnly: true}]}, []][0],
							[for vm in redis.master.extraVolumeMounts {vm}],
						])
					}],
					if redis.metrics.enabled {
						[{
							name:            "metrics"
							image:           "\(redis.metrics.image.registry)/\(redis.metrics.image.repository):\(redis.metrics.image.tag)"
							imagePullPolicy: redis.metrics.image.pullPolicy
							command: ["/bin/bash", "-c", "redis_exporter"]
							env: list.Concat([
								[{name: "REDIS_ALIAS", value: redisName}],
								[if redis.auth.enabled {[{name: "REDIS_USER", value: "default"}]}, []][0],
								[if redis.auth.enabled && !redis.auth.usePasswordFiles {[{name: "REDIS_PASSWORD", valueFrom: secretKeyRef: {name: [if redis.auth.existingSecret != "" {redis.auth.existingSecret}, redisName][0], key: redis.auth.secretKeys.userPasswordKey}}]}, []][0],
								[if redis.tls.enabled {
									[
										{name: "REDIS_ADDR", value: "rediss://localhost:\(redis.master.containerPorts.redis)"},
										[if redis.tls.authClients {
											[
												{name: "REDIS_EXPORTER_TLS_CLIENT_KEY_FILE", value: "/opt/bitnami/redis/certs/tls.key"},
												{name: "REDIS_EXPORTER_TLS_CLIENT_CERT_FILE", value: "/opt/bitnami/redis/certs/tls.crt"},
											]
										}, []][0],
										{name: "REDIS_EXPORTER_TLS_CA_CERT_FILE", value: "/opt/bitnami/redis/certs/ca.crt"},
									]
								}, []][0],
								[for e in redis.metrics.extraEnvVars {e}],
							])
							ports: [{name: "metrics", containerPort: 9121}]
							if redis.metrics.startupProbe.enabled {
								startupProbe: redis.metrics.startupProbe & {tcpSocket: port: "metrics"}
							}
							if redis.metrics.livenessProbe.enabled {
								livenessProbe: redis.metrics.livenessProbe & {tcpSocket: port: "metrics"}
							}
							if redis.metrics.readinessProbe.enabled {
								readinessProbe: redis.metrics.readinessProbe & {httpGet: {path: "/", port: "metrics"}}
							}
							resources: redis.metrics.resources
							volumeMounts: list.Concat([
								[if redis.auth.usePasswordFiles {[{name: "redis-password", mountPath: "/secrets/"}]}, []][0],
								[if redis.tls.enabled {[{name: "redis-certificates", mountPath: "/opt/bitnami/redis/certs", readOnly: true}]}, []][0],
								[for vm in redis.metrics.extraVolumeMounts {vm}],
							])
						}]
					},
					[for c in redis.master.sidecars {c}],
				])
				initContainers: list.Concat([
					[if redis.master.initContainers != _|_ {redis.master.initContainers}, []][0],
					[
						if redis.volumePermissions.enabled && redis.master.persistence.enabled && redis.master.podSecurityContext.enabled && redis.master.containerSecurityContext.enabled {
							{
								name:            "volume-permissions"
								image:           "\(redis.volumePermissions.image.registry)/\(redis.volumePermissions.image.repository):\(redis.volumePermissions.image.tag)"
								imagePullPolicy: redis.volumePermissions.image.pullPolicy
								command: ["/bin/bash", "-ec", "chown -R \(redis.master.containerSecurityContext.runAsUser):\(redis.master.podSecurityContext.fsGroup) \(redis.master.persistence.path)"]
								securityContext: runAsUser: 0
								resources: redis.volumePermissions.resources
								volumeMounts: [{name: "redis-data", mountPath: redis.master.persistence.path}]
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
					if redis.auth.usePasswordFiles {
						{name: "redis-password", secret: {secretName: [if redis.auth.existingSecret != "" {redis.auth.existingSecret}, redisName][0], items: [{key: redis.auth.secretKeys.userPasswordKey, path: "redis-password"}]}}
					},
					{name: "config", configMap: {name: "\(redisName)-configuration"}},
					{name: "redis-tmp-conf", emptyDir: {}},
					{name: "tmp", emptyDir: {}},
					if redis.sysctl.enabled && redis.sysctl.mountHostSys {
						{name: "host-sys", hostPath: path: "/sys"}
					},
					if redis.tls.enabled {
						{name: "redis-certificates", secret: {secretName: [if redis.tls.existingSecret != "" {redis.tls.existingSecret}, "\(redisName)-crt"][0], defaultMode: 256}}
					},
					if !redis.master.persistence.enabled || redis.master.kind == "DaemonSet" {
						{name: "redis-data", emptyDir: {}}
					},
					if redis.master.persistence.enabled && redis.master.persistence.existingClaim != "" {
						{name: "redis-data", persistentVolumeClaim: claimName: redis.master.persistence.existingClaim}
					},
					if redis.master.persistence.enabled && redis.master.kind == "Deployment" && redis.master.persistence.existingClaim == "" {
						{name: "redis-data", persistentVolumeClaim: claimName: "redis-data-\(redisName)-master"}
					},
					for v in redis.master.extraVolumes {v},
					for v in redis.metrics.extraVolumes {v},
				]
			}
		}
		if redis.master.persistence.enabled && redis.master.kind == "StatefulSet" && redis.master.persistence.existingClaim == "" {
			if redis.master.persistentVolumeClaimRetentionPolicy.enabled {
				persistentVolumeClaimRetentionPolicy: {
					whenDeleted: redis.master.persistentVolumeClaimRetentionPolicy.whenDeleted
					whenScaled:  redis.master.persistentVolumeClaimRetentionPolicy.whenScaled
				}
			}
			volumeClaimTemplates: [{
				metadata: {
					name: "redis-data"
					labels: redisLabels & redis.master.persistence.labels & {"app.kubernetes.io/component": "master"}
					if len(redis.master.persistence.annotations) > 0 {annotations: redis.master.persistence.annotations}
				}
				spec: {
					accessModes: redis.master.persistence.accessModes
					resources: requests: storage: redis.master.persistence.size
					if len(redis.master.persistence.selector) > 0 {selector: redis.master.persistence.selector}
					if len(redis.master.persistence.dataSource) > 0 {dataSource: redis.master.persistence.dataSource}
					if redis.master.persistence.storageClass != "" {storageClassName: redis.master.persistence.storageClass}
				}
			}]
		}
	}
}

// 2. /charts/redis/templates/master/psp.yaml
#RedisMasterPSP: policyv1.#PodSecurityPolicy & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "policy/v1beta1"
	kind:       "PodSecurityPolicy"
	metadata: {name: "\(redisName)-master", namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result, if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}}
	spec: {
		allowPrivilegeEscalation: false
		fsGroup: {rule: "MustRunAs", ranges: [{min: redis.master.podSecurityContext.fsGroup, max: redis.master.podSecurityContext.fsGroup}]}
		hostIPC:                false
		hostNetwork:            false
		hostPID:                false
		privileged:             false
		readOnlyRootFilesystem: false
		requiredDropCapabilities: ["ALL"]
		runAsUser: {rule: "MustRunAs", ranges: [{min: redis.master.containerSecurityContext.runAsUser, max: redis.master.containerSecurityContext.runAsUser}]}
		seLinux: rule: "RunAsAny"
		supplementalGroups: {rule: "MustRunAs", ranges: [{min: redis.master.containerSecurityContext.runAsUser, max: redis.master.containerSecurityContext.runAsUser}]}
		volumes: ["configMap", "secret", "emptyDir", "persistentVolumeClaim"]
	}
}

// 3. /charts/redis/templates/master/pvc.yaml
#RedisMasterPVC: corev1.#PersistentVolumeClaim & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "v1"
	kind:       "PersistentVolumeClaim"
	metadata: {name: "redis-data-\(redisName)-master", namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result & redis.master.persistence.labels & {"app.kubernetes.io/component": "master"}, if len(redis.master.persistence.annotations) > 0 {annotations: redis.master.persistence.annotations}}
	spec: {
		accessModes: redis.master.persistence.accessModes
		resources: requests: storage: redis.master.persistence.size
		if len(redis.master.persistence.selector) > 0 {selector: redis.master.persistence.selector}
		if len(redis.master.persistence.dataSource) > 0 {dataSource: redis.master.persistence.dataSource}
		if redis.master.persistence.storageClass != "" {storageClassName: redis.master.persistence.storageClass}
	}
}

// 4. /charts/redis/templates/master/service.yaml
#RedisMasterService: corev1.#Service & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "v1"
	kind:       "Service"
	metadata: {name: "\(redisName)-master", namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result & {"app.kubernetes.io/component": "master"}, if len(redis.commonAnnotations) > 0 || len(redis.master.service.annotations) > 0 {annotations: redis.commonAnnotations & redis.master.service.annotations}}
	spec: {
		type: redis.master.service.type
		if redis.master.service.type == "LoadBalancer" || redis.master.service.type == "NodePort" {externalTrafficPolicy: redis.master.service.externalTrafficPolicy}
		internalTrafficPolicy: redis.master.service.internalTrafficPolicy
		if redis.master.service.type == "LoadBalancer" && redis.master.service.loadBalancerIP != "" {loadBalancerIP: redis.master.service.loadBalancerIP}
		if redis.master.service.type == "LoadBalancer" && redis.master.service.loadBalancerClass != "" {loadBalancerClass: redis.master.service.loadBalancerClass}
		if redis.master.service.type == "LoadBalancer" && len(redis.master.service.loadBalancerSourceRanges) > 0 {loadBalancerSourceRanges: redis.master.service.loadBalancerSourceRanges}
		if redis.master.service.type == "ClusterIP" && redis.master.service.clusterIP != "" {clusterIP: redis.master.service.clusterIP}
		if redis.master.service.sessionAffinity != "" {sessionAffinity: redis.master.service.sessionAffinity}
		if len(redis.master.service.sessionAffinityConfig) > 0 {sessionAffinityConfig: redis.master.service.sessionAffinityConfig}
		if len(redis.master.service.externalIPs) > 0 {externalIPs: redis.master.service.externalIPs}
		ports: list.Concat([[{name: "tcp-redis", port: redis.master.service.ports.redis, targetPort: "redis", if (redis.master.service.type == "NodePort" || redis.master.service.type == "LoadBalancer") && redis.master.service.nodePorts.redis != "" {nodePort: redis.master.service.nodePorts.redis}}], redis.master.service.extraPorts])
		selector: (#RedisLabels & {#config: #config}).result & redis.master.podLabels & {"app.kubernetes.io/component": "master"}
	}
}

#RedisMasterServiceAccountName: {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	result: string
	if redis.master.serviceAccount.name != "" {result: redis.master.serviceAccount.name}
	if redis.master.serviceAccount.name == "" {result: "\(redisName)-master"}
}

// 5. /charts/redis/templates/master/serviceaccount.yaml
#RedisMasterServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	apiVersion:                   "v1"
	kind:                         "ServiceAccount"
	automountServiceAccountToken: redis.master.serviceAccount.automountServiceAccountToken
	metadata: {name: (#RedisMasterServiceAccountName & {#config: #config}).result, namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result, if len(redis.commonAnnotations) > 0 || len(redis.master.serviceAccount.annotations) > 0 {annotations: redis.commonAnnotations & redis.master.serviceAccount.annotations}}
}
