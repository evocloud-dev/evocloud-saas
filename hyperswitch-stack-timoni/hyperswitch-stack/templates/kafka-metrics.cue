package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#KafkaMetrics: {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let m = k.metrics
	let j = m.jmx
	let fullname = "\(#config.metadata.name)-\(k.name)"

	jmxConfigMap: corev1.#ConfigMap & {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "\(fullname)-jmx-configuration"
			namespace: #config.metadata.namespace
			labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "metrics"
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
			}
			if k.commonAnnotations != _|_ {
				annotations: k.commonAnnotations
			}
		}
		data: "jmx-kafka-prometheus.yml": """
			\(j.config)
			rules:
			  - pattern: kafka.controller<type=(ControllerChannelManager), name=(QueueSize), broker-id=(\\d+)><>(Value)
			    name: kafka_controller_$1_$2_$4
			    labels:
			      broker_id: "$3"
			  - pattern: kafka.controller<type=(ControllerChannelManager), name=(TotalQueueSize)><>(Value)
			    name: kafka_controller_$1_$2_$3
			  - pattern: kafka.controller<type=(KafkaController), name=(.+)><>(Value)
			    name: kafka_controller_$1_$2_$3
			  - pattern: kafka.controller<type=(ControllerStats), name=(.+)><>(Count)
			    name: kafka_controller_$1_$2_$3
			  - pattern : kafka.network<type=(Processor), name=(IdlePercent), networkProcessor=(.+)><>(Value)
			    name: kafka_network_$1_$2_$4
			    labels:
			      network_processor: $3
			  - pattern : kafka.network<type=(RequestMetrics), name=(.+), request=(.+)><>(Count|Value)
			    name: kafka_network_$1_$2_$4
			    labels:
			      request: $3
			  - pattern : kafka.network<type=(SocketServer), name=(.+)><>(Count|Value)
			    name: kafka_network_$1_$2_$3
			  - pattern : kafka.network<type=(RequestChannel), name=(.+)><>(Count|Value)
			    name: kafka_network_$1_$2_$3
			  - pattern: kafka.server<type=(.+), name=(.+), topic=(.+)><>(Count|OneMinuteRate)
			    name: kafka_server_$1_$2_$4
			    labels:
			      topic: $3
			  - pattern: kafka.server<type=(ReplicaFetcherManager), name=(.+), clientId=(.+)><>(Value)
			    name: kafka_server_$1_$2_$4
			    labels:
			      client_id: "$3"
			  - pattern: kafka.server<type=(DelayedOperationPurgatory), name=(.+), delayedOperation=(.+)><>(Value)
			    name: kafka_server_$1_$2_$3_$4
			  - pattern: kafka.server<type=(.+), name=(.+)><>(Count|Value|OneMinuteRate)
			    name: kafka_server_$1_total_$2_$3
			  - pattern: kafka.server<type=(.+)><>(queue-size)
			    name: kafka_server_$1_$2
			  - pattern: java.lang<type=(.+), name=(.+)><(.+)>(\\w+)
			    name: java_lang_$1_$4_$3_$2
			  - pattern: java.lang<type=(.+), name=(.+)><>(\\w+)
			    name: java_lang_$1_$3_$2
			  - pattern : java.lang<type=(.*)>
			  - pattern: kafka.log<type=(.+), name=(.+), topic=(.+), partition=(.+)><>Value
			    name: kafka_log_$1_$2
			    labels:
			      topic: $3
			      partition: $4
			\(j.extraRules)
			"""
	}

	jmxService: corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "\(fullname)-jmx-metrics"
			namespace: #config.metadata.namespace
			labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "metrics"
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
			}
			annotations: (*#config.metadata.annotations | {}) & (j.service.annotations | {}) & {
				if k.commonAnnotations != _|_ {
					for key, val in k.commonAnnotations {"\(key)": val}
				}
			}
		}
		spec: {
			type:            "ClusterIP"
			sessionAffinity: j.service.sessionAffinity
			if j.service.clusterIP != "" {
				clusterIP: j.service.clusterIP
			}
			ports: [
				{
					name:       "http-metrics"
					port:       j.service.ports.metrics
					protocol:   "TCP"
					targetPort: "metrics"
				},
			]
			selector: #config.metadata.labels & {
				"app.kubernetes.io/part-of": "kafka"
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
			}
		}
	}

	jmxServiceMonitor: {
		apiVersion: "monitoring.coreos.com/v1"
		kind:       "ServiceMonitor"
		metadata: {
			name:      "\(fullname)-jmx-metrics"
			namespace: *#config.metadata.namespace | m.serviceMonitor.namespace
			labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "metrics"
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
				for key, val in m.serviceMonitor.labels {"\(key)": val}
			}
			if k.commonAnnotations != _|_ {
				annotations: k.commonAnnotations
			}
		}
		spec: {
			if m.serviceMonitor.jobLabel != "" {
				jobLabel: m.serviceMonitor.jobLabel
			}
			selector: {
				matchLabels: #config.metadata.labels & {
					"app.kubernetes.io/component": "metrics"
					if k.commonLabels != _|_ {
						for key, val in k.commonLabels {"\(key)": val}
					}
					for key, val in m.serviceMonitor.selector {"\(key)": val}
				}
			}
			endpoints: [
				{
					port: "http-metrics"
					path: m.serviceMonitor.path
					if m.serviceMonitor.interval != "" {
						interval: m.serviceMonitor.interval
					}
					if m.serviceMonitor.scrapeTimeout != "" {
						scrapeTimeout: m.serviceMonitor.scrapeTimeout
					}
					if len(m.serviceMonitor.relabelings) > 0 {
						relabelings: m.serviceMonitor.relabelings
					}
					if len(m.serviceMonitor.metricRelabelings) > 0 {
						metricRelabelings: m.serviceMonitor.metricRelabelings
					}
					honorLabels: m.serviceMonitor.honorLabels
				},
			]
			namespaceSelector: matchNames: [#config.metadata.namespace]
		}
	}

	prometheusRule: [
		if m.prometheusRule.enabled {
			{
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "PrometheusRule"
				metadata: {
					name:      "\(fullname)"
					namespace: *#config.metadata.namespace | m.prometheusRule.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "metrics"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
						for key, val in m.prometheusRule.labels {"\(key)": val}
					}
					if k.commonAnnotations != _|_ {
						annotations: k.commonAnnotations
					}
				}
				spec: {
					groups: m.prometheusRule.groups
				}
			}
		},
	]
}
