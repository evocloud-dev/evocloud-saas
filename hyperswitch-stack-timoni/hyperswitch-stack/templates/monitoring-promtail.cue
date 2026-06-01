package templates

monitoringPromtail: {
	#config: #Config

	let _promtail = #config."hyperswitch-monitoring".promtail
	let _metadata = #config.metadata
	let ns = _metadata.namespace
	let _name = _metadata.name
	let fullname = "\(_name)-promtail"

	let commonLabels = {
		for k, v in _metadata.labels if k != "app.kubernetes.io/name" && k != "app.kubernetes.io/instance" && k != "app.kubernetes.io/version" && k != "app.kubernetes.io/component" && k != "app.kubernetes.io/managed-by" {
			"\(k)": v
		}
		"helm.sh/chart":                "promtail-6.11.7"
		"app.kubernetes.io/name":       "promtail"
		"app.kubernetes.io/instance":   _name
		"app.kubernetes.io/version":    _promtail.image.tag
		"app.kubernetes.io/managed-by": "timoni"
	}

	let selectorLabels = {
		"app.kubernetes.io/name":     "promtail"
		"app.kubernetes.io/instance": _name
	}

	if _promtail.enabled {
		// File 1: clusterrole.yaml
		if _promtail.rbac.create {
			"clusterrole": {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRole"
				metadata: {
					name:   fullname
					labels: commonLabels
				}
				rules: [
					{
						apiGroups: [""]
						resources: ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
						verbs: ["get", "list", "watch"]
					},
				]
			}
		}

		// File 2: clusterrolebinding.yaml
		if _promtail.rbac.create {
			"clusterrolebinding": {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRoleBinding"
				metadata: {
					name:   fullname
					labels: commonLabels
				}
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "ClusterRole"
					name:     fullname
				}
				subjects: [
					{
						kind: "ServiceAccount"
						name: [if _promtail.serviceAccount.name != null {_promtail.serviceAccount.name}, fullname][0]
						namespace: ns
					},
				]
			}
		}

		// File 3: configmap.yaml
		if _promtail.configmap.enabled {
			"configmap": {
				apiVersion: "v1"
				kind:       "ConfigMap"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				data: {
					"promtail.yaml": _promtail.config.file
				}
			}
		}

		// File 4: daemonset.yaml
		if _promtail.daemonset.enabled {
			"daemonset": {
				apiVersion: "apps/v1"
				kind:       "DaemonSet"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
					if len(_promtail.annotations) > 0 {
						annotations: _promtail.annotations
					}
				}
				spec: {
					selector: matchLabels: selectorLabels
					updateStrategy: _promtail.updateStrategy
					template: #PodTemplate & {
						#promtail:       _promtail
						#fullname:       fullname
						#selectorLabels: selectorLabels
					}
				}
			}
		}

		// File 5: deployment.yaml
		if _promtail.deployment.enabled {
			"deployment": {
				apiVersion: "apps/v1"
				kind:       "Deployment"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					replicas: _promtail.deployment.replicaCount
					selector: matchLabels: selectorLabels
					strategy: _promtail.deployment.strategy
					template: #PodTemplate & {
						#promtail:       _promtail
						#fullname:       fullname
						#selectorLabels: selectorLabels
					}
				}
			}
		}

		// File 6: extra-manifests.yaml
		for i, obj in _promtail.extraObjects {
			"extra-manifest-\(i)": obj
		}

		// File 7: hpa.yaml
		if _promtail.deployment.enabled && _promtail.deployment.autoscaling.enabled {
			"hpa": {
				apiVersion: "autoscaling/v2"
				kind:       "HorizontalPodAutoscaler"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					scaleTargetRef: {
						apiVersion: "apps/v1"
						kind:       "Deployment"
						name:       fullname
					}
					minReplicas: _promtail.deployment.autoscaling.minReplicas
					maxReplicas: _promtail.deployment.autoscaling.maxReplicas
					metrics: [
						if _promtail.deployment.autoscaling.targetCPUUtilizationPercentage != null {
							{
								type: "Resource"
								resource: {
									name: "cpu"
									target: {type: "Utilization", averageUtilization: _promtail.deployment.autoscaling.targetCPUUtilizationPercentage}
								}
							}
						},
					]
				}
			}
		}

		// File 8: ingress.yaml
		if _promtail.service.enabled {
			for name, port in _promtail.extraPorts if port.ingress.enabled {
				"ingress-\(name)": {
					apiVersion: "networking.k8s.io/v1"
					kind:       "Ingress"
					metadata: {
						name:      "\(fullname)-\(name)"
						namespace: ns
						labels:    commonLabels
					}
					spec: {
						rules: [
							for h in port.ingress.hosts {
								{
									host: h
									http: paths: [
										{
											path:     "/"
											pathType: "Prefix"
											backend: service: {
												name: "\(fullname)-\(name)"
												port: number: port.service.port
											}
										},
									]
								}
							},
						]
					}
				}
			}
		}

		// File 9: networkpolicy.yaml
		if _promtail.networkPolicy.enabled {
			"networkpolicy": {
				apiVersion: "networking.k8s.io/v1"
				kind:       "NetworkPolicy"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					podSelector: matchLabels: selectorLabels
					ingress: [
						{
							from: [
								if _promtail.networkPolicy.metrics.podSelector != null {
									{podSelector: _promtail.networkPolicy.metrics.podSelector}
								},
								if _promtail.networkPolicy.metrics.namespaceSelector != null {
									{namespaceSelector: _promtail.networkPolicy.metrics.namespaceSelector}
								},
								for cidr in _promtail.networkPolicy.metrics.cidrs {
									{ipBlock: cidr: cidr}
								},
							]
							ports: [{port: _promtail.config.serverPort, protocol: "TCP"}]
						},
					]
					egress: [
						{
							ports: [{port: _promtail.networkPolicy.k8sApi.port, protocol: "TCP"}]
							to: [
								for cidr in _promtail.networkPolicy.k8sApi.cidrs {
									{ipBlock: cidr: cidr}
								},
							]
						},
					]
					policyTypes: ["Ingress", "Egress"]
				}
			}
		}

		// File 10: podsecuritypolicy.yaml
		if _promtail.rbac.create && _promtail.rbac.pspEnabled {
			"podsecuritypolicy": {
				apiVersion: "policy/v1beta1"
				kind:       "PodSecurityPolicy"
				metadata: {
					name:   fullname
					labels: commonLabels
				}
				spec: _promtail.podSecurityPolicy
			}
		}

		// File 11: prometheus-rules.yaml
		if _promtail.serviceMonitor.enabled && _promtail.serviceMonitor.prometheusRule.enabled {
			"prometheusrule": {
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "PrometheusRule"
				metadata: {
					name: fullname
					namespace: [if _promtail.serviceMonitor.namespace != null {_promtail.serviceMonitor.namespace}, ns][0]
					labels: commonLabels & _promtail.serviceMonitor.prometheusRule.additionalLabels
				}
				spec: groups: [
					{
						name:  fullname
						rules: _promtail.serviceMonitor.prometheusRule.rules
					},
				]
			}
		}

		// File 14: secret.yaml
		if !_promtail.configmap.enabled {
			"secret": {
				apiVersion: "v1"
				kind:       "Secret"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels & _promtail.secret.labels
					if len(_promtail.secret.annotations) > 0 {
						annotations: _promtail.secret.annotations
					}
				}
				stringData: {
					"promtail.yaml": _promtail.config.file
				}
			}
		}

		// File 15 & 16: Services
		for name, port in _promtail.extraPorts {
			"service-\(name)": {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      "\(fullname)-\(name)"
					namespace: ns
					labels:    commonLabels
				}
				spec: {
					type: port.service.type
					ports: [
						{
							name:       name
							port:       port.service.port
							targetPort: name
							protocol:   port.protocol
						},
					]
					selector: selectorLabels
				}
			}
		}

		if _promtail.service.enabled {
			"service-metrics": {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      fullname
					namespace: ns
					labels:    commonLabels & _promtail.service.labels
					if len(_promtail.service.annotations) > 0 {
						annotations: _promtail.service.annotations
					}
				}
				spec: {
					ports: [
						{
							name:       "http-metrics"
							port:       _promtail.config.serverPort
							targetPort: "http-metrics"
							protocol:   "TCP"
						},
					]
					selector: selectorLabels
				}
			}
		}

		// File 17: serviceaccount.yaml
		if _promtail.serviceAccount.create {
			"serviceaccount": {
				apiVersion: "v1"
				kind:       "ServiceAccount"
				metadata: {
					name: [if _promtail.serviceAccount.name != null {_promtail.serviceAccount.name}, fullname][0]
					namespace: ns
					labels:    commonLabels
					if len(_promtail.serviceAccount.annotations) > 0 {
						annotations: _promtail.serviceAccount.annotations
					}
				}
			}
		}

		// File 18: servicemonitor.yaml
		if _promtail.serviceMonitor.enabled {
			"servicemonitor": {
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "ServiceMonitor"
				metadata: {
					name: fullname
					namespace: [if _promtail.serviceMonitor.namespace != null {_promtail.serviceMonitor.namespace}, ns][0]
					labels: commonLabels & _promtail.serviceMonitor.labels
					if len(_promtail.serviceMonitor.annotations) > 0 {
						annotations: _promtail.serviceMonitor.annotations
					}
				}
				spec: {
					selector: matchLabels: selectorLabels
					namespaceSelector: matchNames: [ns]
					endpoints: [
						{
							port: "http-metrics"
							if _promtail.serviceMonitor.interval != null {
								interval: _promtail.serviceMonitor.interval
							}
							if len(_promtail.serviceMonitor.relabelings) > 0 {
								relabelings: _promtail.serviceMonitor.relabelings
							}
							if len(_promtail.serviceMonitor.metricRelabelings) > 0 {
								metricRelabelings: _promtail.serviceMonitor.metricRelabelings
							}
						},
					]
				}
			}
		}

		#PodTemplate: {
			#promtail:       _
			#fullname:       string
			#selectorLabels: _

			metadata: {
				labels: #selectorLabels & #promtail.podLabels
				if len(#promtail.podAnnotations) > 0 {
					annotations: #promtail.podAnnotations
				}
			}
			spec: {
				serviceAccountName: [if #promtail.serviceAccount.name != null {#promtail.serviceAccount.name}, #fullname][0]
				if #promtail.hostNetwork != null {
					hostNetwork: #promtail.hostNetwork
				}
				if #promtail.priorityClassName != null {
					priorityClassName: #promtail.priorityClassName
				}
				securityContext: #promtail.podSecurityContext
				imagePullSecrets: [
					for s in #promtail.imagePullSecrets {{name: s}},
				]
				hostAliases: #promtail.hostAliases
				containers: [
					{
						name:            "promtail"
						image:           "\(#promtail.image.registry)/\(#promtail.image.repository):\(#promtail.image.tag)"
						imagePullPolicy: #promtail.image.pullPolicy
						args: [
							"-config.file=/etc/promtail/promtail.yaml",
							for arg in #promtail.extraArgs {arg},
						]
						volumeMounts: [
							{
								name:      "config"
								mountPath: "/etc/promtail"
							},
							for vm in #promtail.defaultVolumeMounts {vm},
							for vm in #promtail.extraVolumeMounts {vm},
						]
						env: [
							{
								name: "HOSTNAME"
								valueFrom: fieldRef: fieldPath: "spec.nodeName"
							},
							for e in #promtail.extraEnv {e},
						]
						if len(#promtail.extraEnvFrom) > 0 {
							envFrom: #promtail.extraEnvFrom
						}
						ports: [
							{
								name:          "http-metrics"
								containerPort: #promtail.config.serverPort
								protocol:      "TCP"
							},
							for name, p in #promtail.extraPorts {
								{
									name:          name
									containerPort: p.containerPort
									protocol:      p.protocol
								}
							},
						]
						securityContext: #promtail.containerSecurityContext
						resources:       #promtail.resources
					},
					if #promtail.sidecar.configReloader.enabled {
						{
							name:            "config-reloader"
							image:           "\(#promtail.sidecar.configReloader.image.registry)/\(#promtail.sidecar.configReloader.image.repository):\(#promtail.sidecar.configReloader.image.tag)"
							imagePullPolicy: #promtail.sidecar.configReloader.image.pullPolicy
							args: [
								"-web.listen-address=:\(#promtail.sidecar.configReloader.config.serverPort)",
								"-volume-dir=/etc/promtail/",
								"-webhook-method=GET",
								"-webhook-url=http://127.0.0.1:\(#promtail.config.serverPort)/reload",
								for arg in #promtail.sidecar.configReloader.extraArgs {arg},
							]
							ports: [
								{
									name:          "reloader"
									containerPort: #promtail.sidecar.configReloader.config.serverPort
									protocol:      "TCP"
								},
							]
							volumeMounts: [
								{
									name:      "config"
									mountPath: "/etc/promtail"
								},
							]
							securityContext: #promtail.sidecar.configReloader.containerSecurityContext
							resources:       #promtail.sidecar.configReloader.resources
						}
					},
				]
				nodeSelector: #promtail.nodeSelector
				affinity:     #promtail.affinity
				tolerations:  #promtail.tolerations
				volumes: [
					{
						name: "config"
						if #promtail.configmap.enabled {
							configMap: name: #fullname
						}
						if !#promtail.configmap.enabled {
							secret: secretName: #fullname
						}
					},
					for v in #promtail.defaultVolumes {v},
					for v in #promtail.extraVolumes {v},
				]
			}
		}
	}
}
