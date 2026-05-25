package templates

import (
	"list"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
)

#KubePrometheusStackName: {
	#config: #Config
	let kps = #config."hyperswitch-monitoring"."kube-prometheus-stack"
	result: [if kps.nameOverride != "" {kps.nameOverride}, "kps"][0]
}

#KubePrometheusStackFullname: {
	#config: #Config
	let kps = #config."hyperswitch-monitoring"."kube-prometheus-stack"
	let name = (#KubePrometheusStackName & {#config: #config}).result
	result: [if kps.fullnameOverride != "" {kps.fullnameOverride}, "\(#config.metadata.name)-\(name)"][0]
}

#KubePrometheusStackTruncatedName: {
	#name:  string
	result: #name
}

#KubePrometheusStackLabels: {
	#config: #Config
	let kps = #config."hyperswitch-monitoring"."kube-prometheus-stack"
	result: kps.commonLabels & {
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/instance":   #config.metadata.name
		"app.kubernetes.io/version":    "65.1.1"
		"app.kubernetes.io/part-of": (#KubePrometheusStackName & {#config: #config}).result
		chart:    "kube-prometheus-stack-65.1.1"
		release:  #config.metadata.name
		heritage: "timoni"
	}
}

#KubePrometheusStackAlertmanagerCrName: {
	#config: #Config
	let kps = #config."hyperswitch-monitoring"."kube-prometheus-stack"
	let fullname = (#KubePrometheusStackFullname & {#config: #config}).result
	result: [if kps.cleanPrometheusOperatorObjectNames {fullname}, "hps-am"][0]
}

#KubePrometheusStackAlertmanagerServiceAccountName: {
	#config: #Config
	let am = #config."hyperswitch-monitoring"."kube-prometheus-stack".alertmanager
	let fullname = (#KubePrometheusStackFullname & {#config: #config}).result
	result: string
	if am.serviceAccount.create && am.serviceAccount.name != "" {result: am.serviceAccount.name}
	if am.serviceAccount.create && am.serviceAccount.name == "" {result: "\(fullname)-alertmanager"}
	if !am.serviceAccount.create && am.serviceAccount.name != "" {result: am.serviceAccount.name}
	if !am.serviceAccount.create && am.serviceAccount.name == "" {result: "default"}
}

#KubePrometheusStackAlertmanagerImage: {
	#config: #Config
	let mon = #config."hyperswitch-monitoring"
	let img = mon."kube-prometheus-stack".alertmanager.alertmanagerSpec.image
	let registry = [if mon.global.imageRegistry != "" {mon.global.imageRegistry}, img.registry][0]
	result: string
	if img.tag != "" && img.sha != "" {result: "\(registry)/\(img.repository):\(img.tag)@sha256:\(img.sha)"}
	if img.tag == "" && img.sha != "" {result: "\(registry)/\(img.repository)@sha256:\(img.sha)"}
	if img.tag != "" && img.sha == "" {result: "\(registry)/\(img.repository):\(img.tag)"}
	if img.tag == "" && img.sha == "" {result: "\(registry)/\(img.repository)"}
}

// Registry for kube-prometheus-stack Alertmanager rendered objects; let bindings cache shared Helm helper equivalents.
monitoringAlertmanager: {
	#config: #Config
	let mon = #config."hyperswitch-monitoring"
	let kps = mon."kube-prometheus-stack"
	let am = kps.alertmanager
	let fullname = (#KubePrometheusStackFullname & {#config: #config}).result
	let chartName = (#KubePrometheusStackName & {#config: #config}).result
	let crName = (#KubePrometheusStackAlertmanagerCrName & {#config: #config}).result
	let amNamespace = [if kps.namespaceOverride != "" {kps.namespaceOverride}, #config.metadata.namespace][0]
	let amLabels = (#KubePrometheusStackLabels & {#config: #config}).result
	let amServiceAccountName = (#KubePrometheusStackAlertmanagerServiceAccountName & {#config: #config}).result
	let serviceName = "\(fullname)-alertmanager"

	// 1. templates/alertmanager/alertmanager.yaml
	if am.enabled {
		"alertmanager": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "Alertmanager"
			metadata: {
				name:      crName
				namespace: amNamespace
				labels: amLabels & {
					app: "\(chartName)-alertmanager"
				}
				if len(am.annotations) > 0 {
					annotations: am.annotations
				}
			}
			spec: {
				if len(am.alertmanagerSpec.image) > 0 {
					image: (#KubePrometheusStackAlertmanagerImage & {#config: #config}).result
					version: [if am.alertmanagerSpec.version != "" {am.alertmanagerSpec.version}, am.alertmanagerSpec.image.tag][0]
					if am.alertmanagerSpec.image.sha != "" {
						sha: am.alertmanagerSpec.image.sha
					}
				}
				replicas:                     am.alertmanagerSpec.replicas
				listenLocal:                  am.alertmanagerSpec.listenLocal
				serviceAccountName:           amServiceAccountName
				automountServiceAccountToken: am.alertmanagerSpec.automountServiceAccountToken

				if am.alertmanagerSpec.externalUrl != "" {
					externalUrl: am.alertmanagerSpec.externalUrl
				}
				if am.alertmanagerSpec.externalUrl == "" {
					if am.ingress.enabled && len(am.ingress.hosts) > 0 {
						externalUrl: "http://\(am.ingress.hosts[0])\(am.alertmanagerSpec.routePrefix)"
					}
					if !(am.ingress.enabled && len(am.ingress.hosts) > 0) {
						externalUrl: "http://\(serviceName).\(amNamespace):\(am.service.port)"
					}
				}

				if len(am.alertmanagerSpec.nodeSelector) > 0 {
					nodeSelector: am.alertmanagerSpec.nodeSelector
				}
				paused:    am.alertmanagerSpec.paused
				logFormat: am.alertmanagerSpec.logFormat
				logLevel:  am.alertmanagerSpec.logLevel
				retention: am.alertmanagerSpec.retention

				if len(am.enableFeatures) > 0 {
					enableFeatures: am.enableFeatures
				}
				if len(am.alertmanagerSpec.secrets) > 0 {
					secrets: am.alertmanagerSpec.secrets
				}
				if am.alertmanagerSpec.configSecret != "" {
					configSecret: am.alertmanagerSpec.configSecret
				}
				if len(am.alertmanagerSpec.configMaps) > 0 {
					configMaps: am.alertmanagerSpec.configMaps
				}

				if len(am.alertmanagerSpec.alertmanagerConfigSelector) > 0 {
					alertmanagerConfigSelector: am.alertmanagerSpec.alertmanagerConfigSelector
				}
				if len(am.alertmanagerSpec.alertmanagerConfigSelector) == 0 {
					alertmanagerConfigSelector: {}
				}

				if len(am.alertmanagerSpec.alertmanagerConfigNamespaceSelector) > 0 {
					alertmanagerConfigNamespaceSelector: am.alertmanagerSpec.alertmanagerConfigNamespaceSelector
				}
				if len(am.alertmanagerSpec.alertmanagerConfigNamespaceSelector) == 0 {
					alertmanagerConfigNamespaceSelector: {}
				}

				if len(am.alertmanagerSpec.web) > 0 {
					web: am.alertmanagerSpec.web
				}
				if len(am.alertmanagerSpec.alertmanagerConfiguration) > 0 {
					alertmanagerConfiguration: am.alertmanagerSpec.alertmanagerConfiguration
				}
				if len(am.alertmanagerSpec.alertmanagerConfigMatcherStrategy) > 0 {
					alertmanagerConfigMatcherStrategy: am.alertmanagerSpec.alertmanagerConfigMatcherStrategy
				}
				if len(am.alertmanagerSpec.resources) > 0 {
					resources: am.alertmanagerSpec.resources
				}
				if am.alertmanagerSpec.routePrefix != "" {
					routePrefix: am.alertmanagerSpec.routePrefix
				}
				if len(am.alertmanagerSpec.securityContext) > 0 {
					securityContext: am.alertmanagerSpec.securityContext
				}
				if len(am.alertmanagerSpec.storage) > 0 {
					storage: am.alertmanagerSpec.storage
				}
				if len(am.alertmanagerSpec.podMetadata) > 0 {
					podMetadata: am.alertmanagerSpec.podMetadata
				}

				if am.alertmanagerSpec.podAntiAffinity != "" || len(am.alertmanagerSpec.affinity) > 0 {
					affinity: {
						if len(am.alertmanagerSpec.affinity) > 0 {
							am.alertmanagerSpec.affinity
						}
						if am.alertmanagerSpec.podAntiAffinity == "hard" {
							podAntiAffinity: {
								requiredDuringSchedulingIgnoredDuringExecution: [
									{
										topologyKey: am.alertmanagerSpec.podAntiAffinityTopologyKey
										labelSelector: {
											matchExpressions: [
												{key: "app.kubernetes.io/name", operator: "In", values: ["alertmanager"]},
												{key: "alertmanager", operator: "In", values: [crName]},
											]
										}
									},
								]
							}
						}
						if am.alertmanagerSpec.podAntiAffinity == "soft" {
							podAntiAffinity: {
								preferredDuringSchedulingIgnoredDuringExecution: [
									{
										weight: 100
										podAffinityTerm: {
											topologyKey: am.alertmanagerSpec.podAntiAffinityTopologyKey
											labelSelector: {
												matchExpressions: [
													{key: "app.kubernetes.io/name", operator: "In", values: ["alertmanager"]},
													{key: "alertmanager", operator: "In", values: [crName]},
												]
											}
										}
									},
								]
							}
						}
					}
				}

				if len(am.alertmanagerSpec.tolerations) > 0 {
					tolerations: am.alertmanagerSpec.tolerations
				}
				if len(am.alertmanagerSpec.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: am.alertmanagerSpec.topologySpreadConstraints
				}
				if len(mon.global.imagePullSecrets) > 0 {
					imagePullSecrets: mon.global.imagePullSecrets
				}
				if len(am.alertmanagerSpec.containers) > 0 {
					containers: am.alertmanagerSpec.containers
				}
				if len(am.alertmanagerSpec.initContainers) > 0 {
					initContainers: am.alertmanagerSpec.initContainers
				}
				if am.alertmanagerSpec.priorityClassName != "" {
					priorityClassName: am.alertmanagerSpec.priorityClassName
				}
				if len(am.alertmanagerSpec.additionalPeers) > 0 {
					additionalPeers: am.alertmanagerSpec.additionalPeers
				}
				if len(am.alertmanagerSpec.volumes) > 0 {
					volumes: am.alertmanagerSpec.volumes
				}
				if len(am.alertmanagerSpec.volumeMounts) > 0 {
					volumeMounts: am.alertmanagerSpec.volumeMounts
				}
				portName: am.alertmanagerSpec.portName
				if am.alertmanagerSpec.clusterAdvertiseAddress != "" {
					clusterAdvertiseAddress: am.alertmanagerSpec.clusterAdvertiseAddress
				}
				if am.alertmanagerSpec.clusterGossipInterval != "" {
					clusterGossipInterval: am.alertmanagerSpec.clusterGossipInterval
				}
				if am.alertmanagerSpec.clusterPeerTimeout != "" {
					clusterPeerTimeout: am.alertmanagerSpec.clusterPeerTimeout
				}
				if am.alertmanagerSpec.clusterPushpullInterval != "" {
					clusterPushpullInterval: am.alertmanagerSpec.clusterPushpullInterval
				}
				if am.alertmanagerSpec.clusterLabel != "" {
					clusterLabel: am.alertmanagerSpec.clusterLabel
				}
				if am.alertmanagerSpec.forceEnableClusterMode {
					forceEnableClusterMode: am.alertmanagerSpec.forceEnableClusterMode
				}
				if am.alertmanagerSpec.minReadySeconds > 0 {
					minReadySeconds: am.alertmanagerSpec.minReadySeconds
				}
				if len(am.alertmanagerSpec.additionalConfig) > 0 {
					am.alertmanagerSpec.additionalConfig
				}
			}
		}
	}

	// 2. templates/alertmanager/extrasecret.yaml
	if len(am.extraSecret.data) > 0 {
		"extrasecret": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name: [if am.extraSecret.name != "" {am.extraSecret.name}, "alertmanager-\(fullname)-extra"][0]
				namespace: amNamespace
				labels: amLabels & {
					app:                           "\(chartName)-alertmanager"
					"app.kubernetes.io/component": "alertmanager"
				}
				if len(am.extraSecret.annotations) > 0 {
					annotations: am.extraSecret.annotations
				}
			}
			stringData: {
				for k, v in am.extraSecret.data {
					"\(k)": v
				}
			}
		}
	}

	// 3. templates/alertmanager/ingress.yaml
	if am.enabled && am.ingress.enabled {
		"ingress": {
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				name:      serviceName
				namespace: amNamespace
				labels: amLabels & am.ingress.labels & {
					app: "\(chartName)-alertmanager"
				}
				if len(am.ingress.annotations) > 0 {
					annotations: am.ingress.annotations
				}
			}
			spec: {
				if am.ingress.ingressClassName != "" {
					ingressClassName: am.ingress.ingressClassName
				}
				rules: [
					if len(am.ingress.hosts) > 0 {
						for host in am.ingress.hosts {
							{
								host: host
								http: {
									paths: [
										for path in [if len(am.ingress.paths) > 0 {am.ingress.paths}, [am.alertmanagerSpec.routePrefix]][0] {
											{
												path: path
												pathType: [if am.ingress.pathType != "" {am.ingress.pathType}, "ImplementationSpecific"][0]
												backend: {
													service: {
														name: [if am.ingress.serviceName != "" {am.ingress.serviceName}, serviceName][0]
														port: {
															number: [if am.ingress.servicePort != 0 {am.ingress.servicePort}, am.service.port][0]
														}
													}
												}
											}
										},
									]
								}
							}
						}
					},
					if len(am.ingress.hosts) == 0 {
						{
							http: {
								paths: [
									for path in [if len(am.ingress.paths) > 0 {am.ingress.paths}, [am.alertmanagerSpec.routePrefix]][0] {
										{
											path: path
											pathType: [if am.ingress.pathType != "" {am.ingress.pathType}, "ImplementationSpecific"][0]
											backend: {
												service: {
													name: [if am.ingress.serviceName != "" {am.ingress.serviceName}, serviceName][0]
													port: {
														number: [if am.ingress.servicePort != 0 {am.ingress.servicePort}, am.service.port][0]
													}
												}
											}
										}
									},
								]
							}
						}
					},
				]
				if len(am.ingress.tls) > 0 {
					tls: am.ingress.tls
				}
			}
		}
	}

	// 4. templates/alertmanager/ingressperreplica.yaml
	if am.enabled && am.servicePerReplica.enabled && am.ingressPerReplica.enabled {
		for i in list.Range(0, am.alertmanagerSpec.replicas, 1) {
			"ingressperreplica-\(i)": {
				apiVersion: "networking.k8s.io/v1"
				kind:       "Ingress"
				metadata: {
					name:      "\(fullname)-alertmanager-\(i)"
					namespace: amNamespace
					labels: amLabels & am.ingressPerReplica.labels & {
						app: "\(chartName)-alertmanager"
					}
					if len(am.ingressPerReplica.annotations) > 0 {
						annotations: am.ingressPerReplica.annotations
					}
				}
				spec: {
					if am.ingressPerReplica.ingressClassName != "" {
						ingressClassName: am.ingressPerReplica.ingressClassName
					}
					rules: [
						{
							host: "\(am.ingressPerReplica.hostPrefix)-\(i).\(am.ingressPerReplica.hostDomain)"
							http: {
								paths: [
									for path in am.ingressPerReplica.paths {
										{
											path: path
											if am.ingressPerReplica.pathType != "" {
												pathType: am.ingressPerReplica.pathType
											}
											backend: {
												service: {
													name: "\(fullname)-alertmanager-\(i)"
													port: {
														number: am.service.port
													}
												}
											}
										}
									},
								]
							}
						},
					]
					if am.ingressPerReplica.tlsSecretName != "" || am.ingressPerReplica.tlsSecretPerReplica.enabled {
						tls: [
							{
								hosts: ["\(am.ingressPerReplica.hostPrefix)-\(i).\(am.ingressPerReplica.hostDomain)"]
								secretName: [if am.ingressPerReplica.tlsSecretPerReplica.enabled {"\(am.ingressPerReplica.tlsSecretPerReplica.prefix)-\(i)"}, am.ingressPerReplica.tlsSecretName][0]
							},
						]
					}
				}
			}
		}
	}

	// 5. templates/alertmanager/podDisruptionBudget.yaml
	if am.enabled && am.podDisruptionBudget.enabled {
		"poddisruptionbudget": {
			apiVersion: "policy/v1"
			kind:       "PodDisruptionBudget"
			metadata: {
				name:      serviceName
				namespace: amNamespace
				labels: amLabels & {
					app: "\(chartName)-alertmanager"
				}
			}
			spec: {
				if am.podDisruptionBudget.minAvailable != _|_ {
					minAvailable: am.podDisruptionBudget.minAvailable
				}
				if am.podDisruptionBudget.maxUnavailable != "" {
					maxUnavailable: am.podDisruptionBudget.maxUnavailable
				}
				selector: {
					matchLabels: {
						"app.kubernetes.io/name": "alertmanager"
						alertmanager:             crName
					}
				}
			}
		}
	}

	// 6. templates/alertmanager/psp-role.yaml
	if am.enabled && mon.global.rbac.create && mon.global.rbac.pspEnabled {
		"psp-role": rbacv1.#Role & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "Role"
			metadata: {
				name:      serviceName
				namespace: amNamespace
				labels: amLabels & {
					app: "\(chartName)-alertmanager"
				}
			}
			rules: [
				{
					apiGroups: ["policy"]
					resources: ["podsecuritypolicies"]
					verbs: ["use"]
					resourceNames: [serviceName]
				},
			]
		}
	}

	// 7. templates/alertmanager/psp-rolebinding.yaml
	if am.enabled && mon.global.rbac.create && mon.global.rbac.pspEnabled {
		"psp-rolebinding": rbacv1.#RoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "RoleBinding"
			metadata: {
				name:      serviceName
				namespace: amNamespace
				labels: amLabels & {
					app: "\(chartName)-alertmanager"
				}
			}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "Role"
				name:     serviceName
			}
			subjects: [
				{
					kind:      "ServiceAccount"
					name:      amServiceAccountName
					namespace: amNamespace
				},
			]
		}
	}

	// 8. templates/alertmanager/psp.yaml
	if am.enabled && mon.global.rbac.create && mon.global.rbac.pspEnabled {
		"psp": {
			apiVersion: "policy/v1beta1"
			kind:       "PodSecurityPolicy"
			metadata: {
				name: serviceName
				labels: amLabels & {
					app: "\(chartName)-alertmanager"
				}
				if len(mon.global.rbac.pspAnnotations) > 0 {
					annotations: mon.global.rbac.pspAnnotations
				}
			}
			spec: {
				privileged: false
				volumes: [
					"configMap",
					"emptyDir",
					"projected",
					"secret",
					"downwardAPI",
					"persistentVolumeClaim",
				]
				hostNetwork: false
				hostIPC:     false
				hostPID:     false
				runAsUser: {
					rule: "RunAsAny"
				}
				seLinux: {
					rule: "RunAsAny"
				}
				supplementalGroups: {
					rule: "MustRunAs"
					ranges: [
						{min: 0, max: 65535},
					]
				}
				fsGroup: {
					rule: "MustRunAs"
					ranges: [
						{min: 0, max: 65535},
					]
				}
				readOnlyRootFilesystem: false
			}
		}
	}

	// 9. templates/alertmanager/secret.yaml
	if am.enabled && !am.alertmanagerSpec.useExistingSecret {
		"secret": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "alertmanager-\(crName)"
				namespace: amNamespace
				labels: amLabels & {
					app: "\(chartName)-alertmanager"
				}
				if len(am.secret.annotations) > 0 {
					annotations: am.secret.annotations
				}
			}
			stringData: {
				"alertmanager.yaml": [if am.stringConfig != "" {am.stringConfig}, """
					global:
					  resolve_timeout: 5m
					inhibit_rules:
					- source_matchers:
					  - severity = critical
					  target_matchers:
					  - severity =~ warning|info
					  equal:
					  - namespace
					  - alertname
					- source_matchers:
					  - severity = warning
					  target_matchers:
					  - severity = info
					  equal:
					  - namespace
					  - alertname
					- source_matchers:
					  - alertname = InfoInhibitor
					  target_matchers:
					  - severity = info
					  equal:
					  - namespace
					- target_matchers:
					  - alertname = InfoInhibitor
					route:
					  group_by:
					  - namespace
					  group_wait: 30s
					  group_interval: 5m
					  repeat_interval: 12h
					  receiver: "null"
					  routes:
					  - receiver: "null"
					    matchers:
					    - alertname = "Watchdog"
					receivers:
					- name: "null"
					templates:
					- /etc/alertmanager/config/*.tmpl
					"""][0]
				for k, v in am.templateFiles {
					"\(k)": v
				}
			}
		}
	}

	// 10. templates/alertmanager/service.yaml
	if am.enabled {
		"service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      serviceName
				namespace: amNamespace
				labels: amLabels & am.service.labels & {
					app:            "\(chartName)-alertmanager"
					"self-monitor": "\(am.serviceMonitor.selfMonitor)"
				}
				if len(am.service.annotations) > 0 {
					annotations: am.service.annotations
				}
			}
			spec: {
				if am.service.clusterIP != "" {
					clusterIP: am.service.clusterIP
				}
				if len(am.service.externalIPs) > 0 {
					externalIPs: am.service.externalIPs
				}
				if am.service.loadBalancerIP != "" {
					loadBalancerIP: am.service.loadBalancerIP
				}
				if len(am.service.loadBalancerSourceRanges) > 0 {
					loadBalancerSourceRanges: am.service.loadBalancerSourceRanges
				}
				if am.service.type != "ClusterIP" {
					externalTrafficPolicy: am.service.externalTrafficPolicy
				}
				ports: [
					{
						name: am.alertmanagerSpec.portName
						if am.service.type == "NodePort" {
							nodePort: am.service.nodePort
						}
						port:       am.service.port
						targetPort: am.service.targetPort
						protocol:   "TCP"
					},
					{
						name:        "reloader-web"
						appProtocol: "http"
						port:        8080
						targetPort:  "reloader-web"
					},
					for p in am.service.additionalPorts {
						p
					},
				]
				selector: {
					"app.kubernetes.io/name": "alertmanager"
					alertmanager:             crName
				}
				if am.service.sessionAffinity != "" {
					sessionAffinity: am.service.sessionAffinity
				}
				if am.service.sessionAffinity == "ClientIP" {
					sessionAffinityConfig: am.service.sessionAffinityConfig
				}
				type: am.service.type
				if am.service.ipDualStack.enabled {
					ipFamilies:     am.service.ipDualStack.ipFamilies
					ipFamilyPolicy: am.service.ipDualStack.ipFamilyPolicy
				}
			}
		}
	}

	// 11. templates/alertmanager/serviceaccount.yaml
	if am.enabled && am.serviceAccount.create {
		"serviceaccount": corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name:      amServiceAccountName
				namespace: amNamespace
				labels: amLabels & {
					app:                           "\(chartName)-alertmanager"
					"app.kubernetes.io/name":      "\(chartName)-alertmanager"
					"app.kubernetes.io/component": "alertmanager"
				}
				if len(am.serviceAccount.annotations) > 0 {
					annotations: am.serviceAccount.annotations
				}
			}
			automountServiceAccountToken: am.serviceAccount.automountServiceAccountToken
			if len(mon.global.imagePullSecrets) > 0 {
				imagePullSecrets: mon.global.imagePullSecrets
			}
		}
	}

	// 12. templates/alertmanager/servicemonitor.yaml
	if am.enabled && am.serviceMonitor.selfMonitor {
		"servicemonitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {
				name:      serviceName
				namespace: amNamespace
				labels: amLabels & am.serviceMonitor.additionalLabels & {
					app: "\(chartName)-alertmanager"
				}
			}
			spec: {
				selector: {
					matchLabels: {
						app:            "\(chartName)-alertmanager"
						release:        #config.metadata.name
						"self-monitor": "true"
					}
				}
				namespaceSelector: {
					matchNames: [amNamespace]
				}
				endpoints: [
					{
						port:        am.alertmanagerSpec.portName
						enableHttp2: am.serviceMonitor.enableHttp2
						if am.serviceMonitor.interval != "" {
							interval: am.serviceMonitor.interval
						}
						if am.serviceMonitor.proxyUrl != "" {
							proxyUrl: am.serviceMonitor.proxyUrl
						}
						if am.serviceMonitor.scheme != "" {
							scheme: am.serviceMonitor.scheme
						}
						if am.serviceMonitor.bearerTokenFile != "" {
							bearerTokenFile: am.serviceMonitor.bearerTokenFile
						}
						if len(am.serviceMonitor.tlsConfig) > 0 {
							tlsConfig: am.serviceMonitor.tlsConfig
						}
						path: "\(am.alertmanagerSpec.routePrefix)metrics"
						if len(am.serviceMonitor.metricRelabelings) > 0 {
							metricRelabelings: am.serviceMonitor.metricRelabelings
						}
						if len(am.serviceMonitor.relabelings) > 0 {
							relabelings: am.serviceMonitor.relabelings
						}
					},
					{
						port: "reloader-web"
						if am.serviceMonitor.interval != "" {
							interval: am.serviceMonitor.interval
						}
						if am.serviceMonitor.proxyUrl != "" {
							proxyUrl: am.serviceMonitor.proxyUrl
						}
						if am.serviceMonitor.scheme != "" {
							scheme: am.serviceMonitor.scheme
						}
						if len(am.serviceMonitor.tlsConfig) > 0 {
							tlsConfig: am.serviceMonitor.tlsConfig
						}
						path: "/metrics"
						if len(am.serviceMonitor.metricRelabelings) > 0 {
							metricRelabelings: am.serviceMonitor.metricRelabelings
						}
						if len(am.serviceMonitor.relabelings) > 0 {
							relabelings: am.serviceMonitor.relabelings
						}
					},
					for e in am.serviceMonitor.additionalEndpoints {
						e
					},
				]
			}
		}
	}

	// 13. templates/alertmanager/serviceperreplica.yaml
	if am.enabled && am.servicePerReplica.enabled {
		for i in list.Range(0, am.alertmanagerSpec.replicas, 1) {
			"serviceperreplica-\(i)": corev1.#Service & {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      "\(fullname)-alertmanager-\(i)"
					namespace: amNamespace
					labels: amLabels & {
						app: "\(chartName)-alertmanager"
					}
					if len(am.servicePerReplica.annotations) > 0 {
						annotations: am.servicePerReplica.annotations
					}
				}
				spec: {
					if len(am.servicePerReplica.loadBalancerSourceRanges) > 0 {
						loadBalancerSourceRanges: am.servicePerReplica.loadBalancerSourceRanges
					}
					if am.servicePerReplica.type != "ClusterIP" {
						externalTrafficPolicy: am.servicePerReplica.externalTrafficPolicy
					}
					ports: [
						{
							name: am.alertmanagerSpec.portName
							if am.servicePerReplica.type == "NodePort" {
								nodePort: am.servicePerReplica.nodePort
							}
							port:       am.servicePerReplica.port
							targetPort: am.servicePerReplica.targetPort
						},
					]
					selector: {
						"app.kubernetes.io/name":             "alertmanager"
						alertmanager:                         crName
						"statefulset.kubernetes.io/pod-name": "alertmanager-\(crName)-\(i)"
					}
					type: am.servicePerReplica.type
				}
			}
		}
	}
}
