package templates

import (
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	autoscalingv2 "k8s.io/api/autoscaling/v2"
	policyv1 "k8s.io/api/policy/v1"
	networkingv1 "k8s.io/api/networking/v1"
	appsv1 "k8s.io/api/apps/v1"
	"list"
)

// Helpers
#VectorName: {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let name = #config.metadata.name | *"hyperswitch"
	result: string
	if vector.fullnameOverride != "" {
		result: vector.fullnameOverride
	}
	if vector.fullnameOverride == "" {
		result: "\(name)-vector"
	}
}

#VectorHAProxyName: {
	#config: #Config
	let _vName = (#VectorName & {#config: #config}).result
	result: "\(_vName)-haproxy"
}

#VectorPod: corev1.#PodSpec & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let saName = [if vector.serviceAccount.name != "" {vector.serviceAccount.name}, vectorName][0]

	serviceAccountName: saName
	if vector.podHostNetwork {
		hostNetwork: vector.podHostNetwork
	}
	if len([for k, v in vector.podSecurityContext {k}]) > 0 {
		securityContext: vector.podSecurityContext
	}
	if vector.podPriorityClassName != "" {
		priorityClassName: vector.podPriorityClassName
	}
	if vector.shareProcessNamespace {
		shareProcessNamespace: vector.shareProcessNamespace
	}
	dnsPolicy: vector.dnsPolicy
	if len([for k, v in vector.dnsConfig {k}]) > 0 {
		dnsConfig: vector.dnsConfig
	}
	if len(vector.image.pullSecrets) > 0 {
		imagePullSecrets: [for s in vector.image.pullSecrets {name: s}]
	}
	if len(vector.hostAliases) > 0 {
		hostAliases: vector.hostAliases
	}
	if len(vector.initContainers) > 0 {
		initContainers: vector.initContainers
	}
	containers: [
		{
			name: "vector"
			if len([for k, v in vector.securityContext {k}]) > 0 {
				securityContext: vector.securityContext
			}
			let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
			image: [
				if vector.image.sha != "" {"\(vector.image.repository):\(imageTag)@sha256:\(vector.image.sha)"},
				"\(vector.image.repository):\(imageTag)",
			][0]
			imagePullPolicy: vector.image.pullPolicy
			if len(vector.command) > 0 {
				command: vector.command
			}
			if len(vector.args) > 0 {
				args: vector.args
			}
			env: list.Concat([
				[{name: "VECTOR_LOG", value: vector.logLevel}],
				[for e in vector.env {e}],
				if vector.role == "Agent" {
					[
						{
							name: "VECTOR_SELF_NODE_NAME"
							valueFrom: fieldRef: fieldPath: "spec.nodeName"
						},
						{
							name: "VECTOR_SELF_POD_NAME"
							valueFrom: fieldRef: fieldPath: "metadata.name"
						},
						{
							name: "VECTOR_SELF_POD_NAMESPACE"
							valueFrom: fieldRef: fieldPath: "metadata.namespace"
						},
						{name: "PROCFS_ROOT", value: "/host/proc"},
						{name: "SYSFS_ROOT", value: "/host/sys"},
					]
				},
				if vector.role != "Agent" {[]},
			])
			if len(vector.envFrom) > 0 {
				envFrom: vector.envFrom
			}
			ports: list.Concat([
				[for p in vector.containerPorts {p}],
				if len(vector.containerPorts) == 0 && len(vector.existingConfigMaps) == 0 && len([for k, v in vector.customConfig {k}]) == 0 {
					if vector.role == "Aggregator" || vector.role == "Stateless-Aggregator" {
						[
							{name: "datadog-agent", containerPort: 8282, protocol: "TCP"},
							{name: "fluent", containerPort: 24224, protocol: "TCP"},
							{name: "logstash", containerPort: 5044, protocol: "TCP"},
							{name: "splunk-hec", containerPort: 8080, protocol: "TCP"},
							{name: "statsd", containerPort: 8125, protocol: "TCP"},
							{name: "syslog", containerPort: 9000, protocol: "TCP"},
							{name: "vector", containerPort: 6000, protocol: "TCP"},
							{name: "prom-exporter", containerPort: 9090, protocol: "TCP"},
						]
					}
					if vector.role == "Agent" {
						[
							{name: "prom-exporter", containerPort: 9090, protocol: "TCP"},
						]
					}
					if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
						[]
					}
				},
				if !(len(vector.containerPorts) == 0 && len(vector.existingConfigMaps) == 0 && len([for k, v in vector.customConfig {k}]) == 0) {
					[]
				},
			])
			if len([for k, v in vector.livenessProbe {k}]) > 0 {
				livenessProbe: vector.livenessProbe
			}
			if len([for k, v in vector.readinessProbe {k}]) > 0 {
				readinessProbe: vector.readinessProbe
			}
			if len([for k, v in vector.resources {k}]) > 0 {
				resources: vector.resources
			}
			if len([for k, v in vector.lifecycle {k}]) > 0 {
				lifecycle: vector.lifecycle
			}
			volumeMounts: list.Concat([
				[
					{
						name: "data"
						mountPath: [
							if len(vector.existingConfigMaps) > 0 {vector.dataDir},
							if vector.customConfig.data_dir != _|_ {vector.customConfig.data_dir},
							"/vector-data-dir",
						][0]
					},
					{
						name:      "config"
						mountPath: "/etc/vector/"
						readOnly:  true
					},
				],
				if vector.role == "Agent" {vector.defaultVolumeMounts},
				if vector.role != "Agent" {[]},
				vector.extraVolumeMounts,
			])
		},
	]
	if len(vector.extraContainers) > 0 {
		containers: list.Concat([containers, vector.extraContainers])
	}
	terminationGracePeriodSeconds: vector.terminationGracePeriodSeconds
	if len([for k, v in vector.nodeSelector {k}]) > 0 {
		nodeSelector: vector.nodeSelector
	}
	if len([for k, v in vector.affinity {k}]) > 0 {
		affinity: vector.affinity
	}
	if len(vector.tolerations) > 0 {
		tolerations: vector.tolerations
	}
	if len(vector.topologySpreadConstraints) > 0 {
		topologySpreadConstraints: vector.topologySpreadConstraints
	}
	volumes: list.Concat([
		if vector.persistence.enabled && vector.role == "Aggregator" {
			if vector.persistence.existingClaim != "" {
				[{name: "data", persistentVolumeClaim: claimName: vector.persistence.existingClaim}]
			}
			if vector.persistence.existingClaim == "" {[]}
		},
		if !(vector.persistence.enabled && vector.role == "Aggregator") && vector.role != "Agent" {
			[{name: "data", emptyDir: {}}]
		},
		[
			{
				name: "config"
				projected: sources: list.Concat([
					[for cm in vector.existingConfigMaps {configMap: {name: cm}}],
					if len(vector.existingConfigMaps) == 0 {
						[{configMap: {name: vectorName}}]
					},
					if len(vector.existingConfigMaps) != 0 {
						[]
					},
				])
			},
		],
		if vector.role == "Agent" {
			list.Concat([
				[
					{
						name: "data"
						if vector.persistence.hostPath.enabled {
							hostPath: path: vector.persistence.hostPath.path
						}
						if !vector.persistence.hostPath.enabled {
							emptyDir: {}
						}
					},
				],
				vector.defaultVolumes,
			])
		},
		if vector.role != "Agent" {[]},
		vector.extraVolumes,
	])
}

// 1. /charts/vector/templates/configmap.yaml
#VectorConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      vectorName
		namespace: #config.metadata.namespace
		labels:    vectorLabels
	}
	data: {
		if len([for k, v in vector.customConfig {k}]) > 0 {
			"vector.yaml": vector.customConfig
		}
		if len([for k, v in vector.customConfig {k}]) == 0 && (vector.role == "Aggregator" || vector.role == "Stateless-Aggregator") {
			"aggregator.yaml": """
				data_dir: /vector-data-dir
				api:
				  enabled: true
				  address: 127.0.0.1:8686
				  playground: false
				sources:
				  datadog_agent:
				    address: 0.0.0.0:8282
				    type: datadog_agent
				  fluent:
				    address: 0.0.0.0:24224
				    type: fluent
				  internal_metrics:
				    type: internal_metrics
				  logstash:
				    address: 0.0.0.0:5044
				    type: logstash
				  splunk_hec:
				    address: 0.0.0.0:8080
				    type: splunk_hec
				  statsd:
				    address: 0.0.0.0:8125
				    mode: tcp
				    type: statsd
				  syslog:
				    address: 0.0.0.0:9000
				    mode: tcp
				    type: syslog
				  vector:
				    address: 0.0.0.0:6000
				    type: vector
				    version: \"2\"
				sinks:
				  prom_exporter:
				    type: prometheus_exporter
				    inputs: [internal_metrics]
				    address: 0.0.0.0:9090
				  stdout:
				    type: console
				    inputs: [datadog_agent, fluent, logstash, splunk_hec, statsd, syslog, vector]
				    encoding:
				      codec: json
				"""
		}
		if len([for k, v in vector.customConfig {k}]) == 0 && vector.role == "Agent" {
			"agent.yaml": """
				data_dir: /vector-data-dir
				api:
				  enabled: true
				  address: 127.0.0.1:8686
				  playground: false
				sources:
				  kubernetes_logs:
				    type: kubernetes_logs
				  host_metrics:
				    filesystem:
				      devices:
				        excludes: [binfmt_misc]
				      filesystems:
				        excludes: [binfmt_misc]
				      mountpoints:
				        excludes: [\"*/proc/sys/fs/binfmt_misc\"]
				    type: host_metrics
				  internal_metrics:
				    type: internal_metrics
				sinks:
				  prom_exporter:
				    type: prometheus_exporter
				    inputs: [host_metrics, internal_metrics]
				    address: 0.0.0.0:9090
				  stdout:
				    type: console
				    inputs: [kubernetes_logs]
				    encoding:
				      codec: json
				"""
		}
	}
}

// 2. /charts/vector/templates/daemonset.yaml
#VectorDaemonSet: appsv1.#DaemonSet & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "apps/v1"
	kind:       "DaemonSet"
	metadata: {
		name:      vectorName
		namespace: #config.metadata.namespace
		labels:    vectorLabels
		if len(vector.workloadResourceAnnotations) > 0 {
			annotations: vector.workloadResourceAnnotations
		}
	}
	spec: {
		selector: matchLabels: {
			"app.kubernetes.io/name":     "vector"
			"app.kubernetes.io/instance": #config.metadata.name
			if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
				"app.kubernetes.io/component": vector.role
			}
		}
		minReadySeconds: vector.minReadySeconds
		if len([for k, v in vector.updateStrategy {k}]) > 0 {
			updateStrategy: vector.updateStrategy
		}
		template: {
			metadata: {
				annotations: {
					if vector.rollWorkload {
						"checksum/config": "vector-config-checksum"
					}
					for k, v in vector.podAnnotations {
						"\(k)": v
					}
				}
				labels: {
					"app.kubernetes.io/name":     "vector"
					"app.kubernetes.io/instance": #config.metadata.name
					if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
						"app.kubernetes.io/component": vector.role
					}
					for k, v in vector.podLabels {
						"\(k)": v
					}
				}
			}
			spec: #VectorPod & {#config: #config}
		}
	}
}

// 3. /charts/vector/templates/deployment.yaml
#VectorDeployment: appsv1.#Deployment & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      vectorName
		namespace: #config.metadata.namespace
		labels:    vectorLabels
		if len(vector.workloadResourceAnnotations) > 0 {
			annotations: vector.workloadResourceAnnotations
		}
	}
	spec: {
		if !vector.autoscaling.enabled && !vector.autoscaling.external {
			replicas: vector.replicas
		}
		selector: matchLabels: {
			"app.kubernetes.io/name":     "vector"
			"app.kubernetes.io/instance": #config.metadata.name
			if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
				"app.kubernetes.io/component": vector.role
			}
		}
		minReadySeconds: vector.minReadySeconds
		if len([for k, v in vector.updateStrategy {k}]) > 0 {
			strategy: vector.updateStrategy
		}
		template: {
			metadata: {
				annotations: {
					if vector.rollWorkload {
						"checksum/config": "vector-config-checksum"
					}
					for k, v in vector.podAnnotations {
						"\(k)": v
					}
				}
				labels: {
					"app.kubernetes.io/name":     "vector"
					"app.kubernetes.io/instance": #config.metadata.name
					if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
						"app.kubernetes.io/component": vector.role
					}
					for k, v in vector.podLabels {
						"\(k)": v
					}
				}
			}
			spec: #VectorPod & {#config: #config}
		}
	}
}

// 4. /charts/vector/templates/extra-manifests.yaml
#VectorExtra: {
	#config: #Config
	objects: [for o in #config."hyperswitch-app".vector.extraObjects {o}]
}

// 5. /charts/vector/templates/hpa.yaml
#VectorHPA: autoscalingv2.#HorizontalPodAutoscaler & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      vectorName
		namespace: #config.metadata.namespace
		labels:    vectorLabels
		if len(vector.autoscaling.annotations) > 0 {
			annotations: vector.autoscaling.annotations
		}
	}
	spec: {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind: [if vector.role == "Aggregator" {"StatefulSet"}, "Deployment"][0]
			name: vectorName
		}
		minReplicas: vector.autoscaling.minReplicas
		maxReplicas: vector.autoscaling.maxReplicas
		metrics: [
			if vector.autoscaling.targetMemoryUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: vector.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
			if vector.autoscaling.targetCPUUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: vector.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if len([for k, v in vector.autoscaling.customMetric {k}]) > 0 {
				vector.autoscaling.customMetric
			},
		]
		if len([for k, v in vector.autoscaling.behavior {k}]) > 0 {
			behavior: vector.autoscaling.behavior
		}
	}
}

// 6. /charts/vector/templates/ingress.yaml
#VectorIngress: networkingv1.#Ingress & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      vectorName
		namespace: #config.metadata.namespace
		labels:    vectorLabels
		if len(vector.ingress.annotations) > 0 {
			annotations: vector.ingress.annotations
		}
	}
	spec: {
		if vector.ingress.className != "" {
			ingressClassName: vector.ingress.className
		}
		if len(vector.ingress.tls) > 0 {
			tls: [
				for t in vector.ingress.tls {
					hosts: [for h in t.hosts {h}]
					secretName: t.secretName
				},
			]
		}
		rules: [
			for h in vector.ingress.hosts {
				host: h.host
				http: paths: [
					for p in h.paths {
						path:     p.path
						pathType: p.pathType
						backend: service: {
							name: [if vector.haproxy.enabled {(#VectorHAProxyName & {#config: #config}).result}, vectorName][0]
							port: {
								if p.port.name != "" {name: p.port.name}
								if p.port.name == "" {number: p.port.number}
							}
						}
					},
				]
			},
		]
	}
}

// 7. /charts/vector/templates/pdb.yaml
#VectorPDB: policyv1.#PodDisruptionBudget & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      vectorName
		namespace: #config.metadata.namespace
		labels:    vectorLabels
	}
	spec: {
		if vector.podDisruptionBudget.minAvailable != _|_ && vector.podDisruptionBudget.minAvailable > 0 {
			minAvailable: vector.podDisruptionBudget.minAvailable
		}
		if vector.podDisruptionBudget.maxUnavailable != _|_ && vector.podDisruptionBudget.maxUnavailable > 0 {
			maxUnavailable: vector.podDisruptionBudget.maxUnavailable
		}
		selector: matchLabels: {
			"app.kubernetes.io/name":     "vector"
			"app.kubernetes.io/instance": #config.metadata.name
			if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
				"app.kubernetes.io/component": vector.role
			}
		}
	}
}

// 8. /charts/vector/templates/podmonitor.yaml
#VectorPodMonitor: {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "PodMonitor"
	metadata: {
		name:      vectorName
		namespace: #config.metadata.namespace
		labels:    vectorLabels & vector.podMonitor.additionalLabels
	}
	spec: {
		jobLabel: vector.podMonitor.jobLabel
		selector: matchLabels: {
			"app.kubernetes.io/name":     "vector"
			"app.kubernetes.io/instance": #config.metadata.name
			if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
				"app.kubernetes.io/component": vector.role
			}
		}
		namespaceSelector: matchNames: [#config.metadata.namespace]
		if len(vector.podMonitor.podTargetLabels) > 0 {
			podTargetLabels: vector.podMonitor.podTargetLabels
		}
		podMetricsEndpoints: [
			{
				port: vector.podMonitor.port
				path: vector.podMonitor.path
				if vector.podMonitor.interval != "" {
					interval: vector.podMonitor.interval
				}
				if vector.podMonitor.scrapeTimeout != "" {
					scrapeTimeout: vector.podMonitor.scrapeTimeout
				}
				honorLabels:     vector.podMonitor.honorLabels
				honorTimestamps: vector.podMonitor.honorTimestamps
				if len([for k, v in vector.podMonitor.relabelings {k}]) > 0 {
					relabelings: vector.podMonitor.relabelings
				}
				if len([for k, v in vector.podMonitor.metricRelabelings {k}]) > 0 {
					metricRelabelings: vector.podMonitor.metricRelabelings
				}
			},
		]
	}
}

// 9. /charts/vector/templates/psp.yaml
#VectorPSP: {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "policy/v1beta1"
	kind:       "PodSecurityPolicy"
	metadata: {
		name:      vectorName
		namespace: #config.metadata.namespace
		labels:    vectorLabels
	}
	spec: {
		privileged:               false
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   false
		requiredDropCapabilities: ["ALL"]
		volumes: ["hostPath", "configMap", "emptyDir", "secret", "projected"]
		allowedHostPaths: [
			{pathPrefix: "/var/log", readOnly: true},
			{pathPrefix: "/var/lib", readOnly: true},
			{pathPrefix: vector.persistence.hostPath.path, readOnly: false},
			{pathPrefix: "/sys", readOnly: true},
			{pathPrefix: "/proc", readOnly: true},
		]
		hostNetwork: vector.podHostNetwork
		hostIPC:     false
		hostPID:     false
		runAsUser: rule: "RunAsAny"
		seLinux: rule:   "RunAsAny"
		supplementalGroups: {
			rule: "MustRunAs"
			ranges: [{min: 1, max: 65535}]
		}
		fsGroup: {
			rule: "MustRunAs"
			ranges: [{min: 1, max: 65535}]
		}
	}
}

// 10. /charts/vector/templates/rbac.yaml
#VectorRBAC: {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}
	let saName = [if vector.serviceAccount.name != "" {vector.serviceAccount.name}, vectorName][0]

	if vector.rbac.create && vector.role == "Agent" {
		clusterRole: rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: {
				name:   vectorName
				labels: vectorLabels
			}
			rules: [
				{
					apiGroups: [""]
					resources: ["pods", "nodes", "namespaces"]
					verbs: ["get", "list", "watch"]
				},
			]
		}
		clusterRoleBinding: rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: {
				name:   vectorName
				labels: vectorLabels
			}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     vectorName
			}
			subjects: [
				{
					kind:      "ServiceAccount"
					name:      saName
					namespace: #config.metadata.namespace
				},
			]
		}
	}
}

// 11. /charts/vector/templates/secret.yaml
#VectorSecret: corev1.#Secret & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      vectorName
		namespace: #config.metadata.namespace
		labels:    vectorLabels
	}
	type: "Opaque"
	data: {
		for k, v in vector.secrets.generic {
			"\(k)": v
		}
	}
}

// 12. /charts/vector/templates/service-headless.yaml
#VectorHeadlessService: corev1.#Service & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(vectorName)-headless"
		namespace: #config.metadata.namespace
		labels:    vectorLabels
		if len(vector.service.annotations) > 0 {
			annotations: vector.service.annotations
		}
	}
	spec: {
		clusterIP: "None"
		if vector.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: vector.service.ipFamilyPolicy
		}
		if len(vector.service.ipFamilies) > 0 {
			ipFamilies: vector.service.ipFamilies
		}
		ports: list.Concat([
			[for p in vector.service.ports {p}],
			if len(vector.service.ports) == 0 && len(vector.existingConfigMaps) == 0 && len([for k, v in vector.customConfig {k}]) == 0 {
				[
					{name: "datadog-agent", port: 8282, protocol: "TCP"},
					{name: "fluent", port: 24224, protocol: "TCP"},
					{name: "logstash", port: 5044, protocol: "TCP"},
					{name: "splunk-hec", port: 8080, protocol: "TCP"},
					{name: "statsd", port: 8125, protocol: "TCP"},
					{name: "syslog", port: 9000, protocol: "TCP"},
					{name: "vector", port: 6000, protocol: "TCP"},
					{name: "prom-exporter", port: 9090, protocol: "TCP"},
				]
			},
			if !(len(vector.service.ports) == 0 && len(vector.existingConfigMaps) == 0 && len([for k, v in vector.customConfig {k}]) == 0) {
				[]
			},
		])
		selector: {
			"app.kubernetes.io/name":     "vector"
			"app.kubernetes.io/instance": #config.metadata.name
			if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
				"app.kubernetes.io/component": vector.role
			}
		}
		type: "ClusterIP"
		if len(vector.service.topologyKeys) > 0 {
			topologyKeys: vector.service.topologyKeys
		}
	}
}

#VectorHeadlessServiceLegacy: corev1.#Service & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(vectorName)-headless"
		namespace: #config.metadata.namespace
		labels:    vectorLabels
		if len(vector.service.annotations) > 0 {
			annotations: vector.service.annotations
		}
	}
	spec: {
		clusterIP: "None"
		if vector.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: vector.service.ipFamilyPolicy
		}
		if len(vector.service.ipFamilies) > 0 {
			ipFamilies: vector.service.ipFamilies
		}
		ports: list.Concat([
			[for p in vector.service.ports {p}],
			if len(vector.service.ports) == 0 && len(vector.existingConfigMaps) == 0 && len([for k, v in vector.customConfig {k}]) == 0 {
				[
					{name: "datadog-agent", port: 8282, protocol: "TCP"},
					{name: "fluent", port: 24224, protocol: "TCP"},
					{name: "logstash", port: 5044, protocol: "TCP"},
					{name: "splunk-hec", port: 8080, protocol: "TCP"},
					{name: "statsd", port: 8125, protocol: "TCP"},
					{name: "syslog", port: 9000, protocol: "TCP"},
					{name: "vector", port: 6000, protocol: "TCP"},
					{name: "prom-exporter", port: 9090, protocol: "TCP"},
				]
			},
			if !(len(vector.service.ports) == 0 && len(vector.existingConfigMaps) == 0 && len([for k, v in vector.customConfig {k}]) == 0) {
				[]
			},
		])
		selector: {
			"app.kubernetes.io/name":     "vector"
			"app.kubernetes.io/instance": #config.metadata.name
			if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
				"app.kubernetes.io/component": vector.role
			}
		}
		type: "ClusterIP"
		if len(vector.service.topologyKeys) > 0 {
			topologyKeys: vector.service.topologyKeys
		}
	}
}

// 13. /charts/vector/templates/service.yaml
#VectorService: corev1.#Service & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      vectorName
		namespace: #config.metadata.namespace
		labels:    vectorLabels
		if len(vector.service.annotations) > 0 {
			annotations: vector.service.annotations
		}
	}
	spec: {
		if vector.service.externalTrafficPolicy != "" {
			externalTrafficPolicy: vector.service.externalTrafficPolicy
		}
		if vector.service.internalTrafficPolicy != "" {
			internalTrafficPolicy: vector.service.internalTrafficPolicy
		}
		if vector.service.loadBalancerIP != "" {
			loadBalancerIP: vector.service.loadBalancerIP
		}
		if vector.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: vector.service.ipFamilyPolicy
		}
		if len(vector.service.ipFamilies) > 0 {
			ipFamilies: vector.service.ipFamilies
		}
		ports: list.Concat([
			[for p in vector.service.ports {p}],
			if len(vector.service.ports) == 0 && len(vector.existingConfigMaps) == 0 && len([for k, v in vector.customConfig {k}]) == 0 {
				if vector.role == "Aggregator" || vector.role == "Stateless-Aggregator" {
					[
						{name: "datadog-agent", port: 8282, protocol: "TCP"},
						{name: "fluent", port: 24224, protocol: "TCP"},
						{name: "logstash", port: 5044, protocol: "TCP"},
						{name: "splunk-hec", port: 8080, protocol: "TCP"},
						{name: "statsd", port: 8125, protocol: "TCP"},
						{name: "syslog", port: 9000, protocol: "TCP"},
						{name: "vector", port: 6000, protocol: "TCP"},
						{name: "prom-exporter", port: 9090, protocol: "TCP"},
					]
				}
				if vector.role == "Agent" {
					[
						{name: "prom-exporter", port: 9090, protocol: "TCP"},
					]
				}
				if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
					[]
				}
			},
			if !(len(vector.service.ports) == 0 && len(vector.existingConfigMaps) == 0 && len([for k, v in vector.customConfig {k}]) == 0) {
				[]
			},
		])
		selector: {
			"app.kubernetes.io/name":     "vector"
			"app.kubernetes.io/instance": #config.metadata.name
			if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
				"app.kubernetes.io/component": vector.role
			}
		}
		type: vector.service.type
		if len(vector.service.topologyKeys) > 0 {
			topologyKeys: vector.service.topologyKeys
		}
	}
}

// 14. /charts/vector/templates/serviceaccount.yaml
#VectorServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name: [if vector.serviceAccount.name != "" {vector.serviceAccount.name}, vectorName][0]
		namespace: #config.metadata.namespace
		labels:    vectorLabels
		if len(vector.serviceAccount.annotations) > 0 {
			annotations: vector.serviceAccount.annotations
		}
	}
	automountServiceAccountToken: vector.serviceAccount.automountToken
}

// 15. /charts/vector/templates/statefulset.yaml
#VectorStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let vectorName = (#VectorName & {#config: #config}).result
	let vectorLabels = #config.global.labels & vector.commonLabels & {
		"app.kubernetes.io/name":     "vector"
		"app.kubernetes.io/instance": #config.metadata.name
		let imageTag = [if vector.image.tag != "" {vector.image.tag}, "0.38.0"][0]
		"app.kubernetes.io/version":    imageTag
		"app.kubernetes.io/managed-by": "timoni"
		"helm.sh/chart":                "vector-0.34.1"
		if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
			"app.kubernetes.io/component": vector.role
		}
		for k, v in vector.podLabels {
			"\(k)": v
		}
	}

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      vectorName
		namespace: #config.metadata.namespace
		labels:    vectorLabels
		if len(vector.workloadResourceAnnotations) > 0 {
			annotations: vector.workloadResourceAnnotations
		}
	}
	spec: {
		if !vector.autoscaling.enabled && !vector.autoscaling.external {
			replicas: vector.replicas
		}
		podManagementPolicy: vector.podManagementPolicy
		if len([for k, v in vector.persistence.retentionPolicy {k}]) > 0 {
			persistentVolumeClaimRetentionPolicy: vector.persistence.retentionPolicy
		}
		selector: matchLabels: {
			"app.kubernetes.io/name":     "vector"
			"app.kubernetes.io/instance": #config.metadata.name
			if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
				"app.kubernetes.io/component": vector.role
			}
		}
		minReadySeconds: vector.minReadySeconds
		if len([for k, v in vector.updateStrategy {k}]) > 0 {
			updateStrategy: vector.updateStrategy
		}
		serviceName: "\(vectorName)-headless"
		template: {
			metadata: {
				annotations: {
					if vector.rollWorkload {
						"checksum/config": "vector-config-checksum"
					}
					for k, v in vector.podAnnotations {
						"\(k)": v
					}
				}
				labels: {
					"app.kubernetes.io/name":     "vector"
					"app.kubernetes.io/instance": #config.metadata.name
					if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
						"app.kubernetes.io/component": vector.role
					}
					for k, v in vector.podLabels {
						"\(k)": v
					}
				}
			}
			spec: #VectorPod & {#config: #config}
		}
		volumeClaimTemplates: [
			if vector.persistence.enabled && vector.persistence.existingClaim == "" {
				{
					metadata: name: "data"
					spec: {
						accessModes: vector.persistence.accessModes
						if vector.persistence.storageClass != "" {
							storageClassName: vector.persistence.storageClass
						}
						resources: requests: storage: vector.persistence.size
						if len([for k, v in vector.persistence.selectors {k}]) > 0 {
							selector: vector.persistence.selectors
						}
					}
				}
			},
		]
	}
}
