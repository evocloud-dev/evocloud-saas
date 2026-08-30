package templates

import (
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
)

#HyperswitchMonitoringName: {
	#config: #Config
	result:  string | *"hyperswitch-monitoring"
}

#HyperswitchMonitoringFullname: {
	#config: #Config
	result:  string | *"hyperswitch-monitoring"
}

#HyperswitchMonitoringLabels: {
	#config: #Config
	result: {
		"app.kubernetes.io/name": (#HyperswitchMonitoringName & {#config: #config}).result
		"app.kubernetes.io/instance":   #config.metadata.name
		"app.kubernetes.io/version":    #config.moduleVersion
		"app.kubernetes.io/managed-by": "timoni"
	}
}

#HyperswitchMonitoringPostgresqlHostname: {
	#config: #Config
	let mon = #config."hyperswitch-monitoring"
	result: [
		if !mon.postgresql.external {
			"\(#config.metadata.name)-postgresql"
		},
		if mon.postgresql.external {
			mon.postgresql.primary.host
		},
	][0]
}

#HyperswitchMonitoringPrometheusUrl: {
	#config: #Config
	result:  "http://\(#config.metadata.name)-kube-prometheus-prometheus:9090"
}

#HyperswitchMonitoringLokiUrl: {
	#config: #Config
	result:  "http://loki:3100"
}

// 1. /charts/hyperswitch-monitoring/templates/grafana-datasources.yaml
#HyperswitchMonitoringGrafanaDatasources: {
	#config: #Config
	corev1.#ConfigMap
	let mon = #config."hyperswitch-monitoring"
	let _fullname = (#HyperswitchMonitoringFullname & {#config: #config}).result
	let _labels = (#HyperswitchMonitoringLabels & {#config: #config}).result
	let _pg_host = (#HyperswitchMonitoringPostgresqlHostname & {#config: #config}).result
	let _prometheus_url = (#HyperswitchMonitoringPrometheusUrl & {#config: #config}).result
	let _loki_url = (#HyperswitchMonitoringLokiUrl & {#config: #config}).result

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_fullname)-grafana-datasources"
		namespace: #config.metadata.namespace
		labels: _labels & {
			grafana_datasource: "1"
		}
	}
	data: {
		"datasources.yaml": """
			apiVersion: 1
			datasources:
			  - name: Prometheus
			    type: prometheus
			    access: proxy
			    url: \(_prometheus_url)
			    isDefault: true
			    uid: "prometheus"
			  - name: Loki
			    type: loki
			    access: proxy
			    url: \(_loki_url)
			    uid: "loki"
			    isDefault: false
			  - name: PostgreSQL
			    type: postgres
			    access: proxy
			    url: \(_pg_host):\(mon.postgresql.primary.port)
			    user: \(mon.postgresql.primary.username)
			    password: \(mon.postgresql.primary.password)
			    database: \(mon.postgresql.primary.database)
			    uid: postgres_uid
			    jsonData:
			      sslmode: "disable"
			    secureJsonData:
			      password: \(mon.postgresql.primary.password)
			"""
	}
}

// 2. /charts/hyperswitch-monitoring/templates/grafana-ingress.yaml
#HyperswitchGrafanaIngress: {
	#config: #Config
	networkingv1.#Ingress
	let mon = #config."hyperswitch-monitoring"
	let grafana = mon."kube-prometheus-stack".grafana
	let _fullname = (#HyperswitchMonitoringFullname & {#config: #config}).result
	let _labels = (#HyperswitchMonitoringLabels & {#config: #config}).result

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      "\(_fullname)-grafana"
		namespace: #config.metadata.namespace
		labels: _labels & {
			"app.kubernetes.io/component": "grafana"
		}
		if grafana.ingress.annotations != _|_ {
			annotations: grafana.ingress.annotations
		}
	}
	spec: {
		if grafana.ingress.ingressClassName != "" {
			ingressClassName: grafana.ingress.ingressClassName
		}
		rules: [
			for h in grafana.ingress.hosts {
				host: h.host
				http: paths: [
					for p in h.paths {
						path:     p.path
						pathType: p.pathType
						backend: service: {
							name: "\(#config.metadata.name)-grafana"
							port: number: 80
						}
					},
				]
			},
		]
		if len(grafana.ingress.tls) > 0 {
			tls: [
				for t in grafana.ingress.tls {
					hosts:      t.hosts
					secretName: t.secretName
				},
			]
		}
	}
}
