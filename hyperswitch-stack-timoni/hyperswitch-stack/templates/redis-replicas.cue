package templates

import (
	"list"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

// 1. /charts/redis/templates/replicas/application.yaml
#RedisReplicasApplication: appsv1.#StatefulSet & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	let redisLabels = (#RedisLabels & {#config: #config}).result
	let replicaLabels = redisLabels & redis.replica.podLabels & {"app.kubernetes.io/component": "replica"}
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(redisName)-replicas"
		namespace: #config.metadata.namespace
		labels: redisLabels & {"app.kubernetes.io/component": "replica"}
		if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}
	}
	spec: {
		if !redis.replica.autoscaling.enabled {replicas: redis.replica.replicaCount}
		selector: matchLabels: replicaLabels
		serviceName: "\(redisName)-headless"
		if len(redis.replica.updateStrategy) > 0 {updateStrategy: redis.replica.updateStrategy}
		if redis.replica.minReadySeconds > 0 {minReadySeconds: redis.replica.minReadySeconds}
		if redis.replica.podManagementPolicy != "" {podManagementPolicy: redis.replica.podManagementPolicy}
		template: {
			metadata: {
				labels: replicaLabels
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
				serviceAccountName: (#RedisReplicasServiceAccountName & {#config: #config}).result
				automountServiceAccountToken: redis.replica.serviceAccount.automountServiceAccountToken
				if redis.replica.priorityClassName != "" {priorityClassName: redis.replica.priorityClassName}
				if len(redis.replica.affinity) > 0 {affinity: redis.replica.affinity}
				if len(redis.replica.nodeSelector) > 0 {nodeSelector: redis.replica.nodeSelector}
				if len(redis.replica.tolerations) > 0 {tolerations: redis.replica.tolerations}
				if len(redis.replica.topologySpreadConstraints) > 0 {topologySpreadConstraints: redis.replica.topologySpreadConstraints}
				if redis.replica.shareProcessNamespace {shareProcessNamespace: redis.replica.shareProcessNamespace}
				if redis.replica.schedulerName != "" {schedulerName: redis.replica.schedulerName}
				if redis.replica.dnsPolicy != "" {dnsPolicy: redis.replica.dnsPolicy}
				if len(redis.replica.dnsConfig) > 0 {dnsConfig: redis.replica.dnsConfig}
				enableServiceLinks:            redis.replica.enableServiceLinks
				terminationGracePeriodSeconds: redis.replica.terminationGracePeriodSeconds
				containers: [
					{
						name:            "redis"
						image:           "\(redis.image.registry)/\(redis.image.repository):\(redis.image.tag)"
						imagePullPolicy: redis.image.pullPolicy
						if redis.replica.containerSecurityContext.enabled {
							securityContext: {
								runAsUser:                redis.replica.containerSecurityContext.runAsUser
								runAsNonRoot:             redis.replica.containerSecurityContext.runAsNonRoot
								allowPrivilegeEscalation: redis.replica.containerSecurityContext.allowPrivilegeEscalation
								readOnlyRootFilesystem:   redis.replica.containerSecurityContext.readOnlyRootFilesystem
							}
						}
						if len(redis.replica.lifecycleHooks) > 0 {
							lifecycle: redis.replica.lifecycleHooks
						}
						command: ["/bin/bash"]
						args: ["-c", "/opt/bitnami/scripts/start-scripts/start-replica.sh"]
						env: [
							{name: "BITNAMI_DEBUG", value: "\(redis.image.debug)"},
							{name: "REDIS_REPLICATION_MODE", value: "replica"},
							{name: "REDIS_MASTER_HOST", value: [if redis.replica.externalMaster.enabled {redis.replica.externalMaster.host}, if redis.master.count == 1 && redis.master.kind == "StatefulSet" {"\(redisName)-master-0.\(redisName)-headless.\(#config.metadata.namespace).svc.\(redis.clusterDomain)"}, "\(redisName)-master.\(#config.metadata.namespace).svc.\(redis.clusterDomain)"][0]},
							{name: "REDIS_MASTER_PORT_NUMBER", value: [if redis.replica.externalMaster.enabled {"\(redis.replica.externalMaster.port)"}, "\(redis.master.containerPorts.redis)"][0]},
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
							for e in redis.replica.extraEnvVars {e},
						]
						if redis.replica.extraEnvVarsCM != "" || redis.replica.extraEnvVarsSecret != "" {
							envFrom: [
								if redis.replica.extraEnvVarsCM != "" {
									{configMapRef: {name: redis.replica.extraEnvVarsCM}}
								},
								if redis.replica.extraEnvVarsSecret != "" {
									{secretRef: {name: redis.replica.extraEnvVarsSecret}}
								},
							]
						}
						ports: [{name: "redis", containerPort: redis.replica.containerPorts.redis}]
						if redis.replica.startupProbe.enabled {
							startupProbe: {
								tcpSocket: port: "redis"
								initialDelaySeconds: redis.replica.startupProbe.initialDelaySeconds
								periodSeconds:       redis.replica.startupProbe.periodSeconds
								timeoutSeconds:      redis.replica.startupProbe.timeoutSeconds
								successThreshold:    redis.replica.startupProbe.successThreshold
								failureThreshold:    redis.replica.startupProbe.failureThreshold
							}
						}
						if redis.replica.livenessProbe.enabled {
							livenessProbe: {
								initialDelaySeconds: redis.replica.livenessProbe.initialDelaySeconds
								periodSeconds:       redis.replica.livenessProbe.periodSeconds
								timeoutSeconds:      redis.replica.livenessProbe.timeoutSeconds + 1
								successThreshold:    redis.replica.livenessProbe.successThreshold
								failureThreshold:    redis.replica.livenessProbe.failureThreshold
								exec: command: ["sh", "-c", "/health/ping_liveness_local_and_master.sh \(redis.replica.livenessProbe.timeoutSeconds)"]
							}
						}
						if redis.replica.readinessProbe.enabled {
							readinessProbe: {
								initialDelaySeconds: redis.replica.readinessProbe.initialDelaySeconds
								periodSeconds:       redis.replica.readinessProbe.periodSeconds
								timeoutSeconds:      redis.replica.readinessProbe.timeoutSeconds + 1
								successThreshold:    redis.replica.readinessProbe.successThreshold
								failureThreshold:    redis.replica.readinessProbe.failureThreshold
								exec: command: ["sh", "-c", "/health/ping_readiness_local_and_master.sh \(redis.replica.readinessProbe.timeoutSeconds)"]
							}
						}
						resources: redis.replica.resources
						volumeMounts: [
							{name: "start-scripts", mountPath: "/opt/bitnami/scripts/start-scripts"},
							{name: "health", mountPath: "/health"},
							if redis.auth.usePasswordFiles {name: "redis-password", mountPath: "/opt/bitnami/redis/secrets/"},
							{
								name:      "redis-data"
								mountPath: "/data"
								if redis.replica.persistence.subPath != "" {subPath: redis.replica.persistence.subPath}
								if redis.replica.persistence.subPath == "" && redis.replica.persistence.subPathExpr != "" {subPathExpr: redis.replica.persistence.subPathExpr}
							},
							{name: "config", mountPath: "/opt/bitnami/redis/mounted-etc"},
							{name: "redis-tmp-conf", mountPath: "/opt/bitnami/redis/etc/"},
							{name: "tmp", mountPath: "/tmp"},
							if redis.tls.enabled {name: "redis-certificates", mountPath: "/opt/bitnami/redis/certs", readOnly: true},
							for vm in redis.replica.extraVolumeMounts {vm},
						]
					},
					if redis.metrics.enabled {
						{
							name:            "metrics"
							image:           "\(redis.metrics.image.registry)/\(redis.metrics.image.repository):\(redis.metrics.image.tag)"
							imagePullPolicy: redis.metrics.image.pullPolicy
							command: ["/bin/bash", "-c", "redis_exporter"]
							env: [
								{name: "REDIS_ALIAS", value: redisName},
								if redis.auth.enabled {name: "REDIS_USER", value: "default"},
								if redis.auth.enabled && !redis.auth.usePasswordFiles {name: "REDIS_PASSWORD", valueFrom: secretKeyRef: {name: [if redis.auth.existingSecret != "" {redis.auth.existingSecret}, redisName][0], key: redis.auth.secretKeys.userPasswordKey}},
								if redis.auth.enabled && !redis.auth.usePasswordFiles {name: "REDIS_MASTER_PASSWORD", valueFrom: secretKeyRef: {name: [if redis.auth.existingSecret != "" {redis.auth.existingSecret}, redisName][0], key: redis.auth.secretKeys.userPasswordKey}},
								if redis.tls.enabled {
									{name: "REDIS_ADDR", value: "rediss://\(redis.metrics.service.port):\(redis.replica.containerPorts.redis)"}
									if redis.tls.authClients {
										{name: "REDIS_EXPORTER_TLS_CLIENT_KEY_FILE", value: "/opt/bitnami/redis/certs/tls.key"}
										{name: "REDIS_EXPORTER_TLS_CLIENT_CERT_FILE", value: "/opt/bitnami/redis/certs/tls.crt"}
									}
									{name: "REDIS_EXPORTER_TLS_CA_CERT_FILE", value: "/opt/bitnami/redis/certs/ca.crt"}
								},
								for e in redis.metrics.extraEnvVars {e},
							]
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
					if !redis.replica.persistence.enabled || redis.replica.kind == "DaemonSet" {
						{name: "redis-data", emptyDir: {}}
					},
					if redis.replica.persistence.enabled && redis.replica.persistence.existingClaim != "" {
						{name: "redis-data", persistentVolumeClaim: claimName: redis.replica.persistence.existingClaim}
					},
					if redis.replica.persistence.enabled && redis.replica.kind == "Deployment" && redis.replica.persistence.existingClaim == "" {
						{name: "redis-data", persistentVolumeClaim: claimName: "redis-data-\(redisName)-replicas"}
					},
					for v in redis.replica.extraVolumes {v},
					for v in redis.metrics.extraVolumes {v},
				]
			}
		}
		if redis.replica.persistence.enabled && redis.replica.kind == "StatefulSet" && redis.replica.persistence.existingClaim == "" {
			if redis.replica.persistentVolumeClaimRetentionPolicy.enabled {
				persistentVolumeClaimRetentionPolicy: {
					whenDeleted: redis.replica.persistentVolumeClaimRetentionPolicy.whenDeleted
					whenScaled:  redis.replica.persistentVolumeClaimRetentionPolicy.whenScaled
				}
			}
			volumeClaimTemplates: [{
				metadata: {
					name: "redis-data"
					labels: redisLabels & redis.replica.persistence.labels & {"app.kubernetes.io/component": "replica"}
					if len(redis.replica.persistence.annotations) > 0 {annotations: redis.replica.persistence.annotations}
				}
				spec: {
					accessModes: redis.replica.persistence.accessModes
					resources: requests: storage: redis.replica.persistence.size
					if len(redis.replica.persistence.selector) > 0 {selector: redis.replica.persistence.selector}
					if len(redis.replica.persistence.dataSource) > 0 {dataSource: redis.replica.persistence.dataSource}
					if redis.replica.persistence.storageClass != "" {storageClassName: redis.replica.persistence.storageClass}
				}
			}]
		}
	}
}

// 2. /charts/redis/templates/replicas/hpa.yaml
#RedisReplicasHPA: {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {name: "\(redisName)-replicas", namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result & {"app.kubernetes.io/component": "replica"}, if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}}
	spec: {
		scaleTargetRef: {apiVersion: "apps/v1", kind: "StatefulSet", name: "\(redisName)-replicas"}
		minReplicas: redis.replica.autoscaling.minReplicas
		maxReplicas: redis.replica.autoscaling.maxReplicas
		metrics: [
			if redis.replica.autoscaling.targetCPU > 0 {type: "Resource", resource: {name: "cpu", target: {type: "Utilization", averageUtilization: redis.replica.autoscaling.targetCPU}}},
			if redis.replica.autoscaling.targetMemory > 0 {type: "Resource", resource: {name: "memory", target: {type: "Utilization", averageUtilization: redis.replica.autoscaling.targetMemory}}},
		]
	}
}

// 3. /charts/redis/templates/replicas/service.yaml
#RedisReplicasService: corev1.#Service & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "v1"
	kind:       "Service"
	metadata: {name: "\(redisName)-replicas", namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result & {"app.kubernetes.io/component": "replica"}, if len(redis.commonAnnotations) > 0 || len(redis.replica.service.annotations) > 0 {annotations: redis.commonAnnotations & redis.replica.service.annotations}}
	spec: {
		type: redis.replica.service.type
		if redis.replica.service.type == "LoadBalancer" || redis.replica.service.type == "NodePort" {externalTrafficPolicy: redis.replica.service.externalTrafficPolicy}
		internalTrafficPolicy: redis.replica.service.internalTrafficPolicy
		if redis.replica.service.type == "LoadBalancer" && redis.replica.service.loadBalancerIP != "" {loadBalancerIP: redis.replica.service.loadBalancerIP}
		if redis.replica.service.type == "LoadBalancer" && redis.replica.service.loadBalancerClass != "" {loadBalancerClass: redis.replica.service.loadBalancerClass}
		if redis.replica.service.type == "LoadBalancer" && len(redis.replica.service.loadBalancerSourceRanges) > 0 {loadBalancerSourceRanges: redis.replica.service.loadBalancerSourceRanges}
		if redis.replica.service.type == "ClusterIP" && redis.replica.service.clusterIP != "" {clusterIP: redis.replica.service.clusterIP}
		if redis.replica.service.sessionAffinity != "" {sessionAffinity: redis.replica.service.sessionAffinity}
		if len(redis.replica.service.sessionAffinityConfig) > 0 {sessionAffinityConfig: redis.replica.service.sessionAffinityConfig}
		if len(redis.replica.service.externalIPs) > 0 {externalIPs: redis.replica.service.externalIPs}
		ports: list.Concat([[{name: "tcp-redis", port: redis.replica.service.ports.redis, targetPort: "redis", if (redis.replica.service.type == "NodePort" || redis.replica.service.type == "LoadBalancer") && redis.replica.service.nodePorts.redis != "" {nodePort: redis.replica.service.nodePorts.redis}}], redis.replica.service.extraPorts])
		selector: (#RedisLabels & {#config: #config}).result & redis.replica.podLabels & {"app.kubernetes.io/component": "replica"}
	}
}

#RedisReplicasServiceAccountName: {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	result: string
	if redis.replica.serviceAccount.name != "" {result: redis.replica.serviceAccount.name}
	if redis.replica.serviceAccount.name == "" {result: "\(redisName)-replicas"}
}

// 4. /charts/redis/templates/replicas/serviceaccount.yaml
#RedisReplicasServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	apiVersion:                   "v1"
	kind:                         "ServiceAccount"
	automountServiceAccountToken: redis.replica.serviceAccount.automountServiceAccountToken
	metadata: {name: (#RedisReplicasServiceAccountName & {#config: #config}).result, namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result, if len(redis.commonAnnotations) > 0 || len(redis.replica.serviceAccount.annotations) > 0 {annotations: redis.commonAnnotations & redis.replica.serviceAccount.annotations}}
}
