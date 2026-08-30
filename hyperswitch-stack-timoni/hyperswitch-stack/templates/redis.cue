package templates

import (
	"encoding/base64"
	"strings"
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
	policyv1 "k8s.io/api/policy/v1"
	rbacv1 "k8s.io/api/rbac/v1"
)

#RedisLabels: {
	#config: #Config
	let redis = #config."hyperswitch-app".redis

	// Standard labels shared by Redis resources, merged with user-provided commonLabels.
	result: redis.commonLabels & {
		"app.kubernetes.io/name":       "redis"
		"app.kubernetes.io/instance":   #config.metadata.name
		"app.kubernetes.io/version":    (#config.moduleVersion | *"0.0.0")
		"app.kubernetes.io/managed-by": "timoni"
	}
}

#RedisName: {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	// Redis fullname equivalent to Helm's common.names.fullname helper.
	result: string
	if redis.fullnameOverride != "" {
		result: redis.fullnameOverride
	}
	if redis.fullnameOverride == "" {
		result: #config.metadata.name + "-redis"
	}
}

#RedisServiceAccountName: {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result

	// Use an explicit serviceAccount.name when provided, otherwise use the Redis fullname.
	result: string
	if redis.serviceAccount.name != "" {
		result: redis.serviceAccount.name
	}
	if redis.serviceAccount.name == "" {
		result: redisName
	}
}

#RedisAnnotations: {
	#common: {[string]: string} | *{}
	#local: {[string]: string} | *{}

	// Merge chart-wide annotations with resource-specific annotations.
	result: #common & #local
}

// 1. /charts/redis/templates/configmap.yaml
#RedisConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(redisName)-configuration"
		namespace: #config.metadata.namespace
		labels: (#RedisLabels & {#config: #config}).result
		if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}
	}
	data: {
		"redis.conf":   "# User-supplied common configuration:\n\(redis.commonConfiguration)# End of common configuration"
		"master.conf":  "dir \(redis.master.persistence.path)\n# User-supplied master configuration:\n\(redis.master.configuration)\(strings.Join([for c in redis.master.disableCommands {"rename-command \(c) \"\""}], "\n"))\n# End of master configuration"
		"replica.conf": "dir \(redis.replica.persistence.path)\n# User-supplied replica configuration:\n\(redis.replica.configuration)\(strings.Join([for c in redis.replica.disableCommands {"rename-command \(c) \"\""}], "\n"))\n# End of replica configuration"
		if redis.sentinel.enabled {
			"sentinel.conf": "dir \"/tmp\"\nport \(redis.sentinel.containerPorts.sentinel)\nsentinel monitor \(redis.sentinel.masterSet) \(redisName)-node-0.\(redisName)-headless.\(#config.metadata.namespace).svc.\(redis.clusterDomain) \(redis.sentinel.service.ports.redis) \(redis.sentinel.quorum)\nsentinel down-after-milliseconds \(redis.sentinel.masterSet) \(redis.sentinel.downAfterMilliseconds)\nsentinel failover-timeout \(redis.sentinel.masterSet) \(redis.sentinel.failoverTimeout)\nsentinel parallel-syncs \(redis.sentinel.masterSet) \(redis.sentinel.parallelSyncs)\n# User-supplied sentinel configuration:\n\(redis.sentinel.configuration)# End of sentinel configuration"
		}
	}
}

// 2. /charts/redis/templates/extra-list.yaml
#RedisExtra: {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	objects: [for ed in redis.extraDeploy {ed}]
}

// 3. /charts/redis/templates/headless-svc.yaml
#RedisHeadlessService: corev1.#Service & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(redisName)-headless"
		namespace: #config.metadata.namespace
		labels: (#RedisLabels & {#config: #config}).result
		annotations: redis.commonAnnotations & redis.sentinel.service.headless.annotations
	}
	spec: {
		type:      "ClusterIP"
		clusterIP: "None"
		if redis.sentinel.enabled {publishNotReadyAddresses: true}
		ports: [{name: "tcp-redis", port: [if redis.sentinel.enabled {redis.sentinel.service.ports.redis}, redis.master.service.ports.redis][0], targetPort: "redis"}, if redis.sentinel.enabled {name: "tcp-sentinel", port: redis.sentinel.service.ports.sentinel, targetPort: "redis-sentinel"}]
		selector: (#RedisLabels & {#config: #config}).result
	}
}

// 4. /charts/redis/templates/health-configmap.yaml
#RedisHealthConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(redisName)-health"
		namespace: #config.metadata.namespace
		labels: (#RedisLabels & {#config: #config}).result
		if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}
	}
	data: {
		"ping_readiness_local.sh":            "#!/bin/bash\n[[ -f $REDIS_PASSWORD_FILE ]] && export REDIS_PASSWORD=\"$(< \"${REDIS_PASSWORD_FILE}\")\"\n[[ -n \"$REDIS_PASSWORD\" ]] && export REDISCLI_AUTH=\"$REDIS_PASSWORD\"\nredis-cli -h localhost -p $REDIS_PORT ping | grep PONG"
		"ping_liveness_local.sh":             "#!/bin/bash\n[[ -f $REDIS_PASSWORD_FILE ]] && export REDIS_PASSWORD=\"$(< \"${REDIS_PASSWORD_FILE}\")\"\n[[ -n \"$REDIS_PASSWORD\" ]] && export REDISCLI_AUTH=\"$REDIS_PASSWORD\"\nresponse=$(redis-cli -h localhost -p $REDIS_PORT ping)\nresponseFirstWord=$(echo $response | head -n1 | awk '{print $1;}')\nif [ \"$response\" != \"PONG\" ] && [ \"$responseFirstWord\" != \"LOADING\" ] && [ \"$responseFirstWord\" != \"MASTERDOWN\" ]; then echo \"$response\"; exit 1; fi"
		"ping_readiness_master.sh":           "#!/bin/bash\n[[ -f $REDIS_MASTER_PASSWORD_FILE ]] && export REDIS_MASTER_PASSWORD=\"$(< \"${REDIS_MASTER_PASSWORD_FILE}\")\"\n[[ -n \"$REDIS_MASTER_PASSWORD\" ]] && export REDISCLI_AUTH=\"$REDIS_MASTER_PASSWORD\"\nredis-cli -h $REDIS_MASTER_HOST -p $REDIS_MASTER_PORT_NUMBER ping | grep PONG"
		"ping_liveness_master.sh":            "#!/bin/bash\n[[ -f $REDIS_MASTER_PASSWORD_FILE ]] && export REDIS_MASTER_PASSWORD=\"$(< \"${REDIS_MASTER_PASSWORD_FILE}\")\"\n[[ -n \"$REDIS_MASTER_PASSWORD\" ]] && export REDISCLI_AUTH=\"$REDIS_MASTER_PASSWORD\"\nresponse=$(redis-cli -h $REDIS_MASTER_HOST -p $REDIS_MASTER_PORT_NUMBER ping)\nresponseFirstWord=$(echo $response | head -n1 | awk '{print $1;}')\nif [ \"$response\" != \"PONG\" ] && [ \"$responseFirstWord\" != \"LOADING\" ]; then echo \"$response\"; exit 1; fi"
		"ping_readiness_local_and_master.sh": "script_dir=\"$(dirname \"$0\")\"\nexit_status=0\n\"$script_dir/ping_readiness_local.sh\" $1 || exit_status=$?\n\"$script_dir/ping_readiness_master.sh\" $1 || exit_status=$?\nexit $exit_status"
		"ping_liveness_local_and_master.sh":  "script_dir=\"$(dirname \"$0\")\"\nexit_status=0\n\"$script_dir/ping_liveness_local.sh\" $1 || exit_status=$?\n\"$script_dir/ping_liveness_master.sh\" $1 || exit_status=$?\nexit $exit_status"
	}
}

// 5. /charts/redis/templates/metrics-svc.yaml
#RedisMetricsService: corev1.#Service & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(redisName)-metrics"
		namespace: #config.metadata.namespace
		labels: (#RedisLabels & {#config: #config}).result & {"app.kubernetes.io/component": "metrics"}
		if len(redis.commonAnnotations) > 0 || len(redis.metrics.service.annotations) > 0 {annotations: redis.commonAnnotations & redis.metrics.service.annotations}
	}
	spec: {
		type: redis.metrics.service.type
		if redis.metrics.service.type == "ClusterIP" && redis.metrics.service.clusterIP != "" {clusterIP: redis.metrics.service.clusterIP}
		if redis.metrics.service.type == "LoadBalancer" {externalTrafficPolicy: redis.metrics.service.externalTrafficPolicy}
		if redis.metrics.service.type == "LoadBalancer" && redis.metrics.service.loadBalancerIP != "" {loadBalancerIP: redis.metrics.service.loadBalancerIP}
		if redis.metrics.service.type == "LoadBalancer" && redis.metrics.service.loadBalancerClass != "" {loadBalancerClass: redis.metrics.service.loadBalancerClass}
		if redis.metrics.service.type == "LoadBalancer" && len(redis.metrics.service.loadBalancerSourceRanges) > 0 {loadBalancerSourceRanges: redis.metrics.service.loadBalancerSourceRanges}
		ports: [{name: "http-metrics", port: redis.metrics.service.port, protocol: "TCP", targetPort: "metrics"}, ...redis.metrics.service.extraPorts]
		selector: (#RedisLabels & {#config: #config}).result
	}
}

// 6. /charts/redis/templates/networkpolicy.yaml
#RedisNetworkPolicy: netv1.#NetworkPolicy & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {name: redisName, namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result, if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}}
	spec: {
		podSelector: matchLabels: (#RedisLabels & {#config: #config}).result
		policyTypes: ["Ingress", if redis.architecture == "replication" || len(redis.networkPolicy.extraEgress) > 0 {"Egress"}]
		if redis.architecture == "replication" || len(redis.networkPolicy.extraEgress) > 0 {
			egress: [
				if redis.architecture == "replication" {
					ports: [{port: 53, protocol: "UDP"}]
				},
				if redis.architecture == "replication" {
					ports: [{port: redis.master.containerPorts.redis}]
					to: [{podSelector: matchLabels: (#RedisLabels & {#config: #config}).result}]
				},
				for e in redis.networkPolicy.extraEgress {e},
			]
		}
		ingress: [
			{ports: [{port: redis.master.containerPorts.redis}], if !redis.networkPolicy.allowExternal {
				from: [
					{podSelector: matchLabels: {"\(redisName)-client": "true"}},
					{podSelector: matchLabels: (#RedisLabels & {#config: #config}).result},
				]
			}},
			if redis.metrics.enabled {ports: [{port: 9121}]},
			...redis.networkPolicy.extraIngress,
		]
	}
}

// 7. /charts/redis/templates/pdb.yaml
#RedisPDB: policyv1.#PodDisruptionBudget & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {name: redisName, namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result, if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}}
	spec: {if redis.pdb.minAvailable != "" {minAvailable: redis.pdb.minAvailable}, if redis.pdb.maxUnavailable != "" {maxUnavailable: redis.pdb.maxUnavailable}, selector: matchLabels: (#RedisLabels & {#config: #config}).result}
}

// 8. /charts/redis/templates/podmonitor.yaml
#RedisPodMonitor: {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "PodMonitor"
	metadata: {name: redisName, namespace: [if redis.metrics.podMonitor.namespace != "" {redis.metrics.podMonitor.namespace}, #config.metadata.namespace][0], labels: (#RedisLabels & {#config: #config}).result & redis.metrics.podMonitor.additionalLabels, if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}}
	spec: {podMetricsEndpoints: [{port: "http-metrics", if redis.metrics.podMonitor.interval != "" {interval: redis.metrics.podMonitor.interval}, if redis.metrics.podMonitor.scrapeTimeout != "" {scrapeTimeout: redis.metrics.podMonitor.scrapeTimeout}, if redis.metrics.podMonitor.honorLabels {honorLabels: redis.metrics.podMonitor.honorLabels}}], namespaceSelector: matchNames: [#config.metadata.namespace], selector: matchLabels: (#RedisLabels & {#config: #config}).result & {"app.kubernetes.io/component": "metrics"}}
}

// 9. /charts/redis/templates/prometheusrule.yaml
#RedisPrometheusRule: {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "PrometheusRule"
	metadata: {name: redisName, namespace: [if redis.metrics.prometheusRule.namespace != "" {redis.metrics.prometheusRule.namespace}, #config.metadata.namespace][0], labels: (#RedisLabels & {#config: #config}).result & redis.metrics.prometheusRule.additionalLabels, if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}}
	spec: groups: [{name: redisName, rules: redis.metrics.prometheusRule.rules}]
}

// 10. /charts/redis/templates/role.yaml
#RedisRole: rbacv1.#Role & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {name: redisName, namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result, if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}}
	rules: redis.rbac.rules
}

// 11. /charts/redis/templates/rolebinding.yaml
#RedisRoleBinding: rbacv1.#RoleBinding & {
	#config: #Config
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {name: redisName, namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result}
	roleRef: {apiGroup: "rbac.authorization.k8s.io", kind: "Role", name: redisName}
	subjects: [{kind: "ServiceAccount", name: (#RedisServiceAccountName & {#config: #config}).result}]
}

// 12. /charts/redis/templates/scripts-configmap.yaml
#RedisScriptsConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {name: redisName + "-scripts", namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result, if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}}
	data: {
		"start-master.sh": "#!/bin/bash\n[[ -f $REDIS_PASSWORD_FILE ]] && export REDIS_PASSWORD=\"$(< \"${REDIS_PASSWORD_FILE}\")\"\nif [[ -f /opt/bitnami/redis/mounted-etc/master.conf ]];then cp /opt/bitnami/redis/mounted-etc/master.conf /opt/bitnami/redis/etc/master.conf; fi\nif [[ -f /opt/bitnami/redis/mounted-etc/redis.conf ]];then cp /opt/bitnami/redis/mounted-etc/redis.conf /opt/bitnami/redis/etc/redis.conf; fi\nARGS=(\"--port\" \"${REDIS_PORT}\")\nARGS+=(\"--protected-mode\" \"no\")\nARGS+=(\"--include\" \"/opt/bitnami/redis/etc/redis.conf\")\nARGS+=(\"--include\" \"/opt/bitnami/redis/etc/master.conf\")\nexec redis-server \"${ARGS[@]}\""
		if redis.architecture == "replication" {
			"start-replica.sh": "#!/bin/bash\n[[ -f $REDIS_PASSWORD_FILE ]] && export REDIS_PASSWORD=\"$(< \"${REDIS_PASSWORD_FILE}\")\"\n[[ -f $REDIS_MASTER_PASSWORD_FILE ]] && export REDIS_MASTER_PASSWORD=\"$(< \"${REDIS_MASTER_PASSWORD_FILE}\")\"\nARGS=(\"--port\" \"${REDIS_PORT}\")\nARGS+=(\"--replicaof\" \"${REDIS_MASTER_HOST}\" \"${REDIS_MASTER_PORT_NUMBER}\")\nARGS+=(\"--protected-mode\" \"no\")\nARGS+=(\"--include\" \"/opt/bitnami/redis/etc/redis.conf\")\nARGS+=(\"--include\" \"/opt/bitnami/redis/etc/replica.conf\")\nexec redis-server \"${ARGS[@]}\""
		}
	}
}

// 13. /charts/redis/templates/secret-svcbind.yaml
#RedisServiceBindingSecret: corev1.#Secret & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	let redisHost = [if redis.sentinel.enabled {redisName}, "\(redisName)-master"][0]
	let redisPort = [if redis.sentinel.enabled {"\(redis.sentinel.service.ports.redis)"}, "\(redis.master.service.ports.redis)"][0]
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {name: redisName + "-svcbind", namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result, if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}}
	type: "servicebinding.io/redis"
	data: {provider: base64.Encode(null, "bitnami"), type: base64.Encode(null, "redis"), host: base64.Encode(null, redisHost), port: base64.Encode(null, redisPort), password: base64.Encode(null, redis.auth.password), uri: base64.Encode(null, [if redis.auth.password != "" {"redis://:\(redis.auth.password)@\(redisHost):\(redisPort)"}, "redis://\(redisHost):\(redisPort)"][0])}
}

// 14. /charts/redis/templates/secret.yaml
#RedisSecret: corev1.#Secret & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {name: redisName, namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result, if len(redis.commonAnnotations) > 0 || len(redis.secretAnnotations) > 0 {annotations: redis.commonAnnotations & redis.secretAnnotations}}
	type: "Opaque"
	data: "redis-password": base64.Encode(null, redis.auth.password)
}

// 15. /charts/redis/templates/serviceaccount.yaml
#RedisServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	apiVersion:                   "v1"
	kind:                         "ServiceAccount"
	automountServiceAccountToken: redis.serviceAccount.automountServiceAccountToken
	metadata: {name: (#RedisServiceAccountName & {#config: #config}).result, namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result, if len(redis.commonAnnotations) > 0 || len(redis.serviceAccount.annotations) > 0 {annotations: redis.commonAnnotations & redis.serviceAccount.annotations}}
}

// 16. /charts/redis/templates/servicemonitor.yaml
#RedisServiceMonitor: {
	#config: #Config
	let redis = #config."hyperswitch-app".redis
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {name: redisName, namespace: [if redis.metrics.serviceMonitor.namespace != "" {redis.metrics.serviceMonitor.namespace}, #config.metadata.namespace][0], labels: (#RedisLabels & {#config: #config}).result & redis.metrics.serviceMonitor.additionalLabels, if len(redis.commonAnnotations) > 0 {annotations: redis.commonAnnotations}}
	spec: {endpoints: [{port: "http-metrics", if redis.metrics.serviceMonitor.interval != "" {interval: redis.metrics.serviceMonitor.interval}, if redis.metrics.serviceMonitor.scrapeTimeout != "" {scrapeTimeout: redis.metrics.serviceMonitor.scrapeTimeout}, if redis.metrics.serviceMonitor.honorLabels {honorLabels: redis.metrics.serviceMonitor.honorLabels}}], namespaceSelector: matchNames: [#config.metadata.namespace], selector: matchLabels: (#RedisLabels & {#config: #config}).result & {"app.kubernetes.io/component": "metrics"}}
}

// 17. /charts/redis/templates/tls-secret.yaml
#RedisTLSSecret: corev1.#Secret & {
	#config: #Config
	let redisName = (#RedisName & {#config: #config}).result
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {name: redisName + "-crt", namespace: #config.metadata.namespace, labels: (#RedisLabels & {#config: #config}).result}
	type: "kubernetes.io/tls"
	data: {"tls.crt": "", "tls.key": "", "ca.crt": ""}
}
