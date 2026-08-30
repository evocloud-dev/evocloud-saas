package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	autoscalingv2 "k8s.io/api/autoscaling/v2"
	"list"
)

#VectorHAProxyLabels: {
	#name:    string
	#version: string
	#podLabels: [string]: string
	result: {
		"app.kubernetes.io/name":       "vector"
		"app.kubernetes.io/instance":   #name
		"app.kubernetes.io/version":    #version
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/component":  "load-balancer"
		"helm.sh/chart":                "vector-0.34.1"
		for k, v in #podLabels {
			"\(k)": v
		}
	}
}

// 1. /charts/vector/templates/haproxy/configmap.yaml
#VectorHAProxyConfigMap: corev1.#ConfigMap & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let ns = #config.metadata.namespace
	let instanceName = #config.metadata.name

	let haproxyName = (#VectorHAProxyName & {#name: instanceName}).result
	let haproxyLabels = (#VectorHAProxyLabels & {
		#name:      instanceName
		#version:   vector.haproxy.image.tag
		#podLabels: vector.haproxy.podLabels
	}).result
	let vectorName = (#VectorName & {#name: instanceName}).result

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      haproxyName
		namespace: ns
		labels:    haproxyLabels
	}
	data: {
		if vector.haproxy.customConfig != "" {
			"haproxy.cfg": vector.haproxy.customConfig
		}
		if vector.haproxy.customConfig == "" {
			"haproxy.cfg": """
				global
				  log stdout format raw local0
				  maxconn 4096
				  stats socket /tmp/haproxy
				  hard-stop-after \(vector.haproxy.terminationGracePeriodSeconds)s

				defaults
				  log     global
				  option  dontlognull
				  retries 3
				  option  redispatch
				  option  allbackups
				  timeout client 5s
				  timeout server 5s
				  timeout connect 5s

				resolvers coredns
				  nameserver dns1 kube-dns.kube-system.svc.cluster.local:53
				  resolve_retries 3
				  timeout resolve 2s
				  timeout retry 1s
				  accepted_payload_size 8192
				  hold valid 10s
				  hold obsolete 60s

				frontend stats
				  mode http
				  bind :::1024
				  option httplog
				  http-request use-service prometheus-exporter if { path /metrics }

				frontend datadog-agent
				  mode http
				  bind :::8282
				  option httplog
				  default_backend datadog-agent

				frontend fluent
				  mode tcp
				  bind :::24224
				  option tcplog
				  default_backend fluent

				frontend logstash
				  mode tcp
				  bind :::5044
				  option tcplog
				  default_backend logstash

				frontend splunk-hec
				  mode http
				  bind :::8080
				  option httplog
				  default_backend splunk-hec

				frontend statsd
				  mode tcp
				  bind :::8125
				  option tcplog
				  default_backend statsd

				frontend syslog
				  mode tcp
				  bind :::9000
				  option tcplog
				  default_backend syslog

				frontend vector
				  mode http
				  bind :::6000 proto h2
				  option httplog
				  default_backend vector

				backend datadog-agent
				  mode http
				  balance roundrobin
				  option tcp-check
				  server-template srv 10 _datadog-agent._tcp.\(vectorName)-headless.\(ns).svc.cluster.local resolvers coredns check

				backend fluent
				  mode tcp
				  balance roundrobin
				  option tcp-check
				  server-template srv 10 _fluent._tcp.\(vectorName)-headless.\(ns).svc.cluster.local resolvers coredns check

				backend logstash
				  mode tcp
				  balance roundrobin
				  option tcp-check
				  server-template srv 10 _logstash._tcp.\(vectorName)-headless.\(ns).svc.cluster.local resolvers coredns check

				backend splunk-hec
				  mode http
				  balance roundrobin
				  option tcp-check
				  server-template srv 10 _splunk-hec._tcp.\(vectorName)-headless.\(ns).svc.cluster.local resolvers coredns check

				backend statsd
				  mode tcp
				  balance roundrobin
				  option tcp-check
				  server-template srv 10 _statsd._tcp.\(vectorName)-headless.\(ns).svc.cluster.local resolvers coredns check

				backend syslog
				  mode tcp
				  balance roundrobin
				  option tcp-check
				  server-template srv 10 _syslog._tcp.\(vectorName)-headless.\(ns).svc.cluster.local resolvers coredns check

				backend vector
				  mode http
				  balance roundrobin
				  option tcp-check
				  server-template srv 10 _vector._tcp.\(vectorName)-headless.\(ns).svc.cluster.local resolvers coredns proto h2 check
				"""
		}
	}
}

// 2. /charts/vector/templates/haproxy/deployment.yaml
#VectorHAProxyDeployment: appsv1.#Deployment & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let ns = #config.metadata.namespace
	let instanceName = #config.metadata.name

	let haproxyName = (#VectorHAProxyName & {#name: instanceName}).result
	let haproxyLabels = (#VectorHAProxyLabels & {
		#name:      instanceName
		#version:   vector.haproxy.image.tag
		#podLabels: vector.haproxy.podLabels
	}).result
	let saName = [if vector.haproxy.serviceAccount.name != "" {vector.haproxy.serviceAccount.name}, [if vector.haproxy.serviceAccount.create {haproxyName}, "default"][0]][0]

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      haproxyName
		namespace: ns
		labels:    haproxyLabels
	}
	spec: {
		if !vector.haproxy.autoscaling.enabled && !vector.haproxy.autoscaling.external {
			replicas: vector.haproxy.replicas
		}
		selector: matchLabels: {
			"app.kubernetes.io/name":      "vector"
			"app.kubernetes.io/instance":  instanceName
			"app.kubernetes.io/component": "load-balancer"
		}
		if len([for k, v in vector.haproxy.strategy {k}]) > 0 {
			strategy: vector.haproxy.strategy
		}
		template: {
			metadata: {
				annotations: {
					if vector.haproxy.rollWorkload {
						"checksum/config": "haproxy-config-checksum"
					}
					for k, v in vector.haproxy.podAnnotations {
						"\(k)": v
					}
				}
				labels: {
					"app.kubernetes.io/name":      "vector"
					"app.kubernetes.io/instance":  instanceName
					"app.kubernetes.io/component": "load-balancer"
					for k, v in vector.haproxy.podLabels {
						"\(k)": v
					}
				}
			}
			spec: corev1.#PodSpec & {
				if len(vector.haproxy.image.pullSecrets) > 0 {
					imagePullSecrets: [for s in vector.haproxy.image.pullSecrets {name: s}]
				}
				serviceAccountName: saName
				if len([for k, v in vector.haproxy.podSecurityContext {k}]) > 0 {
					securityContext: vector.haproxy.podSecurityContext
				}
				if vector.podPriorityClassName != "" {
					priorityClassName: vector.podPriorityClassName
				}
				if len(vector.haproxy.initContainers) > 0 {
					initContainers: vector.haproxy.initContainers
				}
				containers: [
					{
						name: "haproxy"
						if len([for k, v in vector.haproxy.securityContext {k}]) > 0 {
							securityContext: vector.haproxy.securityContext
						}
						image:           "\(vector.haproxy.image.repository):\(vector.haproxy.image.tag)"
						imagePullPolicy: vector.haproxy.image.pullPolicy
						args: [
							"-f",
							"/usr/local/etc/haproxy/haproxy.cfg",
						]
						ports: list.Concat([
							[for p in vector.haproxy.containerPorts {p}],
							if len(vector.haproxy.containerPorts) == 0 && vector.haproxy.existingConfigMap == "" && vector.haproxy.customConfig == "" {
								if vector.role == "Aggregator" || vector.role == "Stateless-Aggregator" {
									[
										{name: "datadog-agent", containerPort: 8282, protocol: "TCP"},
										{name: "fluent", containerPort: 24224, protocol: "TCP"},
										{name: "logstash", containerPort: 5044, protocol: "TCP"},
										{name: "splunk-hec", containerPort: 8080, protocol: "TCP"},
										{name: "statsd", containerPort: 8125, protocol: "TCP"},
										{name: "syslog", containerPort: 9000, protocol: "TCP"},
										{name: "vector", containerPort: 6000, protocol: "TCP"},
										{name: "prom-exporter", containerPort: 9090, protocol: "TCP"},
									]
								}
								if vector.role == "Agent" {
									[
										{name: "prom-exporter", containerPort: 9090, protocol: "TCP"},
									]
								}
								if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
									[]
								}
							},
							if !(len(vector.haproxy.containerPorts) == 0 && vector.haproxy.existingConfigMap == "" && vector.haproxy.customConfig == "") {
								[]
							},
							if vector.haproxy.customConfig == "" {
								[
									{name: "stats", containerPort: 1024, protocol: "TCP"},
								]
							},
							if vector.haproxy.customConfig != "" {
								[]
							},
						])
						if len([for k, v in vector.haproxy.livenessProbe {k}]) > 0 {
							livenessProbe: vector.haproxy.livenessProbe
						}
						if len([for k, v in vector.haproxy.readinessProbe {k}]) > 0 {
							readinessProbe: vector.haproxy.readinessProbe
						}
						if len([for k, v in vector.haproxy.resources {k}]) > 0 {
							resources: vector.haproxy.resources
						}
						volumeMounts: list.Concat([
							[
								{
									name:      "haproxy-config"
									mountPath: "/usr/local/etc/haproxy"
								},
							],
							vector.haproxy.extraVolumeMounts,
						])
					},
				]
				if len(vector.haproxy.extraContainers) > 0 {
					containers: list.Concat([containers, vector.haproxy.extraContainers])
				}
				volumes: list.Concat([
					[
						{
							name: "haproxy-config"
							configMap: name: [if vector.haproxy.existingConfigMap != "" {vector.haproxy.existingConfigMap}, haproxyName][0]
						},
					],
					vector.haproxy.extraVolumes,
				])
				if len([for k, v in vector.haproxy.nodeSelector {k}]) > 0 {
					nodeSelector: vector.haproxy.nodeSelector
				}
				if len([for k, v in vector.haproxy.affinity {k}]) > 0 {
					affinity: vector.haproxy.affinity
				}
				if len(vector.haproxy.tolerations) > 0 {
					tolerations: vector.haproxy.tolerations
				}
			}
		}
	}
}

// 3. /charts/vector/templates/haproxy/hpa.yaml
#VectorHAProxyHPA: autoscalingv2.#HorizontalPodAutoscaler & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let ns = #config.metadata.namespace
	let instanceName = #config.metadata.name

	let haproxyName = (#VectorHAProxyName & {#name: instanceName}).result
	let haproxyLabels = (#VectorHAProxyLabels & {
		#name:      instanceName
		#version:   vector.haproxy.image.tag
		#podLabels: vector.haproxy.podLabels
	}).result

	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata: {
		name:      haproxyName
		namespace: ns
		labels:    haproxyLabels
	}
	spec: {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       haproxyName
		}
		minReplicas: vector.haproxy.autoscaling.minReplicas
		maxReplicas: vector.haproxy.autoscaling.maxReplicas
		metrics: [
			if vector.haproxy.autoscaling.targetCPUUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "cpu"
						target: {
							type:               "Utilization"
							averageUtilization: vector.haproxy.autoscaling.targetCPUUtilizationPercentage
						}
					}
				}
			},
			if vector.haproxy.autoscaling.targetMemoryUtilizationPercentage != _|_ {
				{
					type: "Resource"
					resource: {
						name: "memory"
						target: {
							type:               "Utilization"
							averageUtilization: vector.haproxy.autoscaling.targetMemoryUtilizationPercentage
						}
					}
				}
			},
			if len([for k, v in vector.haproxy.autoscaling.customMetric {k}]) > 0 {
				vector.haproxy.autoscaling.customMetric
			},
		]
	}
}

// 4. /charts/vector/templates/haproxy/service.yaml
#VectorHAProxyService: corev1.#Service & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let ns = #config.metadata.namespace
	let instanceName = #config.metadata.name

	let haproxyName = (#VectorHAProxyName & {#name: instanceName}).result
	let haproxyLabels = (#VectorHAProxyLabels & {
		#name:      instanceName
		#version:   vector.haproxy.image.tag
		#podLabels: vector.haproxy.podLabels
	}).result

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      haproxyName
		namespace: ns
		labels:    haproxyLabels
		if len(vector.haproxy.service.annotations) > 0 {
			annotations: vector.haproxy.service.annotations
		}
	}
	spec: {
		if vector.haproxy.service.externalTrafficPolicy != "" {
			externalTrafficPolicy: vector.haproxy.service.externalTrafficPolicy
		}
		if vector.haproxy.service.loadBalancerIP != "" {
			loadBalancerIP: vector.haproxy.service.loadBalancerIP
		}
		if vector.haproxy.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: vector.haproxy.service.ipFamilyPolicy
		}
		if len(vector.haproxy.service.ipFamilies) > 0 {
			ipFamilies: vector.haproxy.service.ipFamilies
		}
		ports: list.Concat([
			[for p in vector.haproxy.service.ports {p}],
			if len(vector.haproxy.service.ports) == 0 && vector.haproxy.existingConfigMap == "" && vector.haproxy.customConfig == "" {
				if vector.role == "Aggregator" || vector.role == "Stateless-Aggregator" {
					[
						{name: "datadog-agent", port: 8282, protocol: "TCP"},
						{name: "fluent", port: 24224, protocol: "TCP"},
						{name: "logstash", port: 5044, protocol: "TCP"},
						{name: "splunk-hec", port: 8080, protocol: "TCP"},
						{name: "statsd", port: 8125, protocol: "TCP"},
						{name: "syslog", port: 9000, protocol: "TCP"},
						{name: "vector", port: 6000, protocol: "TCP"},
						{name: "prom-exporter", port: 9090, protocol: "TCP"},
					]
				}
				if vector.role == "Agent" {
					[
						{name: "prom-exporter", port: 9090, protocol: "TCP"},
					]
				}
				if vector.role != "Agent" && vector.role != "Aggregator" && vector.role != "Stateless-Aggregator" {
					[]
				}
			},
			if !(len(vector.haproxy.service.ports) == 0 && vector.haproxy.existingConfigMap == "" && vector.haproxy.customConfig == "") {
				[]
			},
			if vector.haproxy.customConfig == "" {
				[
					{name: "stats", port: 1024, protocol: "TCP"},
				]
			},
			if vector.haproxy.customConfig != "" {
				[]
			},
		])
		selector: {
			"app.kubernetes.io/name":      "vector"
			"app.kubernetes.io/instance":  instanceName
			"app.kubernetes.io/component": "load-balancer"
		}
		type: vector.haproxy.service.type
		if len(vector.haproxy.service.topologyKeys) > 0 {
			topologyKeys: vector.haproxy.service.topologyKeys
		}
	}
}

// 5. /charts/vector/templates/haproxy/serviceaccount.yaml
#VectorHAProxyServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	let vector = #config."hyperswitch-app".vector
	let ns = #config.metadata.namespace
	let instanceName = #config.metadata.name

	let haproxyName = (#VectorHAProxyName & {#name: instanceName}).result
	let haproxyLabels = (#VectorHAProxyLabels & {
		#name:      instanceName
		#version:   vector.haproxy.image.tag
		#podLabels: vector.haproxy.podLabels
	}).result
	let saName = [if vector.haproxy.serviceAccount.name != "" {vector.haproxy.serviceAccount.name}, [if vector.haproxy.serviceAccount.create {haproxyName}, "default"][0]][0]

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      saName
		namespace: ns
		labels:    haproxyLabels
		if len(vector.haproxy.serviceAccount.annotations) > 0 {
			annotations: vector.haproxy.serviceAccount.annotations
		}
	}
	automountServiceAccountToken: vector.haproxy.serviceAccount.automountToken
}
