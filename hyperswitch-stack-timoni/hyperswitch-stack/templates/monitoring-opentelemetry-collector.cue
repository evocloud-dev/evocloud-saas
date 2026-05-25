package templates

import (
	"encoding/yaml"
)

monitoringOpentelemetryCollector: {
	#config:   #Config
	let #otel = #config."hyperswitch-monitoring"."opentelemetry-collector"
	let #metadata = #config.metadata

	let ns = #metadata.namespace
	let _name = #metadata.name
	let fullname = "\(_name)-opentelemetry-collector"

	let commonLabels = {
		for k, v in #metadata.labels if k != "app.kubernetes.io/name" && k != "app.kubernetes.io/instance" && k != "app.kubernetes.io/version" && k != "app.kubernetes.io/component" && k != "app.kubernetes.io/managed-by" {
			"\(k)": v
		}
		"helm.sh/chart":                "opentelemetry-collector-0.81.0"
		"app.kubernetes.io/name":       "opentelemetry-collector"
		"app.kubernetes.io/instance":   _name
		"app.kubernetes.io/version":    #otel.image.tag
		"app.kubernetes.io/managed-by": "timoni"
	}

	let selectorLabels = {
		"app.kubernetes.io/name":     "opentelemetry-collector"
		"app.kubernetes.io/instance": _name
	}

	if #otel.enabled {
		// File 1, 2, 3: configmap.yaml, configmap-agent.yaml, configmap-statefulset.yaml
		// Dynamically named based on mode to match Helm chart logic
		let cmName = [
			if #otel.mode == "daemonset" {"\(fullname)-agent"},
			if #otel.mode == "statefulset" {"\(fullname)-statefulset"},
			fullname,
		][0]

		let _defaultConfig = {
			exporters: debug: {}
			extensions: health_check: endpoint: "${env:MY_POD_IP}:13133"
			processors: {
				batch: {}
				memory_limiter: {
					check_interval:   "5s"
					limit_percentage: 80
					spike_limit_percentage: 25
				}
			}
			receivers: {
				otlp: protocols: {
					grpc: endpoint: "${env:MY_POD_IP}:4317"
					http: endpoint: "${env:MY_POD_IP}:4318"
				}
				prometheus: config: scrape_configs: [{
					job_name:        "opentelemetry-collector"
					scrape_interval: "10s"
					static_configs: [{targets: ["${env:MY_POD_IP}:8888"]}]
				}]
			}
			service: {
				extensions: ["health_check"]
				telemetry: metrics: address: "${env:MY_POD_IP}:8888"
				pipelines: {
					logs: {
						exporters: ["debug"]
						processors: ["memory_limiter", "batch"]
						receivers: ["otlp"]
					}
					metrics: {
						exporters: ["debug"]
						processors: ["memory_limiter", "batch"]
						receivers: ["otlp", "prometheus"]
					}
					traces: {
						exporters: ["debug"]
						processors: ["memory_limiter", "batch"]
						receivers: ["otlp"]
					}
				}
			}
		}

		"configmap": {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      cmName
				namespace: ns
				labels:    commonLabels
			}
			data: {
				relay: yaml.Marshal([if len(#otel.config) > 0 {#otel.config}, _defaultConfig][0])
			}
		}

		// File 4: serviceaccount.yaml
		if #otel.serviceAccount.create {
			"serviceaccount": {
				apiVersion: "v1"
				kind:       "ServiceAccount"
				metadata: {
					name: [if #otel.serviceAccount.name != "" {#otel.serviceAccount.name}, fullname][0]
					namespace: ns
					labels:    commonLabels
					if len(#otel.serviceAccount.annotations) > 0 {
						annotations: #otel.serviceAccount.annotations
					}
				}
			}
		}

		// File 5, 6: clusterrole.yaml, clusterrolebinding.yaml
		let createClusterRole = #otel.clusterRole.create || #otel.presets.kubernetesAttributes.enabled || #otel.presets.clusterMetrics.enabled || #otel.presets.kubeletMetrics.enabled || #otel.presets.kubernetesEvents.enabled
		if createClusterRole {
			"clusterrole": {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRole"
				metadata: {
					name: [if #otel.clusterRole.name != "" {#otel.clusterRole.name}, fullname][0]
					labels: commonLabels
					if len(#otel.clusterRole.annotations) > 0 {
						annotations: #otel.clusterRole.annotations
					}
				}
				rules: [
					for r in #otel.clusterRole.rules {r},
					if #otel.presets.kubernetesAttributes.enabled {
						{
							apiGroups: [""]
							resources: ["pods", "namespaces"]
							verbs: ["get", "watch", "list"]
						}
					},
					if #otel.presets.kubernetesAttributes.enabled {
						{
							apiGroups: ["apps"]
							resources: ["replicasets"]
							verbs: ["get", "list", "watch"]
						}
					},
					if #otel.presets.clusterMetrics.enabled {
						{
							apiGroups: [""]
							resources: ["events", "namespaces", "namespaces/status", "nodes", "nodes/spec", "pods", "pods/status", "replicationcontrollers", "replicationcontrollers/status", "resourcequotas", "services"]
							verbs: ["get", "list", "watch"]
						}
					},
					if #otel.presets.clusterMetrics.enabled {
						{
							apiGroups: ["apps"]
							resources: ["daemonsets", "deployments", "replicasets", "statefulsets"]
							verbs: ["get", "list", "watch"]
						}
					},
					if #otel.presets.kubeletMetrics.enabled {
						{
							apiGroups: [""]
							resources: ["nodes/stats"]
							verbs: ["get", "watch", "list"]
						}
					},
					if #otel.presets.kubernetesEvents.enabled {
						{
							apiGroups: ["events.k8s.io"]
							resources: ["events"]
							verbs: ["watch", "list"]
						}
					},
				]
			}

			"clusterrolebinding": {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRoleBinding"
				metadata: {
					name: [if #otel.clusterRole.name != "" {#otel.clusterRole.name}, fullname][0]
					labels: commonLabels
				}
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "ClusterRole"
					name: [if #otel.clusterRole.name != "" {#otel.clusterRole.name}, fullname][0]
				}
				subjects: [
					{
						kind: "ServiceAccount"
						name: [if #otel.serviceAccount.name != "" {#otel.serviceAccount.name}, fullname][0]
						namespace: ns
					},
				]
			}
		}

		let _servicePorts = [
			for name, port in #otel.ports if port.enabled {
				{
					name: name
					port: port.servicePort
					targetPort: [if port.containerPort != _|_ {port.containerPort}, name][0]
					protocol: port.protocol
					if port.appProtocol != null {
						appProtocol: port.appProtocol
					}
				}
			},
		]

		// File 7: service.yaml
		if #otel.service.enabled && len(_servicePorts) > 0 {
			"service": {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
					if len(#otel.service.annotations) > 0 {
						annotations: #otel.service.annotations
					}
				}
				spec: {
					type:     #otel.service.type
					ports:    _servicePorts
					selector: selectorLabels
				}
			}
		}

		// File 8: pdb.yaml
		if #otel.podDisruptionBudget.enabled && #otel.mode == "deployment" {
			"poddisruptionbudget": {
				apiVersion: "policy/v1"
				kind:       "PodDisruptionBudget"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					selector: matchLabels: selectorLabels
					if #otel.podDisruptionBudget.minAvailable != null {
						minAvailable: #otel.podDisruptionBudget.minAvailable
					}
					if #otel.podDisruptionBudget.maxUnavailable != null {
						maxUnavailable: #otel.podDisruptionBudget.maxUnavailable
					}
				}
			}
		}

		// File 9: hpa.yaml
		if #otel.autoscaling.enabled && (#otel.mode == "deployment" || #otel.mode == "statefulset") {
			"hpa": {
				apiVersion: "autoscaling/v2"
				kind:       "HorizontalPodAutoscaler"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					scaleTargetRef: {
						apiVersion: "apps/v1"
						kind: [if #otel.mode == "deployment" {"Deployment"}, "StatefulSet"][0]
						name: fullname
					}
					minReplicas: #otel.autoscaling.minReplicas
					maxReplicas: #otel.autoscaling.maxReplicas
					if #otel.autoscaling.behavior != null {
						behavior: #otel.autoscaling.behavior
					}
					metrics: [
						if #otel.autoscaling.targetCPUUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "cpu"
									target: {type: "Utilization", averageUtilization: #otel.autoscaling.targetCPUUtilizationPercentage}
								}
							}
						},
						if #otel.autoscaling.targetMemoryUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "memory"
									target: {type: "Utilization", averageUtilization: #otel.autoscaling.targetMemoryUtilizationPercentage}
								}
							}
						},
					]
				}
			}
		}

		// File 10: deployment.yaml
		if #otel.mode == "deployment" {
			"deployment": {
				apiVersion: "apps/v1"
				kind:       "Deployment"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					replicas: #otel.replicaCount
					selector: matchLabels: selectorLabels
					template: {
						metadata: {
							labels: selectorLabels & #otel.podLabels
							if len(#otel.podAnnotations) > 0 {
								annotations: #otel.podAnnotations
							}
						}
						spec: #PodSpec & {#fullname: fullname, #cmName: cmName}
					}
				}
			}
		}

		// File 11: daemonset.yaml
		if #otel.mode == "daemonset" {
			"daemonset": {
				apiVersion: "apps/v1"
				kind:       "DaemonSet"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					selector: matchLabels: selectorLabels
					template: {
						metadata: {
							labels: selectorLabels & #otel.podLabels
							if len(#otel.podAnnotations) > 0 {
								annotations: #otel.podAnnotations
							}
						}
						spec: #PodSpec & {#fullname: fullname, #cmName: cmName}
					}
				}
			}
		}

		// File 12: statefulset.yaml
		if #otel.mode == "statefulset" {
			"statefulset": {
				apiVersion: "apps/v1"
				kind:       "StatefulSet"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					replicas:            #otel.replicaCount
					serviceName:         fullname
					podManagementPolicy: "Parallel"
					selector: matchLabels: selectorLabels
					template: {
						metadata: {
							labels: selectorLabels & #otel.podLabels
							if len(#otel.podAnnotations) > 0 {
								annotations: #otel.podAnnotations
							}
						}
						spec: #PodSpec & {#fullname: fullname, #cmName: cmName}
					}
				}
			}
		}

		// File 13: networkpolicy.yaml
		if #otel.networkPolicy.enabled {
			"networkpolicy": {
				apiVersion: "networking.k8s.io/v1"
				kind:       "NetworkPolicy"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
					if len(#otel.networkPolicy.annotations) > 0 {
						annotations: #otel.networkPolicy.annotations
					}
				}
				spec: {
					podSelector: matchLabels: selectorLabels
					ingress: [
						{
							ports: [
								for name, port in #otel.ports if port.enabled {
									{
										port:     port.containerPort
										protocol: port.protocol
									}
								},
							]
							if len(#otel.networkPolicy.allowIngressFrom) > 0 {
								from: #otel.networkPolicy.allowIngressFrom
							}
						},
						for rule in #otel.networkPolicy.extraIngressRules {rule},
					]
					if len(#otel.networkPolicy.egressRules) > 0 {
						egress: #otel.networkPolicy.egressRules
						policyTypes: ["Ingress", "Egress"]
					}
					if len(#otel.networkPolicy.egressRules) == 0 {
						policyTypes: ["Ingress"]
					}
				}
			}
		}

		// File 14: ingress.yaml
		if #otel.ingress.enabled {
			"ingress": {
				apiVersion: "networking.k8s.io/v1"
				kind:       "Ingress"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
					if len(#otel.ingress.annotations) > 0 {
						annotations: #otel.ingress.annotations
					}
				}
				spec: {
					if #otel.ingress.ingressClassName != null {
						ingressClassName: #otel.ingress.ingressClassName
					}
					if len(#otel.ingress.tls) > 0 {
						tls: #otel.ingress.tls
					}
					rules: [
						for h in #otel.ingress.hosts {
							{
								host: h.host
								http: paths: [
									for p in h.paths {
										{
											path:     p.path
											pathType: p.pathType
											backend: service: {
												name: fullname
												port: number: p.port
											}
										}
									},
								]
							}
						},
					]
				}
			}
		}

		// File 15: servicemonitor.yaml
		if #otel.serviceMonitor.enabled {
			"servicemonitor": {
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "ServiceMonitor"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels & #otel.serviceMonitor.extraLabels
				}
				spec: {
					selector: matchLabels: selectorLabels
					endpoints: [
						for ep in #otel.serviceMonitor.metricsEndpoints {
							{
								port: ep.port
								if ep.interval != null {
									interval: ep.interval
								}
								if len(ep.relabelings) > 0 {
									relabelings: ep.relabelings
								}
								if len(ep.metricRelabelings) > 0 {
									metricRelabelings: ep.metricRelabelings
								}
							}
						},
					]
				}
			}
		}

		// File 16: podmonitor.yaml
		if #otel.podMonitor.enabled {
			"podmonitor": {
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "PodMonitor"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels & #otel.podMonitor.extraLabels
				}
				spec: {
					selector: matchLabels: selectorLabels
					podMetricsEndpoints: [
						for ep in #otel.podMonitor.metricsEndpoints {
							{
								port: ep.port
								if ep.interval != null {
									interval: ep.interval
								}
							}
						},
					]
				}
			}
		}

		// File 17: prometheusrule.yaml
		if #otel.prometheusRule.enabled {
			"prometheusrule": {
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "PrometheusRule"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels & #otel.prometheusRule.extraLabels
				}
				spec: groups: #otel.prometheusRule.groups
			}
		}

		// File 18: extraManifests.yaml
		for i, m in #otel.extraManifests {
			"extra-manifest-\(i)": m
		}

		#PodSpec: {
			#fullname: string
			#cmName:   string

			if #otel.hostNetwork {
				hostNetwork: true
			}
			if #otel.dnsPolicy != "" {
				dnsPolicy: #otel.dnsPolicy
			}
			if #otel.dnsConfig != null {
				dnsConfig: #otel.dnsConfig
			}

			serviceAccountName: [if #otel.serviceAccount.name != "" {#otel.serviceAccount.name}, #fullname][0]
			securityContext: #otel.podSecurityContext
			containers: [
				{
					name:            "otel-collector"
					let registry = [if #otel.image.registry != "" {#otel.image.registry}, #config."hyperswitch-monitoring".global.imageRegistry][0]
					image:           [if registry != "" {"\(registry)/\(#otel.image.repository):\(#otel.image.tag)"}, "\(#otel.image.repository):\(#otel.image.tag)"][0]
					imagePullPolicy: #otel.image.pullPolicy
					if #otel.command.name != "" {
						command: ["/\(#otel.command.name)"]
					}
					args: [
						"--config=/conf/relay.yaml",
						for arg in #otel.command.extraArgs {arg},
					]
					env: [
						{
							name: "MY_POD_IP"
							valueFrom: fieldRef: fieldPath: "status.podIP"
						},
						if #otel.presets.kubeletMetrics.enabled || (#otel.presets.kubernetesAttributes.enabled && #otel.mode == "daemonset") {
							{
								name: "K8S_NODE_NAME"
								valueFrom: fieldRef: fieldPath: "spec.nodeName"
							}
						},
						if #otel.presets.kubeletMetrics.enabled || (#otel.presets.kubernetesAttributes.enabled && #otel.mode == "daemonset") {
							{
								name: "K8S_NODE_IP"
								valueFrom: fieldRef: fieldPath: "status.hostIP"
							}
						},
						for e in #otel.extraEnvs {e},
					]
					if len(#otel.extraEnvsFrom) > 0 {
						envFrom: #otel.extraEnvsFrom
					}
					ports: [
						for name, port in #otel.ports if port.enabled {
							{
								name:          name
								containerPort: port.containerPort
								protocol:      port.protocol
								if #otel.mode == "daemonset" && port.hostPort != null {
									hostPort: port.hostPort
								}
							}
						},
					]
					livenessProbe: {
						httpGet: {
							path: "/"
							port: 13133
						}
					}
					readinessProbe: {
						httpGet: {
							path: "/"
							port: 13133
						}
					}
					resources: #otel.resources
					volumeMounts: [
						{
							name:      "otel-collector-configval"
							mountPath: "/conf"
						},
						if #otel.presets.logsCollection.enabled {
							{
								name:      "varlogpods"
								mountPath: "/var/log/pods"
								readOnly:  true
							}
						},
						if #otel.presets.logsCollection.enabled {
							{
								name:      "varlibdockercontainers"
								mountPath: "/var/lib/docker/containers"
								readOnly:  true
							}
						},
						if #otel.presets.hostMetrics.enabled {
							{
								name:             "hostfs"
								mountPath:        "/hostfs"
								readOnly:         true
								mountPropagation: "HostToContainer"
							}
						},
						for vm in #otel.extraVolumeMounts {vm},
					]
				},
			]
			nodeSelector: #otel.nodeSelector
			tolerations:  #otel.tolerations
			affinity:     #otel.affinity
			volumes: [
				{
					name: "otel-collector-configval"
					configMap: {
						name: #cmName
						items: [{
							key:  "relay"
							path: "relay.yaml"
						}]
					}
				},
				if #otel.presets.logsCollection.enabled {
					{
						name: "varlogpods"
						hostPath: path: "/var/log/pods"
					}
				},
				if #otel.presets.logsCollection.enabled {
					{
						name: "varlibdockercontainers"
						hostPath: path: "/var/lib/docker/containers"
					}
				},
				if #otel.presets.hostMetrics.enabled {
					{
						name: "hostfs"
						hostPath: path: "/"
					}
				},
				for v in #otel.extraVolumes {v},
			]
		}
	}
}
