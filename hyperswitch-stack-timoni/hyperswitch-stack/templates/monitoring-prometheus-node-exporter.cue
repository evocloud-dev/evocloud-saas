package templates

import (
	"list"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
)

#PrometheusNodeExporterName: {
	#config: #Config
	let ne = #config."hyperswitch-monitoring"."kube-prometheus-stack"."prometheus-node-exporter"
	result: [if ne.nameOverride != "" {ne.nameOverride}, "prometheus-node-exporter"][0]
}

#PrometheusNodeExporterFullname: {
	#config: #Config
	let ne = #config."hyperswitch-monitoring"."kube-prometheus-stack"."prometheus-node-exporter"
	let name = (#PrometheusNodeExporterName & {#config: #config}).result
	result: [if ne.fullnameOverride != "" {ne.fullnameOverride}, "\(#config.metadata.name)-\(name)"][0]
}

#PrometheusNodeExporterSelectorLabels: {
	#config: #Config
	let name = (#PrometheusNodeExporterName & {#config: #config}).result
	result: {"app.kubernetes.io/name": name, "app.kubernetes.io/instance": #config.metadata.name}
}

#PrometheusNodeExporterLabels: {
	#config: #Config
	let ne = #config."hyperswitch-monitoring"."kube-prometheus-stack"."prometheus-node-exporter"
	let name = (#PrometheusNodeExporterName & {#config: #config}).result
	result: (#PrometheusNodeExporterSelectorLabels & {#config: #config}).result & ne.commonLabels & {
		"helm.sh/chart":                "prometheus-node-exporter-4.39.0"
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/component":  "metrics"
		"app.kubernetes.io/part-of":    name
		"app.kubernetes.io/version":    "1.8.2"
		if ne.releaseLabel {release: #config.metadata.name}
	}
}

#PrometheusNodeExporterServiceAccountName: {
	#config: #Config
	let ne = #config."hyperswitch-monitoring"."kube-prometheus-stack"."prometheus-node-exporter"
	let fullname = (#PrometheusNodeExporterFullname & {#config: #config}).result
	result: string
	if ne.serviceAccount.create && ne.serviceAccount.name != "" {result: ne.serviceAccount.name}
	if ne.serviceAccount.create && ne.serviceAccount.name == "" {result: fullname}
	if !ne.serviceAccount.create && ne.serviceAccount.name != "" {result: ne.serviceAccount.name}
	if !ne.serviceAccount.create && ne.serviceAccount.name == "" {result: "default"}
}

#PrometheusNodeExporterImage: {
	#config: #Config
	let ne = #config."hyperswitch-monitoring"."kube-prometheus-stack"."prometheus-node-exporter"
	let registry = [if ne.global.imageRegistry != "" {ne.global.imageRegistry}, ne.image.registry][0]
	let tag = [if ne.image.tag != "" {ne.image.tag}, "v1.8.2"][0]
	result: [if ne.image.digest != "" {"\(registry)/\(ne.image.repository):\(tag)@\(ne.image.digest)"}, "\(registry)/\(ne.image.repository):\(tag)"][0]
}

#PrometheusNodeExporterKubeRBACProxyImage: {
	#config: #Config
	let ne = #config."hyperswitch-monitoring"."kube-prometheus-stack"."prometheus-node-exporter"
	let registry = [if ne.global.imageRegistry != "" {ne.global.imageRegistry}, ne.kubeRBACProxy.image.registry][0]
	result: [if ne.kubeRBACProxy.image.sha != "" {"\(registry)/\(ne.kubeRBACProxy.image.repository):\(ne.kubeRBACProxy.image.tag)@sha256:\(ne.kubeRBACProxy.image.sha)"}, "\(registry)/\(ne.kubeRBACProxy.image.repository):\(ne.kubeRBACProxy.image.tag)"][0]
}

// Registry for prometheus-node-exporter rendered objects; the let bindings below cache Helm helper equivalents and shared values used by every converted template.
monitoringPrometheusNodeExporter: {
	#config: #Config
	let ne = #config."hyperswitch-monitoring"."kube-prometheus-stack"."prometheus-node-exporter"
	let fullname = (#PrometheusNodeExporterFullname & {#config: #config}).result
	let neNamespace = [if ne.namespaceOverride != "" {ne.namespaceOverride}, #config.metadata.namespace][0]
	let neLabels = (#PrometheusNodeExporterLabels & {#config: #config}).result
	let selectorLabels = (#PrometheusNodeExporterSelectorLabels & {#config: #config}).result
	let neServiceAccountName = (#PrometheusNodeExporterServiceAccountName & {#config: #config}).result
	let servicePort = [if ne.kubeRBACProxy.enabled {ne.kubeRBACProxy.port}, ne.service.port][0]

	// 1. templates/clusterrole.yaml
	if ne.rbac.create && ne.kubeRBACProxy.enabled {
		"clusterrole": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: {name: fullname, labels: neLabels}
			rules: [{apiGroups: ["authentication.k8s.io"], resources: ["tokenreviews"], verbs: ["create"]}, {apiGroups: ["authorization.k8s.io"], resources: ["subjectaccessreviews"], verbs: ["create"]}]
		}
	}

	// 2. templates/clusterrolebinding.yaml
	if ne.rbac.create && ne.kubeRBACProxy.enabled {
		"clusterrolebinding": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: {
				labels: neLabels
				name:   fullname
			}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				if ne.rbac.useExistingRole != "" {
					name: ne.rbac.useExistingRole
				}
				if ne.rbac.useExistingRole == "" {
					name: fullname
				}
			}
			subjects: [{
				kind:      "ServiceAccount"
				name:      neServiceAccountName
				namespace: neNamespace
			}]
		}
	}

	// 3. templates/daemonset.yaml
	"daemonset": appsv1.#DaemonSet & {
		apiVersion: "apps/v1"
		kind:       "DaemonSet"
		metadata: {name: fullname, namespace: neNamespace, labels: neLabels, if len(ne.daemonsetAnnotations) > 0 {annotations: ne.daemonsetAnnotations}}
		spec: {
			selector: matchLabels: selectorLabels
			revisionHistoryLimit: ne.revisionHistoryLimit
			if len(ne.updateStrategy) > 0 {updateStrategy: ne.updateStrategy}
			template: {
				metadata: {labels: neLabels & ne.podLabels, if len(ne.podAnnotations) > 0 {annotations: ne.podAnnotations}}
				spec: {
					automountServiceAccountToken: ne.serviceAccount.automountServiceAccountToken || ne.kubeRBACProxy.enabled
					if len(ne.securityContext) > 0 {securityContext: ne.securityContext}
					if ne.priorityClassName != "" {priorityClassName: ne.priorityClassName}
					if len(ne.extraInitContainers) > 0 {initContainers: ne.extraInitContainers}
					serviceAccountName: neServiceAccountName
					if ne.terminationGracePeriodSeconds > 0 {terminationGracePeriodSeconds: ne.terminationGracePeriodSeconds}
					containers: [{
						name: "node-exporter"
						image: (#PrometheusNodeExporterImage & {#config: #config}).result
						imagePullPolicy: ne.image.pullPolicy
						args: list.Concat([["--path.procfs=/host/proc", "--path.sysfs=/host/sys"], [if ne.hostRootFsMount.enabled {"--path.rootfs=/host/root"}], ["--web.listen-address=[$(HOST_IP)]:\(servicePort)"], ne.extraArgs])
						if len(ne.containerSecurityContext) > 0 {securityContext: ne.containerSecurityContext}
						env: [{name: "HOST_IP", value: [if ne.kubeRBACProxy.enabled {"127.0.0.1"}, if ne.service.listenOnAllInterfaces {"0.0.0.0"}, "0.0.0.0"][0]}, for k, v in ne.env {name: k, value: "\(v)"}]
						if !ne.kubeRBACProxy.enabled {ports: [{name: ne.service.portName, containerPort: ne.service.port, protocol: "TCP"}]}
						livenessProbe: ne.livenessProbe.value & {httpGet: {path: "/", port: servicePort, scheme: ne.livenessProbe.httpGet.scheme, httpHeaders: ne.livenessProbe.httpGet.httpHeaders, if ne.kubeRBACProxy.enabled {host: "127.0.0.1"}}}
						readinessProbe: ne.readinessProbe.value & {httpGet: {path: "/", port: servicePort, scheme: ne.readinessProbe.httpGet.scheme, httpHeaders: ne.readinessProbe.httpGet.httpHeaders, if ne.kubeRBACProxy.enabled {host: "127.0.0.1"}}}
						if len(ne.resources) > 0 {resources: ne.resources}
						volumeMounts: [{name: "proc", mountPath: "/host/proc", readOnly: true}, {name: "sys", mountPath: "/host/sys", readOnly: true}, if ne.hostRootFsMount.enabled {name: "root", mountPath: "/host/root", readOnly: true}, for m in ne.extraHostVolumeMounts {name: m.name, mountPath: m.mountPath, readOnly: m.readOnly}, for m in ne.configmaps {name: m.name, mountPath: m.mountPath}, for m in ne.secrets {name: m.name, mountPath: m.mountPath}]
					}, if ne.kubeRBACProxy.enabled {
						name: "kube-rbac-proxy"
						args: list.Concat([ne.kubeRBACProxy.extraArgs, ["--secure-listen-address=:\(ne.service.port)", "--upstream=http://127.0.0.1:\(servicePort)/", "--proxy-endpoints-port=\(ne.kubeRBACProxy.proxyEndpointsPort)", "--config-file=/etc/kube-rbac-proxy-config/config-file.yaml"]])
						volumeMounts: [{name: "kube-rbac-proxy-config", mountPath: "/etc/kube-rbac-proxy-config"}]
						imagePullPolicy: ne.kubeRBACProxy.image.pullPolicy
						image: (#PrometheusNodeExporterKubeRBACProxyImage & {#config: #config}).result
						ports: [{containerPort: ne.service.port, name: ne.kubeRBACProxy.portName, if ne.kubeRBACProxy.enableHostPort {hostPort: ne.service.port}}, {containerPort: ne.kubeRBACProxy.proxyEndpointsPort, name: "http-healthz", if ne.kubeRBACProxy.enableProxyEndpointsHostPort {hostPort: ne.kubeRBACProxy.proxyEndpointsPort}}]
						readinessProbe: {httpGet: {scheme: "HTTPS", port: ne.kubeRBACProxy.proxyEndpointsPort, path: "healthz"}, initialDelaySeconds: 5, timeoutSeconds: 5}
						if len(ne.kubeRBACProxy.resources) > 0 {resources: ne.kubeRBACProxy.resources}
						if len(ne.kubeRBACProxy.env) > 0 {env: [for k, v in ne.kubeRBACProxy.env {name: k, value: "\(v)"}]}
						if len(ne.kubeRBACProxy.containerSecurityContext) > 0 {securityContext: ne.kubeRBACProxy.containerSecurityContext}
					}, for c in ne.sidecars {c}]
					if len(ne.imagePullSecrets) > 0 {imagePullSecrets: ne.imagePullSecrets}
					hostNetwork: ne.hostNetwork
					hostPID:     ne.hostPID
					hostIPC:     ne.hostIPC
					if len(ne.affinity) > 0 {affinity: ne.affinity}
					if len(ne.dnsConfig) > 0 {dnsConfig: ne.dnsConfig}
					if len(ne.nodeSelector) > 0 {nodeSelector: ne.nodeSelector}
					if ne.restartPolicy != "" {restartPolicy: ne.restartPolicy}
					if len(ne.tolerations) > 0 {tolerations: ne.tolerations}
					volumes: [
						{name: "proc", hostPath: {path: "/proc"}},
						{name: "sys", hostPath: {path: "/sys"}},
						if ne.hostRootFsMount.enabled {{name: "root", hostPath: {path: "/"}}},
						for m in ne.extraHostVolumeMounts {{name: m.name, hostPath: {path: m.hostPath, if m.type != "" {type: m.type}}}},
						for m in ne.configmaps {{name: m.name, configMap: {name: m.name}}},
						for m in ne.secrets {{name: m.name, secret: {secretName: m.name}}},
						if ne.kubeRBACProxy.enabled {{name: "kube-rbac-proxy-config", configMap: {name: "\(fullname)-rbac-config"}}},
					]
				}
			}
		}
	}

	// 4. templates/endpoints.yaml
	if len(ne.endpoints) > 0 {
		"endpoints": corev1.#Endpoints & {
			apiVersion: "v1"
			kind:       "Endpoints"
			metadata: {
				name:      fullname
				namespace: neNamespace
				labels:    neLabels
			}
			subsets: [{
				addresses: [
					for endpoint in ne.endpoints {
						ip: endpoint
					},
				]
				ports: [{
					name:     ne.service.portName
					port:     9100
					protocol: "TCP"
				}]
			}]
		}
	}

	// 5. templates/extra-manifests.yaml
	for i, manifest in ne.extraManifests {
		"extra-manifest-\(i)": manifest
	}

	// 6. templates/networkpolicy.yaml
	if ne.networkPolicy.enabled {
		"networkpolicy": {
			apiVersion: "networking.k8s.io/v1"
			kind:       "NetworkPolicy"
			metadata: {
				name:      fullname
				namespace: neNamespace
				labels:    neLabels
				if len(ne.service.annotations) > 0 {
					annotations: ne.service.annotations
				}
			}
			spec: {
				ingress: [{
					ports: [{
						port: ne.service.port
					}]
				}]
				policyTypes: [
					"Egress",
					"Ingress",
				]
				podSelector: matchLabels: selectorLabels
			}
		}
	}

	// 7. templates/podmonitor.yaml
	if ne.prometheus.podMonitor.enabled {
		"podmonitor": {
			apiVersion: [if ne.prometheus.podMonitor.apiVersion != "" {ne.prometheus.podMonitor.apiVersion}, "monitoring.coreos.com/v1"][0]
			kind: "PodMonitor"
			metadata: {
				name: fullname
				namespace: [if ne.namespaceOverride != "" {ne.namespaceOverride}, if ne.prometheus.podMonitor.namespace != "" {ne.prometheus.podMonitor.namespace}, #config.metadata.namespace][0]
				labels: neLabels & ne.prometheus.podMonitor.additionalLabels
			}
			spec: {
				jobLabel: [if ne.prometheus.podMonitor.jobLabel != "" {ne.prometheus.podMonitor.jobLabel}, "app.kubernetes.io/name"][0]
				selector: matchLabels: [if len(ne.prometheus.podMonitor.selectorOverride) > 0 {ne.prometheus.podMonitor.selectorOverride}, selectorLabels][0]
				namespaceSelector: matchNames: [
					neNamespace,
				]
				if len(ne.prometheus.podMonitor.attachMetadata) > 0 {
					attachMetadata: ne.prometheus.podMonitor.attachMetadata
				}
				if len(ne.prometheus.podMonitor.podTargetLabels) > 0 {
					podTargetLabels: ne.prometheus.podMonitor.podTargetLabels
				}
				podMetricsEndpoints: [{
					port: ne.service.portName
					if ne.prometheus.podMonitor.scheme != "" {
						scheme: ne.prometheus.podMonitor.scheme
					}
					if ne.prometheus.podMonitor.path != "" {
						path: ne.prometheus.podMonitor.path
					}
					if len(ne.prometheus.podMonitor.basicAuth) > 0 {
						basicAuth: ne.prometheus.podMonitor.basicAuth
					}
					if len(ne.prometheus.podMonitor.bearerTokenSecret) > 0 {
						bearerTokenSecret: ne.prometheus.podMonitor.bearerTokenSecret
					}
					if len(ne.prometheus.podMonitor.tlsConfig) > 0 {
						tlsConfig: ne.prometheus.podMonitor.tlsConfig
					}
					if len(ne.prometheus.podMonitor.authorization) > 0 {
						authorization: ne.prometheus.podMonitor.authorization
					}
					if len(ne.prometheus.podMonitor.oauth2) > 0 {
						oauth2: ne.prometheus.podMonitor.oauth2
					}
					if ne.prometheus.podMonitor.proxyUrl != "" {
						proxyUrl: ne.prometheus.podMonitor.proxyUrl
					}
					if ne.prometheus.podMonitor.interval != "" {
						interval: ne.prometheus.podMonitor.interval
					}
					honorTimestamps: ne.prometheus.podMonitor.honorTimestamps
					honorLabels:     ne.prometheus.podMonitor.honorLabels
					if ne.prometheus.podMonitor.scrapeTimeout != "" {
						scrapeTimeout: ne.prometheus.podMonitor.scrapeTimeout
					}
					if len(ne.prometheus.podMonitor.relabelings) > 0 {
						relabelings: ne.prometheus.podMonitor.relabelings
					}
					if len(ne.prometheus.podMonitor.metricRelabelings) > 0 {
						metricRelabelings: ne.prometheus.podMonitor.metricRelabelings
					}
					enableHttp2:     ne.prometheus.podMonitor.enableHttp2
					filterRunning:   ne.prometheus.podMonitor.filterRunning
					followRedirects: ne.prometheus.podMonitor.followRedirects
				}]
			}
		}
	}

	// 8. templates/psp-clusterrole.yaml
	if ne.rbac.create && ne.rbac.pspEnabled {
		"psp-clusterrole": rbacv1.#ClusterRole & {
			kind:       "ClusterRole"
			apiVersion: "rbac.authorization.k8s.io/v1"
			metadata: {
				name:   "psp-\(fullname)"
				labels: neLabels
			}
			rules: [{
				apiGroups: ["extensions"]
				resources: ["podsecuritypolicies"]
				verbs: ["use"]
				resourceNames: [
					fullname,
				]
			}]
		}
	}

	// 9. templates/psp-clusterrolebinding.yaml
	if ne.rbac.create && ne.rbac.pspEnabled {
		"psp-clusterrolebinding": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: {
				name:   "psp-\(fullname)"
				labels: neLabels
			}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "psp-\(fullname)"
			}
			subjects: [{
				kind:      "ServiceAccount"
				name:      fullname
				namespace: neNamespace
			}]
		}
	}

	// 10. templates/psp.yaml
	if ne.rbac.create && ne.rbac.pspEnabled {
		"psp": {
			apiVersion: "policy/v1beta1"
			kind:       "PodSecurityPolicy"
			metadata: {
				name:      fullname
				namespace: neNamespace
				labels:    neLabels
				if len(ne.rbac.pspAnnotations) > 0 {
					annotations: ne.rbac.pspAnnotations
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
					"hostPath",
				]
				hostNetwork: true
				hostIPC:     false
				hostPID:     true
				hostPorts: [{
					min: 0
					max: 65535
				}]
				runAsUser: rule: "RunAsAny"
				seLinux: rule:   "RunAsAny"
				supplementalGroups: {
					rule: "MustRunAs"
					ranges: [{
						min: 0
						max: 65535
					}]
				}
				fsGroup: {
					rule: "MustRunAs"
					ranges: [{
						min: 0
						max: 65535
					}]
				}
				readOnlyRootFilesystem: false
			}
		}
	}

	// 11. templates/rbac-configmap.yaml
	if ne.kubeRBACProxy.enabled {
		"rbac-configmap": corev1.#ConfigMap & {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      "\(fullname)-rbac-config"
				namespace: neNamespace
			}
			data: {
				"config-file.yaml": "authorization:\n  resourceAttributes:\n    namespace: \(neNamespace)\n    apiVersion: v1\n    resource: services\n    subresource: \(fullname)\n    name: \(fullname)\n"
			}
		}
	}

	// 12. templates/service.yaml
	if ne.service.enabled {
		"service": corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      fullname
				namespace: neNamespace
				labels:    neLabels & ne.service.labels
				if len(ne.service.annotations) > 0 {
					annotations: ne.service.annotations
				}
			}
			spec: {
				if ne.service.ipDualStack.enabled {
					ipFamilies:     ne.service.ipDualStack.ipFamilies
					ipFamilyPolicy: ne.service.ipDualStack.ipFamilyPolicy
				}
				if ne.service.externalTrafficPolicy != "" {
					externalTrafficPolicy: ne.service.externalTrafficPolicy
				}
				type: ne.service.type
				if ne.service.type == "ClusterIP" && ne.service.clusterIP != "" {
					clusterIP: ne.service.clusterIP
				}
				ports: [{
					port: [if ne.service.servicePort != 0 {ne.service.servicePort}, ne.service.port][0]
					if ne.service.type == "NodePort" && ne.service.nodePort != 0 {
						nodePort: ne.service.nodePort
					}
					targetPort: ne.service.targetPort
					protocol:   "TCP"
					name:       ne.service.portName
				}]
				selector: selectorLabels
			}
		}
	}

	// 13. templates/serviceaccount.yaml
	if ne.rbac.create && ne.serviceAccount.create {
		"serviceaccount": corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name:      neServiceAccountName
				namespace: neNamespace
				labels:    neLabels
				if len(ne.serviceAccount.annotations) > 0 {
					annotations: ne.serviceAccount.annotations
				}
			}
			automountServiceAccountToken: ne.serviceAccount.automountServiceAccountToken
			if len(ne.serviceAccount.imagePullSecrets) > 0 {
				imagePullSecrets: ne.serviceAccount.imagePullSecrets
			}
		}
	}

	// 14. templates/servicemonitor.yaml
	if ne.prometheus.monitor.enabled {
		"servicemonitor": {
			apiVersion: [if ne.prometheus.monitor.apiVersion != "" {ne.prometheus.monitor.apiVersion}, "monitoring.coreos.com/v1"][0]
			kind: "ServiceMonitor"
			metadata: {
				name: fullname
				namespace: [if ne.namespaceOverride != "" {ne.namespaceOverride}, if ne.prometheus.monitor.namespace != "" {ne.prometheus.monitor.namespace}, #config.metadata.namespace][0]
				labels: neLabels & ne.prometheus.monitor.additionalLabels
			}
			spec: {
				jobLabel: [if ne.prometheus.monitor.jobLabel != "" {ne.prometheus.monitor.jobLabel}, "app.kubernetes.io/name"][0]
				if len(ne.prometheus.monitor.podTargetLabels) > 0 {
					podTargetLabels: ne.prometheus.monitor.podTargetLabels
				}
				selector: matchLabels: [if len(ne.prometheus.monitor.selectorOverride) > 0 {ne.prometheus.monitor.selectorOverride}, selectorLabels][0]
				if len(ne.prometheus.monitor.attachMetadata) > 0 {
					attachMetadata: ne.prometheus.monitor.attachMetadata
				}
				endpoints: [{
					port:   ne.service.portName
					scheme: ne.prometheus.monitor.scheme
					if ne.prometheus.monitor.bearerTokenFile != "" {
						bearerTokenFile: ne.prometheus.monitor.bearerTokenFile
					}
					if ne.prometheus.monitor.proxyUrl != "" {
						proxyUrl: ne.prometheus.monitor.proxyUrl
					}
					if ne.prometheus.monitor.interval != "" {
						interval: ne.prometheus.monitor.interval
					}
					if ne.prometheus.monitor.scrapeTimeout != "" {
						scrapeTimeout: ne.prometheus.monitor.scrapeTimeout
					}
					if len(ne.prometheus.monitor.relabelings) > 0 {
						relabelings: ne.prometheus.monitor.relabelings
					}
					if len(ne.prometheus.monitor.metricRelabelings) > 0 {
						metricRelabelings: ne.prometheus.monitor.metricRelabelings
					}
				}]
			}
		}
	}

	// 15. templates/verticalpodautoscaler.yaml
	if ne.verticalPodAutoscaler.enabled {
		"verticalpodautoscaler": {
			apiVersion: "autoscaling.k8s.io/v1"
			kind:       "VerticalPodAutoscaler"
			metadata: {name: fullname, namespace: neNamespace, labels: neLabels}
			spec: {
				if len(ne.verticalPodAutoscaler.recommenders) > 0 {
					recommenders: ne.verticalPodAutoscaler.recommenders
				}
				resourcePolicy: containerPolicies: [{
					containerName: "node-exporter"
					if len(ne.verticalPodAutoscaler.controlledResources) > 0 {
						controlledResources: ne.verticalPodAutoscaler.controlledResources
					}
					if ne.verticalPodAutoscaler.controlledValues != "" {
						controlledValues: ne.verticalPodAutoscaler.controlledValues
					}
					if len(ne.verticalPodAutoscaler.maxAllowed) > 0 {
						maxAllowed: ne.verticalPodAutoscaler.maxAllowed
					}
					if len(ne.verticalPodAutoscaler.minAllowed) > 0 {
						minAllowed: ne.verticalPodAutoscaler.minAllowed
					}
				}]
				targetRef: {apiVersion: "apps/v1", kind: "DaemonSet", name: fullname}
				if len(ne.verticalPodAutoscaler.updatePolicy) > 0 {
					updatePolicy: ne.verticalPodAutoscaler.updatePolicy
				}
			}
		}
	}
}
