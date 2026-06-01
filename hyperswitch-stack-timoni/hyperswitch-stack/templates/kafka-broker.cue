package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	policyv1 "k8s.io/api/policy/v1"
	autoscalingv2 "k8s.io/api/autoscaling/v2"
	"strings"
	"list"
)

// Helper for Kafka Broker components
#KafkaBroker: {
	#config: #Config

	// Local Value Extraction
	let k = #config."hyperswitch-app".kafka
	let b = k.broker
	let _metadata = #config.metadata
	let ns = _metadata.namespace
	let instanceName = _metadata.name
	let fullname = "\(instanceName)-\(k.name)"
	let globalAnn = *_metadata.annotations | {}

	// Internal helper for listeners
	let listenersList = [
		k.listeners.client,
		k.listeners.interbroker,
		// For role=broker, we don't include the controller listener in 'listeners'
		// but we still need it in securityProtocolMap if we want to talk to controllers
		// if k.kraft.enabled && !b.controllerOnly {k.listeners.controller},
		if k.externalAccess.enabled {k.listeners.external},
		for l in k.listeners.extraListeners {l},
	]

	let securityProtocolMap = strings.Join([
		for l in [k.listeners.client, k.listeners.interbroker, if k.kraft.enabled {k.listeners.controller}] {
			"\(strings.ToUpper(l.name)):\(strings.ToUpper(l.protocol))"
		},
		for l in k.listeners.extraListeners {
			"\(strings.ToUpper(l.name)):\(strings.ToUpper(l.protocol))"
		},
		if k.externalAccess.enabled {
			"\(strings.ToUpper(k.listeners.external.name)):\(strings.ToUpper(k.listeners.external.protocol))"
		},
	], ",")

	let listeners = strings.Join([
		for l in listenersList if l != _|_ {
			"\(strings.ToUpper(l.name))://:\(l.containerPort)"
		},
	], ",")

	let advertisedListeners = strings.Join([
		for l in [k.listeners.client, k.listeners.interbroker] {
			"\(strings.ToUpper(l.name))://advertised-address-placeholder:\(l.containerPort)"
		},
		for l in k.listeners.extraListeners {
			"\(strings.ToUpper(l.name))://advertised-address-placeholder:\(l.containerPort)"
		},
	], ",")

	let commonConfig = strings.Join([
		"# Interbroker configuration",
		"inter.broker.listener.name=\(strings.ToUpper(k.listeners.interbroker.name))",
		if k.sslEnabled {
			"""
				# TLS configuration
				ssl.keystore.type=JKS
				ssl.truststore.type=JKS
				ssl.keystore.location=/opt/bitnami/kafka/config/certs/kafka.keystore.jks
				ssl.truststore.location=/opt/bitnami/kafka/config/certs/kafka.truststore.jks
				ssl.client.auth=\(k.tls.sslClientAuth)
				ssl.endpoint.identification.algorithm=\(k.tls.endpointIdentificationAlgorithm)
				"""
		},
	], "\n")

	// 1. broker/config-secrets.yaml
	configSecret: corev1.#Secret & {
		apiVersion: "v1"
		kind:       "Secret"
		metadata: {
			name:      "\(fullname)-broker-secret-configuration"
			namespace: ns
			labels: {
				for lab, v in _metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
				"app.kubernetes.io/name":      "kafka"
				"app.kubernetes.io/component": "broker"
			}
			annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
		}
		type: "Opaque"
		stringData: {
			"server-secret.properties": ""
		}
	}

	// 2. broker/configmap.yaml
	configMap: corev1.#ConfigMap & {
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "\(fullname)-broker-configuration"
			namespace: ns
			labels: {
				for lab, v in _metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
				"app.kubernetes.io/name":      "kafka"
				"app.kubernetes.io/component": "broker"
			}
			annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
		}
		data: {
			"server.properties": strings.Join([
				"# Listeners configuration",
				"listeners=\(listeners)",
				"listener.security.protocol.map=\(securityProtocolMap)",
				"advertised.listeners=\(advertisedListeners)",
				if k.kraft.enabled {
					"""
						# KRaft node role
						process.roles=broker
						controller.listener.names=\(strings.ToUpper(k.listeners.controller.name))
						controller.quorum.voters=\(k.kraft.controllerQuorumVoters)
						"""
				},
				"# Zookeeper configuration",
				if k.zookeeper.enabled {
					"zookeeper.connect=\(fullname)-zookeeper:2181"
				},
				"# Kafka data logs directory",
				"log.dirs=\(b.persistence.mountPath)/data",
				"",
				"# Common Kafka Configuration",
				commonConfig,
				"",
				"# Custom Kafka Configuration",
				k.extraConfig,
				b.extraConfig,
			], "\n")
		}
	}

	// 3. broker/hpa.yaml
	hpa: [if b.autoscaling.hpa.enabled {
		autoscalingv2.#HorizontalPodAutoscaler & {
			apiVersion: "autoscaling/v2"
			kind:       "HorizontalPodAutoscaler"
			metadata: {
				name:      "\(fullname)-broker"
				namespace: ns
				labels: {
					for lab, v in _metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "broker"
				}
				annotations: (#MergeAnnotations & {#global: globalAnn, #local: b.autoscaling.hpa.annotations}).#result
			}
			spec: {
				scaleTargetRef: {
					apiVersion: "apps/v1"
					kind:       "StatefulSet"
					name:       "\(fullname)-broker"
				}
				minReplicas: b.autoscaling.hpa.minReplicas
				maxReplicas: b.autoscaling.hpa.maxReplicas
				metrics: [
					if b.autoscaling.hpa.targetCPU != _|_ {
						{
							type: "Resource"
							resource: {
								name: "cpu"
								target: {
									type:               "Utilization"
									averageUtilization: b.autoscaling.hpa.targetCPU
								}
							}
						}
					},
					if b.autoscaling.hpa.targetMemory != _|_ {
						{
							type: "Resource"
							resource: {
								name: "memory"
								target: {
									type:               "Utilization"
									averageUtilization: b.autoscaling.hpa.targetMemory
								}
							}
						}
					},
				]
			}
		}
	}]

	// 4. broker/pdb.yaml
	pdb: [if b.pdb.create {
		policyv1.#PodDisruptionBudget & {
			apiVersion: "policy/v1"
			kind:       "PodDisruptionBudget"
			metadata: {
				name:      "\(fullname)-broker"
				namespace: ns
				labels: {
					for lab, v in _metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "broker"
				}
				annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
			}
			spec: {
				if b.pdb.minAvailable != _|_ && b.pdb.minAvailable != "" {
					minAvailable: b.pdb.minAvailable
				}
				if (b.pdb.minAvailable == _|_ || b.pdb.minAvailable == "") && b.pdb.maxUnavailable != "" {
					maxUnavailable: b.pdb.maxUnavailable
				}
				if (b.pdb.minAvailable == _|_ || b.pdb.minAvailable == "") && (b.pdb.maxUnavailable == _|_ || b.pdb.maxUnavailable == "") {
					maxUnavailable: 1
				}
				selector: matchLabels: {
					for lab, v in _metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "broker"
				}
			}
		}
	}]

	// 5. broker/svc-headless.yaml
	headlessSvc: corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "\(fullname)-broker-headless"
			namespace: ns
			labels: {
				for lab, v in _metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
				"app.kubernetes.io/name":      "kafka"
				"app.kubernetes.io/component": "broker"
			}
			annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
		}
		spec: {
			type:                     "ClusterIP"
			clusterIP:                "None"
			publishNotReadyAddresses: true
			ports: [
				{
					name:       "tcp-interbroker"
					port:       k.service.ports.interbroker
					protocol:   "TCP"
					targetPort: "interbroker"
				},
				{
					name:       "tcp-client"
					port:       k.service.ports.client
					protocol:   "TCP"
					targetPort: "client"
				},
			]
			selector: {
				for lab, v in _metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
				"app.kubernetes.io/name":      "kafka"
				"app.kubernetes.io/component": "broker"
			}
		}
	}

	// 6. broker/svc-external-access.yaml
	externalSvcs: [
		if k.externalAccess.enabled {
			for i in list.Range(0, b.replicaCount, 1) {
				let targetPod = "\(fullname)-broker-\(i)"
				corev1.#Service & {
					apiVersion: "v1"
					kind:       "Service"
					metadata: {
						name:      "\(fullname)-broker-\(i)-external"
						namespace: ns
						labels: {
							for lab, v in _metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
							"app.kubernetes.io/name":      "kafka"
							"app.kubernetes.io/component": "broker"
							"pod":                         targetPod
						}
						annotations: (#MergeAnnotations & {
							#global: globalAnn
							#local: {
								if k.externalAccess.broker.service.loadBalancerAnnotations != _|_ && len(k.externalAccess.broker.service.loadBalancerAnnotations) > i {
									k.externalAccess.broker.service.loadBalancerAnnotations[i]
								}
								if k.externalAccess.broker.service.annotations != _|_ {
									k.externalAccess.broker.service.annotations
								}
							}
						}).#result
					}
					spec: {
						type: k.externalAccess.broker.service.type
						if type == "LoadBalancer" {
							if k.externalAccess.broker.service.allocateLoadBalancerNodePorts != _|_ {
								allocateLoadBalancerNodePorts: k.externalAccess.broker.service.allocateLoadBalancerNodePorts
							}
							if k.externalAccess.broker.service.loadBalancerClass != _|_ && k.externalAccess.broker.service.loadBalancerClass != "" {
								loadBalancerClass: k.externalAccess.broker.service.loadBalancerClass
							}
							if k.externalAccess.broker.service.loadBalancerIPs != _|_ && len(k.externalAccess.broker.service.loadBalancerIPs) > i {
								loadBalancerIP: k.externalAccess.broker.service.loadBalancerIPs[i]
							}
							if k.externalAccess.broker.service.loadBalancerSourceRanges != _|_ {
								loadBalancerSourceRanges: k.externalAccess.broker.service.loadBalancerSourceRanges
							}
						}
						publishNotReadyAddresses: k.externalAccess.broker.service.publishNotReadyAddresses
						ports: [
							{
								name: "tcp-kafka"
								port: k.externalAccess.broker.service.ports.external
								if k.externalAccess.broker.service.nodePorts != _|_ && len(k.externalAccess.broker.service.nodePorts) > i {
									nodePort: k.externalAccess.broker.service.nodePorts[i]
								}
								targetPort: "external"
							},
						]
						if type == "NodePort" && k.externalAccess.broker.service.externalIPs != _|_ && len(k.externalAccess.broker.service.externalIPs) > i {
							externalIPs: [k.externalAccess.broker.service.externalIPs[i]]
						}
						selector: {
							for lab, v in _metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
							"app.kubernetes.io/part-of":          "kafka"
							"app.kubernetes.io/component":        "broker"
							"statefulset.kubernetes.io/pod-name": targetPod
						}
					}
				}
			}
		},
	]

	// 7. broker/statefulset.yaml
	statefulSet: appsv1.#StatefulSet & {
		apiVersion: "apps/v1"
		kind:       "StatefulSet"
		metadata: {
			name:      "\(fullname)-broker"
			namespace: ns
			labels: {
				for lab, v in _metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
				"app.kubernetes.io/name":      "kafka"
				"app.kubernetes.io/component": "broker"
			}
			annotations: (#MergeAnnotations & {#global: globalAnn, #local: b.annotations}).#result
		}
		spec: {
			podManagementPolicy: b.podManagementPolicy
			if !b.autoscaling.hpa.enabled {
				replicas: b.replicaCount
			}
			selector: matchLabels: {
				for lab, v in _metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
				"app.kubernetes.io/name":      "kafka"
				"app.kubernetes.io/component": "broker"
			}
			serviceName:    "\(fullname)-broker-headless"
			updateStrategy: b.updateStrategy
			template: {
				metadata: {
					labels: {
						for lab, v in _metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
						"app.kubernetes.io/name":      "kafka"
						"app.kubernetes.io/component": "broker"
					}
					annotations: {
						"checksum/configuration": "config-checksum-\(k.kraft.clusterId)"
						if k.saslEnabled {
							"checksum/passwords-secret": "static-sasl-checksum"
						}
						for ka, va in b.podAnnotations {"\(ka)": va}
					}
				}
				spec: {
					if k.imagePullSecrets != _|_ {
						imagePullSecrets: k.imagePullSecrets
					}
					automountServiceAccountToken: b.automountServiceAccountToken
					hostNetwork:                  b.hostNetwork
					hostIPC:                      b.hostIPC
					if b.schedulerName != "" {
						schedulerName: b.schedulerName
					}
					if b.affinity != _|_ {
						affinity: b.affinity
					}
					if b.nodeSelector != _|_ {
						nodeSelector: b.nodeSelector
					}
					if b.tolerations != _|_ {
						tolerations: b.tolerations
					}
					if b.topologySpreadConstraints != _|_ {
						topologySpreadConstraints: b.topologySpreadConstraints
					}
					terminationGracePeriodSeconds: b.terminationGracePeriodSeconds
					if b.priorityClassName != "" {
						priorityClassName: b.priorityClassName
					}
					if b.podSecurityContext.enabled {
						securityContext: {
							for sk, sv in b.podSecurityContext if sk != "enabled" {"\(sk)": sv}
						}
					}
					serviceAccountName: *fullname | string
					if k.serviceAccount.name != "" {
						serviceAccountName: k.serviceAccount.name
					}
					initContainers: [
						if b.persistence.enabled && k.volumePermissions.enabled {
							{
								name:  "volume-permissions"
								image: "\(k.volumePermissions.image.registry)/\(k.volumePermissions.image.repository):\(k.volumePermissions.image.tag)"
								command: ["/bin/bash", "-ec"]
								args: ["""
									mkdir -p "\(b.persistence.mountPath)" "\(b.logPersistence.mountPath)"
									chown -R \(b.containerSecurityContext.runAsUser):\(b.podSecurityContext.fsGroup) "\(b.persistence.mountPath)" "\(b.logPersistence.mountPath)"
									find "\(b.persistence.mountPath)" -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" | xargs -r chown -R \(b.containerSecurityContext.runAsUser):\(b.podSecurityContext.fsGroup)
									find "\(b.logPersistence.mountPath)" -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" | xargs -r chown -R \(b.containerSecurityContext.runAsUser):\(b.podSecurityContext.fsGroup)
									"""]
								securityContext: {
									for sk, sv in k.volumePermissions.containerSecurityContext if sk != "enabled" {"\(sk)": sv}
								}
								if k.volumePermissions.resources != _|_ {
									resources: k.volumePermissions.resources
								}
								volumeMounts: [
									{name: "data", mountPath: b.persistence.mountPath},
									{name: "logs", mountPath: b.logPersistence.mountPath},
								]
							}
						},
						if k.externalAccess.enabled {
							{
								name:  "auto-discovery"
								image: "\(k.image.registry)/\(k.image.repository):\(k.image.tag)"
								command: ["/bin/bash", "-ec"]
								args: ["/scripts/auto-discovery.sh"]
								volumeMounts: [
									{name: "scripts", mountPath: "/scripts/auto-discovery.sh", subPath: "auto-discovery.sh"},
									{name: "shared", mountPath: "/shared"},
								]
							}
						},
						{
							name:  "kafka-init"
							image: "\(k.image.registry)/\(k.image.repository):\(k.image.tag)"
							command: ["/bin/bash", "-ec"]
							args: ["/scripts/kafka-init.sh"]
							env: [
								{name: "BITNAMI_DEBUG", value: "false"},
								{
									name: "MY_POD_NAME"
									valueFrom: fieldRef: fieldPath: "metadata.name"
								},
								{name: "KAFKA_VOLUME_DIR", value: b.persistence.mountPath},
								{name: "KAFKA_MIN_ID", value: "\(b.minId)"},
								if k.externalAccess.enabled {
									{name: "EXTERNAL_ACCESS_ENABLED", value: "true"}
								},
								if k.saslEnabled {
									{
										name:  "KAFKA_INTER_BROKER_USER"
										value: k.sasl.interbroker.user
									}
								},
								if k.saslEnabled {
									{
										name: "KAFKA_INTER_BROKER_PASSWORD"
										valueFrom: secretKeyRef: {
											name: "\(fullname)-user-passwords"
											key:  "inter-broker-password"
										}
									}
								},
								{name: "KRAFT_ENABLED", value: "true"},
							]
							volumeMounts: [
								{name: "data", mountPath: b.persistence.mountPath},
								{name: "kafka-config", mountPath: "/config"},
								{name: "configmaps", mountPath: "/configmaps"},
								{name: "scripts", mountPath: "/scripts/kafka-init.sh", subPath: "kafka-init.sh"},
								if k.externalAccess.enabled {{name: "shared", mountPath: "/shared"}},
							]
						},
					]
					containers: [
						{
							name:            "kafka"
							image:           "\(k.image.registry)/\(k.image.repository):\(k.image.tag)"
							imagePullPolicy: k.image.pullPolicy
							if b.containerSecurityContext.enabled {
								securityContext: {
									for sk, sv in b.containerSecurityContext if sk != "enabled" {"\(sk)": sv}
								}
							}
							env: [
								{name: "BITNAMI_DEBUG", value: "false"},
								{name: "KAFKA_HEAP_OPTS", value: b.heapOpts},
								{name: "KAFKA_CFG_PROCESS_ROLES", value: "broker"},
								{name: "KAFKA_CFG_CONTROLLER_QUORUM_VOTERS", value: k.kraft.controllerQuorumVoters},
								{name: "KAFKA_CFG_CONTROLLER_LISTENER_NAMES", value: strings.ToUpper(k.listeners.controller.name)},
								if k.kraft.enabled {
									{
										name: "KAFKA_KRAFT_CLUSTER_ID"
										valueFrom: secretKeyRef: {
											name: "\(fullname)-kraft-cluster-id"
											key:  "kraft-cluster-id"
										}
									}
								},
							]
							ports: [
								{name: "client", containerPort: k.service.ports.client},
								{name: "interbroker", containerPort: k.service.ports.interbroker},
								if k.kraft.enabled {{name: "controller", containerPort: k.service.ports.controller}},
								if k.externalAccess.enabled {{name: "external", containerPort: k.service.ports.external}},
							]
							livenessProbe: {
								exec: command: ["pgrep", "-f", "kafka"]
								initialDelaySeconds: b.livenessProbe.initialDelaySeconds
								periodSeconds:       b.livenessProbe.periodSeconds
								timeoutSeconds:      b.livenessProbe.timeoutSeconds
								successThreshold:    b.livenessProbe.successThreshold
								failureThreshold:    b.livenessProbe.failureThreshold
							}
							readinessProbe: {
								tcpSocket: port: "client"
								initialDelaySeconds: b.readinessProbe.initialDelaySeconds
								periodSeconds:       b.readinessProbe.periodSeconds
								timeoutSeconds:      b.readinessProbe.timeoutSeconds
								successThreshold:    b.readinessProbe.successThreshold
								failureThreshold:    b.readinessProbe.failureThreshold
							}
							if b.resources != _|_ {
								resources: b.resources
							}
							volumeMounts: [
								{name: "data", mountPath: b.persistence.mountPath},
								{name: "logs", mountPath: b.logPersistence.mountPath},
								{name: "kafka-config", mountPath: "/opt/bitnami/kafka/config/server.properties", subPath: "server.properties"},
								{name: "tmp", mountPath: "/tmp"},
								{name: "log4j-config", mountPath: "/opt/bitnami/kafka/config/log4j.properties", subPath: "log4j.properties"},
							]
						},
						if k.metrics.jmx.enabled {
							{
								name:            "jmx-exporter"
								image:           "\(k.metrics.jmx.image.registry)/\(k.metrics.jmx.image.repository):\(k.metrics.jmx.image.tag)"
								imagePullPolicy: k.metrics.jmx.image.pullPolicy
								if k.metrics.jmx.containerSecurityContext.enabled {
									securityContext: {
										for sk, sv in k.metrics.jmx.containerSecurityContext if sk != "enabled" {"\(sk)": sv}
									}
								}
								command: ["java"]
								args: [
									"-XX:MaxRAMPercentage=100",
									"-XshowSettings:vm",
									"-jar",
									"jmx_prometheus_httpserver.jar",
									"\(k.metrics.jmx.containerPorts.metrics)",
									"/etc/jmx-kafka/jmx-kafka-prometheus.yml",
								]
								ports: [
									{
										name:          "metrics"
										containerPort: k.metrics.jmx.containerPorts.metrics
									},
								]
								if k.metrics.jmx.resources != _|_ {
									resources: k.metrics.jmx.resources
								}
								volumeMounts: [
									{
										name:      "jmx-config"
										mountPath: "/etc/jmx-kafka"
									},
								]
							}
						},
					]
					volumes: [
						{
							name: "kafka-config"
							emptyDir: {}
						},
						{
							name: "configmaps"
							configMap: name: "\(fullname)-broker-configuration"
						},
						{
							name: "tmp"
							emptyDir: {}
						},
						{
							name: "scripts"
							configMap: {
								name:        "\(fullname)-scripts"
								defaultMode: 493
							}
						},
						if k.externalAccess.enabled {
							{
								name: "shared"
								emptyDir: {}
							}
						},
						{
							name: "log4j-config"
							configMap: name: "\(fullname)-log4j"
						},
						if !b.persistence.enabled {
							{name: "data", emptyDir: {}}
						},
						if !b.logPersistence.enabled {
							{name: "logs", emptyDir: {}}
						},
						if k.metrics.jmx.enabled {
							{
								name: "jmx-config"
								configMap: name: "\(fullname)-jmx-configuration"
							}
						},
					]
				}
			}
			if b.persistence.enabled {
				volumeClaimTemplates: [
					{
						metadata: name: "data"
						spec: {
							accessModes: b.persistence.accessModes
							resources: requests: storage: b.persistence.size
							if b.persistence.storageClass != "" {
								storageClassName: b.persistence.storageClass
							}
						}
					},
					if b.logPersistence.enabled {
						{
							metadata: name: "logs"
							spec: {
								accessModes: b.logPersistence.accessModes
								resources: requests: storage: b.logPersistence.size
								if b.logPersistence.storageClass != "" {
									storageClassName: b.logPersistence.storageClass
								}
							}
						}
					},
				]
			}
		}
	}

	// 8. broker/vpa.yaml
	vpa: [if b.autoscaling.vpa.enabled {
		{
			apiVersion: "autoscaling.k8s.io/v1"
			kind:       "VerticalPodAutoscaler"
			metadata: {
				name:      "\(fullname)-broker"
				namespace: ns
				labels: {
					for lab, v in _metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "broker"
				}
			}
			spec: {
				targetRef: {
					apiVersion: "apps/v1"
					kind:       "StatefulSet"
					name:       "\(fullname)-broker"
				}
				updatePolicy: updateMode: b.autoscaling.vpa.updateMode
			}
		}
	}]
}
