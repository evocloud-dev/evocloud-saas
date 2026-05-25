package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	policyv1 "k8s.io/api/policy/v1"
	autoscalingv2 "k8s.io/api/autoscaling/v2"
	"strings"
	"list"
)

// Helper for Kafka Controller components
#KafkaController: {
	#config: #Config
	let k = #config."hyperswitch-app".kafka
	let c = k.controller
	let fullname = "\(#config.metadata.name)-\(k.name)"
	let globalAnn = *#config.metadata.annotations | {}

	// Internal helper for listeners
	let listenersList = [
		if k.kraft.enabled {k.listeners.controller},
		// Controllers only listen on the controller port
		// k.listeners.client,
		// k.listeners.interbroker,
		// if k.externalAccess.enabled {k.listeners.external},
		// for l in k.listeners.extraListeners {l},
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

	// Common Config logic
	let commonConfig = strings.Join([
		// "# Interbroker configuration",
		// "inter.broker.listener.name=\(strings.ToUpper(k.listeners.interbroker.name))",
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

	// 1. controller-eligible/config-secrets.yaml
	configSecret: [if k.kraft.enabled && c.replicaCount > 0 {
		corev1.#Secret & {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      "\(fullname)-controller-secret-configuration"
				namespace: #config.metadata.namespace
				labels: {
					for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "controller-eligible"
				}
				annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
			}
			type: "Opaque"
			stringData: {
				"server-secret.properties": ""
			}
		}
	}]

	// 2. controller-eligible/configmap.yaml
	configMap: [if k.kraft.enabled && c.replicaCount > 0 {
		corev1.#ConfigMap & {
			apiVersion: "v1"
			kind:       "ConfigMap"
			metadata: {
				name:      "\(fullname)-controller-configuration"
				namespace: #config.metadata.namespace
				labels: {
					for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "controller-eligible"
					"app.kubernetes.io/part-of":   "kafka"
				}
				annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
			}
			data: {
				"server.properties": strings.Join([
					"# Listeners configuration",
					"listeners=\(listeners)",
					if !c.controllerOnly {
						"advertised.listeners=\(advertisedListeners)"
					},
					"listener.security.protocol.map=\(securityProtocolMap)",
					if k.kraft.enabled {
						"""
						# KRaft process roles
						process.roles=\([if c.controllerOnly {"controller"}, "controller,broker"][0])
						controller.listener.names=\(strings.ToUpper(k.listeners.controller.name))
						controller.quorum.voters=\(k.kraft.controllerQuorumVoters)
						"""
					},
					if k.zookeeper.enabled {
						"""
						# Zookeeper configuration
						zookeeper.metadata.migration.enable=true
						inter.broker.protocol.version=\(k.interBrokerProtocolVersion)
						zookeeper.connect=\(fullname)-zookeeper:2181
						"""
					},
					"# Kafka data logs directory",
					"log.dirs=\(c.persistence.mountPath)/data",
					"",
					"# Common Kafka Configuration",
					commonConfig,
					"",
					"# Custom Kafka Configuration",
					k.extraConfig,
					c.extraConfig,
				], "\n")
			}
		}
	}]

	// 3. controller-eligible/hpa.yaml
	hpa: [if k.kraft.enabled && c.replicaCount > 0 && c.autoscaling.hpa.enabled {
		autoscalingv2.#HorizontalPodAutoscaler & {
			apiVersion: "autoscaling/v2"
			kind:       "HorizontalPodAutoscaler"
			metadata: {
				name:      "\(fullname)-controller"
				namespace: #config.metadata.namespace
				labels: {
					for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "controller"
					"app.kubernetes.io/part-of":   "kafka"
				}
				annotations: (#MergeAnnotations & {#global: globalAnn, #local: c.autoscaling.hpa.annotations}).#result
			}
			spec: {
				scaleTargetRef: {
					apiVersion: "apps/v1"
					kind:       "StatefulSet"
					name:       "\(fullname)-controller"
				}
				minReplicas: c.autoscaling.hpa.minReplicas
				maxReplicas: c.autoscaling.hpa.maxReplicas
				metrics: [
					if c.autoscaling.hpa.targetCPU != _|_ {
						{
							type: "Resource"
							resource: {
								name: "cpu"
								target: {
									type:               "Utilization"
									averageUtilization: c.autoscaling.hpa.targetCPU
								}
							}
						}
					},
					if c.autoscaling.hpa.targetMemory != _|_ {
						{
							type: "Resource"
							resource: {
								name: "memory"
								target: {
									type:               "Utilization"
									averageUtilization: c.autoscaling.hpa.targetMemory
								}
							}
						}
					},
				]
			}
		}
	}]

	// 4. controller-eligible/pdb.yaml
	pdb: [if c.pdb.create && k.kraft.enabled {
		policyv1.#PodDisruptionBudget & {
			apiVersion: "policy/v1"
			kind:       "PodDisruptionBudget"
			metadata: {
				name:      "\(fullname)-controller"
				namespace: #config.metadata.namespace
				labels: {
					for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "controller-eligible"
					"app.kubernetes.io/part-of":   "kafka"
				}
				annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
			}
			spec: {
				if c.pdb.minAvailable != _|_ && c.pdb.minAvailable != "" {
					minAvailable: c.pdb.minAvailable
				}
				if (c.pdb.minAvailable == _|_ || c.pdb.minAvailable == "") && c.pdb.maxUnavailable != "" {
					maxUnavailable: c.pdb.maxUnavailable
				}
				if (c.pdb.minAvailable == _|_ || c.pdb.minAvailable == "") && (c.pdb.maxUnavailable == _|_ || c.pdb.maxUnavailable == "") {
					maxUnavailable: 1
				}
				selector: matchLabels: {
					for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "controller-eligible"
					"app.kubernetes.io/part-of":   "kafka"
				}
			}
		}
	}]

	// 5. controller-eligible/vpa.yaml
	vpa: [if k.kraft.enabled && c.replicaCount > 0 && c.autoscaling.vpa.enabled {
		{
			apiVersion: "autoscaling.k8s.io/v1"
			kind:       "VerticalPodAutoscaler"
			metadata: {
				name:      "\(fullname)-controller"
				namespace: #config.metadata.namespace
				labels: {
					for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "controller"
					"app.kubernetes.io/part-of":   "kafka"
				}
				annotations: (#MergeAnnotations & {#global: globalAnn, #local: c.autoscaling.vpa.annotations}).#result
			}
			spec: {
				resourcePolicy: containerPolicies: [{
					containerName: "kafka"
					if c.autoscaling.vpa.controlledResources != _|_ {
						controlledResources: c.autoscaling.vpa.controlledResources
					}
					if c.autoscaling.vpa.maxAllowed != _|_ {
						maxAllowed: c.autoscaling.vpa.maxAllowed
					}
					if c.autoscaling.vpa.minAllowed != _|_ {
						minAllowed: c.autoscaling.vpa.minAllowed
					}
				}]
				targetRef: {
					apiVersion: "apps/v1"
					kind:       "StatefulSet"
					name:       "\(fullname)-controller"
				}
				updatePolicy: updateMode: c.autoscaling.vpa.updateMode
			}
		}
	}]

	// 6. controller-eligible/svc-external-access.yaml
	externalSvcs: [
		if k.kraft.enabled && k.externalAccess.enabled && (k.externalAccess.controller.forceExpose || !c.controllerOnly) {
			for i in list.Range(0, c.replicaCount, 1) {
				let targetPod = "\(fullname)-controller-\(i)"
				corev1.#Service & {
					apiVersion: "v1"
					kind:       "Service"
					metadata: {
						name:      "\(fullname)-controller-\(i)-external"
						namespace: #config.metadata.namespace
						labels: {
							for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
							"app.kubernetes.io/name":      "kafka"
							"app.kubernetes.io/component": "kafka"
							"pod":                         targetPod
						}
						annotations: (#MergeAnnotations & {
							#global: globalAnn
							#local: {
								if k.externalAccess.controller.service.loadBalancerAnnotations != _|_ && len(k.externalAccess.controller.service.loadBalancerAnnotations) > i {
									k.externalAccess.controller.service.loadBalancerAnnotations[i]
								}
								if k.externalAccess.controller.service.annotations != _|_ {
									k.externalAccess.controller.service.annotations
								}
							}
						}).#result
					}
					spec: {
						type: k.externalAccess.controller.service.type
						if type == "LoadBalancer" {
							if k.externalAccess.controller.service.allocateLoadBalancerNodePorts != _|_ {
								allocateLoadBalancerNodePorts: k.externalAccess.controller.service.allocateLoadBalancerNodePorts
							}
							if k.externalAccess.controller.service.loadBalancerClass != _|_ && k.externalAccess.controller.service.loadBalancerClass != "" {
								loadBalancerClass: k.externalAccess.controller.service.loadBalancerClass
							}
							if k.externalAccess.controller.service.loadBalancerIPs != _|_ && len(k.externalAccess.controller.service.loadBalancerIPs) > i {
								loadBalancerIP: k.externalAccess.controller.service.loadBalancerIPs[i]
							}
							if k.externalAccess.controller.service.loadBalancerSourceRanges != _|_ {
								loadBalancerSourceRanges: k.externalAccess.controller.service.loadBalancerSourceRanges
							}
						}
						publishNotReadyAddresses: k.externalAccess.controller.service.publishNotReadyAddresses
						ports: [
							{
								name: "tcp-kafka"
								port: k.externalAccess.controller.service.ports.external
								if k.externalAccess.controller.service.nodePorts != _|_ && len(k.externalAccess.controller.service.nodePorts) > i {
									nodePort: k.externalAccess.controller.service.nodePorts[i]
								}
								targetPort: "external"
							},
						]
						if type == "NodePort" && k.externalAccess.controller.service.externalIPs != _|_ && len(k.externalAccess.controller.service.externalIPs) > i {
							externalIPs: [k.externalAccess.controller.service.externalIPs[i]]
						}
						selector: {
							for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
							"app.kubernetes.io/part-of":          "kafka"
							"app.kubernetes.io/component":        "controller-eligible"
							"statefulset.kubernetes.io/pod-name": targetPod
						}
					}
				}
			}
		},
	]

	// 7. controller-eligible/svc-headless.yaml
	headlessSvc: [if k.kraft.enabled && c.replicaCount > 0 {
		corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(fullname)-controller-headless"
				namespace: #config.metadata.namespace
				labels: {
					for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "controller-eligible"
					"app.kubernetes.io/part-of":   "kafka"
				}
				annotations: (#MergeAnnotations & {#global: globalAnn, #local: k.commonAnnotations}).#result
			}
			spec: {
				type:                     "ClusterIP"
				clusterIP:                "None"
				publishNotReadyAddresses: true
				ports: [
					if !c.controllerOnly {
						{
							name:       "tcp-interbroker"
							port:       k.service.ports.interbroker
							protocol:   "TCP"
							targetPort: "interbroker"
						}
					},
					if !c.controllerOnly {
						{
							name:       "tcp-client"
							port:       k.service.ports.client
							protocol:   "TCP"
							targetPort: "client"
						}
					},
					{
						name:       "tcp-controller"
						port:       k.service.ports.controller
						protocol:   "TCP"
						targetPort: "controller"
					},
				]
				selector: {
					for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "controller-eligible"
					"app.kubernetes.io/part-of":   "kafka"
				}
			}
		}
	}]

	// 8. controller-eligible/statefulset.yaml
	statefulSet: [if k.kraft.enabled && (c.replicaCount > 0 || c.autoscaling.enabled) {
		appsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:      "\(fullname)-controller"
				namespace: #config.metadata.namespace
				labels: {
					for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "controller-eligible"
					"app.kubernetes.io/part-of":   "kafka"
				}
				annotations: (#MergeAnnotations & {#global: globalAnn, #local: c.annotations}).#result
			}
			spec: {
				podManagementPolicy: c.podManagementPolicy
				if !c.autoscaling.enabled {
					replicas: c.replicaCount
				}
				selector: matchLabels: {
					for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
					"app.kubernetes.io/name":      "kafka"
					"app.kubernetes.io/component": "controller-eligible"
					"app.kubernetes.io/part-of":   "kafka"
				}
				serviceName:    "\(fullname)-controller-headless"
				updateStrategy: c.updateStrategy
				template: {
					metadata: {
						labels: {
							for lab, v in #config.metadata.labels if lab != "app.kubernetes.io/name" {"\(lab)": v}
							"app.kubernetes.io/name":      "kafka"
							"app.kubernetes.io/component": "controller-eligible"
							"app.kubernetes.io/part-of":   "kafka"
						}
						annotations: {
							"checksum/configuration": "config-checksum-\(k.kraft.clusterId)"
							if k.saslEnabled {
								"checksum/passwords-secret": "static-sasl-checksum"
							}
							for ka, va in c.podAnnotations {"\(ka)": va}
						}
					}
					spec: {
						if k.imagePullSecrets != _|_ {
							imagePullSecrets: k.imagePullSecrets
						}
						automountServiceAccountToken: c.automountServiceAccountToken
						hostNetwork:                  c.hostNetwork
						hostIPC:                      c.hostIPC
						if c.schedulerName != "" {
							schedulerName: c.schedulerName
						}
						if c.affinity != _|_ {
							affinity: c.affinity
						}
						if c.nodeSelector != _|_ {
							nodeSelector: c.nodeSelector
						}
						if c.tolerations != _|_ {
							tolerations: c.tolerations
						}
						if c.topologySpreadConstraints != _|_ {
							topologySpreadConstraints: c.topologySpreadConstraints
						}
						terminationGracePeriodSeconds: c.terminationGracePeriodSeconds
						if c.priorityClassName != "" {
							priorityClassName: c.priorityClassName
						}
						if c.podSecurityContext.enabled {
							securityContext: {
								for sk, sv in c.podSecurityContext if sk != "enabled" {"\(sk)": sv}
							}
						}
						serviceAccountName: *fullname | string
						if k.serviceAccount.name != "" {
							serviceAccountName: k.serviceAccount.name
						}
						initContainers: [
							if c.persistence.enabled && k.volumePermissions.enabled {
								{
									name:  "volume-permissions"
									image: "\(k.volumePermissions.image.registry)/\(k.volumePermissions.image.repository):\(k.volumePermissions.image.tag)"
									command: ["/bin/bash", "-ec"]
									args: ["""
										mkdir -p "\(c.persistence.mountPath)" "\(c.logPersistence.mountPath)"
										chown -R \(c.containerSecurityContext.runAsUser):\(c.podSecurityContext.fsGroup) "\(c.persistence.mountPath)" "\(c.logPersistence.mountPath)"
										find "\(c.persistence.mountPath)" -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" | xargs -r chown -R \(c.containerSecurityContext.runAsUser):\(c.podSecurityContext.fsGroup)
										find "\(c.logPersistence.mountPath)" -mindepth 1 -maxdepth 1 -not -name ".snapshot" -not -name "lost+found" | xargs -r chown -R \(c.containerSecurityContext.runAsUser):\(c.podSecurityContext.fsGroup)
										"""]
									securityContext: {
										for sk, sv in k.volumePermissions.containerSecurityContext if sk != "enabled" {"\(sk)": sv}
									}
									if k.volumePermissions.resources != _|_ {
										resources: k.volumePermissions.resources
									}
									volumeMounts: [
										{name: "data", mountPath: c.persistence.mountPath},
										{name: "logs", mountPath: c.logPersistence.mountPath},
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
									{name: "KAFKA_VOLUME_DIR", value: c.persistence.mountPath},
									{name: "KAFKA_MIN_ID", value: "0"},
									if k.externalAccess.enabled {
										{name: "EXTERNAL_ACCESS_ENABLED", value: "true"}
									},
									if k.saslEnabled {
										{
											name:  "KAFKA_CONTROLLER_USER"
											value: k.sasl.controller.user
										}
									},
									if k.saslEnabled {
										{
											name: "KAFKA_CONTROLLER_PASSWORD"
											valueFrom: secretKeyRef: {
												name: "\(fullname)-user-passwords"
												key:  "controller-password"
											}
										}
									},
									{name: "KRAFT_ENABLED", value: "true"},
								]
								volumeMounts: [
									{name: "data", mountPath: c.persistence.mountPath},
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
								if c.containerSecurityContext.enabled {
									securityContext: {
										for sk, sv in c.containerSecurityContext if sk != "enabled" {"\(sk)": sv}
									}
								}
								env: [
									{name: "BITNAMI_DEBUG", value: "false"},
									{name: "KAFKA_HEAP_OPTS", value: c.heapOpts},
									{
										name: "KAFKA_CFG_NODE_ID"
										valueFrom: fieldRef: fieldPath: "metadata.labels['apps.kubernetes.io/pod-index']"
									},
									{name: "KAFKA_CFG_PROCESS_ROLES", value: [if c.controllerOnly {"controller"}, "controller,broker"][0]},
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
									{name: "controller", containerPort: k.listeners.controller.containerPort},
									if !c.controllerOnly {
										{name: "client", containerPort: k.listeners.client.containerPort}
									},
									if !c.controllerOnly {
										{name: "interbroker", containerPort: k.listeners.interbroker.containerPort}
									},
									if !c.controllerOnly && k.externalAccess.enabled {
										{name: "external", containerPort: k.listeners.external.containerPort}
									},
								]
								livenessProbe: {
									exec: command: ["pgrep", "-f", "kafka"]
									initialDelaySeconds: c.livenessProbe.initialDelaySeconds
									periodSeconds:       c.livenessProbe.periodSeconds
									timeoutSeconds:      c.livenessProbe.timeoutSeconds
									successThreshold:    c.livenessProbe.successThreshold
									failureThreshold:    c.livenessProbe.failureThreshold
								}
								readinessProbe: {
									tcpSocket: port: "controller"
									initialDelaySeconds: c.readinessProbe.initialDelaySeconds
									periodSeconds:       c.readinessProbe.periodSeconds
									timeoutSeconds:      c.readinessProbe.timeoutSeconds
									successThreshold:    c.readinessProbe.successThreshold
									failureThreshold:    c.readinessProbe.failureThreshold
								}
								if c.resources != _|_ {
									resources: c.resources
								}
								volumeMounts: [
									{name: "data", mountPath: c.persistence.mountPath},
									{name: "logs", mountPath: c.logPersistence.mountPath},
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
								configMap: name: "\(fullname)-controller-configuration"
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
								configMap: {name: "\(fullname)-log4j"}
							},
							if !c.persistence.enabled {
								{name: "data", emptyDir: {}}
							},
							if !c.logPersistence.enabled {
								{name: "logs", emptyDir: {}}
							},
							if k.metrics.jmx.enabled {
								{
									name: "jmx-config"
									configMap: {name: "\(fullname)-jmx-configuration"}
								}
							},
						]
					}
				}
				if c.persistence.enabled {
					volumeClaimTemplates: [
						{
							metadata: name: "data"
							spec: {
								accessModes: c.persistence.accessModes
								resources: requests: storage: c.persistence.size
								if c.persistence.storageClass != "" {
									storageClassName: c.persistence.storageClass
								}
							}
						},
						if c.logPersistence.enabled {
							{
								metadata: name: "logs"
								spec: {
									accessModes: c.logPersistence.accessModes
									resources: requests: storage: c.logPersistence.size
									if c.logPersistence.storageClass != "" {
										storageClassName: c.logPersistence.storageClass
									}
								}
							}
						},
					]
				}
			}
		}
	}]
}
