package templates

#KubeVersionDefaultValue: {
	#values:      #Config
	#kubeVersion: string
	#old:         _
	#new:         _
	#default:     _

	result: {
		if #default != null {
			#default
		}
		if #default == null {
			#new
		}
	}
}

#ServiceMonitorScrapeLimits: {
	#monitor: _
	result: {
		if #monitor.sampleLimit > 0 {
			sampleLimit: #monitor.sampleLimit
		}
		if #monitor.targetLimit > 0 {
			targetLimit: #monitor.targetLimit
		}
		if #monitor.labelLimit > 0 {
			labelLimit: #monitor.labelLimit
		}
		if #monitor.labelNameLengthLimit > 0 {
			labelNameLengthLimit: #monitor.labelNameLengthLimit
		}
		if #monitor.labelValueLengthLimit > 0 {
			labelValueLengthLimit: #monitor.labelValueLengthLimit
		}
	}
}

monitoringKubeExporters: {
	#config: #Config
	let mon = #config."hyperswitch-monitoring"
	let kps = mon."kube-prometheus-stack"
	let fullname = (#KubePrometheusStackFullname & {#config: #config}).result
	let chartName = (#KubePrometheusStackName & {#config: #config}).result
	let amNamespace = [if kps.namespaceOverride != "" {kps.namespaceOverride}, #config.metadata.namespace][0]
	let amLabels = (#KubePrometheusStackLabels & {#config: #config}).result

	// 1. coreDns
	if kps.coreDns.enabled && kps.kubernetesServiceMonitors.enabled {
		let coredns = kps.coreDns

		if coredns.service.enabled {
			"coredns-service": {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name: "\(fullname)-coredns"
					labels: amLabels & {
						app:        "\(chartName)-coredns"
						"jobLabel": "coredns"
					}
					namespace: "kube-system"
				}
				spec: {
					clusterIP: "None"
					if coredns.service.ipDualStack.enabled {
						ipFamilies:     coredns.service.ipDualStack.ipFamilies
						ipFamilyPolicy: coredns.service.ipDualStack.ipFamilyPolicy
					}
					ports: [
						{
							name:       coredns.serviceMonitor.port
							port:       coredns.service.port
							protocol:   "TCP"
							targetPort: coredns.service.targetPort
						},
					]
					selector: {
						if len(coredns.service.selector) > 0 {
							coredns.service.selector
						}
						if len(coredns.service.selector) == 0 {
							"k8s-app": "kube-dns"
						}
					}
				}
			}
		}

		if coredns.serviceMonitor.enabled {
			"coredns-servicemonitor": {
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "ServiceMonitor"
				metadata: {
					name: "\(fullname)-coredns"
					if kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
						namespace: "kube-system"
					}
					if !kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
						namespace: amNamespace
					}
					labels: amLabels & {
						app: "\(chartName)-coredns"
					}
					if len(coredns.serviceMonitor.additionalLabels) > 0 {
						annotations: coredns.serviceMonitor.additionalLabels
					}
				}
				spec: {
					jobLabel: coredns.serviceMonitor.jobLabel
					(#ServiceMonitorScrapeLimits & {#monitor: coredns.serviceMonitor}).result
					selector: {
						if len(coredns.serviceMonitor.selector) > 0 {
							coredns.serviceMonitor.selector
						}
						if len(coredns.serviceMonitor.selector) == 0 {
							matchLabels: {
								app:     "\(chartName)-coredns"
								release: #config.metadata.name
							}
						}
					}
					namespaceSelector: matchNames: ["kube-system"]
					endpoints: [
						{
							port:            coredns.serviceMonitor.port
							bearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
							if coredns.serviceMonitor.interval != "" {
								interval: coredns.serviceMonitor.interval
							}
							if coredns.serviceMonitor.proxyUrl != "" {
								proxyUrl: coredns.serviceMonitor.proxyUrl
							}
							if len(coredns.serviceMonitor.metricRelabelings) > 0 {
								metricRelabelings: coredns.serviceMonitor.metricRelabelings
							}
							if len(coredns.serviceMonitor.relabelings) > 0 {
								relabelings: coredns.serviceMonitor.relabelings
							}
						},
					]
				}
			}
		}
	}

	// 2. kube-api-server
	if kps.kubeApiServer.enabled && kps.kubernetesServiceMonitors.enabled {
		let apiserver = kps.kubeApiServer
		"apiserver-servicemonitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {
				name: "\(fullname)-apiserver"
				if kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
					namespace: "default"
				}
				if !kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
					namespace: amNamespace
				}
				labels: amLabels & {
					app: "\(chartName)-apiserver"
				}
				if len(apiserver.serviceMonitor.additionalLabels) > 0 {
					annotations: apiserver.serviceMonitor.additionalLabels
				}
			}
			spec: {
				jobLabel: apiserver.serviceMonitor.jobLabel
				(#ServiceMonitorScrapeLimits & {#monitor: apiserver.serviceMonitor}).result
				selector: {
					if len(apiserver.serviceMonitor.selector) > 0 {
						apiserver.serviceMonitor.selector
					}
					if len(apiserver.serviceMonitor.selector) == 0 {
						matchLabels: {
							component: "apiserver"
							provider:  "kubernetes"
						}
					}
				}
				namespaceSelector: matchNames: ["default"]
				endpoints: [
					{
						bearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
						if apiserver.serviceMonitor.interval != "" {
							interval: apiserver.serviceMonitor.interval
						}
						if apiserver.serviceMonitor.proxyUrl != "" {
							proxyUrl: apiserver.serviceMonitor.proxyUrl
						}
						port:   "https"
						scheme: "https"
						if len(apiserver.serviceMonitor.metricRelabelings) > 0 {
							metricRelabelings: apiserver.serviceMonitor.metricRelabelings
						}
						if len(apiserver.serviceMonitor.relabelings) > 0 {
							relabelings: apiserver.serviceMonitor.relabelings
						}
						tlsConfig: {
							caFile:             "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
							serverName:         apiserver.tlsConfig.serverName
							insecureSkipVerify: apiserver.tlsConfig.insecureSkipVerify
						}
					},
				]
			}
		}
	}

	// 3. kubelet
	if kps.kubelet.enabled && kps.kubernetesServiceMonitors.enabled {
		let kubelet = kps.kubelet
		"kubelet-servicemonitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {
				name: "\(fullname)-kubelet"
				if kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
					namespace: kubelet.namespace
				}
				if !kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
					namespace: amNamespace
				}
				labels: amLabels & {
					app: "\(chartName)-kubelet"
				}
				if len(kubelet.serviceMonitor.additionalLabels) > 0 {
					annotations: kubelet.serviceMonitor.additionalLabels
				}
			}
			spec: {
				(#ServiceMonitorScrapeLimits & {#monitor: kubelet.serviceMonitor}).result
				if kubelet.serviceMonitor.attachMetadata.node {
					attachMetadata: node: true
				}
				endpoints: [
					if kubelet.serviceMonitor.https {
						{
							port:   "https-metrics"
							scheme: "https"
							if kubelet.serviceMonitor.interval != "" {
								interval: kubelet.serviceMonitor.interval
							}
							if kubelet.serviceMonitor.proxyUrl != "" {
								proxyUrl: kubelet.serviceMonitor.proxyUrl
							}
							if kubelet.serviceMonitor.scrapeTimeout != "" {
								scrapeTimeout: kubelet.serviceMonitor.scrapeTimeout
							}
							tlsConfig: {
								caFile:             "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
								insecureSkipVerify: kubelet.serviceMonitor.insecureSkipVerify
							}
							bearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
							honorLabels:     kubelet.serviceMonitor.honorLabels
							honorTimestamps: kubelet.serviceMonitor.honorTimestamps
							if len(kubelet.serviceMonitor.metricRelabelings) > 0 {
								metricRelabelings: kubelet.serviceMonitor.metricRelabelings
							}
							if len(kubelet.serviceMonitor.relabelings) > 0 {
								relabelings: kubelet.serviceMonitor.relabelings
							}
						}
					},
					if kubelet.serviceMonitor.https && kubelet.serviceMonitor.cAdvisor {
						{
							port:   "https-metrics"
							scheme: "https"
							path:   "/metrics/cadvisor"
							if kubelet.serviceMonitor.interval != "" {
								interval: kubelet.serviceMonitor.interval
							}
							if kubelet.serviceMonitor.proxyUrl != "" {
								proxyUrl: kubelet.serviceMonitor.proxyUrl
							}
							if kubelet.serviceMonitor.scrapeTimeout != "" {
								scrapeTimeout: kubelet.serviceMonitor.scrapeTimeout
							}
							honorLabels:     kubelet.serviceMonitor.honorLabels
							honorTimestamps: kubelet.serviceMonitor.honorTimestamps
							tlsConfig: {
								caFile:             "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
								insecureSkipVerify: true
							}
							bearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
							if len(kubelet.serviceMonitor.cAdvisorMetricRelabelings) > 0 {
								metricRelabelings: kubelet.serviceMonitor.cAdvisorMetricRelabelings
							}
							if len(kubelet.serviceMonitor.cAdvisorRelabelings) > 0 {
								relabelings: kubelet.serviceMonitor.cAdvisorRelabelings
							}
						}
					},
					if kubelet.serviceMonitor.https && kubelet.serviceMonitor.probes {
						{
							port:   "https-metrics"
							scheme: "https"
							path:   "/metrics/probes"
							if kubelet.serviceMonitor.interval != "" {
								interval: kubelet.serviceMonitor.interval
							}
							if kubelet.serviceMonitor.proxyUrl != "" {
								proxyUrl: kubelet.serviceMonitor.proxyUrl
							}
							if kubelet.serviceMonitor.scrapeTimeout != "" {
								scrapeTimeout: kubelet.serviceMonitor.scrapeTimeout
							}
							honorLabels:     kubelet.serviceMonitor.honorLabels
							honorTimestamps: kubelet.serviceMonitor.honorTimestamps
							tlsConfig: {
								caFile:             "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
								insecureSkipVerify: true
							}
							bearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
							if len(kubelet.serviceMonitor.probesMetricRelabelings) > 0 {
								metricRelabelings: kubelet.serviceMonitor.probesMetricRelabelings
							}
							if len(kubelet.serviceMonitor.probesRelabelings) > 0 {
								relabelings: kubelet.serviceMonitor.probesRelabelings
							}
						}
					},
					if kubelet.serviceMonitor.https && kubelet.serviceMonitor.resource {
						{
							port:   "https-metrics"
							scheme: "https"
							path:   kubelet.serviceMonitor.resourcePath
							if kubelet.serviceMonitor.interval != "" {
								interval: kubelet.serviceMonitor.interval
							}
							if kubelet.serviceMonitor.proxyUrl != "" {
								proxyUrl: kubelet.serviceMonitor.proxyUrl
							}
							if kubelet.serviceMonitor.scrapeTimeout != "" {
								scrapeTimeout: kubelet.serviceMonitor.scrapeTimeout
							}
							honorLabels:     kubelet.serviceMonitor.honorLabels
							honorTimestamps: kubelet.serviceMonitor.honorTimestamps
							tlsConfig: {
								caFile:             "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
								insecureSkipVerify: true
							}
							bearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
							if len(kubelet.serviceMonitor.resourceMetricRelabelings) > 0 {
								metricRelabelings: kubelet.serviceMonitor.resourceMetricRelabelings
							}
							if len(kubelet.serviceMonitor.resourceRelabelings) > 0 {
								relabelings: kubelet.serviceMonitor.resourceRelabelings
							}
						}
					},
					if !kubelet.serviceMonitor.https {
						{
							port: "http-metrics"
							if kubelet.serviceMonitor.interval != "" {
								interval: kubelet.serviceMonitor.interval
							}
							if kubelet.serviceMonitor.proxyUrl != "" {
								proxyUrl: kubelet.serviceMonitor.proxyUrl
							}
							if kubelet.serviceMonitor.scrapeTimeout != "" {
								scrapeTimeout: kubelet.serviceMonitor.scrapeTimeout
							}
							honorLabels:     kubelet.serviceMonitor.honorLabels
							honorTimestamps: kubelet.serviceMonitor.honorTimestamps
							if len(kubelet.serviceMonitor.metricRelabelings) > 0 {
								metricRelabelings: kubelet.serviceMonitor.metricRelabelings
							}
							if len(kubelet.serviceMonitor.relabelings) > 0 {
								relabelings: kubelet.serviceMonitor.relabelings
							}
						}
					},
					if !kubelet.serviceMonitor.https && kubelet.serviceMonitor.cAdvisor {
						{
							port: "http-metrics"
							path: "/metrics/cadvisor"
							if kubelet.serviceMonitor.interval != "" {
								interval: kubelet.serviceMonitor.interval
							}
							if kubelet.serviceMonitor.proxyUrl != "" {
								proxyUrl: kubelet.serviceMonitor.proxyUrl
							}
							if kubelet.serviceMonitor.scrapeTimeout != "" {
								scrapeTimeout: kubelet.serviceMonitor.scrapeTimeout
							}
							honorLabels:     kubelet.serviceMonitor.honorLabels
							honorTimestamps: kubelet.serviceMonitor.honorTimestamps
							if len(kubelet.serviceMonitor.cAdvisorMetricRelabelings) > 0 {
								metricRelabelings: kubelet.serviceMonitor.cAdvisorMetricRelabelings
							}
							if len(kubelet.serviceMonitor.cAdvisorRelabelings) > 0 {
								relabelings: kubelet.serviceMonitor.cAdvisorRelabelings
							}
						}
					},
					if !kubelet.serviceMonitor.https && kubelet.serviceMonitor.probes {
						{
							port: "http-metrics"
							path: "/metrics/probes"
							if kubelet.serviceMonitor.interval != "" {
								interval: kubelet.serviceMonitor.interval
							}
							if kubelet.serviceMonitor.proxyUrl != "" {
								proxyUrl: kubelet.serviceMonitor.proxyUrl
							}
							if kubelet.serviceMonitor.scrapeTimeout != "" {
								scrapeTimeout: kubelet.serviceMonitor.scrapeTimeout
							}
							honorLabels:     kubelet.serviceMonitor.honorLabels
							honorTimestamps: kubelet.serviceMonitor.honorTimestamps
							if len(kubelet.serviceMonitor.probesMetricRelabelings) > 0 {
								metricRelabelings: kubelet.serviceMonitor.probesMetricRelabelings
							}
							if len(kubelet.serviceMonitor.probesRelabelings) > 0 {
								relabelings: kubelet.serviceMonitor.probesRelabelings
							}
						}
					},
					if !kubelet.serviceMonitor.https && kubelet.serviceMonitor.resource {
						{
							port: "http-metrics"
							path: kubelet.serviceMonitor.resourcePath
							if kubelet.serviceMonitor.interval != "" {
								interval: kubelet.serviceMonitor.interval
							}
							if kubelet.serviceMonitor.proxyUrl != "" {
								proxyUrl: kubelet.serviceMonitor.proxyUrl
							}
							if kubelet.serviceMonitor.scrapeTimeout != "" {
								scrapeTimeout: kubelet.serviceMonitor.scrapeTimeout
							}
							honorLabels:     kubelet.serviceMonitor.honorLabels
							honorTimestamps: kubelet.serviceMonitor.honorTimestamps
							if len(kubelet.serviceMonitor.resourceMetricRelabelings) > 0 {
								metricRelabelings: kubelet.serviceMonitor.resourceMetricRelabelings
							}
							if len(kubelet.serviceMonitor.resourceRelabelings) > 0 {
								relabelings: kubelet.serviceMonitor.resourceRelabelings
							}
						}
					},
				]
				jobLabel: "k8s-app"
				namespaceSelector: matchNames: [kubelet.namespace]
				selector: matchLabels: {
					"app.kubernetes.io/name": "kubelet"
					"k8s-app":                "kubelet"
				}
			}
		}
	}

	// 4. kube-controller-manager
	if kps.kubeControllerManager.enabled && kps.kubernetesServiceMonitors.enabled {
		let cm = kps.kubeControllerManager

		if len(cm.endpoints) > 0 {
			"kube-controller-manager-endpoints": {
				apiVersion: "v1"
				kind:       "Endpoints"
				metadata: {
					name: "\(fullname)-kube-controller-manager"
					labels: amLabels & {
						app:       "\(chartName)-kube-controller-manager"
						"k8s-app": "kube-controller-manager"
					}
					namespace: "kube-system"
				}
				subsets: [
					{
						addresses: [for ip in cm.endpoints {{ip: ip}}]
						ports: [
							{
								name: cm.serviceMonitor.port
								port: (#KubeVersionDefaultValue & {#values: #config, #kubeVersion: ">= 1.22-0", #old: 10252, #new: 10257, #default: cm.service.port}).result
								protocol: "TCP"
							},
						]
					},
				]
			}
		}

		if cm.service.enabled {
			"kube-controller-manager-service": {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name: "\(fullname)-kube-controller-manager"
					labels: amLabels & {
						app:        "\(chartName)-kube-controller-manager"
						"jobLabel": "kube-controller-manager"
					}
					namespace: "kube-system"
				}
				spec: {
					clusterIP: "None"
					if cm.service.ipDualStack.enabled {
						ipFamilies:     cm.service.ipDualStack.ipFamilies
						ipFamilyPolicy: cm.service.ipDualStack.ipFamilyPolicy
					}
					ports: [
						{
							name: cm.serviceMonitor.port
							port: (#KubeVersionDefaultValue & {#values: #config, #kubeVersion: ">= 1.22-0", #old: 10252, #new: 10257, #default: cm.service.port}).result
							protocol: "TCP"
							targetPort: (#KubeVersionDefaultValue & {#values: #config, #kubeVersion: ">= 1.22-0", #old: 10252, #new: 10257, #default: cm.service.targetPort}).result
						},
					]
					if len(cm.endpoints) == 0 {
						selector: {
							if len(cm.service.selector) > 0 {
								cm.service.selector
							}
							if len(cm.service.selector) == 0 {
								component: "kube-controller-manager"
							}
						}
					}
					type: "ClusterIP"
				}
			}
		}

		if cm.serviceMonitor.enabled {
			"kube-controller-manager-servicemonitor": {
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "ServiceMonitor"
				metadata: {
					name: "\(fullname)-kube-controller-manager"
					if kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
						namespace: "kube-system"
					}
					if !kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
						namespace: amNamespace
					}
					labels: amLabels & {
						app: "\(chartName)-kube-controller-manager"
					}
					if len(cm.serviceMonitor.additionalLabels) > 0 {
						annotations: cm.serviceMonitor.additionalLabels
					}
				}
				spec: {
					jobLabel: cm.serviceMonitor.jobLabel
					(#ServiceMonitorScrapeLimits & {#monitor: cm.serviceMonitor}).result
					selector: {
						if len(cm.serviceMonitor.selector) > 0 {
							cm.serviceMonitor.selector
						}
						if len(cm.serviceMonitor.selector) == 0 {
							matchLabels: {
								app:     "\(chartName)-kube-controller-manager"
								release: #config.metadata.name
							}
						}
					}
					namespaceSelector: matchNames: ["kube-system"]
					endpoints: [
						{
							port:            cm.serviceMonitor.port
							bearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
							if cm.serviceMonitor.interval != "" {
								interval: cm.serviceMonitor.interval
							}
							if cm.serviceMonitor.proxyUrl != "" {
								proxyUrl: cm.serviceMonitor.proxyUrl
							}
							let isSecure = (#KubeVersionDefaultValue & {#values: #config, #kubeVersion: ">= 1.22-0", #old: false, #new: true, #default: cm.serviceMonitor.https}).result
							if isSecure {
								scheme: "https"
								tlsConfig: {
									caFile: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
									let skipVerify = (#KubeVersionDefaultValue & {#values: #config, #kubeVersion: ">= 1.22-0", #old: null, #new: true, #default: cm.serviceMonitor.insecureSkipVerify}).result
									if skipVerify != null {
										insecureSkipVerify: skipVerify
									}
									if cm.serviceMonitor.serverName != null {
										serverName: cm.serviceMonitor.serverName
									}
								}
							}
							if len(cm.serviceMonitor.metricRelabelings) > 0 {
								metricRelabelings: cm.serviceMonitor.metricRelabelings
							}
							if len(cm.serviceMonitor.relabelings) > 0 {
								relabelings: cm.serviceMonitor.relabelings
							}
						},
					]
				}
			}
		}
	}

	// 5. kubeEtcd
	if kps.kubeEtcd.enabled && kps.kubernetesServiceMonitors.enabled {
		let etcd = kps.kubeEtcd

		if len(etcd.endpoints) > 0 {
			"kube-etcd-endpoints": {
				apiVersion: "v1"
				kind:       "Endpoints"
				metadata: {
					name: "\(fullname)-kube-etcd"
					labels: amLabels & {
						app:       "\(chartName)-kube-etcd"
						"k8s-app": "etcd-server"
					}
					namespace: "kube-system"
				}
				subsets: [
					{
						addresses: [for ip in etcd.endpoints {{ip: ip}}]
						ports: [
							{
								name:     etcd.serviceMonitor.port
								port:     etcd.service.port
								protocol: "TCP"
							},
						]
					},
				]
			}
		}

		if etcd.service.enabled {
			"kube-etcd-service": {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name: "\(fullname)-kube-etcd"
					labels: amLabels & {
						app:        "\(chartName)-kube-etcd"
						"jobLabel": "kube-etcd"
					}
					namespace: "kube-system"
				}
				spec: {
					clusterIP: "None"
					if etcd.service.ipDualStack.enabled {
						ipFamilies:     etcd.service.ipDualStack.ipFamilies
						ipFamilyPolicy: etcd.service.ipDualStack.ipFamilyPolicy
					}
					ports: [
						{
							name:       etcd.serviceMonitor.port
							port:       etcd.service.port
							protocol:   "TCP"
							targetPort: etcd.service.targetPort
						},
					]
					if len(etcd.endpoints) == 0 {
						selector: {
							if len(etcd.service.selector) > 0 {
								etcd.service.selector
							}
							if len(etcd.service.selector) == 0 {
								component: "etcd"
							}
						}
					}
					type: "ClusterIP"
				}
			}
		}

		if etcd.serviceMonitor.enabled {
			"kube-etcd-servicemonitor": {
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "ServiceMonitor"
				metadata: {
					name: "\(fullname)-kube-etcd"
					if kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
						namespace: "kube-system"
					}
					if !kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
						namespace: amNamespace
					}
					labels: amLabels & {
						app: "\(chartName)-kube-etcd"
					}
					if len(etcd.serviceMonitor.additionalLabels) > 0 {
						annotations: etcd.serviceMonitor.additionalLabels
					}
				}
				spec: {
					jobLabel: etcd.serviceMonitor.jobLabel
					(#ServiceMonitorScrapeLimits & {#monitor: etcd.serviceMonitor}).result
					selector: {
						if len(etcd.serviceMonitor.selector) > 0 {
							etcd.serviceMonitor.selector
						}
						if len(etcd.serviceMonitor.selector) == 0 {
							matchLabels: {
								app:     "\(chartName)-kube-etcd"
								release: #config.metadata.name
							}
						}
					}
					namespaceSelector: matchNames: ["kube-system"]
					endpoints: [
						{
							port:            etcd.serviceMonitor.port
							bearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
							if etcd.serviceMonitor.interval != "" {
								interval: etcd.serviceMonitor.interval
							}
							if etcd.serviceMonitor.proxyUrl != "" {
								proxyUrl: etcd.serviceMonitor.proxyUrl
							}
							if etcd.serviceMonitor.scheme == "https" {
								scheme: "https"
								tlsConfig: {
									if etcd.serviceMonitor.serverName != null {
										serverName: etcd.serviceMonitor.serverName
									}
									if etcd.serviceMonitor.caFile != "" {
										caFile: etcd.serviceMonitor.caFile
									}
									if etcd.serviceMonitor.certFile != "" {
										certFile: etcd.serviceMonitor.certFile
									}
									if etcd.serviceMonitor.keyFile != "" {
										keyFile: etcd.serviceMonitor.keyFile
									}
									insecureSkipVerify: etcd.serviceMonitor.insecureSkipVerify
								}
							}
							if len(etcd.serviceMonitor.metricRelabelings) > 0 {
								metricRelabelings: etcd.serviceMonitor.metricRelabelings
							}
							if len(etcd.serviceMonitor.relabelings) > 0 {
								relabelings: etcd.serviceMonitor.relabelings
							}
						},
					]
				}
			}
		}
	}

	// 6. kubeScheduler
	if kps.kubeScheduler.enabled && kps.kubernetesServiceMonitors.enabled {
		let sched = kps.kubeScheduler

		if len(sched.endpoints) > 0 {
			"kube-scheduler-endpoints": {
				apiVersion: "v1"
				kind:       "Endpoints"
				metadata: {
					name: "\(fullname)-kube-scheduler"
					labels: amLabels & {
						app:       "\(chartName)-kube-scheduler"
						"k8s-app": "kube-scheduler"
					}
					namespace: "kube-system"
				}
				subsets: [
					{
						addresses: [for ip in sched.endpoints {{ip: ip}}]
						ports: [
							{
								name: sched.serviceMonitor.port
								port: (#KubeVersionDefaultValue & {#values: #config, #kubeVersion: ">= 1.23-0", #old: 10251, #new: 10259, #default: sched.service.port}).result
								protocol: "TCP"
							},
						]
					},
				]
			}
		}

		if sched.service.enabled {
			"kube-scheduler-service": {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name: "\(fullname)-kube-scheduler"
					labels: amLabels & {
						app:        "\(chartName)-kube-scheduler"
						"jobLabel": "kube-scheduler"
					}
					namespace: "kube-system"
				}
				spec: {
					clusterIP: "None"
					if sched.service.ipDualStack.enabled {
						ipFamilies:     sched.service.ipDualStack.ipFamilies
						ipFamilyPolicy: sched.service.ipDualStack.ipFamilyPolicy
					}
					ports: [
						{
							name: sched.serviceMonitor.port
							port: (#KubeVersionDefaultValue & {#values: #config, #kubeVersion: ">= 1.23-0", #old: 10251, #new: 10259, #default: sched.service.port}).result
							protocol: "TCP"
							targetPort: (#KubeVersionDefaultValue & {#values: #config, #kubeVersion: ">= 1.23-0", #old: 10251, #new: 10259, #default: sched.service.targetPort}).result
						},
					]
					if len(sched.endpoints) == 0 {
						selector: {
							if len(sched.service.selector) > 0 {
								sched.service.selector
							}
							if len(sched.service.selector) == 0 {
								component: "kube-scheduler"
							}
						}
					}
					type: "ClusterIP"
				}
			}
		}

		if sched.serviceMonitor.enabled {
			"kube-scheduler-servicemonitor": {
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "ServiceMonitor"
				metadata: {
					name: "\(fullname)-kube-scheduler"
					if kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
						namespace: "kube-system"
					}
					if !kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
						namespace: amNamespace
					}
					labels: amLabels & {
						app: "\(chartName)-kube-scheduler"
					}
					if len(sched.serviceMonitor.additionalLabels) > 0 {
						annotations: sched.serviceMonitor.additionalLabels
					}
				}
				spec: {
					jobLabel: sched.serviceMonitor.jobLabel
					(#ServiceMonitorScrapeLimits & {#monitor: sched.serviceMonitor}).result
					selector: {
						if len(sched.serviceMonitor.selector) > 0 {
							sched.serviceMonitor.selector
						}
						if len(sched.serviceMonitor.selector) == 0 {
							matchLabels: {
								app:     "\(chartName)-kube-scheduler"
								release: #config.metadata.name
							}
						}
					}
					namespaceSelector: matchNames: ["kube-system"]
					endpoints: [
						{
							port:            sched.serviceMonitor.port
							bearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
							if sched.serviceMonitor.interval != "" {
								interval: sched.serviceMonitor.interval
							}
							if sched.serviceMonitor.proxyUrl != "" {
								proxyUrl: sched.serviceMonitor.proxyUrl
							}
							let isSecure = (#KubeVersionDefaultValue & {#values: #config, #kubeVersion: ">= 1.23-0", #old: false, #new: true, #default: sched.serviceMonitor.https}).result
							if isSecure {
								scheme: "https"
								tlsConfig: {
									caFile: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
									let skipVerify = (#KubeVersionDefaultValue & {#values: #config, #kubeVersion: ">= 1.23-0", #old: null, #new: true, #default: sched.serviceMonitor.insecureSkipVerify}).result
									if skipVerify != null {
										insecureSkipVerify: skipVerify
									}
									if sched.serviceMonitor.serverName != null {
										serverName: sched.serviceMonitor.serverName
									}
								}
							}
							if len(sched.serviceMonitor.metricRelabelings) > 0 {
								metricRelabelings: sched.serviceMonitor.metricRelabelings
							}
							if len(sched.serviceMonitor.relabelings) > 0 {
								relabelings: sched.serviceMonitor.relabelings
							}
						},
					]
				}
			}
		}
	}

	// 7. kubeProxy
	if kps.kubeProxy.enabled && kps.kubernetesServiceMonitors.enabled {
		let proxy = kps.kubeProxy

		if len(proxy.endpoints) > 0 {
			"kube-proxy-endpoints": {
				apiVersion: "v1"
				kind:       "Endpoints"
				metadata: {
					name: "\(fullname)-kube-proxy"
					labels: amLabels & {
						app: "\(chartName)-kube-proxy"
					}
					namespace: "kube-system"
				}
				subsets: [
					{
						addresses: [for ip in proxy.endpoints {{ip: ip}}]
						ports: [
							{
								name:     proxy.serviceMonitor.port
								port:     proxy.service.port
								protocol: "TCP"
							},
						]
					},
				]
			}
		}

		if proxy.service.enabled {
			"kube-proxy-service": {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name: "\(fullname)-kube-proxy"
					labels: amLabels & {
						app:        "\(chartName)-kube-proxy"
						"jobLabel": "kube-proxy"
					}
					namespace: "kube-system"
				}
				spec: {
					clusterIP: "None"
					if proxy.service.ipDualStack.enabled {
						ipFamilies:     proxy.service.ipDualStack.ipFamilies
						ipFamilyPolicy: proxy.service.ipDualStack.ipFamilyPolicy
					}
					ports: [
						{
							name:       proxy.serviceMonitor.port
							port:       proxy.service.port
							protocol:   "TCP"
							targetPort: proxy.service.targetPort
						},
					]
					if len(proxy.endpoints) == 0 {
						selector: {
							if len(proxy.service.selector) > 0 {
								proxy.service.selector
							}
							if len(proxy.service.selector) == 0 {
								"k8s-app": "kube-proxy"
							}
						}
					}
					type: "ClusterIP"
				}
			}
		}

		if proxy.serviceMonitor.enabled {
			"kube-proxy-servicemonitor": {
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "ServiceMonitor"
				metadata: {
					name: "\(fullname)-kube-proxy"
					if kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
						namespace: "kube-system"
					}
					if !kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
						namespace: amNamespace
					}
					labels: amLabels & {
						app: "\(chartName)-kube-proxy"
					}
					if len(proxy.serviceMonitor.additionalLabels) > 0 {
						annotations: proxy.serviceMonitor.additionalLabels
					}
				}
				spec: {
					jobLabel: proxy.serviceMonitor.jobLabel
					(#ServiceMonitorScrapeLimits & {#monitor: proxy.serviceMonitor}).result
					selector: {
						if len(proxy.serviceMonitor.selector) > 0 {
							proxy.serviceMonitor.selector
						}
						if len(proxy.serviceMonitor.selector) == 0 {
							matchLabels: {
								app:     "\(chartName)-kube-proxy"
								release: #config.metadata.name
							}
						}
					}
					namespaceSelector: matchNames: ["kube-system"]
					endpoints: [
						{
							port: proxy.serviceMonitor.port
							if proxy.serviceMonitor.interval != "" {
								interval: proxy.serviceMonitor.interval
							}
							if proxy.serviceMonitor.proxyUrl != "" {
								proxyUrl: proxy.serviceMonitor.proxyUrl
							}
							if proxy.serviceMonitor.https {
								scheme: "https"
								tlsConfig: {
									caFile: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
								}
							}
							if len(proxy.serviceMonitor.metricRelabelings) > 0 {
								metricRelabelings: proxy.serviceMonitor.metricRelabelings
							}
							if len(proxy.serviceMonitor.relabelings) > 0 {
								relabelings: proxy.serviceMonitor.relabelings
							}
						},
					]
				}
			}
		}
	}

	// 8. kubeDns
	if kps.kubeDns.enabled && kps.kubernetesServiceMonitors.enabled {
		let kubedns = kps.kubeDns

		if kubedns.service.enabled {
			"kubedns-service": {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name: "\(fullname)-kube-dns"
					labels: amLabels & {
						app:        "\(chartName)-kube-dns"
						"jobLabel": "kube-dns"
					}
					namespace: "kube-system"
				}
				spec: {
					clusterIP: "None"
					if kubedns.service.ipDualStack.enabled {
						ipFamilies:     kubedns.service.ipDualStack.ipFamilies
						ipFamilyPolicy: kubedns.service.ipDualStack.ipFamilyPolicy
					}
					ports: [
						{
							name:       "http-metrics-dnsmasq"
							port:       kubedns.service.dnsmasq.port
							protocol:   "TCP"
							targetPort: kubedns.service.dnsmasq.targetPort
						},
						{
							name:       "http-metrics-skydns"
							port:       kubedns.service.skydns.port
							protocol:   "TCP"
							targetPort: kubedns.service.skydns.targetPort
						},
					]
					selector: {
						if len(kubedns.service.selector) > 0 {
							kubedns.service.selector
						}
						if len(kubedns.service.selector) == 0 {
							"k8s-app": "kube-dns"
						}
					}
				}
			}
		}

		"kubedns-servicemonitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {
				name: "\(fullname)-kube-dns"
				if kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
					namespace: "kube-system"
				}
				if !kps.prometheus.prometheusSpec.ignoreNamespaceSelectors {
					namespace: amNamespace
				}
				labels: amLabels & {
					app: "\(chartName)-kube-dns"
				}
				if len(kubedns.serviceMonitor.additionalLabels) > 0 {
					annotations: kubedns.serviceMonitor.additionalLabels
				}
			}
			spec: {
				jobLabel: kubedns.serviceMonitor.jobLabel
				(#ServiceMonitorScrapeLimits & {#monitor: kubedns.serviceMonitor}).result
				selector: {
					if len(kubedns.serviceMonitor.selector) > 0 {
						kubedns.serviceMonitor.selector
					}
					if len(kubedns.serviceMonitor.selector) == 0 {
						matchLabels: {
							app:     "\(chartName)-kube-dns"
							release: #config.metadata.name
						}
					}
				}
				namespaceSelector: matchNames: ["kube-system"]
				endpoints: [
					{
						port:            "http-metrics-dnsmasq"
						bearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
						if kubedns.serviceMonitor.interval != "" {
							interval: kubedns.serviceMonitor.interval
						}
						if kubedns.serviceMonitor.proxyUrl != "" {
							proxyUrl: kubedns.serviceMonitor.proxyUrl
						}
						if len(kubedns.serviceMonitor.dnsmasqMetricRelabelings) > 0 {
							metricRelabelings: kubedns.serviceMonitor.dnsmasqMetricRelabelings
						}
						if len(kubedns.serviceMonitor.dnsmasqRelabelings) > 0 {
							relabelings: kubedns.serviceMonitor.dnsmasqRelabelings
						}
					},
					{
						port:            "http-metrics-skydns"
						bearerTokenFile: "/var/run/secrets/kubernetes.io/serviceaccount/token"
						if kubedns.serviceMonitor.interval != "" {
							interval: kubedns.serviceMonitor.interval
						}
						if len(kubedns.serviceMonitor.metricRelabelings) > 0 {
							metricRelabelings: kubedns.serviceMonitor.metricRelabelings
						}
						if len(kubedns.serviceMonitor.relabelings) > 0 {
							relabelings: kubedns.serviceMonitor.relabelings
						}
					},
				]
			}
		}
	}
}
