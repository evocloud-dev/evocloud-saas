package templates

import (
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
)

monitoringLokiMonitoring: {
	#config: #Config
	let loki = #config."hyperswitch-monitoring".loki
	let monitoring = #config."hyperswitch-monitoring".loki.monitoring
	let ns = #config.metadata.namespace
	let _name = #config.metadata.name
	let clusterDomain = #config.global.clusterDomain

	let commonLabels = {
		"helm.sh/chart":              "loki-5.36.2"
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": _name
		"app.kubernetes.io/version": [if loki.image.tag != null {loki.image.tag}, #config.moduleVersion][0]
		"app.kubernetes.io/managed-by": "timoni"
	}

	let commonSelectorLabels = {
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": _name
	}

	// File 1: grafana-agent.yaml
	if monitoring.selfMonitoring.enabled && monitoring.selfMonitoring.grafanaAgent.enabled {
		"grafana-agent-serviceaccount": corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name: "\(_name)-loki-grafana-agent"
				namespace: [if monitoring.selfMonitoring.grafanaAgent.namespace != null {monitoring.selfMonitoring.grafanaAgent.namespace}, ns][0]
			}
		}

		"grafana-agent-clusterrole": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: name: "\(_name)-loki-grafana-agent"
			rules: [
				{
					apiGroups: [""]
					resources: ["nodes", "nodes/proxy", "nodes/metrics", "services", "endpoints", "pods", "events"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: ["networking.k8s.io"]
					resources: ["ingresses"]
					verbs: ["get", "list", "watch"]
				},
				{
					nonResourceURLs: ["/metrics", "/metrics/cadvisor"]
					verbs: ["get"]
				},
			]
		}

		"grafana-agent-clusterrolebinding": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: name: "\(_name)-loki-grafana-agent"
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_name)-loki-grafana-agent"
			}
			subjects: [
				{
					kind: "ServiceAccount"
					name: "\(_name)-loki-grafana-agent"
					namespace: [if monitoring.selfMonitoring.grafanaAgent.namespace != null {monitoring.selfMonitoring.grafanaAgent.namespace}, ns][0]
				},
			]
		}
	}

	// File 2: loki-alerts.yaml
	if monitoring.rules.enabled && monitoring.rules.alerting {
		"loki-alerts": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: "\(_name)-loki-alerts"
				namespace: [if monitoring.rules.namespace != null {monitoring.rules.namespace}, ns][0]
				labels: commonLabels & monitoring.rules.labels
				if len(monitoring.rules.annotations) > 0 {
					annotations: monitoring.rules.annotations
				}
			}
			spec: groups: [
				{
					name: "loki_alerts"
					rules: [
						if monitoring.rules.disabled.LokiRequestErrors == _|_ || !monitoring.rules.disabled.LokiRequestErrors {
							{
								alert: "LokiRequestErrors"
								annotations: message: "{{ $labels.job }} {{ $labels.route }} is experiencing {{ printf \"%.2f\" $value }}% errors.\n"
								expr: "100 * sum(rate(loki_request_duration_seconds_count{status_code=~\"5..\"}[2m])) by (namespace, job, route)\n  /\nsum(rate(loki_request_duration_seconds_count[2m])) by (namespace, job, route)\n  > 10\n"
								for:  "15m"
								labels: {
									severity: "critical"
									for k, v in monitoring.rules.additionalRuleLabels {"\(k)": v}
								}
							}
						},
						if monitoring.rules.disabled.LokiRequestPanics == _|_ || !monitoring.rules.disabled.LokiRequestPanics {
							{
								alert: "LokiRequestPanics"
								annotations: message: "{{ $labels.job }} is experiencing {{ printf \"%.2f\" $value }}% increase of panics.\n"
								expr: "sum(increase(loki_panic_total[10m])) by (namespace, job) > 0\n"
								labels: {
									severity: "critical"
									for k, v in monitoring.rules.additionalRuleLabels {"\(k)": v}
								}
							}
						},
						if monitoring.rules.disabled.LokiRequestLatency == _|_ || !monitoring.rules.disabled.LokiRequestLatency {
							{
								alert: "LokiRequestLatency"
								annotations: message: "{{ $labels.job }} {{ $labels.route }} is experiencing {{ printf \"%.2f\" $value }}s 99th percentile latency.\n"
								expr: "namespace_job_route:loki_request_duration_seconds:99quantile{route!~\"(?i).*tail.*\"} > 1\n"
								for:  "15m"
								labels: {
									severity: "critical"
									for k, v in monitoring.rules.additionalRuleLabels {"\(k)": v}
								}
							}
						},
						if monitoring.rules.disabled.LokiTooManyCompactorsRunning == _|_ || !monitoring.rules.disabled.LokiTooManyCompactorsRunning {
							{
								alert: "LokiTooManyCompactorsRunning"
								annotations: message: "{{ $labels.cluster }} {{ $labels.namespace }} has had {{ printf \"%.0f\" $value }} compactors running for more than 5m. Only one compactor should run at a time.\n"
								expr: "sum(loki_boltdb_shipper_compactor_running) by (cluster, namespace) > 1\n"
								for:  "5m"
								labels: {
									severity: "warning"
									for k, v in monitoring.rules.additionalRuleLabels {"\(k)": v}
								}
							}
						},
					]
				},
				if monitoring.rules.disabled.LokiCanaryLatency == _|_ || !monitoring.rules.disabled.LokiCanaryLatency {
					{
						name: "loki_canaries_alerts"
						rules: [
							{
								alert: "LokiCanaryLatency"
								annotations: message: "{{ $labels.job }} is experiencing {{ printf \"%.2f\" $value }}s 99th percentile latency.\n"
								expr: "histogram_quantile(0.99, sum(rate(loki_canary_response_latency_seconds_bucket[5m])) by (le, namespace, job)) > 5\n"
								for:  "15m"
								labels: {
									severity: "warning"
									for k, v in monitoring.rules.additionalRuleLabels {"\(k)": v}
								}
							},
						]
					}
				},
			]
		}
	}

	// File 3: loki-rules.yaml
	if monitoring.rules.enabled {
		"loki-rules": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "PrometheusRule"
			metadata: {
				name: "\(_name)-loki-rules"
				namespace: [if monitoring.rules.namespace != null {monitoring.rules.namespace}, ns][0]
				labels: commonLabels & monitoring.rules.labels
				if len(monitoring.rules.annotations) > 0 {
					annotations: monitoring.rules.annotations
				}
			}
			spec: groups: [
				{
					name: "loki_rules"
					rules: [
						{
							expr:   "histogram_quantile(0.99, sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job))"
							record: "job:loki_request_duration_seconds:99quantile"
							labels: cluster: _name
						},
						{
							expr:   "histogram_quantile(0.50, sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job))"
							record: "job:loki_request_duration_seconds:50quantile"
							labels: cluster: _name
						},
						{
							expr:   "sum(rate(loki_request_duration_seconds_sum[1m])) by (job) / sum(rate(loki_request_duration_seconds_count[1m])) by (job)"
							record: "job:loki_request_duration_seconds:avg"
							labels: cluster: _name
						},
						{
							expr:   "sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job)"
							record: "job:loki_request_duration_seconds_bucket:sum_rate"
							labels: cluster: _name
						},
						{
							expr:   "sum(rate(loki_request_duration_seconds_sum[1m])) by (job)"
							record: "job:loki_request_duration_seconds_sum:sum_rate"
							labels: cluster: _name
						},
						{
							expr:   "sum(rate(loki_request_duration_seconds_count[1m])) by (job)"
							record: "job:loki_request_duration_seconds_count:sum_rate"
							labels: cluster: _name
						},
						{
							expr:   "histogram_quantile(0.99, sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job, route))"
							record: "job_route:loki_request_duration_seconds:99quantile"
							labels: cluster: _name
						},
						{
							expr:   "histogram_quantile(0.50, sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job, route))"
							record: "job_route:loki_request_duration_seconds:50quantile"
							labels: cluster: _name
						},
						{
							expr:   "sum(rate(loki_request_duration_seconds_sum[1m])) by (job, route) / sum(rate(loki_request_duration_seconds_count[1m])) by (job, route)"
							record: "job_route:loki_request_duration_seconds:avg"
							labels: cluster: _name
						},
						{
							expr:   "sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job, route)"
							record: "job_route:loki_request_duration_seconds_bucket:sum_rate"
							labels: cluster: _name
						},
						{
							expr:   "sum(rate(loki_request_duration_seconds_sum[1m])) by (job, route)"
							record: "job_route:loki_request_duration_seconds_sum:sum_rate"
							labels: cluster: _name
						},
						{
							expr:   "sum(rate(loki_request_duration_seconds_count[1m])) by (job, route)"
							record: "job_route:loki_request_duration_seconds_count:sum_rate"
							labels: cluster: _name
						},
						{
							expr:   "histogram_quantile(0.99, sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, namespace, job, route))"
							record: "namespace_job_route:loki_request_duration_seconds:99quantile"
							labels: cluster: _name
						},
						{
							expr:   "histogram_quantile(0.50, sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, namespace, job, route))"
							record: "namespace_job_route:loki_request_duration_seconds:50quantile"
							labels: cluster: _name
						},
						{
							expr:   "sum(rate(loki_request_duration_seconds_sum[1m])) by (namespace, job, route) / sum(rate(loki_request_duration_seconds_count[1m])) by (namespace, job, route)"
							record: "namespace_job_route:loki_request_duration_seconds:avg"
							labels: cluster: _name
						},
						{
							expr:   "sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, namespace, job, route)"
							record: "namespace_job_route:loki_request_duration_seconds_bucket:sum_rate"
							labels: cluster: _name
						},
						{
							expr:   "sum(rate(loki_request_duration_seconds_sum[1m])) by (namespace, job, route)"
							record: "namespace_job_route:loki_request_duration_seconds_sum:sum_rate"
							labels: cluster: _name
						},
						{
							expr:   "sum(rate(loki_request_duration_seconds_count[1m])) by (namespace, job, route)"
							record: "namespace_job_route:loki_request_duration_seconds_count:sum_rate"
							labels: cluster: _name
						},
					]
				},
				for g in monitoring.rules.additionalGroups {g},
			]
		}
	}

	// File 4: logs-instance.yaml
	if monitoring.selfMonitoring.enabled {
		"logs-instance": {
			apiVersion: "monitoring.grafana.com/v1alpha1"
			kind:       "LogsInstance"
			metadata: {
				name:      _name
				namespace: ns
				labels:    commonLabels & monitoring.selfMonitoring.logsInstance.labels
				if len(monitoring.selfMonitoring.logsInstance.annotations) > 0 {
					annotations: monitoring.selfMonitoring.logsInstance.annotations
				}
			}
			spec: {
				clients: [
					{
						url: "http://\(_name)-loki-gateway.\(ns).svc.\(clusterDomain)/loki/api/v1/push"
						externalLabels: cluster: _name
						if loki.loki.auth_enabled {
							tenantId: monitoring.selfMonitoring.tenant.name
						}
					},
					for c in monitoring.selfMonitoring.logsInstance.clients {c},
				]
				podLogsNamespaceSelector: {}
				podLogsSelector: matchLabels: commonSelectorLabels
			}
		}
	}

	// File 5: metrics-instance.yaml
	if monitoring.serviceMonitor.enabled && monitoring.serviceMonitor.metricsInstance.enabled {
		"metrics-instance": {
			apiVersion: "monitoring.grafana.com/v1alpha1"
			kind:       "MetricsInstance"
			metadata: {
				name:   _name
				labels: commonLabels & monitoring.serviceMonitor.metricsInstance.labels
				if len(monitoring.serviceMonitor.metricsInstance.annotations) > 0 {
					annotations: monitoring.serviceMonitor.metricsInstance.annotations
				}
			}
			spec: {
				if len(monitoring.serviceMonitor.metricsInstance.remoteWrite) > 0 {
					remoteWrite: monitoring.serviceMonitor.metricsInstance.remoteWrite
				}
				serviceMonitorNamespaceSelector: {}
				serviceMonitorSelector: matchLabels: commonSelectorLabels
			}
		}
	}

	// File 6: pod-logs.yaml
	if monitoring.selfMonitoring.enabled {
		"pod-logs": {
			apiVersion: monitoring.selfMonitoring.podLogs.apiVersion
			kind:       "PodLogs"
			metadata: {
				name:      _name
				namespace: ns
				labels:    commonLabels & monitoring.selfMonitoring.podLogs.labels
				if len(monitoring.selfMonitoring.podLogs.annotations) > 0 {
					annotations: monitoring.selfMonitoring.podLogs.annotations
				}
			}
			spec: {
				pipelineStages: [
					{cri: {}},
					for s in monitoring.selfMonitoring.podLogs.additionalPipelineStages {s},
				]
				relabelings: [
					{action: "replace", sourceLabels: ["__meta_kubernetes_pod_node_name"], targetLabel: "__host__"},
					{action: "labelmap", regex: "__meta_kubernetes_pod_label_(.+)"},
					{action: "replace", replacement: "$1", separator: "-", sourceLabels: ["__meta_kubernetes_pod_label_app_kubernetes_io_name", "__meta_kubernetes_pod_label_app_kubernetes_io_component"], targetLabel: "__service__"},
					{action: "replace", replacement: "$1", separator: "/", sourceLabels: ["__meta_kubernetes_namespace", "__service__"], targetLabel: "job"},
					{action: "replace", sourceLabels: ["__meta_kubernetes_pod_container_name"], targetLabel: "container"},
					{action: "replace", replacement: _name, targetLabel: "cluster"},
					for r in monitoring.selfMonitoring.podLogs.relabelings {r},
				]
				namespaceSelector: matchNames: [ns]
				selector: matchLabels: commonSelectorLabels
			}
		}
	}

	// File 7: servicemonitor.yaml
	if monitoring.serviceMonitor.enabled {
		"servicemonitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {
				name:      _name
				namespace: ns
				labels:    commonLabels & monitoring.serviceMonitor.labels
				if len(monitoring.serviceMonitor.annotations) > 0 {
					annotations: monitoring.serviceMonitor.annotations
				}
			}
			spec: {
				if len(monitoring.serviceMonitor.namespaceSelector) > 0 {
					namespaceSelector: monitoring.serviceMonitor.namespaceSelector
				}
				selector: {
					matchLabels: commonSelectorLabels
					matchExpressions: [
						{key: "prometheus.io/service-monitor", operator: "NotIn", values: ["false"]},
					]
				}
				endpoints: [
					{
						port: "http-metrics"
						path: "/metrics"
						if monitoring.serviceMonitor.interval != null {
							interval: monitoring.serviceMonitor.interval
						}
						if monitoring.serviceMonitor.scrapeTimeout != null {
							scrapeTimeout: monitoring.serviceMonitor.scrapeTimeout
						}
						relabelings: [
							{sourceLabels: ["job"], action: "replace", replacement: "\(ns)/$1", targetLabel: "job"},
							{action: "replace", replacement: _name, targetLabel: "cluster"},
							for r in monitoring.serviceMonitor.relabelings {r},
						]
						if len(monitoring.serviceMonitor.metricRelabelings) > 0 {
							metricRelabelings: monitoring.serviceMonitor.metricRelabelings
						}
						scheme: monitoring.serviceMonitor.scheme
						if monitoring.serviceMonitor.tlsConfig != null {
							tlsConfig: monitoring.serviceMonitor.tlsConfig
						}
					},
				]
			}
		}
	}

	// File 8: dashboards-1.yaml
	if monitoring.dashboards.enabled {
		"dashboards-1": corev1.#ConfigMap & {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name: "\(_name)-loki-dashboards-1"
				namespace: [if monitoring.dashboards.namespace != null {monitoring.dashboards.namespace}, ns][0]
				labels: commonLabels & monitoring.dashboards.labels
				if len(monitoring.dashboards.annotations) > 0 {
					annotations: monitoring.dashboards.annotations
				}
			}
			data: {
				"loki-chunks.json":                "{}" // Placeholder or full JSON
				"loki-deletion.json":              "{}"
				"loki-logs.json":                  "{}"
				"loki-mixin-recording-rules.json": "{}"
				"loki-operational.json":           "{}"
			}
		}
	}

	// File 9: dashboards-2.yaml
	if monitoring.dashboards.enabled {
		"dashboards-2": corev1.#ConfigMap & {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name: "\(_name)-loki-dashboards-2"
				namespace: [if monitoring.dashboards.namespace != null {monitoring.dashboards.namespace}, ns][0]
				labels: commonLabels & monitoring.dashboards.labels
				if len(monitoring.dashboards.annotations) > 0 {
					annotations: monitoring.dashboards.annotations
				}
			}
			data: {
				"loki-reads-resources.json":  "{}"
				"loki-reads.json":            "{}"
				"loki-retention.json":        "{}"
				"loki-writes-resources.json": "{}"
				"loki-writes.json":           "{}"
			}
		}
	}
}
