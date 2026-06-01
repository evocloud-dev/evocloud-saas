package templates

import (
	apps_v1 "k8s.io/api/apps/v1"
	core_v1 "k8s.io/api/core/v1"
)

monitoringLokiBloomGateway: {
	#config: #Config
	let _loki_conf = #config."hyperswitch-monitoring".loki
	let ns = #config.metadata.namespace

	_isDistributed:         _loki_conf.deploymentMode == "Distributed"
	_isBloomGatewayEnabled: _isDistributed && (_loki_conf.bloomGateway.replicas > 0)

	_labels: {
		"helm.sh/chart":              "loki-5.36.2"
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": #config.metadata.name
		"app.kubernetes.io/version": [if _loki_conf.image.tag != "" {_loki_conf.image.tag}, #config.moduleVersion][0]
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/component":  "bloom-gateway"
	}

	_selectorLabels: {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  #config.metadata.name
		"app.kubernetes.io/component": "bloom-gateway"
	}

	if _isBloomGatewayEnabled {
		// 1. statefulset-bloom-gateway.yaml
		"statefulset": apps_v1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "\(#config.metadata.name)-loki-bloom-gateway"
				namespace: ns
				labels:    _labels & _loki_conf.bloomGateway.labels
				if _loki_conf.loki.annotations != _|_ {
					annotations: _loki_conf.loki.annotations
				}
			}
			spec: {
				replicas:            _loki_conf.bloomGateway.replicas
				podManagementPolicy: "Parallel"
				updateStrategy: rollingUpdate: partition: 0
				serviceName:          "\(#config.metadata.name)-loki-bloom-gateway-headless"
				revisionHistoryLimit: _loki_conf.loki.revisionHistoryLimit

				selector: matchLabels: _selectorLabels
				template: {
					metadata: {
						labels: _labels & _loki_conf.bloomGateway.podLabels
					}
					spec: {
						serviceAccountName: [if _loki_conf.serviceAccount.name != "" {_loki_conf.serviceAccount.name}, "loki"][0]
						if len(_loki_conf.imagePullSecrets) > 0 {
							imagePullSecrets: _loki_conf.imagePullSecrets
						}
						if _loki_conf.bloomGateway.priorityClassName != "" {priorityClassName: _loki_conf.bloomGateway.priorityClassName}
						securityContext:               _loki_conf.bloomGateway.podSecurityContext
						terminationGracePeriodSeconds: _loki_conf.bloomGateway.terminationGracePeriodSeconds
						containers: [{
							name:            "bloom-gateway"
							image:           "\(_loki_conf.image.registry)/\(_loki_conf.bloomGateway.image.repository):\(_loki_conf.image.tag)"
							imagePullPolicy: _loki_conf.image.pullPolicy
							ports: [{name: "http-metrics", containerPort: _loki_conf.bloomGateway.containerPort, protocol: "TCP"}]
							if len(_loki_conf.bloomGateway.extraEnv) > 0 {env: _loki_conf.bloomGateway.extraEnv}
							if len(_loki_conf.bloomGateway.extraEnvFrom) > 0 {envFrom: _loki_conf.bloomGateway.extraEnvFrom}
							readinessProbe:  _loki_conf.bloomGateway.readinessProbe
							livenessProbe:   _loki_conf.bloomGateway.livenessProbe
							securityContext: _loki_conf.bloomGateway.containerSecurityContext
							volumeMounts: [
								{name: "config", mountPath: "/etc/loki/config"},
								{name: "runtime-config", mountPath: "/etc/loki/runtime-config"},
								if _loki_conf.enterprise.enabled {name: "license", mountPath: "/etc/loki/license"},
								for volumeMount in _loki_conf.bloomGateway.extraVolumeMounts {volumeMount},
							]
							resources: _loki_conf.bloomGateway.resources
						}, for container in _loki_conf.bloomGateway.extraContainers {container}]
						if len(_loki_conf.bloomGateway.affinity) > 0 {
							affinity: _loki_conf.bloomGateway.affinity
						}
						if len(_loki_conf.bloomGateway.nodeSelector) > 0 {nodeSelector: _loki_conf.bloomGateway.nodeSelector}
						if len(_loki_conf.bloomGateway.topologySpreadConstraints) > 0 {topologySpreadConstraints: _loki_conf.bloomGateway.topologySpreadConstraints}
						if len(_loki_conf.bloomGateway.tolerations) > 0 {tolerations: _loki_conf.bloomGateway.tolerations}
						volumes: [
							{name: "config", configMap: {name: "\(#config.metadata.name)-loki-bloom-gateway"}},
							if _loki_conf.enterprise.enabled {
								name: "license"
								secret: secretName: [if _loki_conf.enterprise.useExternalLicense {_loki_conf.enterprise.externalLicenseName}, "enterprise-logs-license"][0]
							},
							for volume in _loki_conf.bloomGateway.extraVolumes {volume},
						]
					}
				}
			}
		}

		// 2. service-bloom-gateway-headless.yaml
		"service": core_v1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-loki-bloom-gateway-headless"
				namespace: ns
				labels:    _labels & _loki_conf.loki.serviceLabels & _loki_conf.bloomGateway.service.labels
				if len(_loki_conf.loki.serviceAnnotations) > 0 || len(_loki_conf.bloomGateway.service.annotations) > 0 {
					annotations: _loki_conf.loki.serviceAnnotations & _loki_conf.bloomGateway.service.annotations
				}
			}
			spec: {
				type: _loki_conf.bloomGateway.service.type
				if _loki_conf.bloomGateway.service.clusterIP != null {clusterIP: _loki_conf.bloomGateway.service.clusterIP}
				if _loki_conf.bloomGateway.service.type == "LoadBalancer" && _loki_conf.bloomGateway.service.loadBalancerIP != null {loadBalancerIP: _loki_conf.bloomGateway.service.loadBalancerIP}
				if _loki_conf.bloomGateway.service.type == "LoadBalancer" && _loki_conf.bloomGateway.service.loadBalancerClass != null {loadBalancerClass: _loki_conf.bloomGateway.service.loadBalancerClass}
				ports: [{name: "http-metrics", port: _loki_conf.bloomGateway.service.port, targetPort: "http-metrics", if _loki_conf.bloomGateway.service.type == "NodePort" && _loki_conf.bloomGateway.service.nodePort != null {nodePort: _loki_conf.bloomGateway.service.nodePort}, protocol: "TCP"}]
				selector: _selectorLabels
			}
		}
	}
}
