package templates

#PrometheusRule: {
	#config: #Config

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "PrometheusRule"
	metadata: {
		name:      #config.#fullname
		namespace: #config.metadata.namespace
		labels:    #config.#labels & {
			if #config.metrics.prometheusRule.labels != _|_ {
				for k, v in #config.metrics.prometheusRule.labels {
					"\(k)": v
				}
			}
		}
	}
	spec: {
		groups: [{
			name: "\(#config.#fullname).application"
			rules: [
				{
					alert: "MoodleMetricsUnavailable"
					expr:  "absent(up{namespace=\"\(#config.metadata.namespace)\",service=\"\(#config.#metricsServiceName)\"}) or max(up{namespace=\"\(#config.metadata.namespace)\",service=\"\(#config.#metricsServiceName)\"}) == 0\n"
					for:   #config.metrics.prometheusRule.unavailableFor
					labels: {
						severity:  "warning"
						namespace: #config.metadata.namespace
						service:   #config.#metricsServiceName
					}
					annotations: {
						summary:     "Moodle application metrics are unavailable"
						description: "Check the monitoring plugin, bearer token, network policy and Prometheus discovery."
					}
				},
				if #config.#hasOverdueTasks {
					{
						alert: "MoodleTasksOverdue"
						expr:  "max by (namespace, service, type) (tool_monitoring_overdue_tasks{namespace=\"\(#config.metadata.namespace)\",service=\"\(#config.#metricsServiceName)\"}) > 0\n"
						for:   #config.metrics.prometheusRule.overdueTasksFor
						labels: severity: "warning"
						annotations: {
							summary:     "Moodle tasks remain overdue"
							description: "Inspect scheduled and ad-hoc workers, task failures and maintenance state."
						}
					}
				},
			]
		}]
	}
}

