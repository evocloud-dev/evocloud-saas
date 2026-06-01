package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// 1. /charts/hyperswitch-monitoring/templates/grafana-dashboards/payments-dashboard.yaml
#HyperswitchGrafanaPaymentsDashboard: {
	#config: #Config
	corev1.#ConfigMap
	let _fullname = (#HyperswitchMonitoringFullname & {#config: #config}).result
	let _labels = (#HyperswitchMonitoringLabels & {#config: #config}).result

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_fullname)-grafana-dashboards"
		namespace: #config.metadata.namespace
		labels: _labels & {
			grafana_dashboard: "1"
		}
	}
	data: {
		"payments-dashboard.json": #MonitoringDashboards.payments
	}
}

// 2. /charts/hyperswitch-monitoring/templates/grafana-dashboards/pod-usage-dashboard.yaml
#HyperswitchGrafanaPodUsageDashboard: {
	#config: #Config
	corev1.#ConfigMap
	let _fullname = (#HyperswitchMonitoringFullname & {#config: #config}).result
	let _labels = (#HyperswitchMonitoringLabels & {#config: #config}).result

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_fullname)-grafana-pod-usage-dashboard"
		namespace: #config.metadata.namespace
		labels: _labels & {
			grafana_dashboard: "1"
		}
	}
	data: {
		"pod-usage-dashboard.json": #MonitoringDashboards.podUsage
	}
}
