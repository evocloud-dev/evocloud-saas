package templates

import (
	"encoding/yaml"
	"list"
)

monitoringGrafana: {
	#config: #Config
	let mon = #config."hyperswitch-monitoring"
	let kps = mon."kube-prometheus-stack"
	let grafana = kps.grafana
	let fullname = (#KubePrometheusStackFullname & {#config: #config}).result
	let chartName = (#KubePrometheusStackName & {#config: #config}).result
	let amLabels = (#KubePrometheusStackLabels & {#config: #config}).result
	let amNamespace = [if kps.namespaceOverride != "" {kps.namespaceOverride}, #config.metadata.namespace][0]
	let grafanaNamespace = [if grafana.namespaceOverride != "" {grafana.namespaceOverride}, amNamespace][0]

	// configmaps-datasources.yaml
	if (grafana.enabled && grafana.sidecar.datasources.enabled) || grafana.forceDeployDatasources {
		"grafana-datasource-configmap": {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      "\(fullname)-grafana-datasource"
				namespace: grafanaNamespace
				if len(grafana.sidecar.datasources.annotations) > 0 {
					annotations: grafana.sidecar.datasources.annotations
				}
				labels: amLabels & {
					(grafana.sidecar.datasources.label): grafana.sidecar.datasources.labelValue
					app:                                 "\(chartName)-grafana"
				}
			}
			data: {
				"datasource.yaml": yaml.Marshal({
					apiVersion: 1
					if len(grafana.deleteDatasources) > 0 {
						deleteDatasources: grafana.deleteDatasources
					}
					if grafana.prune {
						prune: grafana.prune
					}
					datasources: [
						if grafana.sidecar.datasources.defaultDatasourceEnabled {
							{
								name: grafana.sidecar.datasources.name
								type: "prometheus"
								uid:  grafana.sidecar.datasources.uid
								url: [
									if grafana.sidecar.datasources.url != "" {
										grafana.sidecar.datasources.url
									},
									"http://\(fullname)-prometheus.\(amNamespace):\(kps.prometheus.service.port)\(kps.prometheus.prometheusSpec.routePrefix)",
								][0]
								access:    "proxy"
								isDefault: grafana.sidecar.datasources.isDefaultDatasource
								let scrapeInterval = [
									if grafana.sidecar.datasources.defaultDatasourceScrapeInterval != "" {
										grafana.sidecar.datasources.defaultDatasourceScrapeInterval
									},
									if kps.prometheus.prometheusSpec.scrapeInterval != "" {
										kps.prometheus.prometheusSpec.scrapeInterval
									},
									"30s",
								][0]
								jsonData: {
									httpMethod:   grafana.sidecar.datasources.httpMethod
									timeInterval: scrapeInterval
									if grafana.sidecar.datasources.timeout > 0 {
										timeout: grafana.sidecar.datasources.timeout
									}
									if grafana.sidecar.datasources.exemplarTraceIdDestinations.datasourceUid != "" {
										exemplarTraceIdDestinations: [
											{
												datasourceUid: grafana.sidecar.datasources.exemplarTraceIdDestinations.datasourceUid
												name:          grafana.sidecar.datasources.exemplarTraceIdDestinations.traceIdLabelName
											},
										]
									}
								}
							}
						},
						if grafana.sidecar.datasources.defaultDatasourceEnabled && grafana.sidecar.datasources.createPrometheusReplicasDatasources {
							for i in list.Range(0, kps.prometheus.prometheusSpec.replicas, 1) {
								{
									name:      "\(grafana.sidecar.datasources.name)-\(i)"
									type:      "prometheus"
									uid:       "\(grafana.sidecar.datasources.uid)-replica-\(i)"
									url:       "http://prometheus-\((#KubePrometheusStackFullname & {#config: #config}).result)-\(i).prometheus-operated:9090\(kps.prometheus.prometheusSpec.routePrefix)"
									access:    "proxy"
									isDefault: false
									let scrapeInterval = [
										if grafana.sidecar.datasources.defaultDatasourceScrapeInterval != "" {
											grafana.sidecar.datasources.defaultDatasourceScrapeInterval
										},
										if kps.prometheus.prometheusSpec.scrapeInterval != "" {
											kps.prometheus.prometheusSpec.scrapeInterval
										},
										"30s",
									][0]
									jsonData: {
										timeInterval: scrapeInterval
										if grafana.sidecar.datasources.exemplarTraceIdDestinations.datasourceUid != "" {
											exemplarTraceIdDestinations: [
												{
													datasourceUid: grafana.sidecar.datasources.exemplarTraceIdDestinations.datasourceUid
													name:          grafana.sidecar.datasources.exemplarTraceIdDestinations.traceIdLabelName
												},
											]
										}
									}
								}
							}
						},
						if grafana.sidecar.datasources.defaultDatasourceEnabled && grafana.sidecar.datasources.alertmanager.enabled {
							{
								name: grafana.sidecar.datasources.alertmanager.name
								type: "alertmanager"
								uid:  grafana.sidecar.datasources.alertmanager.uid
								url: [
									if grafana.sidecar.datasources.alertmanager.url != "" {
										grafana.sidecar.datasources.alertmanager.url
									},
									"http://\(fullname)-alertmanager.\(amNamespace):\(kps.alertmanager.service.port)\(kps.alertmanager.alertmanagerSpec.routePrefix)",
								][0]
								access: "proxy"
								jsonData: {
									handleGrafanaManagedAlerts: grafana.sidecar.datasources.alertmanager.handleGrafanaManagedAlerts
									implementation:             grafana.sidecar.datasources.alertmanager.implementation
								}
							}
						},
						for ds in grafana.additionalDataSources {
							ds
						},
					]
				})
			}
		}
	}
}
