package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	policyv1 "k8s.io/api/policy/v1"
	netv1 "k8s.io/api/networking/v1"
)

// 1. /charts/clickhouse/templates/configmap-extra.yaml
#ClickhouseConfigMapExtra: corev1.#ConfigMap & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)-extra"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	data: {
		if ch.extraOverrides != _|_ {
			"01_extra_overrides.xml": ch.extraOverrides
		}
	}
}

// 2. /charts/clickhouse/templates/configmap-users-extra.yaml
#ClickhouseConfigMapUsersExtra: corev1.#ConfigMap & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)-users-extra"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	data: {
		if ch.usersExtraOverrides != _|_ {
			"01_users_extra_overrides.xml": ch.usersExtraOverrides
		}
	}
}

// 3. /charts/clickhouse/templates/configmap.yaml
#ClickhouseMainConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	data: {
		if ch.defaultConfigurationOverrides != _|_ {
			"00_default_overrides.xml": ch.defaultConfigurationOverrides
		}
	}
}

// 4. /charts/clickhouse/templates/extra-list.yaml
#ClickhouseExtraDeploy: {
	#config: #Config
	// Placeholder for extraDeploy list items
}

// 5. /charts/clickhouse/templates/ingress-tls-secrets.yaml
#ClickhouseIngressTlsSecret: corev1.#Secret & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(ch.ingress.hostname)-tls"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	type: "kubernetes.io/tls"
	data: {
		"tls.crt": "" // Handled by cert-manager or genCA
		"tls.key": ""
		"ca.crt":  ""
	}
}

// 6. /charts/clickhouse/templates/ingress.yaml
#ClickhouseIngress: netv1.#Ingress & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.ingress.annotations != _|_ {
			annotations: ch.ingress.annotations
		}
	}
	spec: {
		if ch.ingress.ingressClassName != _|_ {
			ingressClassName: ch.ingress.ingressClassName
		}
		rules: [
			if ch.ingress.hostname != _|_ {
				{
					host: ch.ingress.hostname
					http: paths: [
						{
							path: ch.ingress.path
							if ch.ingress.pathType != _|_ {
								pathType: ch.ingress.pathType
							}
							backend: service: {
								name: "\(#config.metadata.name)-\(ch.name)"
								port: name: "http"
							}
						},
					]
				}
			},
		]
		if ch.ingress.tls != _|_ && ch.ingress.tls {
			tls: [{
				hosts: [ch.ingress.hostname]
				secretName: "\(ch.ingress.hostname)-tls"
			}]
		}
	}
}

// 7. /charts/clickhouse/templates/init-scripts-secret.yaml
#ClickhouseInitScriptsSecret: corev1.#Secret & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)-init-scripts"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	if ch.initdbScripts != _|_ {
		stringData: ch.initdbScripts
	}
}

// 8. /charts/clickhouse/templates/networkpolicy.yaml
#ClickhouseNetworkPolicy: {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	spec: {
		podSelector: matchLabels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
		}
		policyTypes: ["Ingress", "Egress"]
		if ch.networkPolicy.allowExternalEgress != _|_ && ch.networkPolicy.allowExternalEgress {
			egress: [{}]
		}
		if ch.networkPolicy.allowExternalEgress == _|_ || !ch.networkPolicy.allowExternalEgress {
			egress: [
				{
					ports: [
						{port: 53, protocol: "UDP"},
						{port: 53, protocol: "TCP"},
					]
				},
				{
					ports: [
						{port: ch.service.ports.http},
						if ch.tls.enabled {{port: ch.service.ports.https}},
						{port: ch.service.ports.tcp},
						if ch.tls.enabled {{port: ch.service.ports.tcpSecure}},
						if ch.zookeeper.enabled {{port: ch.service.ports.keeper}},
						if ch.zookeeper.enabled {{port: ch.service.ports.keeperInter}},
						if ch.zookeeper.enabled && ch.tls.enabled {{port: ch.service.ports.keeperSecure}},
						{port: ch.service.ports.mysql},
						{port: ch.service.ports.postgresql},
						{port: ch.service.ports.interserver},
						if ch.metrics.enabled {{port: ch.service.ports.metrics}},
					]
					to: [{
						podSelector: matchLabels: #config.metadata.labels
					}]
				},
			]
		}
		ingress: [
			{
				ports: [
					{port: ch.containerPorts.http},
					{port: ch.containerPorts.tcp},
					{port: ch.containerPorts.mysql},
					{port: ch.containerPorts.postgresql},
					{port: ch.containerPorts.interserver},
					if ch.tls.enabled {{port: ch.containerPorts.tcpSecure}},
					if ch.tls.enabled {{port: ch.containerPorts.https}},
					if ch.zookeeper.enabled {{port: ch.containerPorts.keeper}},
					if ch.zookeeper.enabled {{port: ch.containerPorts.keeperInter}},
					if ch.zookeeper.enabled && ch.tls.enabled {{port: ch.containerPorts.keeperSecure}},
					if ch.metrics.enabled {{port: ch.containerPorts.metrics}},
				]
				if ch.networkPolicy.allowExternal == _|_ || !ch.networkPolicy.allowExternal {
					from: [
						{
							podSelector: matchLabels: #config.metadata.labels & {
								"app.kubernetes.io/component": "clickhouse"
							}
						},
						{
							podSelector: matchLabels: {
								"\(#config.metadata.name)-\(ch.name)-client": "true"
							}
						},
					]
				}
			},
		]
	}
}

// 9. /charts/clickhouse/templates/pdb.yaml
#ClickhousePodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	spec: {
		if ch.pdb.maxUnavailable != _|_ {
			maxUnavailable: ch.pdb.maxUnavailable
		}
		if ch.pdb.minAvailable != _|_ {
			minAvailable: ch.pdb.minAvailable
		}
		selector: matchLabels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
		}
	}
}

// 10. /charts/clickhouse/templates/prometheusrule.yaml
#ClickhousePrometheusRule: {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "PrometheusRule"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "metrics"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	spec: {
		if ch.metrics.prometheusRule != _|_ && ch.metrics.prometheusRule.rules != _|_ {
			groups: [{
				name:  "\(#config.metadata.name)-\(ch.name)"
				rules: ch.metrics.prometheusRule.rules
			}]
		}
		if ch.metrics.prometheusRule == _|_ || ch.metrics.prometheusRule.rules == _|_ {
			groups: []
		}
	}
}

// 11. /charts/clickhouse/templates/scripts-configmap.yaml
#ClickhouseScriptsConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)-scripts"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	data: {
		"setup.sh": """
			#!/bin/bash
			
			# Execute entrypoint as usual after obtaining KEEPER_SERVER_ID
			# check KEEPER_SERVER_ID in persistent volume via myid
			# if not present, set based on POD hostname
			if [[ -f "/bitnami/clickhouse/keeper/data/myid" ]]; then
			    export KEEPER_SERVER_ID="$(cat /bitnami/clickhouse/keeper/data/myid)"
			else
			    HOSTNAME="$(hostname -s)"
			    if [[ $HOSTNAME =~ (.*)-([0-9]+)$ ]]; then
			        export KEEPER_SERVER_ID=${BASH_REMATCH[2]}
			    else
			        echo "Failed to get index from hostname $HOST"
			        exit 1
			    fi
			fi
			exec /opt/bitnami/scripts/clickhouse/entrypoint.sh /opt/bitnami/scripts/clickhouse/run.sh -- --listen_host=0.0.0.0
			"""
	}
}

// 12. /charts/clickhouse/templates/secret.yaml
#ClickhouseSecret: corev1.#Secret & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	type: "Opaque"
	stringData: {
		"admin-password": ch.auth.password
	}
}

// 13. /charts/clickhouse/templates/service-account.yaml
#ClickhouseServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	automountServiceAccountToken: false
}

// 14. /charts/clickhouse/templates/service-external-access.yaml
#ClickhouseServiceExternalAccess: corev1.#Service & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)-external"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.externalAccess.service.annotations != _|_ {
			annotations: ch.externalAccess.service.annotations
		}
	}
	spec: {
		type: corev1.#ServiceTypeLoadBalancer
		if ch.externalAccess.service.loadBalancerIPs != _|_ {
			loadBalancerIP: ch.externalAccess.service.loadBalancerIPs[0] // Simplified for single replica
		}
		if ch.externalAccess.service.loadBalancerSourceRanges != _|_ {
			loadBalancerSourceRanges: ch.externalAccess.service.loadBalancerSourceRanges
		}
		ports: [
			{
				name:       "http"
				port:       ch.externalAccess.service.ports.http
				targetPort: "http"
			},
			if ch.tls.enabled {
				{
					name:       "https"
					port:       ch.externalAccess.service.ports.https
					targetPort: "https"
				}
			},
			if ch.metrics.enabled {
				{
					name:       "http-metrics"
					port:       ch.externalAccess.service.ports.metrics
					targetPort: "http-metrics"
				}
			},
			{
				name:       "tcp"
				port:       ch.externalAccess.service.ports.tcp
				targetPort: "tcp"
			},
			if ch.tls.enabled {
				{
					name:       "tcp-secure"
					port:       ch.externalAccess.service.ports.tcpSecure
					targetPort: "tcp-secure"
				}
			},
			if ch.zookeeper.enabled {
				{
					name:       "tcp-keeper"
					port:       ch.externalAccess.service.ports.keeper
					targetPort: "tcp-keeper"
				}
			},
			if ch.zookeeper.enabled {
				{
					name:       "tcp-keeperinter"
					port:       ch.externalAccess.service.ports.keeperInter
					targetPort: "tcp-keeperinter"
				}
			},
			if ch.zookeeper.enabled && ch.tls.enabled {
				{
					name:       "tcp-keepertls"
					port:       ch.externalAccess.service.ports.keeperSecure
					targetPort: "tcp-keepertls"
				}
			},
			{
				name:       "tcp-mysql"
				port:       ch.externalAccess.service.ports.mysql
				targetPort: "tcp-mysql"
			},
			{
				name:       "tcp-postgresql"
				port:       ch.externalAccess.service.ports.postgresql
				targetPort: "tcp-postgresql"
			},
			{
				name:       "tcp-intersrv"
				port:       ch.externalAccess.service.ports.interserver
				targetPort: "tcp-intersrv"
			},
		]
		selector: #config.metadata.labels & {
			"app.kubernetes.io/component":        "clickhouse"
			"statefulset.kubernetes.io/pod-name": "\(#config.metadata.name)-\(ch.name)-0" // Simplified for 1 replica
		}
	}
}

// 15. /charts/clickhouse/templates/service-headless.yaml
#ClickhouseServiceHeadless: corev1.#Service & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)-headless"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	spec: {
		type:      corev1.#ServiceTypeClusterIP
		clusterIP: "None"
		ports: [
			{
				name:       "tcp"
				port:       ch.containerPorts.tcp
				targetPort: "tcp"
			},
			{
				name:       "http"
				port:       ch.containerPorts.http
				targetPort: "http"
			},
			{
				name:       "mysql"
				port:       ch.containerPorts.mysql
				targetPort: "mysql"
			},
			{
				name:       "postgresql"
				port:       ch.containerPorts.postgresql
				targetPort: "postgresql"
			},
			{
				name:       "interserver"
				port:       ch.containerPorts.interserver
				targetPort: "interserver"
			},
		]
		selector: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
		}
	}
}

// 16. /charts/clickhouse/templates/service.yaml
#ClickhouseService: corev1.#Service & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ || ch.service.annotations != _|_ {
			annotations: (ch.commonAnnotations | {}) & (ch.service.annotations | {})
		}
	}
	spec: {
		type: ch.service.type
		if ch.service.clusterIP != _|_ && ch.service.type == "ClusterIP" {
			clusterIP: ch.service.clusterIP
		}
		if ch.service.sessionAffinity != _|_ {
			sessionAffinity: ch.service.sessionAffinity
		}
		if ch.service.sessionAffinityConfig != _|_ {
			sessionAffinityConfig: ch.service.sessionAffinityConfig
		}
		if ch.service.type == "LoadBalancer" || ch.service.type == "NodePort" {
			if ch.service.externalTrafficPolicy != _|_ {
				externalTrafficPolicy: ch.service.externalTrafficPolicy
			}
		}
		if ch.service.type == "LoadBalancer" {
			if ch.service.loadBalancerSourceRanges != _|_ {
				loadBalancerSourceRanges: ch.service.loadBalancerSourceRanges
			}
			if ch.service.loadBalancerIP != _|_ {
				loadBalancerIP: ch.service.loadBalancerIP
			}
		}
		ports: [
			{
				name:       "http"
				targetPort: "http"
				port:       ch.service.ports.http
				protocol:   "TCP"
				if (ch.service.type == "NodePort" || ch.service.type == "LoadBalancer") && ch.service.nodePorts.http != _|_ {
					nodePort: ch.service.nodePorts.http
				}
			},
			if ch.tls.enabled {
				{
					name:       "https"
					targetPort: "https"
					port:       ch.service.ports.https
					protocol:   "TCP"
					if (ch.service.type == "NodePort" || ch.service.type == "LoadBalancer") && ch.service.nodePorts.https != _|_ {
						nodePort: ch.service.nodePorts.https
					}
				}
			},
			{
				name:       "tcp"
				targetPort: "tcp"
				port:       ch.service.ports.tcp
				protocol:   "TCP"
				if (ch.service.type == "NodePort" || ch.service.type == "LoadBalancer") && ch.service.nodePorts.tcp != _|_ {
					nodePort: ch.service.nodePorts.tcp
				}
			},
			if ch.tls.enabled {
				{
					name:       "tcp-secure"
					targetPort: "tcp-secure"
					port:       ch.service.ports.tcpSecure
					protocol:   "TCP"
					if (ch.service.type == "NodePort" || ch.service.type == "LoadBalancer") && ch.service.nodePorts.tcpSecure != _|_ {
						nodePort: ch.service.nodePorts.tcpSecure
					}
				}
			},
			if ch.zookeeper.enabled {
				{
					name:       "tcp-keeper"
					targetPort: "tcp-keeper"
					port:       ch.service.ports.keeper
					protocol:   "TCP"
					if (ch.service.type == "NodePort" || ch.service.type == "LoadBalancer") && ch.service.nodePorts.keeper != _|_ {
						nodePort: ch.service.nodePorts.keeper
					}
				}
			},
			if ch.zookeeper.enabled {
				{
					name:       "tcp-keeperinter"
					targetPort: "tcp-keeperinter"
					port:       ch.service.ports.keeperInter
					protocol:   "TCP"
					if (ch.service.type == "NodePort" || ch.service.type == "LoadBalancer") && ch.service.nodePorts.keeperInter != _|_ {
						nodePort: ch.service.nodePorts.keeperInter
					}
				}
			},
			if ch.zookeeper.enabled && ch.tls.enabled {
				{
					name:       "tcp-keepertls"
					targetPort: "tcp-keepertls"
					port:       ch.service.ports.keeperSecure
					protocol:   "TCP"
					if (ch.service.type == "NodePort" || ch.service.type == "LoadBalancer") && ch.service.nodePorts.keeperSecure != _|_ {
						nodePort: ch.service.nodePorts.keeperSecure
					}
				}
			},
			{
				name:       "tcp-mysql"
				targetPort: "tcp-mysql"
				port:       ch.service.ports.mysql
				protocol:   "TCP"
				if (ch.service.type == "NodePort" || ch.service.type == "LoadBalancer") && ch.service.nodePorts.mysql != _|_ {
					nodePort: ch.service.nodePorts.mysql
				}
			},
			{
				name:       "tcp-postgresql"
				targetPort: "tcp-postgresql"
				port:       ch.service.ports.postgresql
				protocol:   "TCP"
				if (ch.service.type == "NodePort" || ch.service.type == "LoadBalancer") && ch.service.nodePorts.postgresql != _|_ {
					nodePort: ch.service.nodePorts.postgresql
				}
			},
			{
				name:       "http-intersrv"
				targetPort: "http-intersrv"
				port:       ch.service.ports.interserver
				protocol:   "TCP"
				if (ch.service.type == "NodePort" || ch.service.type == "LoadBalancer") && ch.service.nodePorts.interserver != _|_ {
					nodePort: ch.service.nodePorts.interserver
				}
			},
			if ch.metrics.enabled {
				{
					name:       "http-metrics"
					targetPort: "http-metrics"
					port:       ch.service.ports.metrics
					protocol:   "TCP"
					if (ch.service.type == "NodePort" || ch.service.type == "LoadBalancer") && ch.service.nodePorts.metrics != _|_ {
						nodePort: ch.service.nodePorts.metrics
					}
				}
			},
		]
		selector: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
		}
	}
}

// 17. /charts/clickhouse/templates/servicemonitor.yaml
#ClickhouseServiceMonitor: {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name: "\(#config.metadata.name)-\(ch.name)"
		if ch.metrics.serviceMonitor.namespace != _|_ {
			namespace: ch.metrics.serviceMonitor.namespace
		}
		if ch.metrics.serviceMonitor.namespace == _|_ {
			namespace: #config.metadata.namespace
		}
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
			if ch.metrics.serviceMonitor.labels != _|_ {
				for k, v in ch.metrics.serviceMonitor.labels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ || ch.metrics.serviceMonitor.annotations != _|_ {
			annotations: (ch.commonAnnotations | {}) & (ch.metrics.serviceMonitor.annotations | {})
		}
	}
	spec: {
		if ch.metrics.serviceMonitor.jobLabel != _|_ {
			jobLabel: ch.metrics.serviceMonitor.jobLabel
		}
		endpoints: [{
			port: "http-metrics"
			path: "/metrics"
			if ch.metrics.serviceMonitor.interval != _|_ {interval: ch.metrics.serviceMonitor.interval}
			if ch.metrics.serviceMonitor.scrapeTimeout != _|_ {scrapeTimeout: ch.metrics.serviceMonitor.scrapeTimeout}
			if ch.metrics.serviceMonitor.honorLabels != _|_ {honorLabels: ch.metrics.serviceMonitor.honorLabels}
			if ch.metrics.serviceMonitor.metricRelabelings != _|_ {metricRelabelings: ch.metrics.serviceMonitor.metricRelabelings}
			if ch.metrics.serviceMonitor.relabelings != _|_ {relabelings: ch.metrics.serviceMonitor.relabelings}
		}]
		selector: matchLabels: #config.metadata.labels & {
			if ch.metrics.serviceMonitor.selector != _|_ {
				for k, v in ch.metrics.serviceMonitor.selector {"\(k)": v}
			}
		}
		namespaceSelector: matchNames: [#config.metadata.namespace]
	}
}

// 18. /charts/clickhouse/templates/start-scripts-secret.yaml
#ClickhouseStartScriptsSecret: corev1.#Secret & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)-start-scripts"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	if ch.startdbScripts != _|_ {
		stringData: ch.startdbScripts
	}
}

// 19. /charts/clickhouse/templates/statefulset.yaml
#ClickhouseStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse

	// Simplified to 1 shard for the base struct, if multiple shards are needed
	// it should be instantiated via a comprehension in config.cue
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)-shard0"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			"shard":                       "0"
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	spec: {
		replicas: ch.replicaCount
		if ch.podManagementPolicy != _|_ {
			podManagementPolicy: ch.podManagementPolicy
		}
		selector: matchLabels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
		}
		serviceName: "\(#config.metadata.name)-\(ch.name)-headless"
		if ch.updateStrategy != _|_ {
			updateStrategy: ch.updateStrategy
		}
		template: {
			metadata: {
				labels: #config.metadata.labels & {
					"app.kubernetes.io/component": "clickhouse"
					"shard":                       "0"
					if ch.commonLabels != _|_ {
						for k, v in ch.commonLabels {"\(k)": v}
					}
				}
				if ch.podAnnotations != _|_ {
					annotations: ch.podAnnotations
				}
			}
			spec: {
				serviceAccountName: "\(#config.metadata.name)-\(ch.name)"
				if ch.automountServiceAccountToken != _|_ {
					automountServiceAccountToken: ch.automountServiceAccountToken
				}
				if ch.hostAliases != _|_ {
					hostAliases: ch.hostAliases
				}
				if ch.nodeSelector != _|_ {
					nodeSelector: ch.nodeSelector
				}
				if ch.tolerations != _|_ {
					tolerations: ch.tolerations
				}
				if ch.priorityClassName != _|_ {
					priorityClassName: ch.priorityClassName
				}
				if ch.schedulerName != _|_ {
					schedulerName: ch.schedulerName
				}
				if ch.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: ch.topologySpreadConstraints
				}
				if ch.podSecurityContext != _|_ && ch.podSecurityContext.enabled != _|_ && ch.podSecurityContext.enabled {
					securityContext: {
						if ch.podSecurityContext.fsGroup != _|_ {fsGroup: ch.podSecurityContext.fsGroup}
					}
				}
				if ch.terminationGracePeriodSeconds != _|_ {
					terminationGracePeriodSeconds: ch.terminationGracePeriodSeconds
				}

				// initContainers
				initContainers: [
					if ch.tls.enabled && (ch.volumePermissions == _|_ || !ch.volumePermissions.enabled) {
						{
							name:            "copy-certs"
							image:           ch.volumePermissions.image.registry + "/" + ch.volumePermissions.image.repository + ":" + ch.volumePermissions.image.tag
							imagePullPolicy: ch.volumePermissions.image.pullPolicy
							command: ["/bin/sh", "-ec", "cp -L /tmp/certs/* /opt/bitnami/clickhouse/certs/\nchmod 600 /opt/bitnami/clickhouse/certs/tls.key\n"]
							volumeMounts: [
								{name: "raw-certificates", mountPath: "/tmp/certs"},
								{name: "clickhouse-certificates", mountPath: "/opt/bitnami/clickhouse/certs"},
								{name: "empty-dir", mountPath: "/tmp", subPath: "tmp-dir"},
							]
						}
					},
					if ch.volumePermissions != _|_ && ch.volumePermissions.enabled && ch.persistence.enabled {
						{
							name:            "volume-permissions"
							image:           ch.volumePermissions.image.registry + "/" + ch.volumePermissions.image.repository + ":" + ch.volumePermissions.image.tag
							imagePullPolicy: ch.volumePermissions.image.pullPolicy
							command: ["/bin/sh", "-ec", "mkdir -p /bitnami/clickhouse/data\nchmod 700 /bitnami/clickhouse/data\nchown \(ch.containerSecurityContext.runAsUser):\(ch.podSecurityContext.fsGroup) /bitnami/clickhouse\nfind /bitnami/clickhouse -mindepth 1 -maxdepth 1 -not -name \".snapshot\" -not -name \"lost+found\" | \\\nxargs -r chown -R \(ch.containerSecurityContext.runAsUser):\(ch.podSecurityContext.fsGroup)\n"]
							volumeMounts: [
								{name: "data", mountPath: "/bitnami/clickhouse"},
								{name: "empty-dir", mountPath: "/tmp", subPath: "tmp-dir"},
								if ch.tls.enabled {{name: "raw-certificates", mountPath: "/tmp/certs"}},
								if ch.tls.enabled {{name: "clickhouse-certificates", mountPath: "/opt/bitnami/clickhouse/certs"}},
							]
						}
					},
				]

				// containers
				containers: [
					{
						name:            "clickhouse"
						image:           ch.image.registry + "/" + ch.image.repository + ":" + ch.image.tag
						imagePullPolicy: ch.image.pullPolicy
						if ch.containerSecurityContext != _|_ && ch.containerSecurityContext.enabled != _|_ && ch.containerSecurityContext.enabled {
							securityContext: {
								if ch.containerSecurityContext.runAsUser != _|_ {runAsUser: ch.containerSecurityContext.runAsUser}
								if ch.containerSecurityContext.runAsNonRoot != _|_ {runAsNonRoot: ch.containerSecurityContext.runAsNonRoot}
							}
						}
						env: [
							{name: "BITNAMI_DEBUG", value: "false"},
							{name: "CLICKHOUSE_HTTP_PORT", value: "\(ch.containerPorts.http)"},
							{name: "CLICKHOUSE_TCP_PORT", value: "\(ch.containerPorts.tcp)"},
							{name: "CLICKHOUSE_MYSQL_PORT", value: "\(ch.containerPorts.mysql)"},
							{name: "CLICKHOUSE_POSTGRESQL_PORT", value: "\(ch.containerPorts.postgresql)"},
							{name: "CLICKHOUSE_INTERSERVER_HTTP_PORT", value: "\(ch.containerPorts.interserver)"},
							if ch.tls.enabled {{name: "CLICKHOUSE_TCP_SECURE_PORT", value: "\(ch.containerPorts.tcpSecure)"}},
							if ch.tls.enabled {{name: "CLICKHOUSE_HTTPS_PORT", value: "\(ch.containerPorts.https)"}},
							if ch.zookeeper.enabled {{name: "CLICKHOUSE_KEEPER_PORT", value: "\(ch.containerPorts.keeper)"}},
							if ch.zookeeper.enabled {{name: "CLICKHOUSE_KEEPER_INTER_PORT", value: "\(ch.containerPorts.keeperInter)"}},
							if ch.zookeeper.enabled && ch.tls.enabled {{name: "CLICKHOUSE_KEEPER_SECURE_PORT", value: "\(ch.containerPorts.keeperSecure)"}},
							if ch.metrics.enabled {{name: "CLICKHOUSE_METRICS_PORT", value: "\(ch.containerPorts.metrics)"}},
							{name: "CLICKHOUSE_ADMIN_USER", value: ch.auth.username},
							{name: "CLICKHOUSE_SHARD_ID", value: "shard0"},
							{name: "CLICKHOUSE_REPLICA_ID", valueFrom: fieldRef: fieldPath: "metadata.name"},
							{name: "CLICKHOUSE_ADMIN_PASSWORD", valueFrom: secretKeyRef: {name: "\(#config.metadata.name)-\(ch.name)", key: "admin-password"}},
							{name: "ALLOW_EMPTY_PASSWORD", value: "yes"},
						]
						ports: [
							{name: "http", containerPort: ch.containerPorts.http},
							{name: "tcp", containerPort: ch.containerPorts.tcp},
							if ch.tls.enabled {{name: "https", containerPort: ch.containerPorts.https}},
							if ch.tls.enabled {{name: "tcp-secure", containerPort: ch.containerPorts.tcpSecure}},
							if ch.zookeeper.enabled {{name: "tcp-keeper", containerPort: ch.containerPorts.keeper}},
							if ch.zookeeper.enabled {{name: "tcp-keeperinter", containerPort: ch.containerPorts.keeperInter}},
							if ch.zookeeper.enabled && ch.tls.enabled {{name: "tcp-keepertls", containerPort: ch.containerPorts.keeperSecure}},
							{name: "tcp-postgresql", containerPort: ch.containerPorts.postgresql},
							{name: "tcp-mysql", containerPort: ch.containerPorts.mysql},
							{name: "http-intersrv", containerPort: ch.containerPorts.interserver},
							if ch.metrics.enabled {{name: "http-metrics", containerPort: ch.containerPorts.metrics}},
						]
						volumeMounts: [
							{name: "empty-dir", mountPath: "/opt/bitnami/clickhouse/etc", subPath: "app-conf-dir"},
							{name: "empty-dir", mountPath: "/opt/bitnami/clickhouse/logs", subPath: "app-logs-dir"},
							{name: "empty-dir", mountPath: "/opt/bitnami/clickhouse/tmp", subPath: "app-tmp-dir"},
							{name: "empty-dir", mountPath: "/tmp", subPath: "tmp-dir"},
							{name: "scripts", mountPath: "/scripts/setup.sh", subPath: "setup.sh"},
							{name: "data", mountPath: "/bitnami/clickhouse"},
							{name: "config", mountPath: "/bitnami/clickhouse/etc/conf.d/default"},
							if ch.extraOverrides != _|_ {{name: "extra-config", mountPath: "/bitnami/clickhouse/etc/conf.d/extra-configmap"}},
							if ch.usersExtraOverrides != _|_ {{name: "users-extra-config", mountPath: "/bitnami/clickhouse/etc/users.d/users-extra-configmap"}},
							if ch.tls.enabled {{name: "clickhouse-certificates", mountPath: "/bitnami/clickhouse/certs"}},
							if ch.initdbScripts != _|_ {{name: "custom-init-scripts", mountPath: "/docker-entrypoint-initdb.d"}},
							if ch.startdbScripts != _|_ {{name: "custom-start-scripts", mountPath: "/docker-entrypoint-startdb.d"}},
						]
					},
				]
				volumes: [
					{name: "scripts", configMap: {name: "\(#config.metadata.name)-\(ch.name)-scripts", defaultMode: 0o755}},
					{name: "empty-dir", emptyDir: {}},
					{name: "config", configMap: {name: "\(#config.metadata.name)-\(ch.name)"}},
					if ch.initdbScripts != _|_ {{name: "custom-init-scripts", secret: {secretName: "\(#config.metadata.name)-\(ch.name)-init-scripts"}}},
					if ch.startdbScripts != _|_ {{name: "custom-start-scripts", secret: {secretName: "\(#config.metadata.name)-\(ch.name)-start-scripts"}}},
					if ch.extraOverrides != _|_ {{name: "extra-config", configMap: {name: "\(#config.metadata.name)-\(ch.name)-extra"}}},
					if ch.usersExtraOverrides != _|_ {{name: "users-extra-config", configMap: {name: "\(#config.metadata.name)-\(ch.name)-users-extra"}}},
					if ch.persistence.enabled && ch.persistence.existingClaim != _|_ {
						{name: "data", persistentVolumeClaim: claimName: ch.persistence.existingClaim}
					},
					if !ch.persistence.enabled {
						{name: "data", emptyDir: {}}
					},
					if ch.tls.enabled {{name: "raw-certificates", secret: {secretName: "\(#config.metadata.name)-\(ch.name)-crt"}}},
					if ch.tls.enabled {{name: "clickhouse-certificates", emptyDir: {}}},
				]
			}
		}
		if ch.persistence.enabled && ch.persistence.existingClaim == _|_ {
			volumeClaimTemplates: [
				{
					apiVersion: "v1"
					kind:       "PersistentVolumeClaim"
					metadata: {
						name: "data"
						if ch.persistence.annotations != _|_ {annotations: ch.persistence.annotations}
						if ch.persistence.labels != _|_ {labels: ch.persistence.labels}
					}
					spec: {
						accessModes: ch.persistence.accessModes
						resources: requests: storage: ch.persistence.size
						if ch.persistence.storageClass != _|_ {
							storageClassName: ch.persistence.storageClass
						}
					}
				},
			]
		}
	}
}

// 20. /charts/clickhouse/templates/tls-secret.yaml
#ClickhouseTlsSecret: corev1.#Secret & {
	#config: #Config
	let ch = #config."hyperswitch-app".clickhouse
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-\(ch.name)-crt"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "clickhouse"
			if ch.commonLabels != _|_ {
				for k, v in ch.commonLabels {"\(k)": v}
			}
		}
		if ch.commonAnnotations != _|_ {
			annotations: ch.commonAnnotations
		}
	}
	type: "kubernetes.io/tls"
	stringData: {
		"tls.crt": "" // Handled by cert-manager or genCA
		"tls.key": ""
		"ca.crt":  ""
	}
}
