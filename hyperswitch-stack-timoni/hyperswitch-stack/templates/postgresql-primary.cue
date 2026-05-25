package templates

import (
	"list"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
	"strconv"
)

// 1. /charts/postgresql/templates/primary/configmap.yaml
#PostgresqlPrimaryConfigMap: corev1.#ConfigMap & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.metadata.name + "-postgresql-primary-configuration"
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.commonLabels
		}
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	data: {
		if _pg.primary.configuration != "" {
			"postgresql.conf": _pg.primary.configuration
		}
		if _pg.primary.pgHbaConfiguration != "" {
			"pg_hba.conf": _pg.primary.pgHbaConfiguration
		}
	}
}

// 2. /charts/postgresql/templates/primary/extended-configmap.yaml
#PostgresqlPrimaryExtendedConfigMap: corev1.#ConfigMap & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.metadata.name + "-postgresql-primary-extended-configuration"
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.commonLabels
		}
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	data: {
		"override.conf": _pg.primary.extendedConfiguration
	}
}

// 3. /charts/postgresql/templates/primary/initialization-configmap.yaml
#PostgresqlPrimaryInitConfigMap: corev1.#ConfigMap & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.metadata.name + "-postgresql-primary-init-scripts"
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.commonLabels
		}
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	data: _pg.primary.initdb.scripts
}

// 4. /charts/postgresql/templates/primary/metrics-configmap.yaml
#PostgresqlPrimaryMetricsConfigMap: corev1.#ConfigMap & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.metadata.name + "-postgresql-primary-metrics"
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "metrics"
			_pg.commonLabels
		}
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	data: {
		"custom-metrics.yaml": _pg.metrics.customMetrics
	}
}

// 5. /charts/postgresql/templates/primary/metrics-svc.yaml
#PostgresqlPrimaryMetricsService: corev1.#Service & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.metadata.name + "-postgresql-primary-metrics"
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "metrics"
			_pg.commonLabels
		}
		if len(_pg.commonAnnotations) > 0 || len(_pg.metrics.service.annotations) > 0 {
			annotations: _pg.commonAnnotations & _pg.metrics.service.annotations
		}
	}
	spec: {
		type:            _pg.metrics.service.type
		sessionAffinity: _pg.metrics.service.sessionAffinity
		if _pg.metrics.service.clusterIP != "" {
			clusterIP: _pg.metrics.service.clusterIP
		}
		ports: [
			{
				name:       "http-metrics"
				port:       _pg.metrics.service.ports.metrics
				targetPort: "http-metrics"
			},
		]
		selector: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.primary.podLabels
		}
	}
}

// 6. /charts/postgresql/templates/primary/svc-headless.yaml
#PostgresqlPrimaryHeadlessService: corev1.#Service & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.metadata.name + "-postgresql-primary-headless"
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.commonLabels
		}
		if len(_pg.commonAnnotations) > 0 || len(_pg.primary.service.headless.annotations) > 0 {
			annotations: _pg.commonAnnotations & _pg.primary.service.headless.annotations
		}
	}
	spec: {
		type:                     "ClusterIP"
		clusterIP:                "None"
		publishNotReadyAddresses: true
		ports: [
			{
				name:       "tcp-postgresql"
				port:       _pg.primary.service.ports.postgresql
				targetPort: "tcp-postgresql"
			},
		]
		selector: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.primary.podLabels
		}
	}
}

// 7. /charts/postgresql/templates/primary/svc.yaml
#PostgresqlPrimaryService: corev1.#Service & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		_primaryName: (#GetPrimaryName & {#config: #config}).result
		name:      _primaryName
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.commonLabels
		}
		if len(_pg.commonAnnotations) > 0 || len(_pg.primary.service.annotations) > 0 {
			annotations: _pg.commonAnnotations & _pg.primary.service.annotations
		}
	}
	spec: {
		type: _pg.primary.service.type
		if _pg.primary.service.type == "LoadBalancer" || _pg.primary.service.type == "NodePort" {
			externalTrafficPolicy: _pg.primary.service.externalTrafficPolicy
		}
		if _pg.primary.service.type == "LoadBalancer" {
			if len(_pg.primary.service.loadBalancerSourceRanges) > 0 {
				loadBalancerSourceRanges: _pg.primary.service.loadBalancerSourceRanges
			}
			if _pg.primary.service.loadBalancerClass != "" {
				loadBalancerClass: _pg.primary.service.loadBalancerClass
			}
			if _pg.primary.service.loadBalancerIP != "" {
				loadBalancerIP: _pg.primary.service.loadBalancerIP
			}
		}
		if _pg.primary.service.type == "ClusterIP" {
			if _pg.primary.service.clusterIP != "" {
				clusterIP: _pg.primary.service.clusterIP
			}
		}
		sessionAffinity: _pg.primary.service.sessionAffinity
		if _pg.primary.service.sessionAffinity == "ClientIP" && len(_pg.primary.service.sessionAffinityConfig) > 0 {
			sessionAffinityConfig: _pg.primary.service.sessionAffinityConfig
		}
		ports: list.Concat([[
			{
				name:       "tcp-postgresql"
				port:       _pg.primary.service.ports.postgresql
				targetPort: "tcp-postgresql"
				if _pg.primary.service.type == "NodePort" || _pg.primary.service.type == "LoadBalancer" {
					if _pg.primary.service.nodePorts.postgresql != "" {
						nodePort: _pg.primary.service.nodePorts.postgresql
					}
				}
			},
		], _pg.primary.service.extraPorts])
		selector: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.primary.podLabels
		}
	}
}

// 8. /charts/postgresql/templates/primary/networkpolicy.yaml
#PostgresqlPrimaryNetworkPolicy: {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		_primaryName: (#GetPrimaryName & {#config: #config}).result
		name:      _primaryName
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.commonLabels
		}
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	spec: {
		podSelector: matchLabels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.primary.podLabels
		}
		policyTypes: ["Ingress", "Egress"]
		if _pg.primary.networkPolicy.allowExternalEgress {
			egress: [{}]
		}
		if !_pg.primary.networkPolicy.allowExternalEgress {
			egress: [
				{
					ports: [
						{port: 53, protocol: "UDP"},
						{port: 53, protocol: "TCP"},
					]
				},
				{
					ports: [{port: _pg.containerPorts.postgresql, protocol: "TCP"}]
					to: [{
						podSelector: matchLabels: {
							for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
							"app.kubernetes.io/name":      "postgresql"
							"app.kubernetes.io/instance":  #config.metadata.name
							"app.kubernetes.io/component": "read"
							_pg.commonLabels
						}
					}]
				},
				for ee in _pg.primary.networkPolicy.extraEgress {ee},
			]
		}
		ingress: [
			{
				ports: [
					{port: _pg.containerPorts.postgresql, protocol: "TCP"},
					if _pg.metrics.enabled {
						{port: _pg.metrics.containerPorts.metrics, protocol: "TCP"}
					},
				]
				if !_pg.primary.networkPolicy.allowExternal {
					from: [
						{
							podSelector: matchLabels: {
								for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
								"app.kubernetes.io/name":      "postgresql"
								"app.kubernetes.io/instance":  #config.metadata.name
								"app.kubernetes.io/component": "primary"
								_pg.primary.podLabels
								_pg.commonLabels
							}
						},
						{
							podSelector: matchLabels: {
								_primaryName: (#GetPrimaryName & {#config: #config}).result
								"\(_primaryName)-client": "true"
							}
						},
						if len(_pg.primary.networkPolicy.ingressNSMatchLabels) > 0 {
							{
								namespaceSelector: matchLabels: _pg.primary.networkPolicy.ingressNSMatchLabels
								if len(_pg.primary.networkPolicy.ingressNSPodMatchLabels) > 0 {
									podSelector: matchLabels: _pg.primary.networkPolicy.ingressNSPodMatchLabels
								}
							}
						},
					]
				}
			},
			for ei in _pg.primary.networkPolicy.extraIngress {ei},
		]
	}
}

// 9. /charts/postgresql/templates/primary/pdb.yaml
#PostgresqlPrimaryPDB: policyv1.#PodDisruptionBudget & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		_primaryName: (#GetPrimaryName & {#config: #config}).result
		name:      _primaryName
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.commonLabels
		}
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	spec: {
		if _pg.primary.pdb.minAvailable != "" {
			minAvailable: _pg.primary.pdb.minAvailable
		}
		if _pg.primary.pdb.maxUnavailable != "" {
			maxUnavailable: _pg.primary.pdb.maxUnavailable
		}
		if _pg.primary.pdb.minAvailable == "" && _pg.primary.pdb.maxUnavailable == "" {
			maxUnavailable: 1
		}
		selector: matchLabels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.primary.podLabels
		}
	}
}

// 10. /charts/postgresql/templates/primary/servicemonitor.yaml
#PostgresqlPrimaryServiceMonitor: {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name: #config.metadata.name + "-postgresql-primary"
		namespace: [if _pg.metrics.serviceMonitor.namespace != "" {_pg.metrics.serviceMonitor.namespace}, #config.metadata.namespace][0]
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "metrics"
			_pg.commonLabels
			_pg.metrics.serviceMonitor.labels
		}
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	spec: {
		jobLabel: [if _pg.metrics.serviceMonitor.jobLabel != "" {_pg.metrics.serviceMonitor.jobLabel}, "app.kubernetes.io/name"][0]
		selector: matchLabels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "metrics"
			_pg.metrics.serviceMonitor.selector
		}
		endpoints: [
			{
				port:     "http-metrics"
				interval: _pg.metrics.serviceMonitor.interval
				if _pg.metrics.serviceMonitor.scrapeTimeout != "" {
					scrapeTimeout: _pg.metrics.serviceMonitor.scrapeTimeout
				}
				honorLabels: _pg.metrics.serviceMonitor.honorLabels
				if len(_pg.metrics.serviceMonitor.relabelings) > 0 {
					relabelings: _pg.metrics.serviceMonitor.relabelings
				}
				if len(_pg.metrics.serviceMonitor.metricRelabelings) > 0 {
					metricRelabelings: _pg.metrics.serviceMonitor.metricRelabelings
				}
			},
		]
		namespaceSelector: matchNames: [#config.metadata.namespace]
	}
}

// 11. /charts/postgresql/templates/primary/preinitialization-configmap.yaml
#PostgresqlPrimaryPreInitConfigMap: corev1.#ConfigMap & {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.metadata.name + "-postgresql-primary-pre-init-scripts"
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.commonLabels
		}
		if len(_pg.commonAnnotations) > 0 {
			annotations: _pg.commonAnnotations
		}
	}
	data: _pg.primary.preInitDb.scripts
}

// 12. /charts/postgresql/templates/primary/statefulset.yaml
#PostgresqlPrimaryStatefulSet: {
	#config: #Config
	_pg: #config."hyperswitch-app".postgresql

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		_primaryName: (#GetPrimaryName & {#config: #config}).result
		name:      _primaryName
		namespace: #config.metadata.namespace
		labels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
			_pg.commonLabels
			_pg.primary.labels
		}
		if len(_pg.commonAnnotations) > 0 || len(_pg.primary.annotations) > 0 {
			annotations: _pg.commonAnnotations & _pg.primary.annotations
		}
	}
	spec: {
		replicas: 1
		_primaryName: (#GetPrimaryName & {#config: #config}).result
		serviceName:    _primaryName + "-headless"
		updateStrategy: _pg.primary.updateStrategy
		selector: matchLabels: {
			for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
			"app.kubernetes.io/name":      "postgresql"
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "primary"
		}
		template: {
			metadata: {
				labels: {
					for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "postgresql"
					"app.kubernetes.io/instance":  #config.metadata.name
					"app.kubernetes.io/component": "primary"
					_pg.commonLabels
					_pg.primary.podLabels
					_pg.primary.labels
				}
				annotations: {
					if _pg.primary.configuration != "" || _pg.primary.pgHbaConfiguration != "" {
						"checksum/configuration": "dummy"
					}
					if _pg.primary.extendedConfiguration != "" {
						"checksum/extended-configuration": "dummy"
					}
					_pg.commonAnnotations
					_pg.primary.podAnnotations
				}
			}
			spec: {
				if _pg.primary.extraPodSpec != _|_ {
					_pg.primary.extraPodSpec
				}
				serviceAccountName: [if _pg.serviceAccount.create {[if _pg.serviceAccount.name != "" {_pg.serviceAccount.name}, #config.metadata.name + "-postgresql"][0]}, _pg.serviceAccount.name][0]
				if len(_pg.image.pullSecrets) > 0 {
					imagePullSecrets: [for s in _pg.image.pullSecrets {name: s}]
				}
				automountServiceAccountToken: _pg.primary.automountServiceAccountToken
				if len(_pg.primary.hostAliases) > 0 {
					hostAliases: _pg.primary.hostAliases
				}
				if _pg.primary.affinity != _|_ && len(_pg.primary.affinity) > 0 {
					affinity: _pg.primary.affinity
				}
				if _pg.primary.affinity == _|_ || len(_pg.primary.affinity) == 0 {
					affinity: {
						podAntiAffinity: {
							if _pg.primary.podAntiAffinityPreset == "soft" {
								preferredDuringSchedulingIgnoredDuringExecution: [
									{
										weight: 100
										podAffinityTerm: {
											labelSelector: matchLabels: {
												"app.kubernetes.io/name":      "postgresql"
												"app.kubernetes.io/instance":  #config.metadata.name
												"app.kubernetes.io/component": "primary"
											}
											topologyKey: "kubernetes.io/hostname"
										}
									},
								]
							}
							if _pg.primary.podAntiAffinityPreset == "hard" {
								requiredDuringSchedulingIgnoredDuringExecution: [
									{
										labelSelector: matchLabels: {
											"app.kubernetes.io/name":      "postgresql"
											"app.kubernetes.io/instance":  #config.metadata.name
											"app.kubernetes.io/component": "primary"
										}
										topologyKey: "kubernetes.io/hostname"
									},
								]
							}
						}
					}
				}
				if len(_pg.primary.nodeSelector) > 0 {
					nodeSelector: _pg.primary.nodeSelector
				}
				if len(_pg.primary.tolerations) > 0 {
					tolerations: _pg.primary.tolerations
				}
				if len(_pg.primary.topologySpreadConstraints) > 0 {
					topologySpreadConstraints: _pg.primary.topologySpreadConstraints
				}
				if _pg.primary.priorityClassName != "" {
					priorityClassName: _pg.primary.priorityClassName
				}
				if _pg.primary.schedulerName != "" {
					schedulerName: _pg.primary.schedulerName
				}
				if _pg.primary.terminationGracePeriodSeconds != "" {
					terminationGracePeriodSeconds: _pg.primary.terminationGracePeriodSeconds
				}
				if _pg.primary.podSecurityContext.enabled {
					securityContext: {
						fsGroup:             _pg.primary.podSecurityContext.fsGroup
						fsGroupChangePolicy: _pg.primary.podSecurityContext.fsGroupChangePolicy
						if len(_pg.primary.podSecurityContext.sysctls) > 0 {
							sysctls: _pg.primary.podSecurityContext.sysctls
						}
						if len(_pg.primary.podSecurityContext.supplementalGroups) > 0 {
							supplementalGroups: _pg.primary.podSecurityContext.supplementalGroups
						}
					}
				}
				hostNetwork: _pg.primary.hostNetwork
				hostIPC:     _pg.primary.hostIPC

				initContainers: [
					for ic in (_pg.primary.initContainers | *[]) {ic},
				]

				containers: list.Concat([
					[{
						name:            "postgresql"
						image:           _pg.image.registry + "/" + _pg.image.repository + ":" + _pg.image.tag
						imagePullPolicy: _pg.image.pullPolicy
						if _pg.primary.containerSecurityContext.enabled {
							securityContext: {
								runAsUser:                _pg.primary.containerSecurityContext.runAsUser
								runAsGroup:               _pg.primary.containerSecurityContext.runAsGroup
								runAsNonRoot:             _pg.primary.containerSecurityContext.runAsNonRoot
								privileged:               _pg.primary.containerSecurityContext.privileged
								readOnlyRootFilesystem:   _pg.primary.containerSecurityContext.readOnlyRootFilesystem
								allowPrivilegeEscalation: _pg.primary.containerSecurityContext.allowPrivilegeEscalation
								capabilities: drop:   _pg.primary.containerSecurityContext.capabilities.drop
								seccompProfile: type: _pg.primary.containerSecurityContext.seccompProfile.type
							}
						}
						if len(_pg.primary.command) > 0 {
							command: _pg.primary.command
						}
						if len(_pg.primary.args) > 0 {
							args: _pg.primary.args
						}

						let customUser = [if _pg.auth.username != "" {_pg.auth.username}, "postgres"][0]
						let portStr = strconv.FormatInt(_pg.containerPorts.postgresql, 10)

						env: list.Concat([
							[
								{name: "BITNAMI_DEBUG", value: [if _pg.image.debug {"true"}, "false"][0]},
								{name: "POSTGRESQL_PORT_NUMBER", value: portStr},
								{name: "POSTGRESQL_VOLUME_DIR", value: _pg.primary.persistence.mountPath},
								{name: "PGDATA", value: "/bitnami/postgresql/data"},

								if customUser == "postgres" {
									if _pg.auth.enablePostgresUser {
										if _pg.auth.usePasswordFiles {
											{name: "POSTGRES_PASSWORD_FILE", value: "/opt/bitnami/postgresql/secrets/postgres-password"}
										}
										if !_pg.auth.usePasswordFiles {
											{
												name: "POSTGRES_PASSWORD"
												valueFrom: secretKeyRef: {
													name: [if _pg.auth.existingSecret != "" {_pg.auth.existingSecret}, #config.metadata.name + "-postgresql"][0]
													key: "postgres-password"
												}
											}
										}
									}
									if !_pg.auth.enablePostgresUser {
										{name: "ALLOW_EMPTY_PASSWORD", value: "true"}
									}
								},
								if customUser != "postgres" {
									{name: "POSTGRES_USER", value: customUser}
								},
								if customUser != "postgres" {
									if _pg.auth.usePasswordFiles {
										{name: "POSTGRES_PASSWORD_FILE", value: "/opt/bitnami/postgresql/secrets/password"}
									}
									if !_pg.auth.usePasswordFiles {
										{
											name: "POSTGRES_PASSWORD"
											valueFrom: secretKeyRef: {
												name: [if _pg.auth.existingSecret != "" {_pg.auth.existingSecret}, #config.metadata.name + "-postgresql"][0]
												key: "password"
											}
										}
									}
								},
								if customUser != "postgres" && _pg.auth.enablePostgresUser {
									if _pg.auth.usePasswordFiles {
										{name: "POSTGRES_POSTGRES_PASSWORD_FILE", value: "/opt/bitnami/postgresql/secrets/postgres-password"}
									}
									if !_pg.auth.usePasswordFiles {
										{
											name: "POSTGRES_POSTGRES_PASSWORD"
											valueFrom: secretKeyRef: {
												name: [if _pg.auth.existingSecret != "" {_pg.auth.existingSecret}, #config.metadata.name + "-postgresql"][0]
												key: "postgres-password"
											}
										}
									}
								},
								{name: "POSTGRES_DATABASE", value: _pg.auth.database},
								{name: "POSTGRES_REPLICATION_MODE", value: "master"},
								{name: "POSTGRES_REPLICATION_USER", value: _pg.auth.replicationUsername},
								if _pg.auth.usePasswordFiles {
									{name: "POSTGRES_REPLICATION_PASSWORD_FILE", value: "/opt/bitnami/postgresql/secrets/replication-password"}
								},
								if !_pg.auth.usePasswordFiles {
									{
										name: "POSTGRES_REPLICATION_PASSWORD"
										valueFrom: secretKeyRef: {
											name: [if _pg.auth.existingSecret != "" {_pg.auth.existingSecret}, #config.metadata.name + "-postgresql"][0]
											key: "replication-password"
										}
									}
								},
								if _pg.primary.initdb.args != "" {
									{name: "POSTGRES_INITDB_ARGS", value: _pg.primary.initdb.args}
								},
								if _pg.primary.initdb.postgresqlWalDir != "" {
									{name: "POSTGRES_INITDB_WALDIR", value: _pg.primary.initdb.postgresqlWalDir}
								},
								if _pg.primary.initdb.user != "" {
									{name: "POSTGRES_INITSCRIPTS_USERNAME", value: _pg.primary.initdb.user}
								},
								if _pg.primary.initdb.password != "" {
									{name: "POSTGRES_INITSCRIPTS_PASSWORD", value: _pg.primary.initdb.password}
								},
								{name: "POSTGRESQL_ENABLE_TLS", value: [if _pg.tls.enabled {"yes"}, "no"][0]},
								if _pg.tls.enabled {
									{name: "POSTGRESQL_TLS_PREFER_SERVER_CIPHERS", value: [if _pg.tls.preferServerCiphers {"yes"}, "no"][0]}
									{name: "POSTGRESQL_TLS_CERT_FILE", value: "/opt/bitnami/postgresql/certs/tls.crt"}
									{name: "POSTGRESQL_TLS_KEY_FILE", value: "/opt/bitnami/postgresql/certs/tls.key"}
									if _pg.tls.certCAFilename != "" {
										{name: "POSTGRESQL_TLS_CA_FILE", value: "/opt/bitnami/postgresql/certs/ca.crt"}
									}
								},
								{name: "POSTGRESQL_ENABLE_LDAP", value: "no"},
							],
							[for ev in _pg.primary.extraEnvVars {ev}],
						])
						if _pg.primary.extraEnvVarsCM != "" || _pg.primary.extraEnvVarsSecret != "" {
							envFrom: list.Concat([
								if _pg.primary.extraEnvVarsCM != "" {
									[{configMapRef: {name: _pg.primary.extraEnvVarsCM}}]
								},
								if _pg.primary.extraEnvVarsSecret != "" {
									[{secretRef: {name: _pg.primary.extraEnvVarsSecret}}]
								},
							])
						}
						ports: [
							{name: "tcp-postgresql", containerPort: _pg.containerPorts.postgresql},
						]

						let dbStr = [if _pg.auth.database != "" {"-d dbname=" + _pg.auth.database}, ""][0]
						let probeCommand = "exec pg_isready -U " + customUser + " " + dbStr + " -h 127.0.0.1 -p " + portStr

						if _pg.primary.startupProbe.enabled {
							startupProbe: (_pg.primary.customStartupProbe | {
								exec: command: ["/bin/sh", "-c", probeCommand]
								initialDelaySeconds: _pg.primary.startupProbe.initialDelaySeconds
								periodSeconds:       _pg.primary.startupProbe.periodSeconds
								timeoutSeconds:      _pg.primary.startupProbe.timeoutSeconds
								failureThreshold:    _pg.primary.startupProbe.failureThreshold
								successThreshold:    _pg.primary.startupProbe.successThreshold
							})
						}

						if _pg.primary.livenessProbe.enabled {
							livenessProbe: (_pg.primary.customLivenessProbe | {
								exec: command: ["/bin/sh", "-c", probeCommand]
								initialDelaySeconds: _pg.primary.livenessProbe.initialDelaySeconds
								periodSeconds:       _pg.primary.livenessProbe.periodSeconds
								timeoutSeconds:      _pg.primary.livenessProbe.timeoutSeconds
								failureThreshold:    _pg.primary.livenessProbe.failureThreshold
								successThreshold:    _pg.primary.livenessProbe.successThreshold
							})
						}

						if _pg.primary.readinessProbe.enabled {
							readinessProbe: (_pg.primary.customReadinessProbe | {
								exec: command: ["/bin/sh", "-c", "-e", "exec pg_isready -U " + customUser + " -h 127.0.0.1 -p " + portStr]
								initialDelaySeconds: _pg.primary.readinessProbe.initialDelaySeconds
								periodSeconds:       _pg.primary.readinessProbe.periodSeconds
								timeoutSeconds:      _pg.primary.readinessProbe.timeoutSeconds
								failureThreshold:    _pg.primary.readinessProbe.failureThreshold
								successThreshold:    _pg.primary.readinessProbe.successThreshold
							})
						}

						resources: _pg.primary.resources
						if _pg.primary.lifecycleHooks != _|_ {
							lifecycle: _pg.primary.lifecycleHooks
						}

						volumeMounts: list.Concat([
							[
								{name: "empty-dir", mountPath: "/tmp", subPath: "tmp-dir"},
								{name: "empty-dir", mountPath: "/opt/bitnami/postgresql/conf", subPath: "app-conf-dir"},
								{name: "empty-dir", mountPath: "/opt/bitnami/postgresql/tmp", subPath: "app-tmp-dir"},
							],
							if _pg.primary.configuration != "" || _pg.primary.pgHbaConfiguration != "" || _pg.primary.existingConfigmap != "" {
								[{name: "postgresql-config", mountPath: "/bitnami/postgresql/conf"}]
							},
							if _pg.primary.extendedConfiguration != "" || _pg.primary.existingExtendedConfigmap != "" {
								[{name: "postgresql-extended-config", mountPath: "/bitnami/postgresql/conf/conf.d/"}]
							},
							if _pg.auth.usePasswordFiles {
								[{name: "postgresql-password", mountPath: "/opt/bitnami/postgresql/secrets/"}]
							},
							if _pg.tls.enabled {
								[{name: "postgresql-certificates", mountPath: "/opt/bitnami/postgresql/certs", readOnly: true}]
							},
							if len(_pg.primary.initdb.scripts) > 0 || _pg.primary.initdb.scriptsConfigMap != "" {
								[{name: "custom-init-scripts", mountPath: "/docker-entrypoint-initdb.d/"}]
							},
							if len(_pg.primary.preInitDb.scripts) > 0 || _pg.primary.preInitDb.scriptsConfigMap != "" {
								[{name: "custom-preinit-scripts", mountPath: "/docker-entrypoint-preinitdb.d/"}]
							},
							[{name: _pg.primary.persistence.volumeName, mountPath: _pg.primary.persistence.mountPath, subPath: _pg.primary.persistence.subPath}],
							[for vm in _pg.primary.extraVolumeMounts {vm}],
						])
					}],
					if _pg.metrics.enabled {
						[{
							name: "metrics"
							let portStr_m = strconv.FormatInt(_pg.containerPorts.postgresql, 10)
							image:           _pg.metrics.image.registry + "/" + _pg.metrics.image.repository + ":" + _pg.metrics.image.tag
							imagePullPolicy: _pg.metrics.image.pullPolicy
							if _pg.metrics.containerSecurityContext.enabled {
								securityContext: _pg.metrics.containerSecurityContext
							}
							env: list.Concat([
								[
									{name: "DATA_SOURCE_URI", value: "127.0.0.1:" + portStr_m + "/postgres?sslmode=disable"},
									if _pg.auth.usePasswordFiles {
										{name: "DATA_SOURCE_PASS_FILE", value: "/opt/bitnami/postgresql/secrets/postgres-password"}
									},
									if !_pg.auth.usePasswordFiles {
										{
											name: "DATA_SOURCE_PASS"
											valueFrom: secretKeyRef: {
												name: [if _pg.auth.existingSecret != "" {_pg.auth.existingSecret}, #config.metadata.name + "-postgresql"][0]
												key: "postgres-password"
											}
										}
									},
									{name: "DATA_SOURCE_USER", value: "postgres"},
								],
								[for ev in _pg.metrics.extraEnvVars {ev}],
							])
							ports: [
								{name: "http-metrics", containerPort: _pg.metrics.containerPorts.metrics},
							]
							resources: _pg.metrics.resources
							volumeMounts: list.Concat([
								[{name: "empty-dir", mountPath: "/tmp", subPath: "tmp-dir"}],
								if _pg.auth.usePasswordFiles {
									[{name: "postgresql-password", mountPath: "/opt/bitnami/postgresql/secrets/"}]
								},
								if _pg.metrics.customMetrics != "" {
									[{name: "custom-metrics", mountPath: "/conf", readOnly: true}]
								},
							])
						}]
					},
					if _pg.primary.sidecars != _|_ {
						[for s in _pg.primary.sidecars {s}]
					},
				])

				volumes: [
					{name: "empty-dir", emptyDir: {}},
					if _pg.primary.configuration != "" || _pg.primary.pgHbaConfiguration != "" || _pg.primary.existingConfigmap != "" {
						{
							name: "postgresql-config"
							configMap: {name: [if _pg.primary.existingConfigmap != "" {_pg.primary.existingConfigmap}, #config.metadata.name + "-postgresql-primary-configuration"][0]}
						}
					},
					if _pg.primary.extendedConfiguration != "" || _pg.primary.existingExtendedConfigmap != "" {
						{
							name: "postgresql-extended-config"
							configMap: {name: [if _pg.primary.existingExtendedConfigmap != "" {_pg.primary.existingExtendedConfigmap}, #config.metadata.name + "-postgresql-primary-extended-configuration"][0]}
						}
					},
					if _pg.auth.usePasswordFiles {
						{
							name: "postgresql-password"
							secret: secretName: [if _pg.auth.existingSecret != "" {_pg.auth.existingSecret}, #config.metadata.name + "-postgresql"][0]
						}
					},
					if _pg.tls.enabled {
						{
							name: "raw-certificates"
							secret: secretName: [if _pg.tls.certificatesSecret != "" {_pg.tls.certificatesSecret}, #config.metadata.name + "-postgresql-crt"][0]
						}
						{name: "postgresql-certificates", emptyDir: {}}
					},
					if len(_pg.primary.initdb.scripts) > 0 || _pg.primary.initdb.scriptsConfigMap != "" {
						{
							name: "custom-init-scripts"
							configMap: {name: [if _pg.primary.initdb.scriptsConfigMap != "" {_pg.primary.initdb.scriptsConfigMap}, #config.metadata.name + "-postgresql-primary-init-scripts"][0]}
						}
					},
					if len(_pg.primary.preInitDb.scripts) > 0 || _pg.primary.preInitDb.scriptsConfigMap != "" {
						{
							name: "custom-preinit-scripts"
							configMap: {name: [if _pg.primary.preInitDb.scriptsConfigMap != "" {_pg.primary.preInitDb.scriptsConfigMap}, #config.metadata.name + "-postgresql-primary-pre-init-scripts"][0]}
						}
					},
					if _pg.metrics.enabled && len(_pg.metrics.customMetrics) > 0 {
						{
							name: "custom-metrics"
							configMap: {name: #config.metadata.name + "-postgresql-primary-metrics"}
						}
					},
					if !_pg.primary.persistence.enabled {
						{name: _pg.primary.persistence.volumeName, emptyDir: {}}
					},
					if _pg.primary.persistence.enabled && _pg.primary.persistence.existingClaim != "" {
						{
							name: _pg.primary.persistence.volumeName
							persistentVolumeClaim: claimName: _pg.primary.persistence.existingClaim
						}
					},
					for v in _pg.primary.extraVolumes {v},
				]
			}
		}
		if _pg.primary.persistence.enabled && _pg.primary.persistence.existingClaim == "" {
			if _pg.primary.persistentVolumeClaimRetentionPolicy.enabled {
				persistentVolumeClaimRetentionPolicy: {
					whenDeleted: _pg.primary.persistentVolumeClaimRetentionPolicy.whenDeleted
					whenScaled:  _pg.primary.persistentVolumeClaimRetentionPolicy.whenScaled
				}
			}
			volumeClaimTemplates: [
				{
					metadata: {
						name: _pg.primary.persistence.volumeName
						if len(_pg.primary.persistence.annotations) > 0 {
							annotations: _pg.primary.persistence.annotations
						}
						if len(_pg.primary.persistence.labels) > 0 {
							labels: _pg.primary.persistence.labels
						}
					}
					spec: {
						accessModes: _pg.primary.persistence.accessModes
						resources: requests: storage: _pg.primary.persistence.size
						if _pg.primary.persistence.storageClass != "" {
							if _pg.primary.persistence.storageClass == "-" {
								storageClassName: ""
							}
							if _pg.primary.persistence.storageClass != "-" {
								storageClassName: _pg.primary.persistence.storageClass
							}
						}
						if _pg.primary.persistence.dataSource != _|_ {
							dataSource: _pg.primary.persistence.dataSource
						}
						if _pg.primary.persistence.selector != _|_ && len(_pg.primary.persistence.selector) > 0 {
							selector: _pg.primary.persistence.selector
						}
					}
				},
			]
		}
	}
}
