package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	netv1 "k8s.io/api/networking/v1"
	policyv1 "k8s.io/api/policy/v1"
)

// 1. /charts/postgresql/templates/primary/configmap.yaml
#CardVaultPostgresqlPrimaryConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_metadata.name)-locker-db-configuration"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.primary.annotations}).#result
	}
	data: {
		if pg.primary.configuration != "" {
			"postgresql.conf": pg.primary.configuration
		}
		if pg.primary.pgHbaConfiguration != "" {
			"pg_hba.conf": pg.primary.pgHbaConfiguration
		}
	}
}

// 2. /charts/postgresql/templates/primary/extended-configmap.yaml
#CardVaultPostgresqlPrimaryExtendedConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_metadata.name)-locker-db-extended-configuration"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.primary.annotations}).#result
	}
	data: {
		if pg.primary.extendedConfiguration != "" {
			"override.conf": pg.primary.extendedConfiguration
		}
	}
}

// 3. /charts/postgresql/templates/primary/initialization-configmap.yaml
#CardVaultPostgresqlPrimaryInitializationConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_metadata.name)-locker-db-init-scripts"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.primary.annotations}).#result
	}
	data: pg.primary.initdb.scripts
}

// 4. /charts/postgresql/templates/primary/metrics-configmap.yaml
#CardVaultPostgresqlPrimaryMetricsConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_metadata.name)-locker-db-metrics"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "metrics"
			"app.kubernetes.io/name":      "locker-db"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.primary.annotations}).#result
	}
	data: {
		"custom-metrics.yaml": pg.metrics.customMetrics
	}
}

// 5. /charts/postgresql/templates/primary/metrics-svc.yaml
#CardVaultPostgresqlPrimaryMetricsService: corev1.#Service & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(_metadata.name)-locker-db-metrics"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "metrics"
			"app.kubernetes.io/name":      "locker-db"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.metrics.service.annotations}).#result
	}
	spec: {
		type:            "ClusterIP"
		sessionAffinity: pg.metrics.service.sessionAffinity
		ports: [
			{
				name:       "http-metrics"
				port:       pg.metrics.service.ports.metrics
				targetPort: "http-metrics"
			},
		]
		selector: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
			if pg.primary.podLabels != _|_ {
				for k, v in pg.primary.podLabels {"\(k)": v}
			}
		}
	}
}

// 6. /charts/postgresql/templates/primary/networkpolicy.yaml
#CardVaultPostgresqlPrimaryNetworkPolicy: netv1.#NetworkPolicy & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}
	let instanceName = _metadata.name

	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(instanceName)-locker-db"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.primary.annotations}).#result
	}
	spec: {
		podSelector: matchLabels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  instanceName
			if pg.primary.podLabels != _|_ {
				for k, v in pg.primary.podLabels {"\(k)": v}
			}
		}
		policyTypes: ["Ingress", "Egress"]
		egress: [
			if pg.primary.networkPolicy.allowExternalEgress {
				{}
			},
			if !pg.primary.networkPolicy.allowExternalEgress {
				{
					ports: [
						{port: 53, protocol: "UDP"},
						{port: 53, protocol: "TCP"},
					]
				}
				{
					ports: [{port: pg.containerPorts.postgresql}]
					to: [{
						podSelector: matchLabels: {
							for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
							"app.kubernetes.io/component": "read"
						}
					}]
				}
				for e in pg.primary.networkPolicy.extraEgress {e}
			},
		]
		ingress: [
			{
				ports: [
					{port: pg.containerPorts.postgresql, protocol: "TCP"},
					if pg.metrics.enabled {
						{port: pg.metrics.service.ports.metrics, protocol: "TCP"}
					},
				]
				if !pg.primary.networkPolicy.allowExternal {
					from: [
						{
							podSelector: matchLabels: {
								for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
								"app.kubernetes.io/component": "primary"
								"app.kubernetes.io/name":      "locker-db"
								"app.kubernetes.io/instance":  instanceName
								if pg.primary.podLabels != _|_ {
									for k, v in pg.primary.podLabels {"\(k)": v}
								}
							}
						},
						{
							podSelector: matchLabels: {
								"\(instanceName)-locker-db-client": "true"
							}
						},
						if pg.primary.networkPolicy.ingressNSMatchLabels != _|_ {
							{
								namespaceSelector: matchLabels: pg.primary.networkPolicy.ingressNSMatchLabels
								if pg.primary.networkPolicy.ingressNSPodMatchLabels != _|_ {
									podSelector: matchLabels: pg.primary.networkPolicy.ingressNSPodMatchLabels
								}
							}
						},
					]
				}
			},
			for i in pg.primary.networkPolicy.extraIngress {i},
		]
	}
}

// 7. /charts/postgresql/templates/primary/pdb.yaml
#CardVaultPostgresqlPrimaryPDB: policyv1.#PodDisruptionBudget & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(_metadata.name)-locker-db"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
			if pg.primary.labels != _|_ {
				for k, v in pg.primary.labels {"\(k)": v}
			}
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.primary.annotations}).#result
	}
	spec: {
		if pg.primary.pdb.minAvailable != _|_ {
			minAvailable: pg.primary.pdb.minAvailable
		}
		if pg.primary.pdb.minAvailable == _|_ {
			maxUnavailable: pg.primary.pdb.maxUnavailable
		}
		selector: matchLabels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
			if pg.primary.podLabels != _|_ {
				for k, v in pg.primary.podLabels {"\(k)": v}
			}
		}
	}
}

// 8. /charts/postgresql/templates/primary/preinitialization-configmap.yaml
#CardVaultPostgresqlPrimaryPreinitializationConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_metadata.name)-locker-db-preinit-scripts"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.primary.annotations}).#result
	}
	data: pg.primary.preInitDb.scripts
}

// 9. /charts/postgresql/templates/primary/servicemonitor.yaml
#CardVaultPostgresqlPrimaryServiceMonitor: {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      "\(_metadata.name)-locker-db"
		namespace: pg.metrics.serviceMonitor.namespace | _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "metrics"
			"app.kubernetes.io/name":      "locker-db"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.primary.annotations}).#result
	}
	spec: {
		if pg.metrics.serviceMonitor.jobLabel != _|_ {
			jobLabel: pg.metrics.serviceMonitor.jobLabel
		}
		selector: matchLabels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "metrics"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
			if pg.metrics.serviceMonitor.selector != _|_ {
				for k, v in pg.metrics.serviceMonitor.selector {"\(k)": v}
			}
		}
		endpoints: [
			{
				port:          "http-metrics"
				interval:      pg.metrics.serviceMonitor.interval
				scrapeTimeout: pg.metrics.serviceMonitor.scrapeTimeout
				honorLabels:   pg.metrics.serviceMonitor.honorLabels
				if pg.metrics.serviceMonitor.relabelings != _|_ {
					relabelings: pg.metrics.serviceMonitor.relabelings
				}
				if pg.metrics.serviceMonitor.metricRelabelings != _|_ {
					metricRelabelings: pg.metrics.serviceMonitor.metricRelabelings
				}
			},
		]
		namespaceSelector: matchNames: [_metadata.namespace]
	}
}

// 10. /charts/postgresql/templates/primary/statefulset.yaml
#CardVaultPostgresqlPrimaryStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}
	let instanceName = _metadata.name

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(instanceName)-locker-db"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  instanceName
			if pg.primary.labels != _|_ {
				for k, v in pg.primary.labels {"\(k)": v}
			}
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.primary.annotations}).#result
	}
	spec: {
		replicas:    1
		serviceName: "\(instanceName)-locker-db-headless"
		if pg.primary.updateStrategy != _|_ {
			updateStrategy: pg.primary.updateStrategy
		}
		selector: matchLabels: {
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  instanceName
		}
		template: {
			metadata: {
				name: "\(instanceName)-locker-db"
				labels: {
					for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
					"app.kubernetes.io/component": "primary"
					"app.kubernetes.io/name":      "locker-db"
					"app.kubernetes.io/instance":  instanceName
					if pg.primary.podLabels != _|_ {
						for k, v in pg.primary.podLabels {"\(k)": v}
					}
				}
				annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.primary.podAnnotations}).#result
			}
			spec: {
				serviceAccountName: pg.serviceAccount.name | "\(instanceName)-locker-db"
				if pg.imagePullSecrets != [] {
					imagePullSecrets: pg.imagePullSecrets
				}
				automountServiceAccountToken: pg.primary.automountServiceAccountToken
				if pg.primary.affinity != _|_ {
					affinity: pg.primary.affinity
				}
				if pg.primary.nodeSelector != _|_ {
					nodeSelector: pg.primary.nodeSelector
				}
				if pg.primary.tolerations != _|_ {
					tolerations: pg.primary.tolerations
				}
				if pg.primary.topologySpreadConstraints != [] {
					topologySpreadConstraints: pg.primary.topologySpreadConstraints
				}
				if pg.primary.priorityClassName != "" {
					priorityClassName: pg.primary.priorityClassName
				}
				if pg.primary.schedulerName != "" {
					schedulerName: pg.primary.schedulerName
				}
				terminationGracePeriodSeconds: pg.primary.terminationGracePeriodSeconds
				if pg.primary.podSecurityContext.enabled {
					securityContext: {
						fsGroup: pg.primary.podSecurityContext.fsGroup
					}
				}
				hostNetwork: pg.hostNetwork
				hostIPC:     pg.hostIPC

				initContainers: [
					{
						name:            "init-chmod-data"
						image:           "\(pg.primary.volumePermissions.image.registry)/\(pg.primary.volumePermissions.image.repository):\(pg.primary.volumePermissions.image.tag)"
						imagePullPolicy: "IfNotPresent"
						command: [
							"/bin/sh",
							"-ec",
							"chown \(pg.primary.containerSecurityContext.runAsUser):\(pg.primary.podSecurityContext.fsGroup) /bitnami/postgresql\nmkdir -p /bitnami/postgresql/data\nchmod 700 /bitnami/postgresql/data\nfind /bitnami/postgresql -mindepth 1 -maxdepth 1 -not -name \"conf\" -not -name \".snapshot\" -not -name \"lost+found\" | xargs -r chown -R \(pg.primary.containerSecurityContext.runAsUser):\(pg.primary.podSecurityContext.fsGroup)\n",
						]
						securityContext: {
							runAsUser: 0
						}
						volumeMounts: [
							{
								name:      "empty-dir"
								mountPath: "/tmp"
								subPath:   "tmp-dir"
							},
							{
								name:      "data"
								mountPath: "/bitnami/postgresql"
							},
						]
					},
					for ic in pg.primary.initContainers {ic},
				]
				containers: [
					{
						name:            "postgresql"
						image:           "\(pg.image.registry)/\(pg.image.repository):\(pg.image.tag)"
						imagePullPolicy: pg.image.pullPolicy
						if pg.primary.containerSecurityContext.enabled {
							securityContext: {
								runAsUser: pg.primary.containerSecurityContext.runAsUser
							}
						}
						env: [
							{name: "BITNAMI_DEBUG", value: "false"},
							{name: "POSTGRESQL_PORT_NUMBER", value: "\(pg.containerPorts.postgresql)"},
							{name: "POSTGRESQL_VOLUME_DIR", value: "/bitnami/postgresql"},
							{name: "PGDATA", value: "/bitnami/postgresql/data"},
							{name: "POSTGRES_USER", value: pg.auth.username},
							{
								name: "POSTGRES_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(instanceName)-locker-db"
									key:  "password"
								}
							},
							{name: "POSTGRES_DATABASE", value: pg.auth.database},
							{name: "POSTGRESQL_ENABLE_TLS", value: "no"},
							{name: "POSTGRESQL_LOG_HOSTNAME", value: "false"},
							{name: "POSTGRESQL_LOG_CONNECTIONS", value: "false"},
							{name: "POSTGRESQL_LOG_DISCONNECTIONS", value: "false"},
							{name: "POSTGRESQL_PGAUDIT_LOG_CATALOG", value: "off"},
							{name: "POSTGRESQL_CLIENT_MIN_MESSAGES", value: "error"},
							{name: "POSTGRESQL_SHARED_PRELOAD_LIBRARIES", value: "pgaudit"},
						]
						ports: [{containerPort: pg.containerPorts.postgresql, name: "tcp-postgresql"}]
						livenessProbe: {
							exec: command: [
								"/bin/sh",
								"-c",
								"exec pg_isready -U \(pg.auth.username) -d \"dbname=\(pg.auth.database)\" -h 127.0.0.1 -p \(pg.containerPorts.postgresql)",
							]
							initialDelaySeconds: 30
							periodSeconds:       10
							timeoutSeconds:      5
							successThreshold:    1
							failureThreshold:    6
						}
						readinessProbe: {
							exec: command: [
								"/bin/sh",
								"-c",
								"-e",
								"exec pg_isready -U \(pg.auth.username) -d \"dbname=\(pg.auth.database)\" -h 127.0.0.1 -p \(pg.containerPorts.postgresql)\n[ -f /opt/bitnami/postgresql/tmp/.initialized ] || [ -f /bitnami/postgresql/.initialized ]\n",
							]
							initialDelaySeconds: 5
							periodSeconds:       10
							timeoutSeconds:      5
							successThreshold:    1
							failureThreshold:    6
						}
						resources: pg.primary.resources
						volumeMounts: [
							{mountPath: "/tmp", name: "empty-dir", subPath: "tmp-dir"},
							{mountPath: "/opt/bitnami/postgresql/conf", name: "empty-dir", subPath: "app-conf-dir"},
							{mountPath: "/opt/bitnami/postgresql/tmp", name: "empty-dir", subPath: "app-tmp-dir"},
							if pg.primary.configuration != "" || pg.primary.pgHbaConfiguration != "" {
								{
									name:      "postgresql-config"
									mountPath: "/opt/bitnami/postgresql/conf"
								}
							},
							if pg.primary.extendedConfiguration != "" {
								{
									name:      "postgresql-extended-config"
									mountPath: "/opt/bitnami/postgresql/conf/conf.d"
									subPath:   "override.conf"
								}
							},
							if len(pg.primary.initdb.scripts) > 0 && pg.primary.initdb.scriptsConfigMap == "" {
								{
									name:      "custom-init-scripts"
									mountPath: "/docker-entrypoint-initdb.d"
								}
							},
							{mountPath: "/bitnami/postgresql", name: "data"},
						]
					},
					if pg.metrics.enabled {
						{
							name:  "metrics"
							image: "\(pg.metrics.image.repository):\(pg.metrics.image.tag)"
							if pg.metrics.containerSecurityContext.enabled {
								securityContext: {
									runAsUser: pg.metrics.containerSecurityContext.runAsUser
								}
							}
							ports: [{containerPort: pg.metrics.service.ports.metrics, name: "http-metrics"}]
							env: [
								{name: "DATA_SOURCE_NAME", value: "postgresql://\(pg.auth.username):$(POSTGRES_PASSWORD)@127.0.0.1:\(pg.containerPorts.postgresql)/\(pg.auth.database)?sslmode=disable"},
								{
									name: "POSTGRES_PASSWORD"
									valueFrom: secretKeyRef: {
										name: "\(instanceName)-locker-db"
										key:  "password"
									}
								},
							]
							resources: pg.metrics.resources
						}
					},
					for ec in pg.primary.extraContainers {ec},
				]
				volumes: [
					{
						name: "empty-dir"
						emptyDir: {}
					},
					if pg.primary.configuration != "" || pg.primary.pgHbaConfiguration != "" {
						{
							name: "postgresql-config"
							configMap: name: "\(instanceName)-locker-db-configuration"
						}
					},
					if pg.primary.extendedConfiguration != "" {
						{
							name: "postgresql-extended-config"
							configMap: name: "\(instanceName)-locker-db-extended-configuration"
						}
					},
					if len(pg.primary.initdb.scripts) > 0 && pg.primary.initdb.scriptsConfigMap == "" {
						{
							name: "custom-init-scripts"
							configMap: name: "\(instanceName)-locker-db-init-scripts"
						}
					},
					if pg.shmVolume.enabled {
						{
							name: "dshm"
							emptyDir: {
								medium: "Memory"
								if pg.shmVolume.sizeLimit != _|_ {
									sizeLimit: pg.shmVolume.sizeLimit
								}
							}
						}
					},
				]
			}
		}
		if pg.primary.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: {
						name: "data"
						annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.primary.persistence.annotations}).#result
						if pg.primary.persistence.labels != _|_ {
							labels: pg.primary.persistence.labels
						}
					}
					spec: {
						accessModes: pg.primary.persistence.accessModes
						resources: requests: storage: pg.primary.persistence.size
						if pg.primary.persistence.storageClass != "" {
							storageClassName: pg.primary.persistence.storageClass
						}
					}
				},
			]
		}
	}
}

// 11. /charts/postgresql/templates/primary/svc.yaml
#CardVaultPostgresqlService: corev1.#Service & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(_metadata.name)-locker-db"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.primary.service.annotations}).#result
	}
	spec: {
		type:            pg.primary.service.type
		sessionAffinity: pg.primary.service.sessionAffinity
		ports: [
			{
				name:       "tcp-postgresql"
				port:       pg.primary.service.ports.postgresql
				targetPort: "tcp-postgresql"
			},
		]
		selector: {
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
			if pg.primary.podLabels != _|_ {
				for k, v in pg.primary.podLabels {"\(k)": v}
			}
		}
	}
}

// 12. /charts/postgresql/templates/primary/svc-headless.yaml
#CardVaultPostgresqlHeadlessService: corev1.#Service & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(_metadata.name)-locker-db-headless"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.primary.service.headless.annotations}).#result
	}
	spec: {
		clusterIP:                "None"
		publishNotReadyAddresses: true
		ports: [
			{
				name:       "tcp-postgresql"
				port:       pg.primary.service.ports.postgresql
				targetPort: "tcp-postgresql"
			},
		]
		selector: {
			"app.kubernetes.io/component": "primary"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
			if pg.primary.podLabels != _|_ {
				for k, v in pg.primary.podLabels {"\(k)": v}
			}
		}
	}
}
