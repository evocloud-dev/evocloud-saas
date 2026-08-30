package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	policyv1 "k8s.io/api/policy/v1"
	networkingv1 "k8s.io/api/networking/v1"
)

#KafkaZookeeper: {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let z = k.zookeeper
	let fullname = "\(#config.metadata.name)-\(k.name)-zookeeper"

	_headlessSuffix: *"headless" | string
	if z.service.headless.servicenameOverride != "" {_headlessSuffix: z.service.headless.servicenameOverride}
	let headlessFullname = "\(fullname)-\(_headlessSuffix)"

	_saName: *"" | string
	if z.serviceAccount.name != "" {_saName: z.serviceAccount.name}
	if z.serviceAccount.name == "" {_saName: fullname}

	_debug:          z.image.debug || z.diagnosticMode.enabled
	_allowAnonymous: *"yes" | "no"
	if z.auth.client.enabled {_allowAnonymous: "no"}
	_metricsPort: *z.containerPorts.metrics | int
	if z.metrics.containerPort != 0 {_metricsPort: z.metrics.containerPort}
	_enableAuth: *"no" | "yes"
	if z.auth.client.enabled {_enableAuth: "yes"}
	_enableQuorumAuth: *"no" | "yes"
	if z.auth.quorum.enabled {_enableQuorumAuth: "yes"}
	_listenAllIps: *"no" | "yes"
	if z.listenOnAllIPs {_listenAllIps: "yes"}
	_clientAuthSecret: *fullname | string
	if z.auth.client.existingSecret != "" {_clientAuthSecret: z.auth.client.existingSecret}
	if z.auth.client.existingSecret == "" {_clientAuthSecret: "\(fullname)-client-auth"}
	_quorumAuthSecret: *fullname | string
	if z.auth.quorum.existingSecret != "" {_quorumAuthSecret: z.auth.quorum.existingSecret}
	if z.auth.quorum.existingSecret == "" {_quorumAuthSecret: "\(fullname)-quorum-auth"}
	_configMapName: *fullname | string
	if z.existingConfigmap != "" {_configMapName: z.existingConfigmap}

	_clientTlsCertSecretName: *fullname | string
	if z.tls.client.existingSecret != "" {_clientTlsCertSecretName: z.tls.client.existingSecret}
	if z.tls.client.existingSecret == "" {_clientTlsCertSecretName: "\(fullname)-client-crt"}

	_quorumTlsCertSecretName: *fullname | string
	if z.tls.quorum.existingSecret != "" {_quorumTlsCertSecretName: z.tls.quorum.existingSecret}
	if z.tls.quorum.existingSecret == "" {_quorumTlsCertSecretName: "\(fullname)-quorum-crt"}

	// 1. configmap.yaml
	configMap: [
		if true {
			corev1.#ConfigMap & {
				apiVersion: "v1"
				kind:       "ConfigMap"
				metadata: {
					name:      fullname
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "zookeeper"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
					if k.commonAnnotations != _|_ {
						annotations: k.commonAnnotations
					}
				}
				data: {
					"zoo.cfg": z.configuration
				}
			}
		},
	]

	// 2. scripts-configmap.yaml
	scriptsConfigMap: corev1.#ConfigMap & {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "\(fullname)-scripts"
			namespace: #config.metadata.namespace
			labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "zookeeper"
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
			}
			if k.commonAnnotations != _|_ {
				annotations: k.commonAnnotations
			}
		}
		data: {
			"init-certs.sh": """
				#!/bin/bash

				if [[ -f "/certs/client/tls.key" ]] && [[ -f "/certs/client/tls.crt" ]] && [[ -f "/certs/client/ca.crt" ]]; then
				    if [[ -f "/opt/bitnami/zookeeper/config/certs/client/.initialized" ]]; then
				        exit 0
				    fi
				    openssl pkcs12 -export -in "/certs/client/tls.crt" \\
				      -passout pass:\"${ZOO_TLS_CLIENT_KEYSTORE_PASSWORD}\" \\
				      -inkey \"/certs/client/tls.key\" \\
				      -out \"/tmp/keystore.p12\"
				    keytool -importkeystore -srckeystore \"/tmp/keystore.p12\" \\
				      -srcstoretype PKCS12 \\
				      -srcstorepass \"${ZOO_TLS_CLIENT_KEYSTORE_PASSWORD}\" \\
				      -deststorepass \"${ZOO_TLS_CLIENT_KEYSTORE_PASSWORD}\" \\
				      -destkeystore \"/opt/bitnami/zookeeper/config/certs/client/zookeeper.keystore.jks\"
				    rm \"/tmp/keystore.p12\"
				    keytool -import -file \"/certs/client/ca.crt\" \\
				          -keystore \"/opt/bitnami/zookeeper/config/certs/client/zookeeper.truststore.jks\" \\
				          -storepass \"${ZOO_TLS_CLIENT_TRUSTSTORE_PASSWORD}\" \\
				          -noprompt
				    touch /opt/bitnami/zookeeper/config/certs/client/.initialized
				fi
				"""
			"setup.sh": """
				#!/bin/bash

				# Execute entrypoint as usual after obtaining ZOO_SERVER_ID
				# check ZOO_SERVER_ID in persistent volume via myid
				# if not present, set based on POD hostname
				if [[ -f \"/bitnami/zookeeper/data/myid\" ]]; then
				    export ZOO_SERVER_ID=\"$(cat /bitnami/zookeeper/data/myid)\"
				else
				    HOSTNAME=\"$(hostname -s)\"
				    if [[ $HOSTNAME =~ (.*)-([0-9]+)$ ]]; then
				        ORD=${BASH_REMATCH[2]}
				        export ZOO_SERVER_ID=\"$((ORD + \(z.minServerId) ))\"
				    else
				        echo \"Failed to get index from hostname $HOSTNAME\"
				        exit 1
				    fi
				fi
				exec /entrypoint.sh /run.sh
				"""
		}
	}

	// 3. svc.yaml
	service: corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      fullname
			namespace: #config.metadata.namespace
			labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "zookeeper"
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
			}
			if z.service.annotations != _|_ || k.commonAnnotations != _|_ {
				annotations: {
					if z.service.annotations != _|_ {
						for key, val in z.service.annotations {"\(key)": val}
					}
					if k.commonAnnotations != _|_ {
						for key, val in k.commonAnnotations {"\(key)": val}
					}
				}
			}
		}
		spec: {
			type: z.service.type
			if z.service.clusterIP != "" && z.service.type == "ClusterIP" {
				clusterIP: z.service.clusterIP
			}
			if z.service.type == "LoadBalancer" || z.service.type == "NodePort" {
				externalTrafficPolicy: z.service.externalTrafficPolicy
			}
			if z.service.type == "LoadBalancer" && len(z.service.loadBalancerSourceRanges) > 0 {
				loadBalancerSourceRanges: z.service.loadBalancerSourceRanges
			}
			if z.service.type == "LoadBalancer" && z.service.loadBalancerIP != "" {
				loadBalancerIP: z.service.loadBalancerIP
			}
			sessionAffinity: z.service.sessionAffinity
			if z.service.sessionAffinityConfig != _|_ {
				sessionAffinityConfig: z.service.sessionAffinityConfig
			}
			ports: [
				if !z.service.disableBaseClientPort {
					{
						name:       "tcp-client"
						port:       z.service.ports.client
						targetPort: "client"
						if (z.service.type == "NodePort" || z.service.type == "LoadBalancer") && z.service.nodePorts.client != "" {
							nodePort: z.service.nodePorts.client
						}
					}
				},
				if z.tls.client.enabled {
					{
						name:       "tcp-client-tls"
						port:       z.service.ports.tls
						targetPort: "client-tls"
						if (z.service.type == "NodePort" || z.service.type == "LoadBalancer") && z.service.nodePorts.tls != "" {
							nodePort: z.service.nodePorts.tls
						}
					}
				},
				if z.replicaCount > 1 {
					{
						name:       "tcp-follower"
						port:       z.service.ports.follower
						targetPort: "follower"
					}
				},
				if z.replicaCount > 1 {
					{
						name:       "tcp-election"
						port:       z.service.ports.election
						targetPort: "election"
					}
				},
				for p in z.service.extraPorts {p},
			]
			selector: {
				for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
				for key, val in z.podLabels {"\(key)": val}
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
				"app.kubernetes.io/name":      "kafka"
				"app.kubernetes.io/component": "zookeeper"
			}
		}
	}

	// 4. svc-headless.yaml
	headlessService: corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      headlessFullname
			namespace: #config.metadata.namespace
			labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "zookeeper"
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
			}
			if z.service.headless.annotations != _|_ || k.commonAnnotations != _|_ {
				annotations: {
					if z.service.headless.annotations != _|_ {
						for key, val in z.service.headless.annotations {"\(key)": val}
					}
					if k.commonAnnotations != _|_ {
						for key, val in k.commonAnnotations {"\(key)": val}
					}
				}
			}
		}
		spec: {
			type:                     "ClusterIP"
			clusterIP:                "None"
			publishNotReadyAddresses: z.service.headless.publishNotReadyAddresses
			ports: [
				if !z.service.disableBaseClientPort {
					{
						name:       "tcp-client"
						port:       z.service.ports.client
						targetPort: "client"
					}
				},
				if z.tls.client.enabled {
					{
						name:       "tcp-client-tls"
						port:       z.service.ports.tls
						targetPort: "client-tls"
					}
				},
				{
					name:       "tcp-follower"
					port:       z.service.ports.follower
					targetPort: "follower"
				},
				{
					name:       "tcp-election"
					port:       z.service.ports.election
					targetPort: "election"
				},
			]
			selector: {
				for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
				for key, val in z.podLabels {"\(key)": val}
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
				"app.kubernetes.io/name":      "kafka"
				"app.kubernetes.io/component": "zookeeper"
			}
		}
	}

	// 5. statefulset.yaml
	statefulSet: appsv1.#StatefulSet & {
		apiVersion: "apps/v1"
		kind:       "StatefulSet"
		metadata: {
			name:      fullname
			namespace: #config.metadata.namespace
			labels: #config.metadata.labels & {
				"app.kubernetes.io/component": "zookeeper"
				"role":                        "zookeeper"
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
			}
			if k.commonAnnotations != _|_ {
				annotations: k.commonAnnotations
			}
		}
		spec: {
			replicas:             z.replicaCount
			revisionHistoryLimit: z.revisionHistoryLimit
			podManagementPolicy:  z.podManagementPolicy
			selector: matchLabels: {
				for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
				for key, val in z.podLabels {"\(key)": val}
				if k.commonLabels != _|_ {
					for key, val in k.commonLabels {"\(key)": val}
				}
				"app.kubernetes.io/name":      "kafka"
				"app.kubernetes.io/component": "zookeeper"
			}
			serviceName: headlessFullname
			if z.updateStrategy != _|_ {
				updateStrategy: z.updateStrategy
			}
			template: {
				metadata: {
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "zookeeper"
						for key, val in z.podLabels {"\(key)": val}
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
					annotations: {
						if z.podAnnotations != _|_ {
							for key, val in z.podAnnotations {"\(key)": val}
						}
					}
				}
				spec: {
					enableServiceLinks:           z.enableServiceLinks
					serviceAccountName:           _saName
					automountServiceAccountToken: z.automountServiceAccountToken
					if z.podSecurityContext.enabled {
						securityContext: {
							for sk, sv in z.podSecurityContext if sk != "enabled" {"\(sk)": sv}
						}
					}
					if len(z.hostAliases) > 0 {
						hostAliases: z.hostAliases
					}
					if z.affinity != _|_ {
						affinity: z.affinity
					}
					if z.nodeSelector != _|_ {
						nodeSelector: z.nodeSelector
					}
					if z.tolerations != _|_ {
						tolerations: z.tolerations
					}
					if len(z.topologySpreadConstraints) > 0 {
						topologySpreadConstraints: z.topologySpreadConstraints
					}
					if z.priorityClassName != "" {
						priorityClassName: z.priorityClassName
					}
					if z.schedulerName != "" {
						schedulerName: z.schedulerName
					}
					if z.dnsPolicy != "" {
						dnsPolicy: z.dnsPolicy
					}
					if z.dnsConfig != _|_ {
						dnsConfig: z.dnsConfig
					}
					initContainers: [
						if z.volumePermissions.enabled && z.persistence.enabled {
							{
								name:            "volume-permissions"
								image:           "\(z.volumePermissions.image.registry)/\(z.volumePermissions.image.repository):\(z.volumePermissions.image.tag)"
								imagePullPolicy: z.volumePermissions.image.pullPolicy
								command: ["/bin/bash"]
								args: [
									"-ec",
									"""
									mkdir -p /bitnami/zookeeper
									chown -R \(z.containerSecurityContext.runAsUser):\(z.podSecurityContext.fsGroup) /bitnami/zookeeper
									find /bitnami/zookeeper -mindepth 1 -maxdepth 1 -not -name \".snapshot\" -not -name \"lost+found\" | xargs -r chown -R \(z.containerSecurityContext.runAsUser):\(z.podSecurityContext.fsGroup)
									""",
								]
								if z.volumePermissions.containerSecurityContext.enabled {
									securityContext: runAsUser: z.volumePermissions.containerSecurityContext.runAsUser
								}
								volumeMounts: [
									{name: "empty-dir", mountPath: "/tmp", subPath: "tmp-dir"},
									{name: "data", mountPath: "/bitnami/zookeeper"},
								]
							}
						},
						if z.tls.client.enabled || z.tls.quorum.enabled {
							{
								name:            "init-certs"
								image:           "\(z.image.registry)/\(z.image.repository):\(z.image.tag)"
								imagePullPolicy: z.image.pullPolicy
								if z.containerSecurityContext.enabled {
									securityContext: {
										for sk, sv in z.containerSecurityContext if sk != "enabled" {"\(sk)": sv}
									}
								}
								command: ["/scripts/init-certs.sh"]
								env: [
									{
										name: "MY_POD_NAME"
										valueFrom: fieldRef: fieldPath: "metadata.name"
									},
								]
								volumeMounts: [
									{name: "empty-dir", mountPath: "/tmp", subPath: "tmp-dir"},
									{name: "scripts", mountPath: "/scripts/init-certs.sh", subPath: "init-certs.sh"},
									if z.tls.client.enabled {
										{name: "client-certificates", mountPath: "/certs/client"}
									},
									if z.tls.client.enabled {
										{name: "client-shared-certs", mountPath: "/opt/bitnami/zookeeper/config/certs/client"}
									},
									if z.tls.quorum.enabled {
										{name: "quorum-certificates", mountPath: "/certs/quorum"}
									},
									if z.tls.quorum.enabled {
										{name: "quorum-shared-certs", mountPath: "/opt/bitnami/zookeeper/config/certs/quorum"}
									},
								]
							}
						},
						for ic in z.initContainers {ic},
					]
					containers: [
						{
							name:            "zookeeper"
							image:           "\(z.image.registry)/\(z.image.repository):\(z.image.tag)"
							imagePullPolicy: z.image.pullPolicy
							if z.containerSecurityContext.enabled {
								securityContext: {
									for sk, sv in z.containerSecurityContext if sk != "enabled" {"\(sk)": sv}
								}
							}
							if z.diagnosticMode.enabled {
								command: z.diagnosticMode.command
								args:    z.diagnosticMode.args
							}
							if !z.diagnosticMode.enabled && len(z.command) > 0 {
								command: z.command
							}
							if !z.diagnosticMode.enabled && len(z.args) > 0 {
								args: z.args
							}
							env: [
								{name: "BITNAMI_DEBUG", value: "\(_debug)"},
								{name: "ZOO_DATA_LOG_DIR", value: z.dataLogDir},
								{name: "ZOO_PORT_NUMBER", value: "\(z.containerPorts.client)"},
								{name: "ZOO_TICK_TIME", value: "\(z.tickTime)"},
								{name: "ZOO_INIT_LIMIT", value: "\(z.initLimit)"},
								{name: "ZOO_SYNC_LIMIT", value: "\(z.syncLimit)"},
								{name: "ZOO_PRE_ALLOC_SIZE", value: "\(z.preAllocSize)"},
								{name: "ZOO_SNAPCOUNT", value: "\(z.snapCount)"},
								{name: "ZOO_MAX_CLIENT_CNXNS", value: "\(z.maxClientCnxns)"},
								{name: "ZOO_4LW_COMMANDS_WHITELIST", value: z.fourlwCommandsWhitelist},
								{name: "ZOO_LISTEN_ALLIPS_ENABLED", value: _listenAllIps},
								{name: "ZOO_AUTOPURGE_INTERVAL", value: "\(z.autopurge.purgeInterval)"},
								{name: "ZOO_AUTOPURGE_RETAIN_COUNT", value: "\(z.autopurge.snapRetainCount)"},
								{name: "ZOO_MAX_SESSION_TIMEOUT", value: "\(z.maxSessionTimeout)"},
								{
									name: "ZOO_SERVERS"
									if z.zooServers != "" {
										value: z.zooServers
									}
									if z.zooServers == "" {
										value: "" // Placeholder
									}
								},
								{name: "ZOO_ENABLE_AUTH", value: _enableAuth},
								if z.auth.client.enabled {
									{name: "ZOO_CLIENT_USER", value: z.auth.client.clientUser}
								},
								if z.auth.client.enabled {
									{
										name: "ZOO_CLIENT_PASSWORD"
										valueFrom: secretKeyRef: {
											name: _clientAuthSecret
											key:  "client-password"
										}
									}
								},
								{name: "ZOO_ENABLE_QUORUM_AUTH", value: _enableQuorumAuth},
								{name: "ZOO_HEAP_SIZE", value: "\(z.heapSize)"},
								{name: "ZOO_LOG_LEVEL", value: z.logLevel},
								{name: "ALLOW_ANONYMOUS_LOGIN", value: _allowAnonymous},
								if z.jvmFlags != "" {
									{name: "JVMFLAGS", value: z.jvmFlags}
								},
								if z.metrics.enabled {
									{name: "ZOO_ENABLE_PROMETHEUS_METRICS", value: "yes"}
								},
								if z.metrics.enabled {
									{name: "ZOO_PROMETHEUS_METRICS_PORT_NUMBER", value: "\(_metricsPort)"}
								},
								{
									name: "POD_NAME"
									valueFrom: fieldRef: fieldPath: "metadata.name"
								},
								{name: "ZOO_ADMIN_SERVER_PORT_NUMBER", value: "\(z.containerPorts.adminServer)"},
								for ev in z.extraEnvVars {ev},
							]
							ports: [
								if !z.service.disableBaseClientPort {
									{name: "client", containerPort: z.containerPorts.client}
								},
								if z.tls.client.enabled {
									{name: "client-tls", containerPort: z.containerPorts.tls}
								},
								if z.replicaCount > 1 {
									{name: "follower", containerPort: z.containerPorts.follower}
								},
								if z.replicaCount > 1 {
									{name: "election", containerPort: z.containerPorts.election}
								},
								if z.metrics.enabled {
									{name: "metrics", containerPort: _metricsPort}
								},
								{name: "http-admin", containerPort: z.containerPorts.adminServer},
							]
							if !z.diagnosticMode.enabled {
								if z.livenessProbe.enabled {
									livenessProbe: {
										exec: command: ["/bin/bash", "-ec", "ZOO_HC_TIMEOUT=\(z.livenessProbe.probeCommandTimeout) /opt/bitnami/scripts/zookeeper/healthcheck.sh"]
										initialDelaySeconds: z.livenessProbe.initialDelaySeconds
										periodSeconds:       z.livenessProbe.periodSeconds
										timeoutSeconds:      z.livenessProbe.timeoutSeconds
										failureThreshold:    z.livenessProbe.failureThreshold
										successThreshold:    z.livenessProbe.successThreshold
									}
								}
								if z.readinessProbe.enabled {
									readinessProbe: {
										exec: command: ["/bin/bash", "-ec", "ZOO_HC_TIMEOUT=\(z.readinessProbe.probeCommandTimeout) /opt/bitnami/scripts/zookeeper/healthcheck.sh"]
										initialDelaySeconds: z.readinessProbe.initialDelaySeconds
										periodSeconds:       z.readinessProbe.periodSeconds
										timeoutSeconds:      z.readinessProbe.timeoutSeconds
										failureThreshold:    z.readinessProbe.failureThreshold
										successThreshold:    z.readinessProbe.successThreshold
									}
								}
							}
							volumeMounts: [
								{name: "empty-dir", mountPath: "/tmp", subPath: "tmp-dir"},
								{name: "empty-dir", mountPath: "/opt/bitnami/zookeeper/conf", subPath: "app-conf-dir"},
								{name: "empty-dir", mountPath: "/opt/bitnami/zookeeper/logs", subPath: "app-logs-dir"},
								{name: "scripts", mountPath: "/scripts/setup.sh", subPath: "setup.sh"},
								{name: "data", mountPath: "/bitnami/zookeeper"},
								if z.configuration != "" || z.existingConfigmap != "" {
									{name: "config", mountPath: "/opt/bitnami/zookeeper/conf/zoo.cfg", subPath: "zoo.cfg"}
								},
								for vm in z.extraVolumeMounts {vm},
							]
						},
						for s in z.sidecars {s},
					]
					volumes: [
						{name: "empty-dir", emptyDir: {}},
						{name: "scripts", configMap: {name: "\(fullname)-scripts", defaultMode: 493}},
						if z.configuration != "" || z.existingConfigmap != "" {
							{
								name: "config"
								configMap: {name: _configMapName}
							}
						},
						if !z.persistence.enabled {
							{name: "data", emptyDir: {}}
						},
						if z.persistence.enabled && z.persistence.existingClaim != "" {
							{
								name: "data"
								persistentVolumeClaim: claimName: z.persistence.existingClaim
							}
						},
						if z.tls.client.enabled {
							{name: "client-certificates", secret: {secretName: _clientTlsCertSecretName, defaultMode: 256}}
						},
						if z.tls.client.enabled {
							{name: "client-shared-certs", emptyDir: {}}
						},
						if z.tls.quorum.enabled {
							{name: "quorum-certificates", secret: {secretName: _quorumTlsCertSecretName, defaultMode: 256}}
						},
						if z.tls.quorum.enabled {
							{name: "quorum-shared-certs", emptyDir: {}}
						},
						for v in z.extraVolumes {v},
					]
				}
			}
			if z.persistence.enabled && z.persistence.existingClaim == "" {
				volumeClaimTemplates: [
					{
						metadata: {
							name: "data"
							if z.persistence.annotations != _|_ {
								annotations: z.persistence.annotations
							}
							if z.persistence.labels != _|_ {
								labels: z.persistence.labels
							}
						}
						spec: {
							accessModes: z.persistence.accessModes
							resources: requests: storage: z.persistence.size
							if z.persistence.storageClass != "" {
								storageClassName: z.persistence.storageClass
							}
							if z.persistence.selector != _|_ {
								selector: z.persistence.selector
							}
						}
					},
				]
			}
		}
	}

	// 6. serviceaccount.yaml
	serviceAccount: [
		if z.serviceAccount.create {
			corev1.#ServiceAccount & {
				apiVersion: "v1"
				kind:       "ServiceAccount"
				metadata: {
					name:      _saName
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "zookeeper"
						"role":                        "zookeeper"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
					if z.serviceAccount.annotations != _|_ || k.commonAnnotations != _|_ {
						annotations: {
							if z.serviceAccount.annotations != _|_ {
								for key, val in z.serviceAccount.annotations {"\(key)": val}
							}
							if k.commonAnnotations != _|_ {
								for key, val in k.commonAnnotations {"\(key)": val}
							}
						}
					}
				}
				automountServiceAccountToken: z.serviceAccount.automountServiceAccountToken
			}
		},
	]

	// 7. pdb.yaml
	pdb: [
		if z.pdb.create {
			policyv1.#PodDisruptionBudget & {
				apiVersion: "policy/v1"
				kind:       "PodDisruptionBudget"
				metadata: {
					name:      fullname
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "zookeeper"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
					if k.commonAnnotations != _|_ {
						annotations: k.commonAnnotations
					}
				}
				spec: {
					if z.pdb.minAvailable != "" {
						minAvailable: z.pdb.minAvailable
					}
					if z.pdb.maxUnavailable != "" || z.pdb.minAvailable == "" {
						if z.pdb.maxUnavailable != "" {
							maxUnavailable: z.pdb.maxUnavailable
						}
						if z.pdb.maxUnavailable == "" {
							maxUnavailable: 1
						}
					}
					selector: matchLabels: {
						for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
						for key, val in z.podLabels {"\(key)": val}
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
						"app.kubernetes.io/name":      "kafka"
						"app.kubernetes.io/component": "zookeeper"
					}
				}
			}
		},
	]

	// 8. networkpolicy.yaml
	networkPolicy: [
		if z.networkPolicy.enabled {
			networkingv1.#NetworkPolicy & {
				apiVersion: "networking.k8s.io/v1"
				kind:       "NetworkPolicy"
				metadata: {
					name:      fullname
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "zookeeper"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
					if k.commonAnnotations != _|_ {
						annotations: k.commonAnnotations
					}
				}
				spec: {
					podSelector: matchLabels: {
						for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
						for key, val in z.podLabels {"\(key)": val}
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
						"app.kubernetes.io/name":      "kafka"
						"app.kubernetes.io/component": "zookeeper"
					}
					policyTypes: ["Ingress", "Egress"]
					egress: [
						if z.networkPolicy.allowExternalEgress {
							{}
						},
						if !z.networkPolicy.allowExternalEgress {
							{
								ports: [
									{port: 53, protocol: "UDP"},
									{port: 53, protocol: "TCP"},
									{port: z.containerPorts.follower},
									{port: z.containerPorts.election},
								]
							}
						},
					]
					ingress: [
						{
							ports: [
								{port: z.containerPorts.client},
								if z.metrics.enabled {
									{port: _metricsPort}
								},
							]
							if !z.networkPolicy.allowExternal {
								from: [
									{
										podSelector: matchLabels: {
											for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
											if k.commonLabels != _|_ {
												for key, val in k.commonLabels {"\(key)": val}
											}
											"app.kubernetes.io/name": "kafka"
										}
									},
								]
							}
						},
						{
							ports: [
								{port: z.containerPorts.follower},
								{port: z.containerPorts.election},
							]
							from: [
								{
									podSelector: matchLabels: {
										for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
										for key, val in z.podLabels {"\(key)": val}
										if k.commonLabels != _|_ {
											for key, val in k.commonLabels {"\(key)": val}
										}
										"app.kubernetes.io/name":      "kafka"
										"app.kubernetes.io/component": "zookeeper"
									}
								},
							]
						},
					]
				}
			}
		},
	]

	// 9. extra-list.yaml
	extraDeploy: [
		for ed in z.extraDeploy {ed},
	]

	// 10. metrics-svc.yaml
	metricsService: [
		if z.metrics.enabled {
			corev1.#Service & {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      "\(fullname)-metrics"
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "metrics"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
					if z.metrics.service.annotations != _|_ || k.commonAnnotations != _|_ {
						annotations: {
							if z.metrics.service.annotations != _|_ {
								for key, val in z.metrics.service.annotations {"\(key)": val}
							}
							if k.commonAnnotations != _|_ {
								for key, val in k.commonAnnotations {"\(key)": val}
							}
						}
					}
				}
				spec: {
					type: z.metrics.service.type
					ports: [
						{
							name:       "http-metrics"
							port:       z.metrics.service.port
							targetPort: "metrics"
						},
					]
					selector: {
						for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
						for key, val in z.podLabels {"\(key)": val}
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
						"app.kubernetes.io/name":      "kafka"
						"app.kubernetes.io/component": "zookeeper"
					}
				}
			}
		},
	]

	// 11. secrets.yaml
	authSecret: [
		if z.auth.client.enabled && z.auth.client.existingSecret == "" {
			corev1.#Secret & {
				apiVersion: "v1"
				kind:       "Secret"
				metadata: {
					name:      "\(fullname)-client-auth"
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "zookeeper"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
				}
				type: "Opaque"
				stringData: {
					"client-password": z.auth.client.clientPassword
					"server-password": z.auth.client.serverPasswords
				}
			}
		},
	]

	quorumSecret: [
		if z.auth.quorum.enabled && z.auth.quorum.existingSecret == "" {
			corev1.#Secret & {
				apiVersion: "v1"
				kind:       "Secret"
				metadata: {
					name:      "\(fullname)-quorum-auth"
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "zookeeper"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
				}
				type: "Opaque"
				stringData: {
					"quorum-learner-password": z.auth.quorum.learnerPassword
					"quorum-server-password":  z.auth.quorum.serverPasswords
				}
			}
		},
	]

	tlsPasswordSecrets: [
		if z.tls.client.enabled && z.tls.client.passwordsSecretName == "" {
			corev1.#Secret & {
				apiVersion: "v1"
				kind:       "Secret"
				metadata: {
					name:      "\(fullname)-client-tls-pass"
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "zookeeper"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
				}
				type: "Opaque"
				stringData: {
					if z.tls.client.keystorePassword != "" {
						"keystore-password": z.tls.client.keystorePassword
					}
					if z.tls.client.keystorePassword == "" {
						"keystore-password": "password"
					}
					if z.tls.client.truststorePassword != "" {
						"truststore-password": z.tls.client.truststorePassword
					}
					if z.tls.client.truststorePassword == "" {
						"truststore-password": "password"
					}
				}
			}
		},
		if z.tls.quorum.enabled && z.tls.quorum.passwordsSecretName == "" {
			corev1.#Secret & {
				apiVersion: "v1"
				kind:       "Secret"
				metadata: {
					name:      "\(fullname)-quorum-tls-pass"
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "zookeeper"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
				}
				type: "Opaque"
				stringData: {
					if z.tls.quorum.keystorePassword != "" {
						"keystore-password": z.tls.quorum.keystorePassword
					}
					if z.tls.quorum.keystorePassword == "" {
						"keystore-password": "password"
					}
					if z.tls.quorum.truststorePassword != "" {
						"truststore-password": z.tls.quorum.truststorePassword
					}
					if z.tls.quorum.truststorePassword == "" {
						"truststore-password": "password"
					}
				}
			}
		},
	]

	// 12. tls-secrets.yaml
	tlsSecrets: [
		if z.tls.client.enabled && z.tls.client.existingSecret == "" && z.tls.client.autoGenerated {
			corev1.#Secret & {
				apiVersion: "v1"
				kind:       "Secret"
				metadata: {
					name:      "\(fullname)-client-crt"
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "zookeeper"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
				}
				type: "kubernetes.io/tls"
				data: {
					"tls.crt": z.tls.client.tlsCert
					"tls.key": z.tls.client.tlsKey
					"ca.crt":  z.tls.client.caCert
				}
			}
		},
		if z.tls.quorum.enabled && z.tls.quorum.existingSecret == "" && z.tls.quorum.autoGenerated {
			corev1.#Secret & {
				apiVersion: "v1"
				kind:       "Secret"
				metadata: {
					name:      "\(fullname)-quorum-crt"
					namespace: #config.metadata.namespace
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "zookeeper"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
					}
				}
				type: "kubernetes.io/tls"
				data: {
					"tls.crt": z.tls.quorum.tlsCert
					"tls.key": z.tls.quorum.tlsKey
					"ca.crt":  z.tls.quorum.caCert
				}
			}
		},
	]

	// 13. servicemonitor.yaml
	serviceMonitor: [
		if z.metrics.enabled && z.metrics.serviceMonitor.enabled {
			{
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "ServiceMonitor"
				metadata: {
					name: fullname
					if z.metrics.serviceMonitor.namespace != "" {
						namespace: z.metrics.serviceMonitor.namespace
					}
					if z.metrics.serviceMonitor.namespace == "" {
						namespace: #config.metadata.namespace
					}
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "metrics"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
						if z.metrics.serviceMonitor.additionalLabels != _|_ {
							for key, val in z.metrics.serviceMonitor.additionalLabels {"\(key)": val}
						}
					}
					if k.commonAnnotations != _|_ {
						annotations: k.commonAnnotations
					}
				}
				spec: {
					if z.metrics.serviceMonitor.jobLabel != "" {
						jobLabel: z.metrics.serviceMonitor.jobLabel
					}
					selector: matchLabels: {
						for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
						for key, val in z.podLabels {"\(key)": val}
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
						if z.metrics.serviceMonitor.selector != _|_ {
							for key, val in z.metrics.serviceMonitor.selector {"\(key)": val}
						}
						"app.kubernetes.io/component": "metrics"
					}
					endpoints: [
						{
							port: "http-metrics"
							path: "/metrics"
							if z.metrics.serviceMonitor.interval != "" {
								interval: z.metrics.serviceMonitor.interval
							}
							if z.metrics.serviceMonitor.scrapeTimeout != "" {
								scrapeTimeout: z.metrics.serviceMonitor.scrapeTimeout
							}
							if len(z.metrics.serviceMonitor.relabelings) > 0 {
								relabelings: z.metrics.serviceMonitor.relabelings
							}
							if len(z.metrics.serviceMonitor.metricRelabelings) > 0 {
								metricRelabelings: z.metrics.serviceMonitor.metricRelabelings
							}
							honorLabels: z.metrics.serviceMonitor.honorLabels
							if z.metrics.serviceMonitor.scheme != "" {
								scheme: z.metrics.serviceMonitor.scheme
							}
							if z.metrics.serviceMonitor.tlsConfig != _|_ {
								tlsConfig: z.metrics.serviceMonitor.tlsConfig
							}
						},
					]
					namespaceSelector: matchNames: [#config.metadata.namespace]
				}
			}
		},
	]

	// 14. prometheusrule.yaml
	prometheusRule: [
		if z.metrics.enabled && z.metrics.prometheusRule.enabled && len(z.metrics.prometheusRule.rules) > 0 {
			{
				apiVersion: "monitoring.coreos.com/v1"
				kind:       "PrometheusRule"
				metadata: {
					name: fullname
					if z.metrics.prometheusRule.namespace != "" {
						namespace: z.metrics.prometheusRule.namespace
					}
					if z.metrics.prometheusRule.namespace == "" {
						namespace: #config.metadata.namespace
					}
					labels: #config.metadata.labels & {
						"app.kubernetes.io/component": "metrics"
						if k.commonLabels != _|_ {
							for key, val in k.commonLabels {"\(key)": val}
						}
						if z.metrics.prometheusRule.additionalLabels != _|_ {
							for key, val in z.metrics.prometheusRule.additionalLabels {"\(key)": val}
						}
					}
					if k.commonAnnotations != _|_ {
						annotations: k.commonAnnotations
					}
				}
				spec: {
					groups: [
						{
							name:  fullname
							rules: z.metrics.prometheusRule.rules
						},
					]
				}
			}
		},
	]
}
