package templates

import (
	monitoringv1 "monitoring.coreos.com/prometheusrule/v1"
)

// #PrometheusRule emits a Prometheus Operator PrometheusRule resource.
// This is the Timoni equivalent of Helm's metrics/prometheus-rules.yaml.
//
// We use the vendored monitoring.coreos.com/prometheusrule/v1 schema for 
// strict validation.
//
// Helm condition: {{- if .Values.metrics.rules.enabled }}
#PrometheusRule: monitoringv1.#PrometheusRule & {
	#in:    #Config
	metadata: {
		name:      #in.metadata.name
		namespace: #in.metadata.namespace
		labels: #in.metadata.labels
		if #in.metrics.rules.labels != _|_ {
			for k, v in #in.metrics.rules.labels {
				"\(k)": v
			}
		}
	}
	spec: {
		groups: [
			// Default alerting group — mirrors Helm's .Values.metrics.rules.defaults
			if #in.metrics.rules.defaults.enabled {
				// Helm: $filter := .filter | default (printf `namespace="%s",job=~"^%s.*"` $.Release.Namespace $fullname)
				let _filter = [
					if #in.metrics.rules.defaults.filter != "" {#in.metrics.rules.defaults.filter},
					if #in.metrics.rules.defaults.filter == "" {"namespace=\"\(#in.metadata.namespace)\",job=~\"^\(#in.metadata.name).*\""},
				][0]

				{
					name: "\(#in.metadata.name)-Defaults"
					rules: [
						{
							alert: "nextcloud: not reachable"
							expr:  "avg(nextcloud_up{ \(_filter) }) without(endpoint,container,pod,instance) < 1"
							for:   "5m"
							labels: severity: "critical"
							if #in.metrics.rules.defaults.labels != _|_ {
								for k, v in #in.metrics.rules.defaults.labels {
									"labels": labels & {"\(k)": v}
								}
							}
							annotations: summary: "Nextcloud in \(#in.metadata.namespace) is not reachable by exporter"
						},
						{
							alert: "nextcloud: outdated version"
							expr:  "sum(nextcloud_system_update_available{ \(_filter) }) without(endpoint,container,pod,instance) > 0"
							labels: severity: "warning"
							annotations: summary: "Nextcloud in \(#in.metadata.namespace) is outdated"
						},
						{
							alert: "nextcloud: outdated apps"
							expr:  "sum(nextcloud_apps_updates_available_total{ \(_filter) }) without(endpoint,container,pod,instance) > 0"
							labels: severity: "info"
							annotations: summary: "Nextcloud in \(#in.metadata.namespace) has outdated apps"
						},
					]
				}
			},
			// Additional user-defined rules — mirrors Helm's .Values.metrics.rules.additionalRules
			if #in.metrics.rules.additionalRules != _|_ {
				{
					name:  "\(#in.metadata.name)-Additional"
					rules: #in.metrics.rules.additionalRules
				}
			},
		]
	}
}
