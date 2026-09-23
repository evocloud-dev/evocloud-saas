// SPDX-License-Identifier: Apache-2.0

package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// #MetricsService mirrors metrics.yaml lines 2-17 (Service)
#MetricsService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-metrics"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: corev1.#ServiceSpec & {
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
			},
		]
		selector: #config.selector.labels
	}
}

// #ServiceMonitor mirrors metrics.yaml lines 18-35 (ServiceMonitor)
#ServiceMonitor: {
	#config: #Config

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels {
				"\(k)": v
			}
			for k, v in #config.metrics.serviceMonitor.labels {
				"\(k)": v
			}
		}
	}
	spec: {
		selector: matchLabels: #config.selector.labels
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

// #PrometheusRule mirrors metrics.yaml lines 36-55 (PrometheusRule)
#PrometheusRule: {
	#config: #Config

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "PrometheusRule"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels: {
			for k, v in #config.metadata.labels {
				"\(k)": v
			}
			for k, v in #config.metrics.prometheusRule.labels {
				"\(k)": v
			}
		}
	}
	spec: {
		groups: [
			{
				name: "\(#config.metadata.name).nginx"
				rules: [
					{
						alert: "BentoPDFNginxUnavailable"
						expr:  "nginx_up{namespace=\"\(#config.metadata.namespace)\",service=\"\(#config.metadata.name)-metrics\"} == 0"
						for:   "5m"
						labels: severity: "warning"
						annotations: summary: "BentoPDF exporter cannot read NGINX status"
					},
					for r in #config.metrics.prometheusRule.additionalRules {
						r
					},
				]
			},
		]
	}
}
