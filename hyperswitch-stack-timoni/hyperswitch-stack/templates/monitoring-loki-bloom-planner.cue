package templates

import (
	apps_v1 "k8s.io/api/apps/v1"
	core_v1 "k8s.io/api/core/v1"
)

monitoringLokiBloomPlanner: {
	#config: #Config
	let _loki_conf = #config."hyperswitch-monitoring".loki
	let ns = #config.metadata.namespace

	_isDistributed:         _loki_conf.deploymentMode == "Distributed"
	_isBloomPlannerEnabled: _isDistributed && (_loki_conf.bloomPlanner.replicas > 0)

	_labels: {
		"helm.sh/chart":              "loki-5.36.2"
		"app.kubernetes.io/name":     "loki"
		"app.kubernetes.io/instance": #config.metadata.name
		"app.kubernetes.io/version": [if _loki_conf.image.tag != "" {_loki_conf.image.tag}, #config.moduleVersion][0]
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/component":  "bloom-planner"
	}

	_selectorLabels: {
		"app.kubernetes.io/name":      "loki"
		"app.kubernetes.io/instance":  #config.metadata.name
		"app.kubernetes.io/component": "bloom-planner"
	}

	if _isBloomPlannerEnabled {
		// 1. statefulset-bloom-planner.yaml
		"statefulset": apps_v1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "\(#config.metadata.name)-loki-bloom-planner"
				namespace: ns
				labels:    _labels & _loki_conf.bloomPlanner.labels
				if _loki_conf.loki.annotations != _|_ {
					annotations: _loki_conf.loki.annotations
				}
			}
			spec: {
				replicas:            _loki_conf.bloomPlanner.replicas
				podManagementPolicy: "Parallel"
				updateStrategy: rollingUpdate: partition: 0
				serviceName:          "\(#config.metadata.name)-loki-bloom-planner-headless"
				revisionHistoryLimit: _loki_conf.loki.revisionHistoryLimit

				selector: matchLabels: _selectorLabels
				template: {
					metadata: {
						annotations: {
							"checksum/config": "TODO_SHA256"
							for k, v in _loki_conf.loki.podAnnotations {
								"\(k)": v
							}
							for k, v in _loki_conf.bloomPlanner.podAnnotations {
								"\(k)": v
							}
						}
						labels: _selectorLabels & _loki_conf.loki.podLabels & _loki_conf.bloomPlanner.podLabels & {
							"app.kubernetes.io/part-of": "memberlist"
						}
					}
					spec: {
						serviceAccountName: [if _loki_conf.rbac.namespaced {"\(#config.metadata.name)-loki"}, "default"][0]
						if len(_loki_conf.imagePullSecrets) > 0 {
							imagePullSecrets: _loki_conf.imagePullSecrets
						}
						if len(_loki_conf.bloomPlanner.hostAliases) > 0 {
							hostAliases: _loki_conf.bloomPlanner.hostAliases
						}
						if _loki_conf.bloomPlanner.priorityClassName != "" {
							priorityClassName: _loki_conf.bloomPlanner.priorityClassName
						}
						securityContext:               _loki_conf.loki.podSecurityContext
						terminationGracePeriodSeconds: _loki_conf.bloomPlanner.terminationGracePeriodSeconds

						if len(_loki_conf.bloomPlanner.initContainers) > 0 {
							initContainers: _loki_conf.bloomPlanner.initContainers
						}

						let loki_tag = [if _loki_conf.image.tag != "" {_loki_conf.image.tag}, #config.moduleVersion][0]
						containers: [
							{
								name:            "bloom-planner"
								image:           "\(_loki_conf.image.repository):\(loki_tag)"
								imagePullPolicy: _loki_conf.image.pullPolicy
								if _loki_conf.bloomPlanner.command != null {
									command: [_loki_conf.bloomPlanner.command]
								}
								args: [
									"-config.file=/etc/loki/config/config.yaml",
									"-target=bloom-planner",
									for arg in _loki_conf.bloomPlanner.extraArgs {
										arg
									},
								]
								ports: [
									{
										name:          "http-metrics"
										containerPort: 3100
										protocol:      "TCP"
									},
									{
										name:          "grpc"
										containerPort: 9095
										protocol:      "TCP"
									},
									{
										name:          "http-memberlist"
										containerPort: 7946
										protocol:      "TCP"
									},
								]
								if len(_loki_conf.bloomPlanner.extraEnv) > 0 {
									env: _loki_conf.bloomPlanner.extraEnv
								}
								if len(_loki_conf.bloomPlanner.extraEnvFrom) > 0 {
									envFrom: _loki_conf.bloomPlanner.extraEnvFrom
								}
								securityContext: _loki_conf.loki.containerSecurityContext
								readinessProbe:  _loki_conf.loki.readinessProbe
								volumeMounts: [
									{
										name:      "temp"
										mountPath: "/tmp"
									},
									{
										name:      "config"
										mountPath: "/etc/loki/config"
									},
									{
										name:      "runtime-config"
										mountPath: "/etc/loki/runtime-config"
									},
									{
										name:      "data"
										mountPath: "/var/loki"
									},
									if _loki_conf.enterprise.enabled {
										{
											name:      "license"
											mountPath: "/etc/loki/license"
										}
									},
									for vm in _loki_conf.bloomPlanner.extraVolumeMounts {
										vm
									},
								]
								resources: _loki_conf.bloomPlanner.resources
							},
						]
						if len(_loki_conf.bloomPlanner.extraContainers) > 0 {
							for c in _loki_conf.bloomPlanner.extraContainers {
								containers: [c]
							}
						}
						affinity:     _loki_conf.bloomPlanner.affinity
						nodeSelector: _loki_conf.bloomPlanner.nodeSelector
						tolerations:  _loki_conf.bloomPlanner.tolerations
						volumes: [
							{
								name: "temp"
								emptyDir: {}
							},
							{
								name: "config"
								configMap: {name: _loki_conf.loki.generatedConfigObjectName}
							},
							{
								name: "runtime-config"
								configMap: {name: "\(#config.metadata.name)-loki-runtime"}
							},
							if !_loki_conf.bloomPlanner.persistence.enabled {
								{
									name: "data"
									emptyDir: {}
								}
							},
							if _loki_conf.enterprise.enabled {
								{
									name: "license"
									secret: secretName: [if _loki_conf.enterprise.useExternalLicense {_loki_conf.enterprise.externalLicenseName}, "enterprise-logs-license"][0]
								}
							},
							for v in _loki_conf.bloomPlanner.extraVolumes {
								v
							},
						]
					}
				}
				if _loki_conf.bloomPlanner.persistence.enabled {
					volumeClaimTemplates: [
						for claim in _loki_conf.bloomPlanner.persistence.claims {
							{
								metadata: {
									name: claim.name
									if len(claim.annotations) > 0 {
										annotations: claim.annotations
									}
								}
								spec: {
									accessModes: ["ReadWriteOnce"]
									if claim.storageClass != null {
										storageClassName: claim.storageClass
									}
									resources: requests: storage: claim.size
								}
							}
						},
					]
				}
			}
		}

		// 2. service-bloom-planner-headless.yaml
		"service-headless": core_v1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-loki-bloom-planner-headless"
				namespace: ns
				labels: _labels & _loki_conf.loki.serviceLabels & _loki_conf.bloomPlanner.service.labels & {
					variant:                         "headless"
					"prometheus.io/service-monitor": "false"
				}
				annotations: _loki_conf.loki.serviceAnnotations & _loki_conf.bloomPlanner.service.annotations
			}
			spec: {
				clusterIP: "None"
				ports: [
					{
						name:       "http-metrics"
						port:       3100
						protocol:   "TCP"
						targetPort: "http-metrics"
					},
					{
						name:       "grpc"
						port:       9095
						protocol:   "TCP"
						targetPort: "grpc"
					},
				]
				selector: _selectorLabels
			}
		}
	}
}
