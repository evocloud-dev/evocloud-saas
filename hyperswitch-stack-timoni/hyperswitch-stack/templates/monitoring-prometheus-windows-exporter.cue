package templates

import (
	"list"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#PrometheusWindowsExporterName: {
	#config: #Config
	let win = #config."hyperswitch-monitoring"."kube-prometheus-stack"."prometheus-windows-exporter"
	result: [if win.nameOverride != "" {win.nameOverride}, "prometheus-windows-exporter"][0]
}

#PrometheusWindowsExporterFullname: {
	#config: #Config
	let win = #config."hyperswitch-monitoring"."kube-prometheus-stack"."prometheus-windows-exporter"
	let name = (#PrometheusWindowsExporterName & {#config: #config}).result
	result: [if win.fullnameOverride != "" {win.fullnameOverride}, "\(#config.metadata.name)-\(name)"][0]
}

#PrometheusWindowsExporterSelectorLabels: {
	#config: #Config
	let name = (#PrometheusWindowsExporterName & {#config: #config}).result
	result: {"app.kubernetes.io/name": name, "app.kubernetes.io/instance": #config.metadata.name}
}

#PrometheusWindowsExporterLabels: {
	#config: #Config
	let win = #config."hyperswitch-monitoring"."kube-prometheus-stack"."prometheus-windows-exporter"
	let name = (#PrometheusWindowsExporterName & {#config: #config}).result
	result: (#PrometheusWindowsExporterSelectorLabels & {#config: #config}).result & win.podLabels & {
		"helm.sh/chart":                "prometheus-windows-exporter-0.7.1"
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/component":  "metrics"
		"app.kubernetes.io/part-of":    name
		"app.kubernetes.io/version":    "0.25.1"
		if win.releaseLabel {release: #config.metadata.name}
	}
}

#PrometheusWindowsExporterServiceAccountName: {
	#config: #Config
	let win = #config."hyperswitch-monitoring"."kube-prometheus-stack"."prometheus-windows-exporter"
	let fullname = (#PrometheusWindowsExporterFullname & {#config: #config}).result
	result: string
	if win.serviceAccount.create && win.serviceAccount.name != "" {result: win.serviceAccount.name}
	if win.serviceAccount.create && win.serviceAccount.name == "" {result: fullname}
	if !win.serviceAccount.create && win.serviceAccount.name != "" {result: win.serviceAccount.name}
	if !win.serviceAccount.create && win.serviceAccount.name == "" {result: "default"}
}

#PrometheusWindowsExporterImage: {
	#config: #Config
	let win = #config."hyperswitch-monitoring"."kube-prometheus-stack"."prometheus-windows-exporter"
	let registry = [if win.global.imageRegistry != "" {win.global.imageRegistry}, win.image.registry][0]
	let tag = [if win.image.tag != "" {win.image.tag}, "0.25.1"][0]
	result: [if win.image.digest != "" {"\(registry)/\(win.image.repository):\(tag)@\(win.image.digest)"}, "\(registry)/\(win.image.repository):\(tag)"][0]
}

// Registry for prometheus-windows-exporter rendered objects; the let bindings below cache Helm helper equivalents and shared values used by every converted template.
monitoringPrometheusWindowsExporter: {
	#config: #Config
	let win = #config."hyperswitch-monitoring"."kube-prometheus-stack"."prometheus-windows-exporter"
	let fullname = (#PrometheusWindowsExporterFullname & {#config: #config}).result
	let winNamespace = [if win.namespaceOverride != "" {win.namespaceOverride}, #config.metadata.namespace][0]
	let winLabels = (#PrometheusWindowsExporterLabels & {#config: #config}).result
	let selectorLabels = (#PrometheusWindowsExporterSelectorLabels & {#config: #config}).result
	let winServiceAccountName = (#PrometheusWindowsExporterServiceAccountName & {#config: #config}).result

	// 1. templates/config.yaml
	"config": corev1.#ConfigMap & {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      fullname
			namespace: winNamespace
			labels:    winLabels
			if len(win.service.annotations) > 0 {
				annotations: win.service.annotations
			}
		}
		data: {
			"config.yml": win.config
		}
	}

	// 2. templates/daemonset.yaml
	"daemonset": appsv1.#DaemonSet & {
		apiVersion: "apps/v1"
		kind:       "DaemonSet"
		metadata: {
			name:      fullname
			namespace: winNamespace
			labels:    winLabels
			if len(win.daemonsetAnnotations) > 0 {
				annotations: win.daemonsetAnnotations
			}
		}
		spec: {
			selector: matchLabels: selectorLabels
			if len(win.updateStrategy) > 0 {
				updateStrategy: win.updateStrategy
			}
			template: {
				metadata: {
					if len(win.podAnnotations) > 0 {
						annotations: win.podAnnotations
					}
					labels: winLabels
				}
				spec: {
					automountServiceAccountToken: win.serviceAccount.automountServiceAccountToken
					if len(win.securityContext) > 0 {
						securityContext: win.securityContext
					}
					if win.priorityClassName != "" {
						priorityClassName: win.priorityClassName
					}
					initContainers: [{
						name: "configure-firewall"
						image: (#PrometheusWindowsExporterImage & {#config: #config}).result
						command: ["powershell"]
						args: ["New-NetFirewallRule", "-DisplayName", "'windows-exporter'", "-Direction", "inbound", "-Profile", "Any", "-Action", "Allow", "-LocalPort", "\(win.service.port)", "-Protocol", "TCP"]
					}, for c in win.extraInitContainers {c}]
					serviceAccountName: winServiceAccountName
					containers: [{
						name: "windows-exporter"
						image: (#PrometheusWindowsExporterImage & {#config: #config}).result
						imagePullPolicy: win.image.pullPolicy
						args: list.Concat([["--config.file=%CONTAINER_SANDBOX_MOUNT_POINT%/config.yml", "--collector.textfile.directories=%CONTAINER_SANDBOX_MOUNT_POINT%", "--web.listen-address=:\(win.service.port)"], win.extraArgs])
						if len(win.containerSecurityContext) > 0 {
							securityContext: win.containerSecurityContext
						}
						env: [for k, v in win.env {name: k, value: "\(v)"}]
						ports: [{
							name:          win.service.portName
							containerPort: win.service.port
							protocol:      "TCP"
						}]
						livenessProbe: win.livenessProbe.value & {httpGet: {path: win.livenessProbe.httpGet.path, port: win.service.port, scheme: win.livenessProbe.httpGet.scheme, httpHeaders: win.livenessProbe.httpGet.httpHeaders}}
						readinessProbe: win.readinessProbe.value & {httpGet: {path: win.readinessProbe.httpGet.path, port: win.service.port, scheme: win.readinessProbe.httpGet.scheme, httpHeaders: win.readinessProbe.httpGet.httpHeaders}}
						if len(win.resources) > 0 {
							resources: win.resources
						}
						volumeMounts: [{name: "config", mountPath: "/config.yml", subPath: "config.yml"}, for m in win.extraHostVolumeMounts {name: m.name, mountPath: m.mountPath, readOnly: m.readOnly}, for m in win.configmaps {name: m.name, mountPath: m.mountPath}, for m in win.secrets {name: m.name, mountPath: m.mountPath}]
					}, for c in win.sidecars {c}]
					if len(win.imagePullSecrets) > 0 {
						imagePullSecrets: win.imagePullSecrets
					}
					hostNetwork: win.hostNetwork
					hostPID:     win.hostPID
					if len(win.affinity) > 0 {affinity: win.affinity}
					if len(win.dnsConfig) > 0 {dnsConfig: win.dnsConfig}
					if len(win.nodeSelector) > 0 {nodeSelector: win.nodeSelector}
					if len(win.tolerations) > 0 {tolerations: win.tolerations}
					volumes: [
						{name: "config", configMap: {name: fullname}},
						for m in win.extraHostVolumeMounts {name: m.name, hostPath: path: m.hostPath},
						for m in win.configmaps {name: m.name, configMap: {name: m.name}},
						for m in win.secrets {name: m.name, secret: secretName: m.name},
					]
				}
			}
		}
	}

	// 3. templates/podmonitor.yaml
	if win.prometheus.podMonitor.enabled {
		"podmonitor": {
			apiVersion: [if win.prometheus.podMonitor.apiVersion != "" {win.prometheus.podMonitor.apiVersion}, "monitoring.coreos.com/v1"][0]
			kind: "PodMonitor"
			metadata: {
				name: fullname
				namespace: [if win.namespaceOverride != "" {win.namespaceOverride}, if win.prometheus.podMonitor.namespace != "" {win.prometheus.podMonitor.namespace}, #config.metadata.namespace][0]
				labels: winLabels & win.prometheus.podMonitor.additionalLabels
			}
			spec: {
				jobLabel: [if win.prometheus.podMonitor.jobLabel != "" {win.prometheus.podMonitor.jobLabel}, "app.kubernetes.io/name"][0]
				selector: matchLabels: [if len(win.prometheus.podMonitor.selectorOverride) > 0 {win.prometheus.podMonitor.selectorOverride}, selectorLabels][0]
				namespaceSelector: matchNames: [winNamespace]
				if len(win.prometheus.podMonitor.attachMetadata) > 0 {attachMetadata: win.prometheus.podMonitor.attachMetadata}
				if len(win.prometheus.podMonitor.podTargetLabels) > 0 {podTargetLabels: win.prometheus.podMonitor.podTargetLabels}
				podMetricsEndpoints: [{
					port: win.service.portName
					if win.prometheus.podMonitor.scheme != "" {scheme: win.prometheus.podMonitor.scheme}
					if win.prometheus.podMonitor.path != "" {path: win.prometheus.podMonitor.path}
					if len(win.prometheus.podMonitor.basicAuth) > 0 {basicAuth: win.prometheus.podMonitor.basicAuth}
					if len(win.prometheus.podMonitor.bearerTokenSecret) > 0 {bearerTokenSecret: win.prometheus.podMonitor.bearerTokenSecret}
					if len(win.prometheus.podMonitor.tlsConfig) > 0 {tlsConfig: win.prometheus.podMonitor.tlsConfig}
					if len(win.prometheus.podMonitor.authorization) > 0 {authorization: win.prometheus.podMonitor.authorization}
					if len(win.prometheus.podMonitor.oauth2) > 0 {oauth2: win.prometheus.podMonitor.oauth2}
					if win.prometheus.podMonitor.proxyUrl != "" {proxyUrl: win.prometheus.podMonitor.proxyUrl}
					if win.prometheus.podMonitor.interval != "" {interval: win.prometheus.podMonitor.interval}
					honorTimestamps: win.prometheus.podMonitor.honorTimestamps
					honorLabels:     win.prometheus.podMonitor.honorLabels
					if win.prometheus.podMonitor.scrapeTimeout != "" {scrapeTimeout: win.prometheus.podMonitor.scrapeTimeout}
					if len(win.prometheus.podMonitor.relabelings) > 0 {relabelings: win.prometheus.podMonitor.relabelings}
					if len(win.prometheus.podMonitor.metricRelabelings) > 0 {metricRelabelings: win.prometheus.podMonitor.metricRelabelings}
					enableHttp2:     win.prometheus.podMonitor.enableHttp2
					filterRunning:   win.prometheus.podMonitor.filterRunning
					followRedirects: win.prometheus.podMonitor.followRedirects
				}]
			}
		}
	}

	// 4. templates/service.yaml
	"service": corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      fullname
			namespace: winNamespace
			labels:    winLabels
			if win.prometheus.monitor.enabled || win.prometheus.podMonitor.enabled {
				if len(win.service.annotations) > 0 {
					annotations: win.service.annotations
				}
			}
			if !win.prometheus.monitor.enabled && !win.prometheus.podMonitor.enabled {
				annotations: win.service.annotations & {"prometheus.io/scrape": "true"}
			}
		}
		spec: {
			type: win.service.type
			ports: [{
				port: win.service.port
				if win.service.type == "NodePort" && win.service.nodePort > 0 {nodePort: win.service.nodePort}
				targetPort:  win.service.portName
				protocol:    "TCP"
				appProtocol: "http"
				name:        win.service.portName
			}]
			selector: selectorLabels
		}
	}

	// 5. templates/serviceaccount.yaml
	if win.rbac.create && win.serviceAccount.create {
		"serviceaccount": corev1.#ServiceAccount & {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name:      winServiceAccountName
				namespace: winNamespace
				labels:    winLabels
				if len(win.serviceAccount.annotations) > 0 {annotations: win.serviceAccount.annotations}
			}
			if len(win.serviceAccount.imagePullSecrets) > 0 {imagePullSecrets: win.serviceAccount.imagePullSecrets}
		}
	}

	// 6. templates/servicemonitor.yaml
	if win.prometheus.monitor.enabled {
		"servicemonitor": {
			apiVersion: [if win.prometheus.monitor.apiVersion != "" {win.prometheus.monitor.apiVersion}, "monitoring.coreos.com/v1"][0]
			kind: "ServiceMonitor"
			metadata: {
				name: fullname
				namespace: [if win.namespaceOverride != "" {win.namespaceOverride}, if win.prometheus.monitor.namespace != "" {win.prometheus.monitor.namespace}, #config.metadata.namespace][0]
				labels: winLabels & win.prometheus.monitor.additionalLabels
			}
			spec: {
				jobLabel: [if win.prometheus.monitor.jobLabel != "" {win.prometheus.monitor.jobLabel}, "app.kubernetes.io/name"][0]
				if len(win.prometheus.monitor.podTargetLabels) > 0 {podTargetLabels: win.prometheus.monitor.podTargetLabels}
				selector: matchLabels: [if len(win.prometheus.monitor.selectorOverride) > 0 {win.prometheus.monitor.selectorOverride}, selectorLabels][0]
				if len(win.prometheus.monitor.attachMetadata) > 0 {attachMetadata: win.prometheus.monitor.attachMetadata}
				endpoints: [{
					port:   win.service.portName
					scheme: win.prometheus.monitor.scheme
					if len(win.prometheus.monitor.basicAuth) > 0 {basicAuth: win.prometheus.monitor.basicAuth}
					if win.prometheus.monitor.bearerTokenFile != "" {bearerTokenFile: win.prometheus.monitor.bearerTokenFile}
					if len(win.prometheus.monitor.tlsConfig) > 0 {tlsConfig: win.prometheus.monitor.tlsConfig}
					if win.prometheus.monitor.proxyUrl != "" {proxyUrl: win.prometheus.monitor.proxyUrl}
					if win.prometheus.monitor.interval != "" {interval: win.prometheus.monitor.interval}
					if win.prometheus.monitor.scrapeTimeout != "" {scrapeTimeout: win.prometheus.monitor.scrapeTimeout}
					if len(win.prometheus.monitor.relabelings) > 0 {relabelings: win.prometheus.monitor.relabelings}
					if len(win.prometheus.monitor.metricRelabelings) > 0 {metricRelabelings: win.prometheus.monitor.metricRelabelings}
				}]
			}
		}
	}
}
