package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#MetricsService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config._fullname)-metrics"
		namespace: #config.metadata.namespace
		labels:    #config._labels
		if #config.service.annotations != _|_ {
			annotations: #config.service.annotations
		}
	}
	spec: {
		if #config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if len(#config.service.ipFamilies) > 0 {
			ipFamilies: #config.service.ipFamilies
		}
		ports: [
			{
				name:       "metrics"
				port:       #config.metrics.port
				targetPort: "metrics"
				protocol:   "TCP"
			},
		]
		selector: #config._selectorLabels
	}
}

#ServiceMonitor: {
	#config: #Config
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels: {
			#config._labels
			for k, v in #config.metrics.serviceMonitor.labels {
				"\(k)": v
			}
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		selector: matchLabels: #config._selectorLabels
		endpoints: [
			{
				port:          "metrics"
				path:          "/metrics"
				interval:      #config.metrics.serviceMonitor.interval
				scrapeTimeout: #config.metrics.serviceMonitor.scrapeTimeout
			},
		]
	}
}

#PrometheusRule: {
	#config: #Config
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "PrometheusRule"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels: {
			#config._labels
			for k, v in #config.metrics.prometheusRule.labels {
				"\(k)": v
			}
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: {
		groups: [
			{
				name: "\(#config._fullname).native"
				rules: [
					{
						alert: "AFFiNEMetricsUnavailable"
						expr:  "up{namespace=\"\(#config.metadata.namespace)\",service=\"\(#config._fullname)-metrics\"} == 0"
						for:   "5m"
						labels: severity: "warning"
						annotations: summary: "AFFiNE native metrics target is unavailable"
					},
					for r in #config.metrics.prometheusRule.additionalRules {r},
				]
			},
		]
	}
}

