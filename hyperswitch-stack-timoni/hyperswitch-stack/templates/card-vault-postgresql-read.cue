package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	netv1 "k8s.io/api/networking/v1"
	policyv1 "k8s.io/api/policy/v1"
)

// 1. /charts/postgresql/templates/read/extended-configmap.yaml
#CardVaultPostgresqlReadExtendedConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_metadata.name)-locker-db-read-extended-configuration"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "read"
			"app.kubernetes.io/name":      "locker-db"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.readReplicas.annotations}).#result
	}
	data: {
		if pg.readReplicas.extendedConfiguration != "" {
			"override.conf": pg.readReplicas.extendedConfiguration
		}
	}
}

// 2. /charts/postgresql/templates/read/metrics-configmap.yaml
#CardVaultPostgresqlReadMetricsConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_metadata.name)-locker-db-read-metrics"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "metrics-read"
			"app.kubernetes.io/name":      "locker-db"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.readReplicas.annotations}).#result
	}
	data: {
		"custom-metrics.yaml": pg.metrics.customMetrics
	}
}

// 3. /charts/postgresql/templates/read/metrics-svc.yaml
#CardVaultPostgresqlReadMetricsService: corev1.#Service & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(_metadata.name)-locker-db-read-metrics"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "metrics-read"
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
			"app.kubernetes.io/component": "read"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
			if pg.readReplicas.podLabels != _|_ {
				for k, v in pg.readReplicas.podLabels {"\(k)": v}
			}
		}
	}
}

// 4. /charts/postgresql/templates/read/networkpolicy.yaml
#CardVaultPostgresqlReadNetworkPolicy: netv1.#NetworkPolicy & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(_metadata.name)-locker-db-read"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "read"
			"app.kubernetes.io/name":      "locker-db"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.readReplicas.annotations}).#result
	}
	spec: {
		podSelector: matchLabels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "read"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
			if pg.readReplicas.podLabels != _|_ {
				for k, v in pg.readReplicas.podLabels {"\(k)": v}
			}
		}
		policyTypes: ["Ingress", "Egress"]
		egress: [
			if pg.readReplicas.networkPolicy.allowExternalEgress {
				{}
			},
			if !pg.readReplicas.networkPolicy.allowExternalEgress {
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
							"app.kubernetes.io/component": "primary"
						}
					}]
				}
				for e in pg.readReplicas.networkPolicy.extraEgress {e}
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
				if !pg.readReplicas.networkPolicy.allowExternal {
					from: [
						{
							podSelector: matchLabels: {
								for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
								"app.kubernetes.io/component": "read"
								"app.kubernetes.io/name":      "locker-db"
								"app.kubernetes.io/instance":  _metadata.name
								if pg.readReplicas.podLabels != _|_ {
									for k, v in pg.readReplicas.podLabels {"\(k)": v}
								}
							}
						},
						{
							podSelector: matchLabels: {
								"\(_metadata.name)-locker-db-read-client": "true"
							}
						},
						if pg.readReplicas.networkPolicy.ingressNSMatchLabels != _|_ {
							{
								namespaceSelector: matchLabels: pg.readReplicas.networkPolicy.ingressNSMatchLabels
								if pg.readReplicas.networkPolicy.ingressNSPodMatchLabels != _|_ {
									podSelector: matchLabels: pg.readReplicas.networkPolicy.ingressNSPodMatchLabels
								}
							}
						},
					]
				}
			},
			for i in pg.readReplicas.networkPolicy.extraIngress {i},
		]
	}
}

// 5. /charts/postgresql/templates/read/pdb.yaml
#CardVaultPostgresqlReadPDB: policyv1.#PodDisruptionBudget & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(_metadata.name)-locker-db-read"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "read"
			"app.kubernetes.io/name":      "locker-db"
			if pg.readReplicas.labels != _|_ {
				for k, v in pg.readReplicas.labels {"\(k)": v}
			}
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.readReplicas.annotations}).#result
	}
	spec: {
		if pg.readReplicas.pdb.minAvailable != _|_ {
			minAvailable: pg.readReplicas.pdb.minAvailable
		}
		if pg.readReplicas.pdb.minAvailable == _|_ {
			maxUnavailable: pg.readReplicas.pdb.maxUnavailable
		}
		selector: matchLabels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "read"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
			if pg.readReplicas.podLabels != _|_ {
				for k, v in pg.readReplicas.podLabels {"\(k)": v}
			}
		}
	}
}

// 6. /charts/postgresql/templates/read/servicemonitor.yaml
#CardVaultPostgresqlReadServiceMonitor: {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      "\(_metadata.name)-locker-db-read"
		namespace: pg.metrics.serviceMonitor.namespace | _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "metrics-read"
			"app.kubernetes.io/name":      "locker-db"
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.readReplicas.annotations}).#result
	}
	spec: {
		if pg.metrics.serviceMonitor.jobLabel != _|_ {
			jobLabel: pg.metrics.serviceMonitor.jobLabel
		}
		selector: matchLabels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "metrics-read"
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

// 7. /charts/postgresql/templates/read/statefulset.yaml
#CardVaultPostgresqlReadStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}
	let instanceName = _metadata.name

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(instanceName)-locker-db-read"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "read"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  instanceName
			if pg.readReplicas.labels != _|_ {
				for k, v in pg.readReplicas.labels {"\(k)": v}
			}
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.readReplicas.annotations}).#result
	}
	spec: {
		replicas:    pg.readReplicas.replicaCount
		serviceName: "\(instanceName)-locker-db-read-headless"
		if pg.readReplicas.updateStrategy != _|_ {
			updateStrategy: pg.readReplicas.updateStrategy
		}
		selector: matchLabels: {
			"app.kubernetes.io/component": "read"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  instanceName
		}
		template: {
			metadata: {
				name: "\(instanceName)-locker-db-read"
				labels: {
					for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
					"app.kubernetes.io/component": "read"
					"app.kubernetes.io/name":      "locker-db"
					"app.kubernetes.io/instance":  instanceName
					if pg.readReplicas.podLabels != _|_ {
						for k, v in pg.readReplicas.podLabels {"\(k)": v}
					}
				}
				annotations: (#MergeAnnotations & {
					#global: globalAnn
					#local: {
						if pg.readReplicas.extendedConfiguration != "" {
							"checksum/extended-configuration": "DUMMY_CHECKSUM"
						}
						for k, v in pg.readReplicas.podAnnotations {"\(k)": v}
					}
				}).#result
			}
			spec: {
				serviceAccountName: pg.serviceAccount.name | "\(instanceName)-locker-db"
				if pg.imagePullSecrets != [] {
					imagePullSecrets: pg.imagePullSecrets
				}
				automountServiceAccountToken: pg.readReplicas.automountServiceAccountToken
				if pg.readReplicas.affinity != _|_ {
					affinity: pg.readReplicas.affinity
				}
				if pg.readReplicas.nodeSelector != _|_ {
					nodeSelector: pg.readReplicas.nodeSelector
				}
				if pg.readReplicas.tolerations != _|_ {
					tolerations: pg.readReplicas.tolerations
				}
				if pg.readReplicas.topologySpreadConstraints != [] {
					topologySpreadConstraints: pg.readReplicas.topologySpreadConstraints
				}
				if pg.readReplicas.priorityClassName != "" {
					priorityClassName: pg.readReplicas.priorityClassName
				}
				if pg.readReplicas.schedulerName != "" {
					schedulerName: pg.readReplicas.schedulerName
				}
				terminationGracePeriodSeconds: pg.readReplicas.terminationGracePeriodSeconds
				if pg.readReplicas.podSecurityContext.enabled {
					securityContext: {
						fsGroup: pg.readReplicas.podSecurityContext.fsGroup
					}
				}
				hostNetwork: pg.hostNetwork
				hostIPC:     pg.hostIPC

				initContainers: [
					{
						name:            "init-chmod-data"
						image:           "bitnami/os-shell:11-debian-11-r95"
						imagePullPolicy: "IfNotPresent"
						command: [
							"/bin/sh",
							"-ec",
							"chown \(pg.readReplicas.containerSecurityContext.runAsUser):\(pg.readReplicas.podSecurityContext.fsGroup) /bitnami/postgresql\nmkdir -p /bitnami/postgresql/data\nchmod 700 /bitnami/postgresql/data\nfind /bitnami/postgresql -mindepth 1 -maxdepth 1 -not -name \"conf\" -not -name \".snapshot\" -not -name \"lost+found\" | xargs -r chown -R \(pg.readReplicas.containerSecurityContext.runAsUser):\(pg.readReplicas.podSecurityContext.fsGroup)\n",
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
					for ic in pg.readReplicas.initContainers {ic},
				]
				containers: [
					{
						name:            "postgresql"
						image:           "\(pg.image.registry)/\(pg.image.repository):\(pg.image.tag)"
						imagePullPolicy: pg.image.pullPolicy
						if pg.readReplicas.containerSecurityContext.enabled {
							securityContext: {
								runAsUser: pg.readReplicas.containerSecurityContext.runAsUser
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
							{name: "POSTGRES_REPLICATION_MODE", value: "slave"},
							{name: "POSTGRES_REPLICATION_USER", value: "repl_user"},
							{
								name: "POSTGRES_REPLICATION_PASSWORD"
								valueFrom: secretKeyRef: {
									name: "\(instanceName)-locker-db"
									key:  "replication-password"
								}
							},
							{name: "POSTGRES_CLUSTER_APP_NAME", value: "walreceiver"},
							{name: "POSTGRES_MASTER_HOST", value: "\(instanceName)-locker-db"},
							{name: "POSTGRES_MASTER_PORT_NUMBER", value: "5432"},
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
						resources: pg.readReplicas.resources
						volumeMounts: [
							{mountPath: "/tmp", name: "empty-dir", subPath: "tmp-dir"},
							{mountPath: "/opt/bitnami/postgresql/conf", name: "empty-dir", subPath: "app-conf-dir"},
							{mountPath: "/opt/bitnami/postgresql/tmp", name: "empty-dir", subPath: "app-tmp-dir"},
							if pg.readReplicas.extendedConfiguration != "" {
								{
									name:      "postgresql-extended-config"
									mountPath: "/bitnami/postgresql/conf/conf.d/"
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
								{name: "DATA_SOURCE_URI", value: "127.0.0.1:5432/postgres?sslmode=disable"},
								{
									name: "DATA_SOURCE_PASS"
									valueFrom: secretKeyRef: {
										name: "\(instanceName)-locker-db"
										key:  "password"
									}
								},
								{name: "DATA_SOURCE_USER", value: pg.auth.username},
							]
							resources: pg.metrics.resources
						}
					},
					for ec in pg.readReplicas.extraContainers {ec},
				]
				volumes: [
					if pg.readReplicas.extendedConfiguration != "" {
						{
							name: "postgresql-extended-config"
							configMap: name: "\(instanceName)-locker-db-read-extended-configuration"
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
					{
						name: "empty-dir"
						emptyDir: {}
					},
				]
			}
		}
		if pg.readReplicas.persistence.enabled {
			volumeClaimTemplates: [
				{
					metadata: {
						name: "data"
						annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.readReplicas.persistence.annotations}).#result
						if pg.readReplicas.persistence.labels != _|_ {
							labels: pg.readReplicas.persistence.labels
						}
					}
					spec: {
						accessModes: pg.readReplicas.persistence.accessModes
						resources: requests: storage: pg.readReplicas.persistence.size
						if pg.readReplicas.persistence.storageClass != "" {
							storageClassName: pg.readReplicas.persistence.storageClass
						}
					}
				},
			]
		}
	}
}

// 8. /charts/postgresql/templates/read/svc.yaml
#CardVaultPostgresqlReadService: corev1.#Service & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(_metadata.name)-locker-db-read"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "read"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.readReplicas.service.annotations}).#result
	}
	spec: {
		type:            pg.readReplicas.service.type
		sessionAffinity: pg.readReplicas.service.sessionAffinity
		ports: [
			{
				name:       "tcp-postgresql"
				port:       pg.readReplicas.service.ports.postgresql
				targetPort: "tcp-postgresql"
			},
		]
		selector: {
			"app.kubernetes.io/component": "read"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
			if pg.readReplicas.podLabels != _|_ {
				for k, v in pg.readReplicas.podLabels {"\(k)": v}
			}
		}
	}
}

// 9. /charts/postgresql/templates/read/svc-headless.yaml
#CardVaultPostgresqlReadHeadlessService: corev1.#Service & {
	#config: #Config
	let cv = #config."hyperswitch-app"."hyperswitch-card-vault"
	let pg = cv.postgresql
	let _metadata = #config.metadata
	let globalAnn = *_metadata.annotations | {}

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(_metadata.name)-locker-db-read-headless"
		namespace: _metadata.namespace
		labels: {
			for k, v in _metadata.labels if k != "app.kubernetes.io/name" {"\(k)": v}
			"app.kubernetes.io/component": "read"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
		}
		annotations: (#MergeAnnotations & {#global: globalAnn, #local: pg.readReplicas.service.headless.annotations}).#result
	}
	spec: {
		clusterIP:                "None"
		publishNotReadyAddresses: true
		ports: [
			{
				name:       "tcp-postgresql"
				port:       pg.readReplicas.service.ports.postgresql
				targetPort: "tcp-postgresql"
			},
		]
		selector: {
			"app.kubernetes.io/component": "read"
			"app.kubernetes.io/name":      "locker-db"
			"app.kubernetes.io/instance":  _metadata.name
			if pg.readReplicas.podLabels != _|_ {
				for k, v in pg.readReplicas.podLabels {"\(k)": v}
			}
		}
	}
}
