package templates

import (
	"list"
	"strings"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
	policyv1 "k8s.io/api/policy/v1"
)

#KubePrometheusStackThanosRulerName: {
	#config: #Config
	let kps = #config."hyperswitch-monitoring"."kube-prometheus-stack"
	let name = (#KubePrometheusStackName & {#config: #config}).result
	result: [if kps.thanosRuler.name != "" {kps.thanosRuler.name}, "\(name)-thanos-ruler"][0]
}

#KubePrometheusStackThanosRulerCrName: {
	#config: #Config
	let kps = #config."hyperswitch-monitoring"."kube-prometheus-stack"
	let fullname = (#KubePrometheusStackFullname & {#config: #config}).result
	result: [
		if kps.cleanPrometheusOperatorObjectNames {fullname},
		(strings.TrimSuffix(strings.Slice(fullname, 0, [if len(fullname) < 25 {len(fullname)}, 25][0]), "-") + "-thanos-ruler"),
	][0]
}

#KubePrometheusStackThanosRulerServiceAccountName: {
	#config: #Config
	let kps = #config."hyperswitch-monitoring"."kube-prometheus-stack"
	let tr = kps.thanosRuler
	let name = (#KubePrometheusStackThanosRulerName & {#config: #config}).result
	result: [
		if tr.serviceAccount.create && tr.serviceAccount.name != "" {tr.serviceAccount.name},
		if tr.serviceAccount.create && tr.serviceAccount.name == "" {name},
		if !tr.serviceAccount.create && tr.serviceAccount.name != "" {tr.serviceAccount.name},
		"default",
	][0]
}

monitoringThanosRuler: {
	#config: #Config
	let mon = #config."hyperswitch-monitoring"
	let kps = mon."kube-prometheus-stack"
	let tr = kps.thanosRuler
	let trName = (#KubePrometheusStackThanosRulerName & {#config: #config}).result
	let trCrName = (#KubePrometheusStackThanosRulerCrName & {#config: #config}).result
	let trLabels = (#KubePrometheusStackLabels & {#config: #config}).result & {
		app: trName
	}
	let ns = [if kps.namespaceOverride != "" {kps.namespaceOverride}, #config.metadata.namespace][0]
	let trServiceAccountName = (#KubePrometheusStackThanosRulerServiceAccountName & {#config: #config}).result

	// 1. extrasecret.yaml
	if tr.extraSecret.data != _|_ && len(tr.extraSecret.data) > 0 {
		"#1-extrasecret": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name: [if tr.extraSecret.name != "" {tr.extraSecret.name}, "\(trName)-extra"][0]
				namespace: ns
				labels: trLabels & {
					"app.kubernetes.io/component": "thanos-ruler"
				}
				if len(tr.extraSecret.annotations) > 0 {
					annotations: tr.extraSecret.annotations
				}
			}
			type: "Opaque"
			data: {
				for k, v in tr.extraSecret.data {
					"\(k)": v
				}
			}
		}
	}

	// 2. ingress.yaml
	if tr.enabled && tr.ingress.enabled {
		"#2-ingress": networkingv1.#Ingress & {
			let _pathType = [if tr.ingress.pathType != "" {tr.ingress.pathType}, "ImplementationSpecific"][0]
			let routePrefix = [tr.thanosRulerSpec.routePrefix]
			let _paths = [if tr.ingress.paths != _|_ {tr.ingress.paths}, routePrefix][0]
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				name:      trName
				namespace: ns
				labels:    trLabels
				if len(tr.ingress.annotations) > 0 {
					annotations: tr.ingress.annotations
				}
			}
			spec: {
				if tr.ingress.ingressClassName != "" {
					ingressClassName: tr.ingress.ingressClassName
				}
				rules: [
					if len(tr.ingress.hosts) > 0 {
						for h in tr.ingress.hosts {
							{
								host: h
								http: paths: [
									for p in _paths {
										{
											path:     p
											pathType: _pathType
											backend: service: {
												name: trName
												port: number: tr.service.port
											}
										}
									},
								]
							}
						}
					},
					if len(tr.ingress.hosts) == 0 {
						{
							http: paths: [
								for p in paths {
									{
										path:     p
										pathType: pathType
										backend: service: {
											name: trName
											port: number: tr.service.port
										}
									}
								},
							]
						}
					},
				]
				if len(tr.ingress.tls) > 0 {
					tls: tr.ingress.tls
				}
			}
		}
	}

	// 3. podDisruptionBudget.yaml
	if tr.enabled && tr.podDisruptionBudget.enabled {
		"#3-podDisruptionBudget": policyv1.#PodDisruptionBudget & {
			apiVersion: "policy/v1"
			kind:       "PodDisruptionBudget"
			metadata: {
				name:      trName
				namespace: ns
				labels:    trLabels
			}
			spec: {
				if tr.podDisruptionBudget.minAvailable != _|_ {
					minAvailable: tr.podDisruptionBudget.minAvailable
				}
				if tr.podDisruptionBudget.maxUnavailable != _|_ {
					maxUnavailable: tr.podDisruptionBudget.maxUnavailable
				}
				selector: matchLabels: {
					"app.kubernetes.io/name": "thanos-ruler"
					"thanos-ruler":           trCrName
				}
			}
		}
	}

	// 4. ruler.yaml
	if tr.enabled {
		"#4-ruler": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ThanosRuler"
			metadata: {
				name:      trCrName
				namespace: ns
				labels:    trLabels
				if len(tr.annotations) > 0 {
					annotations: tr.annotations
				}
			}
			spec: {
				if tr.thanosRulerSpec.image != _|_ {
					let registry = [if mon.global.imageRegistry != "" {mon.global.imageRegistry}, tr.thanosRulerSpec.image.registry][0]
					if tr.thanosRulerSpec.image.tag != "" && tr.thanosRulerSpec.image.sha != "" {
						image: "\(registry)/\(tr.thanosRulerSpec.image.repository):\(tr.thanosRulerSpec.image.tag)@sha256:\(tr.thanosRulerSpec.image.sha)"
					}
					if tr.thanosRulerSpec.image.tag == "" && tr.thanosRulerSpec.image.sha != "" {
						image: "\(registry)/\(tr.thanosRulerSpec.image.repository)@sha256:\(tr.thanosRulerSpec.image.sha)"
					}
					if tr.thanosRulerSpec.image.tag != "" && tr.thanosRulerSpec.image.sha == "" {
						image: "\(registry)/\(tr.thanosRulerSpec.image.repository):\(tr.thanosRulerSpec.image.tag)"
					}
					if tr.thanosRulerSpec.image.tag == "" && tr.thanosRulerSpec.image.sha == "" {
						image: "\(registry)/\(tr.thanosRulerSpec.image.repository)"
					}
					if tr.thanosRulerSpec.image.sha != "" {
						sha: tr.thanosRulerSpec.image.sha
					}
				}
				replicas:           tr.thanosRulerSpec.replicas
				listenLocal:        tr.thanosRulerSpec.listenLocal
				serviceAccountName: trServiceAccountName
				if tr.thanosRulerSpec.externalPrefix != "" {
					externalPrefix: tr.thanosRulerSpec.externalPrefix
				}
				if tr.thanosRulerSpec.externalPrefix == "" && tr.ingress.enabled && len(tr.ingress.hosts) > 0 {
					externalPrefix: "http://" + tr.ingress.hosts[0] + tr.thanosRulerSpec.routePrefix
				}
				if tr.thanosRulerSpec.externalPrefix == "" && !(tr.ingress.enabled && len(tr.ingress.hosts) > 0) && tr.thanosRulerSpec.externalPrefixNilUsesHelmValues {
					externalPrefix: "http://" + trName + "." + ns + ":" + "\(tr.service.port)"
				}
				if len(tr.thanosRulerSpec.additionalArgs) > 0 {
					additionalArgs: tr.thanosRulerSpec.additionalArgs
				}
				if len(tr.thanosRulerSpec.nodeSelector) > 0 {
					nodeSelector: tr.thanosRulerSpec.nodeSelector
				}
				paused:    tr.thanosRulerSpec.paused
				logFormat: tr.thanosRulerSpec.logFormat
				logLevel:  tr.thanosRulerSpec.logLevel
				retention: tr.thanosRulerSpec.retention
				if tr.thanosRulerSpec.evaluationInterval != "" {
					evaluationInterval: tr.thanosRulerSpec.evaluationInterval
				}
				if tr.thanosRulerSpec.ruleNamespaceSelector != _|_ {
					ruleNamespaceSelector: tr.thanosRulerSpec.ruleNamespaceSelector
				}
				if tr.thanosRulerSpec.ruleNamespaceSelector == _|_ {
					ruleNamespaceSelector: {}
				}
				if tr.thanosRulerSpec.ruleSelector != _|_ {
					ruleSelector: tr.thanosRulerSpec.ruleSelector
				}
				if tr.thanosRulerSpec.ruleSelector == _|_ {
					if tr.thanosRulerSpec.ruleSelectorNilUsesHelmValues {
						ruleSelector: matchLabels: release: #config.metadata.name
					}
					if !tr.thanosRulerSpec.ruleSelectorNilUsesHelmValues {
						ruleSelector: {}
					}
				}
				if tr.thanosRulerSpec.alertQueryUrl != "" {
					alertQueryUrl: tr.thanosRulerSpec.alertQueryUrl
				}
				if len(tr.thanosRulerSpec.alertmanagersUrl) > 0 {
					alertmanagersUrl: tr.thanosRulerSpec.alertmanagersUrl
				}
				if tr.thanosRulerSpec.alertmanagersConfig.existingSecret.name != "" {
					alertmanagersConfig: {
						key:  tr.thanosRulerSpec.alertmanagersConfig.existingSecret.key
						name: tr.thanosRulerSpec.alertmanagersConfig.existingSecret.name
					}
				}
				if tr.thanosRulerSpec.alertmanagersConfig.existingSecret.name == "" && tr.thanosRulerSpec.alertmanagersConfig.secret != _|_ {
					alertmanagersConfig: {
						key:  "alertmanager-configs.yaml"
						name: trName
					}
				}
				if len(tr.thanosRulerSpec.queryEndpoints) > 0 {
					queryEndpoints: tr.thanosRulerSpec.queryEndpoints
				}
				if tr.thanosRulerSpec.queryConfig.existingSecret.name != "" {
					queryConfig: {
						key:  tr.thanosRulerSpec.queryConfig.existingSecret.key
						name: tr.thanosRulerSpec.queryConfig.existingSecret.name
					}
				}
				if tr.thanosRulerSpec.queryConfig.existingSecret.name == "" && tr.thanosRulerSpec.queryConfig.secret != _|_ {
					queryConfig: {
						key:  "query-configs.yaml"
						name: trName
					}
				}
				if tr.thanosRulerSpec.resources != _|_ {
					resources: tr.thanosRulerSpec.resources
				}
				if tr.thanosRulerSpec.routePrefix != "" {
					routePrefix: tr.thanosRulerSpec.routePrefix
				}
				if tr.thanosRulerSpec.securityContext != _|_ {
					securityContext: tr.thanosRulerSpec.securityContext
				}
				if tr.thanosRulerSpec.storage != _|_ {
					storage: tr.thanosRulerSpec.storage
				}
				if tr.thanosRulerSpec.objectStorageConfig.existingSecret.name != "" {
					objectStorageConfig: {
						key:  tr.thanosRulerSpec.objectStorageConfig.existingSecret.key
						name: tr.thanosRulerSpec.objectStorageConfig.existingSecret.name
					}
				}
				if tr.thanosRulerSpec.objectStorageConfig.existingSecret.name == "" && tr.thanosRulerSpec.objectStorageConfig.secret != _|_ {
					objectStorageConfig: {
						key:  "object-storage-configs.yaml"
						name: trName
					}
				}
				if len(tr.thanosRulerSpec.labels) > 0 {
					labels: tr.thanosRulerSpec.labels
				}
				if tr.thanosRulerSpec.podMetadata != _|_ {
					podMetadata: tr.thanosRulerSpec.podMetadata
				}
				if tr.thanosRulerSpec.affinity != _|_ || tr.thanosRulerSpec.podAntiAffinity != "" {
					affinity: {
						if tr.thanosRulerSpec.affinity != _|_ {
							tr.thanosRulerSpec.affinity
						}
						if tr.thanosRulerSpec.podAntiAffinity == "hard" {
							podAntiAffinity: requiredDuringSchedulingIgnoredDuringExecution: [{
								topologyKey: tr.thanosRulerSpec.podAntiAffinityTopologyKey
								labelSelector: matchExpressions: [
									{key: "app.kubernetes.io/name", operator: "In", values: ["thanos-ruler"]},
									{key: "thanos-ruler", operator: "In", values: [trCrName]},
								]
							}]
						}
						if tr.thanosRulerSpec.podAntiAffinity == "soft" {
							podAntiAffinity: preferredDuringSchedulingIgnoredDuringExecution: [{
								weight: 100
								podAffinityTerm: {
									topologyKey: tr.thanosRulerSpec.podAntiAffinityTopologyKey
									labelSelector: matchExpressions: [
										{key: "app.kubernetes.io/name", operator: "In", values: ["thanos-ruler"]},
										{key: "thanos-ruler", operator: "In", values: [trCrName]},
									]
								}
							}]
						}
					}
				}
				if len(tr.thanosRulerSpec.tolerations) > 0 {
					tolerations: tr.thanosRulerSpec.tolerations
				}
				if len(tr.thanosRulerSpec.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: tr.thanosRulerSpec.topologySpreadConstraints
				}
				if len(mon.global.imagePullSecrets) > 0 {
					imagePullSecrets: mon.global.imagePullSecrets
				}
				if len(tr.thanosRulerSpec.containers) > 0 {
					containers: tr.thanosRulerSpec.containers
				}
				if len(tr.thanosRulerSpec.initContainers) > 0 {
					initContainers: tr.thanosRulerSpec.initContainers
				}
				if tr.thanosRulerSpec.priorityClassName != "" {
					priorityClassName: tr.thanosRulerSpec.priorityClassName
				}
				if len(tr.thanosRulerSpec.volumes) > 0 {
					volumes: tr.thanosRulerSpec.volumes
				}
				if len(tr.thanosRulerSpec.volumeMounts) > 0 {
					volumeMounts: tr.thanosRulerSpec.volumeMounts
				}
				if len(tr.thanosRulerSpec.alertDropLabels) > 0 {
					alertDropLabels: tr.thanosRulerSpec.alertDropLabels
				}
				portName: tr.thanosRulerSpec.portName
				if tr.thanosRulerSpec.web != _|_ {
					web: tr.thanosRulerSpec.web
				}
			}
		}
	}

	// 5. secret.yaml
	if tr.enabled {
		"#5-secret": corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      trName
				namespace: ns
				labels:    trLabels
			}
			type: "Opaque"
			data: {
				if tr.thanosRulerSpec.alertmanagersConfig.secret != _|_ && tr.thanosRulerSpec.alertmanagersConfig.existingSecret.name == "" {
					"alertmanager-configs.yaml": tr.thanosRulerSpec.alertmanagersConfig.secret
				}
				if tr.thanosRulerSpec.objectStorageConfig.secret != _|_ && tr.thanosRulerSpec.objectStorageConfig.existingSecret.name == "" {
					"object-storage-configs.yaml": tr.thanosRulerSpec.objectStorageConfig.secret
				}
				if tr.thanosRulerSpec.queryConfig.secret != _|_ && tr.thanosRulerSpec.queryConfig.existingSecret.name == "" {
					"query-configs.yaml": tr.thanosRulerSpec.queryConfig.secret
				}
			}
		}
	}

	// 6. serviceaccount.yaml
	if tr.enabled && tr.serviceAccount.create {
		"#6-serviceaccount": corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name:      trServiceAccountName
				namespace: ns
				labels: trLabels & {
					"app.kubernetes.io/name":      trName
					"app.kubernetes.io/component": "thanos-ruler"
				}
				if len(tr.serviceAccount.annotations) > 0 {
					annotations: tr.serviceAccount.annotations
				}
			}
			if len(mon.global.imagePullSecrets) > 0 {
				imagePullSecrets: mon.global.imagePullSecrets
			}
		}
	}

	// 7. servicemonitor.yaml
	if tr.enabled && tr.serviceMonitor.selfMonitor {
		"#7-servicemonitor": {
			apiVersion: "monitoring.coreos.com/v1"
			kind:       "ServiceMonitor"
			metadata: {
				name:      trName
				namespace: ns
				labels:    trLabels
				if len(tr.serviceMonitor.additionalLabels) > 0 {
					tr.serviceMonitor.additionalLabels
				}
			}
			spec: {
				selector: matchLabels: {
					app:            trName
					release:        #config.metadata.name
					"self-monitor": "true"
				}
				namespaceSelector: matchNames: [ns]
				endpoints: list.Concat([
					[{
						port: tr.thanosRulerSpec.portName
						if tr.serviceMonitor.interval != "" {
							interval: tr.serviceMonitor.interval
						}
						if tr.serviceMonitor.proxyUrl != "" {
							proxyUrl: tr.serviceMonitor.proxyUrl
						}
						if tr.serviceMonitor.scheme != "" {
							scheme: tr.serviceMonitor.scheme
						}
						if tr.serviceMonitor.bearerTokenFile != "" {
							bearerTokenFile: tr.serviceMonitor.bearerTokenFile
						}
						if tr.serviceMonitor.tlsConfig != _|_ {
							tlsConfig: tr.serviceMonitor.tlsConfig
						}
						path: strings.TrimSuffix(tr.thanosRulerSpec.routePrefix, "/") + "/metrics"
						if len(tr.serviceMonitor.metricRelabelings) > 0 {
							metricRelabelings: tr.serviceMonitor.metricRelabelings
						}
						if len(tr.serviceMonitor.relabelings) > 0 {
							relabelings: tr.serviceMonitor.relabelings
						}
					}],
					[for e in tr.serviceMonitor.additionalEndpoints {
						{
							port: e.port
							interval: [if e.interval != "" {e.interval}, tr.serviceMonitor.interval][0]
							proxyUrl: [if e.proxyUrl != "" {e.proxyUrl}, tr.serviceMonitor.proxyUrl][0]
							scheme: [if e.scheme != "" {e.scheme}, tr.serviceMonitor.scheme][0]
							bearerTokenFile: [if e.bearerTokenFile != "" {e.bearerTokenFile}, tr.serviceMonitor.bearerTokenFile][0]
							if e.tlsConfig != _|_ {
								tlsConfig: e.tlsConfig
							}
							if e.tlsConfig == _|_ && tr.serviceMonitor.tlsConfig != _|_ {
								tlsConfig: tr.serviceMonitor.tlsConfig
							}
							path: e.path
							metricRelabelings: [if len(e.metricRelabelings) > 0 {e.metricRelabelings}, tr.serviceMonitor.metricRelabelings][0]
							relabelings: [if len(e.relabelings) > 0 {e.relabelings}, tr.serviceMonitor.relabelings][0]
						}
					}],
				])
			}
		}
	}

	// 8. service.yaml
	if tr.enabled {
		"#8-service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      trName
				namespace: ns
				labels: trLabels & {
					"self-monitor": "true"
				}
				if len(tr.service.labels) > 0 {
					tr.service.labels
				}
				if len(tr.service.annotations) > 0 {
					annotations: tr.service.annotations
				}
			}
			spec: {
				if tr.service.clusterIP != "" {
					clusterIP: tr.service.clusterIP
				}
				if tr.service.ipDualStack.enabled {
					ipFamilies:     tr.service.ipDualStack.ipFamilies
					ipFamilyPolicy: tr.service.ipDualStack.ipFamilyPolicy
				}
				if len(tr.service.externalIPs) > 0 {
					externalIPs: tr.service.externalIPs
				}
				if tr.service.loadBalancerIP != "" {
					loadBalancerIP: tr.service.loadBalancerIP
				}
				if len(tr.service.loadBalancerSourceRanges) > 0 {
					loadBalancerSourceRanges: tr.service.loadBalancerSourceRanges
				}
				if tr.service.type != "ClusterIP" {
					externalTrafficPolicy: tr.service.externalTrafficPolicy
				}
				ports: list.Concat([
					[{
						name: tr.thanosRulerSpec.portName
						if tr.service.type == "NodePort" {
							nodePort: tr.service.nodePort
						}
						port:       tr.service.port
						targetPort: tr.service.targetPort
						protocol:   "TCP"
					}],
					tr.service.additionalPorts,
				])
				selector: {
					"app.kubernetes.io/name": "thanos-ruler"
					"thanos-ruler":           trCrName
				}
				type: tr.service.type
			}
		}
	}
}
