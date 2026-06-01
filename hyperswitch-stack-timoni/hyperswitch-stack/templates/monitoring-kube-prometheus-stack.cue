package templates

import (
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	"list"
)

monitoringPrometheus: {
	#config: #Config
	let mon = #config."hyperswitch-monitoring"
	let kps = mon."kube-prometheus-stack"
	let promValues = kps.prometheus
	let fullname = (#KubePrometheusStackFullname & {#config: #config}).result
	let chartName = (#KubePrometheusStackName & {#config: #config}).result
	let amLabels = (#KubePrometheusStackLabels & {#config: #config}).result
	let amNamespace = [if kps.namespaceOverride != "" {kps.namespaceOverride}, #config.metadata.namespace][0]
	let promNamespace = amNamespace

	// 1. additionalAlertRelabelConfigs.yaml
	if promValues.monitor.enabled && promValues.prometheusSpec.additionalAlertRelabelConfigs != _|_ {
		"prometheus-am-relabel-confg": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(fullname)-prometheus-am-relabel-confg"
				namespace: promNamespace
				if len(promValues.prometheusSpec.additionalPrometheusSecretsAnnotations) > 0 {
					annotations: promValues.prometheusSpec.additionalPrometheusSecretsAnnotations
				}
				labels: amLabels & {
					app: "\(chartName)-prometheus-am-relabel-confg"
				}
			}
			stringData: "additional-alert-relabel-configs.yaml": [if promValues.prometheusSpec.additionalAlertRelabelConfigs != _|_ {promValues.prometheusSpec.additionalAlertRelabelConfigs}, ""][0]
		}
	}

	// 2. additionalAlertmanagerConfigs.yaml
	if promValues.monitor.enabled && promValues.prometheusSpec.additionalAlertManagerConfigs != _|_ {
		"prometheus-am-confg": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(fullname)-prometheus-am-confg"
				namespace: promNamespace
				if len(promValues.prometheusSpec.additionalPrometheusSecretsAnnotations) > 0 {
					annotations: promValues.prometheusSpec.additionalPrometheusSecretsAnnotations
				}
				labels: amLabels & {
					app: "\(chartName)-prometheus-am-confg"
				}
			}
			stringData: "additional-alertmanager-configs.yaml": [if promValues.prometheusSpec.additionalAlertManagerConfigs != _|_ {promValues.prometheusSpec.additionalAlertManagerConfigs}, ""][0]
		}
	}

	// 3. additionalPrometheusRules.yaml
	if len(mon.additionalPrometheusRules) > 0 || len(mon.additionalPrometheusRulesMap) > 0 {
		"additional-prometheus-rules": {
			apiVersion: "v1"
			kind:       "List"
			metadata: {
				name:      "\(fullname)-additional-prometheus-rules"
				namespace: promNamespace
			}
			items: [
				if len(mon.additionalPrometheusRulesMap) > 0 {
					for ruleName, rule in mon.additionalPrometheusRulesMap {
						{
							apiVersion: "monitoring.coreos.com/v1"
							kind:       "PrometheusRule"
							metadata: {
								name:      "\(chartName)-\(ruleName)"
								namespace: promNamespace
								labels: amLabels & {
									app: chartName
								} & rule.additionalLabels
							}
							spec: groups: rule.groups
						}
					}
				},
				if len(mon.additionalPrometheusRulesMap) == 0 && len(mon.additionalPrometheusRules) > 0 {
					for rule in mon.additionalPrometheusRules {
						{
							apiVersion: "monitoring.coreos.com/v1"
							kind:       "PrometheusRule"
							metadata: {
								name:      "\(chartName)-\(rule.name)"
								namespace: promNamespace
								labels: amLabels & {
									app: chartName
								} & rule.additionalLabels
							}
							spec: groups: rule.groups
						}
					}
				},
			]
		}
	}

	// 4. additionalScrapeConfigs.yaml
	if promValues.monitor.enabled && promValues.prometheusSpec.additionalScrapeConfigs != _|_ {
		"prometheus-scrape-confg": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(fullname)-prometheus-scrape-confg"
				namespace: promNamespace
				if len(promValues.prometheusSpec.additionalPrometheusSecretsAnnotations) > 0 {
					annotations: promValues.prometheusSpec.additionalPrometheusSecretsAnnotations
				}
				labels: amLabels & {
					app: "\(chartName)-prometheus-scrape-confg"
				}
			}
			stringData: "additional-scrape-configs.yaml": [if promValues.prometheusSpec.additionalScrapeConfigs != _|_ {promValues.prometheusSpec.additionalScrapeConfigs}, ""][0]
		}
	}

	// 5. ciliumnetworkpolicy.yaml
	if promValues.monitor.enabled && promValues.networkPolicy.enabled && promValues.networkPolicy.flavor == "cilium" {
		"prometheus-cilium-networkpolicy": {
			apiVersion: "cilium.io/v2"
			kind:       "CiliumNetworkPolicy"
			metadata: {
				name:      "\(fullname)-prometheus"
				namespace: promNamespace
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
			spec: {
				endpointSelector: {
					if len(promValues.networkPolicy.cilium.endpointSelector) > 0 {
						promValues.networkPolicy.cilium.endpointSelector
					}
					if len(promValues.networkPolicy.cilium.endpointSelector) == 0 {
						matchExpressions: [
							{key: "app.kubernetes.io/name", operator: "In", values: ["prometheus"]},
							{key: "prometheus", operator: "In", values: ["\(fullname)-prometheus"]},
						]
					}
				}
				if len(promValues.networkPolicy.cilium.egress) > 0 {
					egress: promValues.networkPolicy.cilium.egress
				}
				if len(promValues.networkPolicy.cilium.ingress) > 0 {
					ingress: promValues.networkPolicy.cilium.ingress
				}
			}
		}
	}

	// 6. clusterrole.yaml
	if promValues.monitor.enabled && mon.global.rbac.create {
		"prometheus-clusterrole": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: {
				name: "\(fullname)-prometheus"
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
			rules: [
				{
					apiGroups: [""]
					resources: ["nodes", "nodes/metrics", "services", "endpoints", "pods"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: [""]
					resources: ["configmaps"]
					verbs: ["get"]
				},
				{
					apiGroups: ["networking.k8s.io"]
					resources: ["ingresses"]
					verbs: ["get", "list", "watch"]
				},
				{
					nonResourceURLs: ["/metrics", "/metrics/cadvisor"]
					verbs: ["get"]
				},
			]
		}
	}

	// 7. clusterrolebinding.yaml
	if promValues.monitor.enabled && mon.global.rbac.create {
		"prometheus-clusterrolebinding": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: {
				name: "\(fullname)-prometheus"
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(fullname)-prometheus"
			}
			subjects: [
				{
					kind: "ServiceAccount"
					name: [if promValues.serviceAccount.name != "" {promValues.serviceAccount.name}, "\(fullname)-prometheus"][0]
					namespace: promNamespace
				},
			]
		}
	}

	// 8. csi-secret.yaml
	if promValues.monitor.enabled && promValues.prometheusSpec.csi != _|_ {
		"prometheus-csi-secret": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(fullname)-prometheus-csi-secret"
				namespace: promNamespace
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
			if promValues.prometheusSpec.csi.data != _|_ {
				data: promValues.prometheusSpec.csi.data
			}
		}
	}

	// 9. extrasecret.yaml
	if promValues.monitor.enabled && len(promValues.extraSecrets) > 0 {
		for s in promValues.extraSecrets {
			"prometheus-extra-secret-\(s.name)": corev1.#Secret & {
				apiVersion: "v1"
				kind:       "Secret"
				metadata: {
					name:      s.name
					namespace: promNamespace
					labels: amLabels & s.labels & {
						app: "\(chartName)-prometheus"
					}
					if len(s.annotations) > 0 {
						annotations: s.annotations
					}
				}
				data: s.data
			}
		}
	}

	// 10. ingress.yaml
	if promValues.monitor.enabled && promValues.ingress.enabled {
		"prometheus-ingress": {
			apiVersion: [if promValues.ingress.apiVersion != "" {promValues.ingress.apiVersion}, "networking.k8s.io/v1"][0]
			kind: "Ingress"
			metadata: {
				name:      "\(fullname)-prometheus"
				namespace: promNamespace
				labels: amLabels & promValues.ingress.labels & {
					app: "\(chartName)-prometheus"
				}
				if len(promValues.ingress.annotations) > 0 {
					annotations: promValues.ingress.annotations
				}
			}
			spec: {
				if promValues.ingress.ingressClassName != "" {
					ingressClassName: promValues.ingress.ingressClassName
				}
				if len(promValues.ingress.tls) > 0 {
					tls: [
						for t in promValues.ingress.tls {
							{
								hosts: t.hosts
								if t.secretName != "" {
									secretName: t.secretName
								}
							}
						},
					]
				}
				rules: [
					for h in promValues.ingress.hosts {
						{
							host: h
							http: paths: [
								{
									path:     promValues.prometheusSpec.routePrefix
									pathType: promValues.ingress.pathType
									backend: service: {
										name: "\(fullname)-prometheus"
										port: number: promValues.service.port
									}
								},
							]
						}
					},
				]
			}
		}
	}

	// 11. ingressThanosSidecar.yaml
	if promValues.monitor.enabled && promValues.thanosIngress.enabled {
		"prometheus-thanos-ingress": {
			apiVersion: [if promValues.thanosIngress.apiVersion != "" {promValues.thanosIngress.apiVersion}, "networking.k8s.io/v1"][0]
			kind: "Ingress"
			metadata: {
				name:      "\(fullname)-prometheus-thanos"
				namespace: promNamespace
				labels: amLabels & promValues.thanosIngress.labels & {
					app: "\(chartName)-prometheus"
				}
				if len(promValues.thanosIngress.annotations) > 0 {
					annotations: promValues.thanosIngress.annotations
				}
			}
			spec: {
				if promValues.thanosIngress.ingressClassName != "" {
					ingressClassName: promValues.thanosIngress.ingressClassName
				}
				if len(promValues.thanosIngress.tls) > 0 {
					tls: [
						for t in promValues.thanosIngress.tls {
							{
								hosts: t.hosts
								if t.secretName != "" {
									secretName: t.secretName
								}
							}
						},
					]
				}
				rules: [
					for h in promValues.thanosIngress.hosts {
						{
							host: h
							http: paths: [
								{
									path:     promValues.thanosIngress.path
									pathType: promValues.thanosIngress.pathType
									backend: service: {
										name: "\(fullname)-prometheus-thanos"
										port: number: promValues.thanosIngress.servicePort
									}
								},
							]
						}
					},
				]
			}
		}
	}

	// 12. ingressperreplica.yaml
	if promValues.monitor.enabled && promValues.servicePerReplica.enabled && promValues.ingressPerReplica.enabled {
		"prometheus-ingress-per-replica": {
			apiVersion: "v1"
			kind:       "List"
			metadata: {
				name:      "\(fullname)-prometheus-ingressperreplica"
				namespace: promNamespace
			}
			items: [
				for i in [for x in list.Range(0, promValues.prometheusSpec.replicas, 1) {x}] {
					{
						kind: "Ingress"
						apiVersion: [if promValues.ingressPerReplica.apiVersion != "" {promValues.ingressPerReplica.apiVersion}, "networking.k8s.io/v1"][0]
						metadata: {
							name:      "\(fullname)-prometheus-\(i)"
							namespace: promNamespace
							labels: amLabels & promValues.ingressPerReplica.labels & {
								app: "\(chartName)-prometheus"
							}
							if len(promValues.ingressPerReplica.annotations) > 0 {
								annotations: promValues.ingressPerReplica.annotations
							}
						}
						spec: {
							if promValues.ingressPerReplica.ingressClassName != "" {
								ingressClassName: promValues.ingressPerReplica.ingressClassName
							}
							rules: [
								{
									host: "\(promValues.ingressPerReplica.hostPrefix)-\(i).\(promValues.ingressPerReplica.hostDomain)"
									http: paths: [
										for p in promValues.ingressPerReplica.paths {
											{
												path:     p
												pathType: promValues.ingressPerReplica.pathType
												backend: service: {
													name: "\(fullname)-prometheus-\(i)"
													port: number: promValues.servicePerReplica.port
												}
											}
										},
									]
								},
							]
							if promValues.ingressPerReplica.tlsSecretName != "" || promValues.ingressPerReplica.tlsSecretPerReplica.enabled {
								tls: [
									{
										hosts: ["\(promValues.ingressPerReplica.hostPrefix)-\(i).\(promValues.ingressPerReplica.hostDomain)"]
										secretName: [if promValues.ingressPerReplica.tlsSecretPerReplica.enabled {"\(promValues.ingressPerReplica.tlsSecretPerReplica.prefix)-\(i)"}, promValues.ingressPerReplica.tlsSecretName][0]
									},
								]
							}
						}
					}
				},
			]
		}
	}

	// 13. networkpolicy.yaml
	if promValues.monitor.enabled && promValues.networkPolicy.enabled && promValues.networkPolicy.flavor == "kubernetes" {
		"prometheus-networkpolicy": {
			apiVersion: "networking.k8s.io/v1"
			kind:       "NetworkPolicy"
			metadata: {
				name:      "\(fullname)-prometheus"
				namespace: promNamespace
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
			spec: {
				podSelector: matchLabels: {
					"app.kubernetes.io/name": "prometheus"
					prometheus:               "\(fullname)-prometheus"
				}
				policyTypes: ["Ingress", "Egress"]
				ingress: promValues.networkPolicy.ingress
				egress:  promValues.networkPolicy.egress
			}
		}
	}

	// 14. podDisruptionBudget.yaml
	if promValues.monitor.enabled && promValues.podDisruptionBudget.enabled {
		"prometheus-pdb": {
			apiVersion: "policy/v1"
			kind:       "PodDisruptionBudget"
			metadata: {
				name:      "\(fullname)-prometheus"
				namespace: promNamespace
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
			spec: {
				if promValues.podDisruptionBudget.minAvailable != _|_ {
					minAvailable: promValues.podDisruptionBudget.minAvailable
				}
				if promValues.podDisruptionBudget.maxUnavailable != _|_ {
					maxUnavailable: promValues.podDisruptionBudget.maxUnavailable
				}
				selector: matchLabels: {
					"app.kubernetes.io/name": "prometheus"
					prometheus:               "\(fullname)-prometheus"
				}
			}
		}
	}

	// 15. podmonitors.yaml
	if promValues.monitor.enabled && len(promValues.additionalPodMonitors) > 0 {
		for pm in promValues.additionalPodMonitors {
			"prometheus-additional-pm-\(pm.name)": {
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "PodMonitor"
				metadata: {
					name:      pm.name
					namespace: promNamespace
					labels: amLabels & pm.additionalLabels & {
						app: "\(chartName)-prometheus"
					}
				}
				spec: pm
			}
		}
	}

	// 16. prometheus.yaml
	if promValues.enabled {
		"prometheus-instance": {
			apiVersion: [if promValues.agentMode {"monitoring.coreos.com/v1alpha1"}, "monitoring.coreos.com/v1"][0]
			kind: [if promValues.agentMode {"PrometheusAgent"}, "Prometheus"][0]
			metadata: {
				name:      "\(fullname)-prometheus"
				namespace: promNamespace
				labels: amLabels & promValues.labels & {
					app: "\(chartName)-prometheus"
				}
				if len(promValues.annotations) > 0 {
					annotations: promValues.annotations
				}
			}
			spec: {
				automountServiceAccountToken: promValues.prometheusSpec.automountServiceAccountToken
				if !promValues.agentMode && (promValues.prometheusSpec.alertingEndpoints != _|_ || mon."kube-prometheus-stack".alertmanager.enabled) {
					alerting: alertmanagers: [
						if promValues.prometheusSpec.alertingEndpoints != _|_ {
							for ep in promValues.prometheusSpec.alertingEndpoints {ep}
						},
						if promValues.prometheusSpec.alertingEndpoints == _|_ && mon."kube-prometheus-stack".alertmanager.enabled {
							{
								namespace: promNamespace
								name:      "\(fullname)-alertmanager"
								port:      mon."kube-prometheus-stack".alertmanager.alertmanagerSpec.portName
								if mon."kube-prometheus-stack".alertmanager.alertmanagerSpec.routePrefix != "" {
									pathPrefix: mon."kube-prometheus-stack".alertmanager.alertmanagerSpec.routePrefix
								}
								if mon."kube-prometheus-stack".alertmanager.alertmanagerSpec.scheme != "" {
									scheme: mon."kube-prometheus-stack".alertmanager.alertmanagerSpec.scheme
								}
								if mon."kube-prometheus-stack".alertmanager.alertmanagerSpec.tlsConfig != _|_ {
									tlsConfig: mon."kube-prometheus-stack".alertmanager.alertmanagerSpec.tlsConfig
								}
								apiVersion: mon."kube-prometheus-stack".alertmanager.apiVersion
							}
						},
					]
				}
				if promValues.prometheusSpec.apiserverConfig != _|_ {
					apiserverConfig: promValues.prometheusSpec.apiserverConfig
				}
				if promValues.prometheusSpec.image != _|_ {
					image:   "\(promValues.prometheusSpec.image.registry)/\(promValues.prometheusSpec.image.repository):\(promValues.prometheusSpec.image.tag)"
					version: promValues.prometheusSpec.image.tag
				}
				if promValues.prometheusSpec.additionalArgs != _|_ {
					additionalArgs: promValues.prometheusSpec.additionalArgs
				}
				if promValues.prometheusSpec.externalLabels != _|_ {
					externalLabels: promValues.prometheusSpec.externalLabels
				}
				if promValues.prometheusSpec.prometheusExternalLabelNameClear {
					prometheusExternalLabelName: ""
				}
				if !promValues.prometheusSpec.prometheusExternalLabelNameClear && promValues.prometheusSpec.prometheusExternalLabelName != "" {
					prometheusExternalLabelName: promValues.prometheusSpec.prometheusExternalLabelName
				}
				if promValues.prometheusSpec.replicaExternalLabelNameClear {
					replicaExternalLabelName: ""
				}
				if !promValues.prometheusSpec.replicaExternalLabelNameClear && promValues.prometheusSpec.replicaExternalLabelName != "" {
					replicaExternalLabelName: promValues.prometheusSpec.replicaExternalLabelName
				}
				if promValues.prometheusSpec.enableRemoteWriteReceiver != _|_ {
					enableRemoteWriteReceiver: promValues.prometheusSpec.enableRemoteWriteReceiver
				}
				if promValues.prometheusSpec.externalUrl != "" {
					externalUrl: promValues.prometheusSpec.externalUrl
				}
				if promValues.prometheusSpec.externalUrl == "" {
					if promValues.ingress.enabled && len(promValues.ingress.hosts) > 0 {
						externalUrl: "http://\(promValues.ingress.hosts[0])\(promValues.prometheusSpec.routePrefix)"
					}
					if !promValues.ingress.enabled || len(promValues.ingress.hosts) == 0 {
						externalUrl: "http://\(fullname)-prometheus.\(promNamespace):\(promValues.service.port)"
					}
				}
				if promValues.prometheusSpec.nodeSelector != _|_ {
					nodeSelector: promValues.prometheusSpec.nodeSelector
				}
				paused:      promValues.prometheusSpec.paused
				replicas:    promValues.prometheusSpec.replicas
				shards:      promValues.prometheusSpec.shards
				logLevel:    promValues.prometheusSpec.logLevel
				logFormat:   promValues.prometheusSpec.logFormat
				listenLocal: promValues.prometheusSpec.listenLocal
				if !promValues.agentMode {
					enableAdminAPI: promValues.prometheusSpec.enableAdminAPI
				}
				if promValues.prometheusSpec.web != _|_ {
					web: promValues.prometheusSpec.web
				}
				if !promValues.agentMode && promValues.prometheusSpec.exemplars != _|_ {
					exemplars: promValues.prometheusSpec.exemplars
				}
				if len(promValues.prometheusSpec.enableFeatures) > 0 {
					enableFeatures: promValues.prometheusSpec.enableFeatures
				}
				if promValues.prometheusSpec.scrapeClasses != _|_ {
					scrapeClasses: promValues.prometheusSpec.scrapeClasses
				}
				if promValues.prometheusSpec.scrapeInterval != "" {
					scrapeInterval: promValues.prometheusSpec.scrapeInterval
				}
				if promValues.prometheusSpec.scrapeTimeout != "" {
					scrapeTimeout: promValues.prometheusSpec.scrapeTimeout
				}
				if !promValues.agentMode && promValues.prometheusSpec.evaluationInterval != "" {
					evaluationInterval: promValues.prometheusSpec.evaluationInterval
				}
				if promValues.prometheusSpec.resources != _|_ {
					resources: promValues.prometheusSpec.resources
				}
				if !promValues.agentMode {
					retention: promValues.prometheusSpec.retention
					if promValues.prometheusSpec.retentionSize != "" {
						retentionSize: promValues.prometheusSpec.retentionSize
					}
					if promValues.prometheusSpec.tsdb != _|_ {
						tsdb: promValues.prometheusSpec.tsdb
					}
				}
				walCompression: promValues.prometheusSpec.walCompression
				if promValues.prometheusSpec.routePrefix != "" {
					routePrefix: promValues.prometheusSpec.routePrefix
				}
				if len(promValues.prometheusSpec.secrets) > 0 {
					secrets: promValues.prometheusSpec.secrets
				}
				if len(promValues.prometheusSpec.configMaps) > 0 {
					configMaps: promValues.prometheusSpec.configMaps
				}
				serviceAccountName: [if promValues.serviceAccount.name != "" {promValues.serviceAccount.name}, "\(fullname)-prometheus"][0]
				serviceMonitorSelector: [if promValues.prometheusSpec.serviceMonitorSelector != _|_ {promValues.prometheusSpec.serviceMonitorSelector}, {}][0]
				serviceMonitorNamespaceSelector: [if promValues.prometheusSpec.serviceMonitorNamespaceSelector != _|_ {promValues.prometheusSpec.serviceMonitorNamespaceSelector}, {}][0]
				podMonitorSelector: [if promValues.prometheusSpec.podMonitorSelector != _|_ {promValues.prometheusSpec.podMonitorSelector}, {}][0]
				podMonitorNamespaceSelector: [if promValues.prometheusSpec.podMonitorNamespaceSelector != _|_ {promValues.prometheusSpec.podMonitorNamespaceSelector}, {}][0]
				probeSelector: [if promValues.prometheusSpec.probeSelector != _|_ {promValues.prometheusSpec.probeSelector}, {}][0]
				probeNamespaceSelector: [if promValues.prometheusSpec.probeNamespaceSelector != _|_ {promValues.prometheusSpec.probeNamespaceSelector}, {}][0]
				if !promValues.agentMode && (promValues.prometheusSpec.remoteRead != _|_ || promValues.prometheusSpec.additionalRemoteRead != _|_ ) {
					remoteRead: [
						if promValues.prometheusSpec.remoteRead != _|_ {
							for rr in promValues.prometheusSpec.remoteRead {rr}
						},
						if promValues.prometheusSpec.additionalRemoteRead != _|_ {
							for arr in promValues.prometheusSpec.additionalRemoteRead {arr}
						},
					]
				}
				if promValues.prometheusSpec.remoteWrite != _|_ || promValues.prometheusSpec.additionalRemoteWrite != _|_ {
					remoteWrite: [
						if promValues.prometheusSpec.remoteWrite != _|_ {
							for rw in promValues.prometheusSpec.remoteWrite {rw}
						},
						if promValues.prometheusSpec.additionalRemoteWrite != _|_ {
							for arw in promValues.prometheusSpec.additionalRemoteWrite {arw}
						},
					]
				}
				if promValues.prometheusSpec.securityContext != _|_ {
					securityContext: promValues.prometheusSpec.securityContext
				}
				if !promValues.agentMode {
					ruleNamespaceSelector: [if promValues.prometheusSpec.ruleNamespaceSelector != _|_ {promValues.prometheusSpec.ruleNamespaceSelector}, {}][0]
					ruleSelector: [if promValues.prometheusSpec.ruleSelector != _|_ {promValues.prometheusSpec.ruleSelector}, {}][0]
				}
				scrapeConfigSelector: [if promValues.prometheusSpec.scrapeConfigSelector != _|_ {promValues.prometheusSpec.scrapeConfigSelector}, {}][0]
				scrapeConfigNamespaceSelector: [if promValues.prometheusSpec.scrapeConfigNamespaceSelector != _|_ {promValues.prometheusSpec.scrapeConfigNamespaceSelector}, {}][0]
				if promValues.prometheusSpec.storageSpec != _|_ {
					storage: promValues.prometheusSpec.storageSpec
				}
				if promValues.prometheusSpec.persistentVolumeClaimRetentionPolicy != _|_ {
					persistentVolumeClaimRetentionPolicy: promValues.prometheusSpec.persistentVolumeClaimRetentionPolicy
				}
				if promValues.prometheusSpec.podMetadata != _|_ {
					podMetadata: promValues.prometheusSpec.podMetadata
				}
				if !promValues.agentMode && promValues.prometheusSpec.query != _|_ {
					query: promValues.prometheusSpec.query
				}
				if promValues.prometheusSpec.affinity != _|_ {
					affinity: promValues.prometheusSpec.affinity
				}
				if promValues.prometheusSpec.tolerations != _|_ {
					tolerations: promValues.prometheusSpec.tolerations
				}
				if promValues.prometheusSpec.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: promValues.prometheusSpec.topologySpreadConstraints
				}
				if promValues.prometheusSpec.additionalScrapeConfigs != _|_ {
					additionalScrapeConfigs: {
						name: "\(fullname)-prometheus-scrape-confg"
						key:  "additional-scrape-configs.yaml"
					}
				}
				if promValues.prometheusSpec.additionalScrapeConfigsSecret.enabled {
					additionalScrapeConfigs: {
						name: promValues.prometheusSpec.additionalScrapeConfigsSecret.name
						key:  promValues.prometheusSpec.additionalScrapeConfigsSecret.key
					}
				}
				if !promValues.agentMode {
					if promValues.prometheusSpec.additionalAlertManagerConfigs != _|_ {
						additionalAlertManagerConfigs: {
							name: "\(fullname)-prometheus-am-confg"
							key:  "additional-alertmanager-configs.yaml"
						}
					}
					if promValues.prometheusSpec.additionalAlertRelabelConfigs != _|_ {
						additionalAlertRelabelConfigs: {
							name: "\(fullname)-prometheus-am-relabel-confg"
							key:  "additional-alert-relabel-configs.yaml"
						}
					}
				}
				if promValues.prometheusSpec.containers != _|_ {
					containers: promValues.prometheusSpec.containers
				}
				if promValues.prometheusSpec.initContainers != _|_ {
					initContainers: promValues.prometheusSpec.initContainers
				}
				if promValues.prometheusSpec.priorityClassName != "" {
					priorityClassName: promValues.prometheusSpec.priorityClassName
				}
				if !promValues.agentMode && promValues.prometheusSpec.thanos != _|_ {
					thanos: promValues.prometheusSpec.thanos
				}
				if !promValues.agentMode && promValues.prometheusSpec.disableCompaction {
					disableCompaction: promValues.prometheusSpec.disableCompaction
				}
				portName: promValues.prometheusSpec.portName
				if len(promValues.prometheusSpec.volumes) > 0 {
					volumes: promValues.prometheusSpec.volumes
				}
				if len(promValues.prometheusSpec.volumeMounts) > 0 {
					volumeMounts: promValues.prometheusSpec.volumeMounts
				}
				if promValues.prometheusSpec.arbitraryFSAccessThroughSMs != _|_ {
					arbitraryFSAccessThroughSMs: promValues.prometheusSpec.arbitraryFSAccessThroughSMs
				}
				if promValues.prometheusSpec.overrideHonorLabels {
					overrideHonorLabels: promValues.prometheusSpec.overrideHonorLabels
				}
				if promValues.prometheusSpec.overrideHonorTimestamps {
					overrideHonorTimestamps: promValues.prometheusSpec.overrideHonorTimestamps
				}
				if promValues.prometheusSpec.ignoreNamespaceSelectors {
					ignoreNamespaceSelectors: promValues.prometheusSpec.ignoreNamespaceSelectors
				}
				if promValues.prometheusSpec.enforcedNamespaceLabel != "" {
					enforcedNamespaceLabel: promValues.prometheusSpec.enforcedNamespaceLabel
				}
				if !promValues.agentMode && promValues.prometheusSpec.queryLogFile != "" {
					queryLogFile: promValues.prometheusSpec.queryLogFile
				}
				if promValues.prometheusSpec.sampleLimit > 0 {
					sampleLimit: promValues.prometheusSpec.sampleLimit
				}
				if promValues.prometheusSpec.enforcedKeepDroppedTargets > 0 {
					enforcedKeepDroppedTargets: promValues.prometheusSpec.enforcedKeepDroppedTargets
				}
				if promValues.prometheusSpec.enforcedSampleLimit > 0 {
					enforcedSampleLimit: promValues.prometheusSpec.enforcedSampleLimit
				}
				if promValues.prometheusSpec.enforcedTargetLimit > 0 {
					enforcedTargetLimit: promValues.prometheusSpec.enforcedTargetLimit
				}
				if promValues.prometheusSpec.enforcedLabelLimit > 0 {
					enforcedLabelLimit: promValues.prometheusSpec.enforcedLabelLimit
				}
				if promValues.prometheusSpec.enforcedLabelNameLengthLimit > 0 {
					enforcedLabelNameLengthLimit: promValues.prometheusSpec.enforcedLabelNameLengthLimit
				}
				if promValues.prometheusSpec.enforcedLabelValueLengthLimit > 0 {
					enforcedLabelValueLengthLimit: promValues.prometheusSpec.enforcedLabelValueLengthLimit
				}
				if !promValues.agentMode && promValues.prometheusSpec.allowOverlappingBlocks {
					allowOverlappingBlocks: promValues.prometheusSpec.allowOverlappingBlocks
				}
				if promValues.prometheusSpec.minReadySeconds > 0 {
					minReadySeconds: promValues.prometheusSpec.minReadySeconds
				}
				if promValues.prometheusSpec.maximumStartupDurationSeconds > 0 {
					maximumStartupDurationSeconds: promValues.prometheusSpec.maximumStartupDurationSeconds
				}
				hostNetwork: promValues.prometheusSpec.hostNetwork
				if len(promValues.prometheusSpec.hostAliases) > 0 {
					hostAliases: promValues.prometheusSpec.hostAliases
				}
				if promValues.prometheusSpec.tracingConfig != _|_ {
					tracingConfig: promValues.prometheusSpec.tracingConfig
				}
				if promValues.prometheusSpec.serviceDiscoveryRole != "" {
					serviceDiscoveryRole: promValues.prometheusSpec.serviceDiscoveryRole
				}
			}
		}
	}

	// 17. psp-clusterrole.yaml
	if promValues.monitor.enabled && mon.global.rbac.create && mon.global.rbac.pspEnabled {
		"prometheus-psp-clusterrole": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: {
				name: "\(fullname)-prometheus-psp"
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
			rules: [
				{
					apiGroups: ["policy"]
					resources: ["podsecuritypolicies"]
					resourceNames: ["\(fullname)-prometheus"]
					verbs: ["use"]
				},
			]
		}
	}

	// 18. psp-clusterrolebinding.yaml
	if promValues.monitor.enabled && mon.global.rbac.create && mon.global.rbac.pspEnabled {
		"prometheus-psp-clusterrolebinding": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: {
				name: "\(fullname)-prometheus-psp"
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(fullname)-prometheus-psp"
			}
			subjects: [
				{
					kind: "ServiceAccount"
					name: [if promValues.serviceAccount.name != "" {promValues.serviceAccount.name}, "\(fullname)-prometheus"][0]
					namespace: promNamespace
				},
			]
		}
	}

	// 19. psp.yaml
	if promValues.monitor.enabled && mon.global.rbac.pspEnabled {
		"prometheus-psp": {
			apiVersion: "policy/v1beta1"
			kind:       "PodSecurityPolicy"
			metadata: {
				name: "\(fullname)-prometheus"
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
				if len(mon.global.rbac.pspAnnotations) > 0 {
					annotations: mon.global.rbac.pspAnnotations
				}
			}
			spec: {
				privileged: false
				volumes: ["configMap", "emptyDir", "projected", "secret", "persistentVolumeClaim"]
				allowPrivilegeEscalation: false
				hostNetwork:              promValues.prometheusSpec.hostNetwork
				hostIPC:                  false
				hostPID:                  false
				runAsUser: rule:          "RunAsAny"
				seLinux: rule:            "RunAsAny"
				supplementalGroups: rule: "MustRunAs"
				supplementalGroups: ranges: [{min: 1, max: 65535}]
				fsGroup: rule: "MustRunAs"
				fsGroup: ranges: [{min: 1, max: 65535}]
				readOnlyRootFilesystem: false
			}
		}
	}

	// 20. secret.yaml
	if promValues.monitor.enabled && promValues.prometheusSpec.thanos != _|_ && promValues.prometheusSpec.thanos.objectStorageConfig != _|_ && promValues.prometheusSpec.thanos.objectStorageConfig.secret != _|_ {
		"prometheus-thanos-objstore-secret": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(fullname)-prometheus"
				namespace: promNamespace
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
			stringData: "object-storage-configs.yaml": promValues.prometheusSpec.thanos.objectStorageConfig.secret
		}
	}

	// 21. service.yaml
	if promValues.enabled {
		"prometheus-service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(fullname)-prometheus"
				namespace: promNamespace
				labels: amLabels & promValues.service.labels & {
					app:                           "\(chartName)-prometheus"
					"app.kubernetes.io/name":      "\(chartName)-prometheus"
					"app.kubernetes.io/component": "prometheus"
					"self-monitor":                "\(promValues.serviceMonitor.selfMonitor)"
				}
				if len(promValues.service.annotations) > 0 {
					annotations: promValues.service.annotations
				}
			}
			spec: {
				ports: [
					{
						name:       promValues.prometheusSpec.portName
						port:       promValues.service.port
						targetPort: promValues.service.targetPort
						protocol:   "TCP"
					},
					{
						name:       "reloader-web"
						port:       promValues.service.reloaderWebPort
						targetPort: "reloader-web"
					},
				]
				selector: {
					"app.kubernetes.io/name": "prometheus"
					prometheus:               "\(fullname)-prometheus"
				}
				type: promValues.service.type
			}
		}
	}

	// 22. serviceThanosSidecar.yaml
	if promValues.monitor.enabled && promValues.prometheusSpec.thanos != _|_ {
		"prometheus-thanos-service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(fullname)-prometheus-thanos"
				namespace: promNamespace
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
			spec: {
				ports: [{name: "grpc", port: promValues.thanosIngress.servicePort, targetPort: promValues.thanosIngress.servicePort}]
				selector: {
					"app.kubernetes.io/name": "prometheus"
					prometheus:               "\(fullname)-prometheus"
				}
			}
		}
	}

	// 23. serviceThanosSidecarExternal.yaml
	if promValues.monitor.enabled && promValues.prometheusSpec.thanos != _|_ && promValues.thanosServiceExternal.enabled {
		"prometheus-thanos-service-external": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(fullname)-prometheus-thanos-external"
				namespace: promNamespace
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
			spec: {
				ports: [{name: "grpc", port: promValues.thanosServiceExternal.servicePort, targetPort: promValues.thanosServiceExternal.servicePort}]
				selector: {
					"app.kubernetes.io/name": "prometheus"
					prometheus:               "\(fullname)-prometheus"
				}
				type: "LoadBalancer"
			}
		}
	}

	// 24. serviceaccount.yaml
	if promValues.monitor.enabled && promValues.serviceAccount.create {
		"prometheus-serviceaccount": corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name: [if promValues.serviceAccount.name != "" {promValues.serviceAccount.name}, "\(fullname)-prometheus"][0]
				namespace: promNamespace
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
		}
	}

	// 25. servicemonitor.yaml
	if promValues.monitor.enabled && promValues.serviceMonitor.selfMonitor {
		"prometheus-servicemonitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {
				name:      "\(fullname)-prometheus"
				namespace: promNamespace
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
			spec: {
				selector: matchLabels: {
					"app.kubernetes.io/name": "prometheus"
					prometheus:               "\(fullname)-prometheus"
				}
				endpoints: [{port: promValues.prometheusSpec.portName}]
			}
		}
	}

	// 26. servicemonitorThanosSidecar.yaml
	if promValues.monitor.enabled && promValues.prometheusSpec.thanos != _|_ && promValues.thanosIngress.enabled {
		"prometheus-thanos-servicemonitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {
				name:      "\(fullname)-prometheus-thanos"
				namespace: promNamespace
				labels: amLabels & {
					app: "\(chartName)-prometheus"
				}
			}
			spec: {
				selector: matchLabels: {
					"app.kubernetes.io/name": "prometheus"
					prometheus:               "\(fullname)-prometheus"
				}
				endpoints: [{port: "grpc"}]
			}
		}
	}

	// 27. servicemonitors.yaml
	if promValues.monitor.enabled && len(promValues.additionalServiceMonitors) > 0 {
		for sm in promValues.additionalServiceMonitors {
			"prometheus-additional-sm-\(sm.name)": {
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "ServiceMonitor"
				metadata: {
					name:      sm.name
					namespace: promNamespace
					labels: amLabels & sm.additionalLabels & {
						app: "\(chartName)-prometheus"
					}
				}
				spec: sm
			}
		}
	}

	// 28. serviceperreplica.yaml
	if promValues.monitor.enabled && promValues.servicePerReplica.enabled {
		"prometheus-service-per-replica": {
			apiVersion: "v1"
			kind:       "List"
			metadata: {
				name:      "\(fullname)-prometheus-serviceperreplica"
				namespace: promNamespace
			}
			items: [
				for i in [for x in list.Range(0, promValues.prometheusSpec.replicas, 1) {x}] {
					{
						kind:       "Service"
						apiVersion: "v1"
						metadata: {
							name:      "\(fullname)-prometheus-\(i)"
							namespace: promNamespace
							labels: amLabels & promValues.servicePerReplica.labels & {
								app: "\(chartName)-prometheus"
							}
						}
						spec: {
							ports: [{name: promValues.prometheusSpec.portName, port: promValues.servicePerReplica.port, targetPort: promValues.servicePerReplica.port}]
							selector: {
								"app.kubernetes.io/name":             "prometheus"
								prometheus:                           "\(fullname)-prometheus"
								"statefulset.kubernetes.io/pod-name": "\(fullname)-prometheus-\(i)"
							}
						}
					}
				},
			]
		}
	}
}
