package templates

import (
	monitoringv1 "monitoring.coreos.com/servicemonitor/v1"
)

// #ServiceMonitor emits a Prometheus Operator ServiceMonitor resource.
// This is the Timoni equivalent of Helm's metrics/servicemonitor.yaml.
//
// We use the vendored monitoring.coreos.com/servicemonitor/v1 schema for 
// strict validation.
//
// Helm condition: {{- if and .Values.metrics.enabled .Values.metrics.serviceMonitor.enabled }}
#ServiceMonitor: monitoringv1.#ServiceMonitor & {
	#in:    #Config
	metadata: {
		name:      #in.metadata.name
		// Helm: .Values.metrics.serviceMonitor.namespace | default .Release.Namespace
		namespace: [
			if #in.metrics.serviceMonitor.namespace != "" {#in.metrics.serviceMonitor.namespace},
			if #in.metrics.serviceMonitor.namespace == "" {#in.metadata.namespace},
		][0]
		labels: #in.metadata.labels & {
			"app.kubernetes.io/component": "metrics"
		}
		if #in.metrics.serviceMonitor.labels != _|_ {
			for k, v in #in.metrics.serviceMonitor.labels {
				"\(k)": v
			}
		}
	}
	spec: {
		// Helm: .Values.metrics.serviceMonitor.jobLabel
		if #in.metrics.serviceMonitor.jobLabel != "" {
			jobLabel: #in.metrics.serviceMonitor.jobLabel
		}
		// Helm: selector.matchLabels via nextcloud.selectorLabels with component=metrics
		selector: matchLabels: {
			"app.kubernetes.io/name":      #in.metadata.labels["app.kubernetes.io/name"]
			"app.kubernetes.io/instance":  #in.metadata.labels["app.kubernetes.io/instance"]
			"app.kubernetes.io/component": "metrics"
		}
		// Helm: namespaceSelector — default to release namespace
		namespaceSelector: [
			if #in.metrics.serviceMonitor.namespaceSelector != _|_ {#in.metrics.serviceMonitor.namespaceSelector},
			if #in.metrics.serviceMonitor.namespaceSelector == _|_ {{matchNames: [#in.metadata.namespace]}},
		][0]
		// Helm: endpoints with port, interval, scrapeTimeout
		endpoints: [{
			port: "metrics"
			path: "/"
			if #in.metrics.serviceMonitor.interval != "" {
				interval: #in.metrics.serviceMonitor.interval
			}
			if #in.metrics.serviceMonitor.scrapeTimeout != "" {
				scrapeTimeout: #in.metrics.serviceMonitor.scrapeTimeout
			}
		}]
	}
}
