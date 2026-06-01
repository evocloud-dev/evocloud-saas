package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	policyv1 "k8s.io/api/policy/v1"
)

// 1. /charts/clickhouse/charts/zookeeper/templates/configmap.yaml
#ZookeeperConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-zookeeper"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
	}
	data: {
		"zoo.cfg": ""
	}
}

// 2. /charts/clickhouse/charts/zookeeper/templates/extra-list.yaml
#ZookeeperExtraDeploy: {
	#config: #Config
	// Placeholder for extraDeploy list items
}

// 3. /charts/clickhouse/charts/zookeeper/templates/metrics-svc.yaml
#ZookeeperMetricsService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-zookeeper-metrics"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "metrics"
		}
	}
	spec: {
		type: corev1.#ServiceTypeClusterIP
		ports: [
			{
				name:       "http-metrics"
				port:       9141
				targetPort: "metrics"
			},
		]
		selector: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
	}
}

// 4. /charts/clickhouse/charts/zookeeper/templates/networkpolicy.yaml
#ZookeeperNetworkPolicy: {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(#config.metadata.name)-zookeeper"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		podSelector: matchLabels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
		policyTypes: ["Ingress", "Egress"]
		egress: [{}]
		ingress: [{}]
	}
}

// 5. /charts/clickhouse/charts/zookeeper/templates/pdb.yaml
#ZookeeperPodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: #Config

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      "\(#config.metadata.name)-zookeeper"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
	}
	spec: {
		maxUnavailable: 1
		selector: matchLabels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
	}
}

// 6. /charts/clickhouse/charts/zookeeper/templates/prometheusrule.yaml
#ZookeeperPrometheusRule: {
	#config: #Config

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "PrometheusRule"
	metadata: {
		name:      "\(#config.metadata.name)-zookeeper"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "metrics"
		}
	}
	spec: {
		groups: []
	}
}

// 7. /charts/clickhouse/charts/zookeeper/templates/scripts-configmap.yaml
#ZookeeperScriptsConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-zookeeper-scripts"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
	}
	data: {
		"init-certs.sh": """
			#!/bin/bash
			"""
		"setup.sh": """
			#!/bin/bash
			
			# Execute entrypoint as usual after obtaining ZOO_SERVER_ID
			# check ZOO_SERVER_ID in persistent volume via myid
			# if not present, set based on POD hostname
			if [[ -f "/bitnami/zookeeper/data/myid" ]]; then
			    export ZOO_SERVER_ID="$(cat /bitnami/zookeeper/data/myid)"
			else
			    HOSTNAME="$(hostname -s)"
			    if [[ $HOSTNAME =~ (.*)-([0-9]+)$ ]]; then
			        ORD=${BASH_REMATCH[2]}
			        export ZOO_SERVER_ID="$((ORD + 1 ))"
			    else
			        echo "Failed to get index from hostname $HOSTNAME"
			        exit 1
			    fi
			fi
			exec /opt/bitnami/scripts/zookeeper/entrypoint.sh /opt/bitnami/scripts/zookeeper/run.sh
			"""
	}
}

// 8. /charts/clickhouse/charts/zookeeper/templates/secrets.yaml
#ZookeeperSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-zookeeper-client-auth"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
	}
	type: "Opaque"
	data: {}
}

// 9. /charts/clickhouse/charts/zookeeper/templates/serviceaccount.yaml
#ZookeeperServiceAccount: corev1.#ServiceAccount & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      "\(#config.metadata.name)-zookeeper"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
			"role":                        "zookeeper"
		}
	}
	automountServiceAccountToken: false
}

// 10. /charts/clickhouse/charts/zookeeper/templates/servicemonitor.yaml
#ZookeeperServiceMonitor: {
	#config: #Config

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      "\(#config.metadata.name)-zookeeper"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "metrics"
		}
	}
	spec: {
		endpoints: [{
			port: "http-metrics"
			path: "/metrics"
		}]
		selector: matchLabels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
	}
}

// 11. /charts/clickhouse/charts/zookeeper/templates/statefulset.yaml
#ZookeeperStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	let app = #config."hyperswitch-app"
	let zk = app.clickhouse.zookeeper

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-zookeeper"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
			"role":                        "zookeeper"
		}
	}
	spec: {
		replicas:             zk.replicaCount
		revisionHistoryLimit: 10
		podManagementPolicy:  "Parallel"
		selector: matchLabels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
		serviceName: "\(#config.metadata.name)-zookeeper-headless"
		template: {
			metadata: {
				labels: #config.metadata.labels & {
					"app.kubernetes.io/component": "zookeeper"
					"role":                        "zookeeper"
				}
			}
			spec: {
				enableServiceLinks:           true
				automountServiceAccountToken: false
				securityContext: {
					fsGroup:   1001
					runAsUser: 1001
				}
				containers: [{
					name:            "zookeeper"
					image:           "\(zk.image.registry)/\(zk.image.repository):\(zk.image.tag)"
					imagePullPolicy: corev1.#PullPolicy & zk.image.pullPolicy
					securityContext: {
						runAsUser:                1001
						runAsNonRoot:             true
						readOnlyRootFilesystem:   false
						allowPrivilegeEscalation: false
					}
					command: ["/scripts/setup.sh"]
					env: [
						{
							name:  "BITNAMI_DEBUG"
							value: "false"
						},
						{
							name:  "ZOO_PORT_NUMBER"
							value: "\(zk.containerPorts.client)"
						},
						{
							name:  "ZOO_TICK_TIME"
							value: "\(zk.tickTime)"
						},
						{
							name:  "ZOO_LOG_LEVEL"
							value: zk.logLevel
						},
						if zk.replicaCount > 1 {
							{
								name:  "ZOO_SERVERS"
								value: "\( #config.metadata.name )-zookeeper-0.\( #config.metadata.name )-zookeeper-headless.\(#config.metadata.namespace).svc.cluster.local:\(zk.containerPorts.follower):\(zk.containerPorts.election)::1"
							}
						},
						{
							name:  "ALLOW_ANONYMOUS_LOGIN"
							value: "yes"
						},
						{
							name:  "ZOO_4LW_COMMANDS_WHITELIST"
							value: "srvr,mntr,ruok"
						},
						{
							name:  "ZOO_DATA_DIR"
							value: "/bitnami/zookeeper/data"
						},
						{
							name:  "ZOO_DATA_LOG_DIR"
							value: "/bitnami/zookeeper/data/log"
						},
						{
							name:  "ZOO_LOG_DIR"
							value: "/opt/bitnami/zookeeper/logs"
						},
						{
							name: "POD_NAME"
							valueFrom: fieldRef: fieldPath: "metadata.name"
						},
					]
					ports: [
						{
							name:          "client"
							containerPort: zk.containerPorts.client
						},
						{
							name:          "follower"
							containerPort: zk.containerPorts.follower
						},
						{
							name:          "election"
							containerPort: zk.containerPorts.election
						},
						{
							name:          "http-admin"
							containerPort: 8080
						},
					]
					livenessProbe: {
						exec: command: [
							"/bin/bash",
							"-ec",
							"ZOO_HC_TIMEOUT=10 /opt/bitnami/scripts/zookeeper/healthcheck.sh",
						]
						initialDelaySeconds: 60
						periodSeconds:       20
						timeoutSeconds:      10
						successThreshold:    1
						failureThreshold:    6
					}
					readinessProbe: {
						exec: command: [
							"/bin/bash",
							"-ec",
							"ZOO_HC_TIMEOUT=5 /opt/bitnami/scripts/zookeeper/healthcheck.sh",
						]
						initialDelaySeconds: 15
						periodSeconds:       10
						timeoutSeconds:      5
						successThreshold:    1
						failureThreshold:    6
					}
					volumeMounts: [
						{
							name:      "empty-dir"
							mountPath: "/tmp"
							subPath:   "tmp-dir"
						},
						{
							name:      "scripts"
							mountPath: "/scripts/setup.sh"
							subPath:   "setup.sh"
						},
						{
							name:      "data"
							mountPath: "/bitnami/zookeeper"
						},
					]
				}]
				volumes: [
					{
						name: "empty-dir"
						emptyDir: {}
					},
					{
						name: "scripts"
						configMap: {
							name:        "\(#config.metadata.name)-zookeeper-scripts"
							defaultMode: 493
						}
					},
					if !zk.persistence.enabled {
						{
							name: "data"
							emptyDir: {}
						}
					},
				]
			}
		}
		if zk.persistence.enabled {
			volumeClaimTemplates: [{
				metadata: name: "data"
				spec: {
					accessModes: zk.persistence.accessModes
					resources: requests: storage: zk.persistence.size
					if zk.persistence.storageClass != _|_ {
						storageClassName: zk.persistence.storageClass
					}
				}
			}]
		}
	}
}

// 12. /charts/clickhouse/charts/zookeeper/templates/svc-headless.yaml
#ZookeeperHeadlessService: corev1.#Service & {
	#config: #Config
	let app = #config."hyperswitch-app"
	let zk = app.clickhouse.zookeeper

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-zookeeper-headless"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
	}
	spec: {
		type:      corev1.#ServiceTypeClusterIP
		clusterIP: "None"
		ports: [
			{
				name:       "client"
				port:       zk.containerPorts.client
				targetPort: "client"
			},
			{
				name:       "follower"
				port:       zk.containerPorts.follower
				targetPort: "follower"
			},
			{
				name:       "election"
				port:       zk.containerPorts.election
				targetPort: "election"
			},
		]
		selector: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
	}
}

// 13. /charts/clickhouse/charts/zookeeper/templates/svc.yaml
#ZookeeperService: corev1.#Service & {
	#config: #Config
	let app = #config."hyperswitch-app"
	let zk = app.clickhouse.zookeeper

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-zookeeper"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
	}
	spec: {
		type: corev1.#ServiceTypeClusterIP
		ports: [
			{
				name:       "client"
				port:       zk.containerPorts.client
				targetPort: "client"
			},
			{
				name:       "follower"
				port:       zk.containerPorts.follower
				targetPort: "follower"
			},
			{
				name:       "election"
				port:       zk.containerPorts.election
				targetPort: "election"
			},
		]
		selector: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
	}
}

// 14. /charts/clickhouse/charts/zookeeper/templates/tls-secrets.yaml
#ZookeeperTlsSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-zookeeper-client-crt"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "zookeeper"
		}
	}
	type: "kubernetes.io/tls"
	data: {}
}
