package templates

#ServiceMonitorBuilder: {
	_config: #Config

	_targetNamespace: [
		if _config.metrics.serviceMonitor.namespace != "" {_config.metrics.serviceMonitor.namespace},
		_config.namespace,
	][0]

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      _config.fullname
		namespace: _targetNamespace
		labels:    _config.metadata.labels & _config.metrics.serviceMonitor.additionalLabels
	}
	spec: {
		selector: matchLabels: _config.selector.labels
		endpoints: [{
			port:     "http"
			path:     "/rest/metrics/prometheus"
			interval: _config.metrics.serviceMonitor.interval
			if _config.metrics.serviceMonitor.scrapeTimeout != "" {
				scrapeTimeout: _config.metrics.serviceMonitor.scrapeTimeout
			}
			if len(_config.metrics.serviceMonitor.relabelings) > 0 {
				relabelings: _config.metrics.serviceMonitor.relabelings
			}
			if len(_config.metrics.serviceMonitor.metricRelabelings) > 0 {
				metricRelabelings: _config.metrics.serviceMonitor.metricRelabelings
			}
		}]
		namespaceSelector: matchNames: [_config.namespace]
	}
}
