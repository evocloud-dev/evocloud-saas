package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#GrafanaDashboardsConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-grafana-dashboards"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
			if #config.grafana.dashboards.labels != _|_ {
				#config.grafana.dashboards.labels
			}
		}
		if #config.grafana.dashboards.annotations != _|_ {
			annotations: #config.grafana.dashboards.annotations
		}
	}
	data: {
		if #config.grafana.dashboards.data != _|_ {
			#config.grafana.dashboards.data
		}
	}
}

