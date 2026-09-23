// SPDX-License-Identifier: Apache-2.0

package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for BentoPDF values, mirroring values.yaml and values.schema.json.
#Config: {
	// The kubeVersion is set at apply-time by querying the Kubernetes API.
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.30.0"}

	// The moduleVersion is set from the user-supplied module version.
	moduleVersion!: string

	// Common metadata
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: {
		"app.kubernetes.io/part-of": "helmforge"
		for k, v in commonLabels {
			"\(k)": v
		}
	}
	metadata: annotations?: timoniv1.#Annotations

	// Immutable selector labels
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// -- Override the short chart resource name.
	nameOverride?: string

	// -- Override the full release resource name.
	fullnameOverride?: string

	// -- Extra resource labels; selector labels are reserved.
	commonLabels: *{} | timoniv1.#Labels

	// -- Stateless replicas; PDF processing occurs in the browser.
	replicaCount: *1 | int & >=1

	// -- Image.
	image!: timoniv1.#Image

	// -- Registry credentials for a private mirror.
	imagePullSecrets: *[] | [...corev1.#LocalObjectReference]

	// -- NGINX listener; deploy the official image at the domain root.
	server: {
		// -- Service HTTP port.
		port: *8080 | int & >=1024 & <=65535
		// -- Enable the NGINX IPv6 listener; Service IP families are configured separately.
		ipv6: *true | bool
	}

	// -- Public runtime tool controls; these are not an authorization boundary.
	config: {
		// -- Disabled Tools.
		disabledTools: *[] | [...string & =~"^[a-z0-9-]+$"]
		// -- Native editor category IDs, for example annotation-shape or redaction.
		editorDisabledCategories: *[] | [...string & =~"^[a-z0-9-]+$"]
	}

	// -- Service Account.
	serviceAccount: {
		// -- Create a dedicated ServiceAccount with no API permissions.
		create: *true | bool
		// -- Existing or overridden ServiceAccount name.
		name: *"" | string
		// -- ServiceAccount annotations.
		annotations: *{} | timoniv1.#Annotations
		// -- Automount Service Account Token.
		automountServiceAccountToken: *false | bool
	}

	// -- Service.
	service: {
		// -- Kubernetes Service type.
		type: *"ClusterIP" | "NodePort" | "LoadBalancer"
		// -- Service HTTP port.
		port: *8080 | int & >=1 & <=65535
		// -- Service annotations.
		annotations: *{} | timoniv1.#Annotations
		// -- Service IP family policy; empty uses cluster default.
		ipFamilyPolicy: *"" | "SingleStack" | "PreferDualStack" | "RequireDualStack"
		// -- Requested address families; RequireDualStack needs a dual-stack cluster.
		ipFamilies: *[] | [...("IPv4" | "IPv6")]
	}

	// -- Gateway.
	gatewayAPI: {
		// -- Render canonical Gateway API HTTPRoutes.
		enabled: *false | bool
		// -- Route definitions with parentRefs, hostnames, rules, labels and annotations.
		httpRoutes: *[] | [...#HTTPRouteConfig]
	}


	// -- Probes.
	probes: {
		// -- Startup.
		startup: #ProbeConfig & {
			enabled:          *true | bool
			path:             *"/" | string
			periodSeconds:    *5 | int
			timeoutSeconds:   *2 | int
			failureThreshold: *30 | int
		}
		// -- Liveness.
		liveness: #ProbeConfig & {
			enabled:          *true | bool
			path:             *"/" | string
			periodSeconds:    *20 | int
			timeoutSeconds:   *3 | int
			failureThreshold: *3 | int
		}
		// -- Readiness checks the initialized HTTP server.
		readiness: #ProbeConfig & {
			enabled:          *true | bool
			path:             *"/" | string
			periodSeconds:    *10 | int
			timeoutSeconds:   *3 | int
			failureThreshold: *3 | int
		}
	}

	// -- Resources.
	resources: corev1.#ResourceRequirements & {
		// -- Requests.
		requests: {
			// -- Cpu.
			cpu: *"50m" | timoniv1.#CPUQuantity
			// -- Memory.
			memory: *"64Mi" | timoniv1.#MemoryQuantity
		}
		// -- Limits.
		limits: {
			// -- Cpu.
			cpu: *"500m" | timoniv1.#CPUQuantity
			// -- Memory.
			memory: *"256Mi" | timoniv1.#MemoryQuantity
		}
	}

	// -- Non-root pod identity with RuntimeDefault seccomp.
	podSecurityContext: corev1.#PodSecurityContext & {
		// -- Run As Non Root.
		runAsNonRoot: *true | bool
		// -- Run As User.
		runAsUser: *101 | int
		// -- Run As Group.
		runAsGroup: *101 | int
		// -- Fs Group.
		fsGroup: *101 | int
		// -- Seccomp Profile.
		seccompProfile: {
			// -- Type.
			type: *"RuntimeDefault" | string
		}
	}

	// -- Restricted container privileges; all configuration and assets are read-only.
	securityContext: corev1.#SecurityContext & {
		// -- Allow Privilege Escalation.
		allowPrivilegeEscalation: *false | bool
		// -- Read Only Root Filesystem.
		readOnlyRootFilesystem: *true | bool
		// -- Capabilities.
		capabilities: {
			// -- Drop.
			drop: *["ALL"] | [...string]
		}
	}

	// -- Pod Disruption Budget.
	podDisruptionBudget: {
		// -- Protect voluntary disruptions. Requires at least two replicas; no singleton eviction deadlock.
		enabled: *false | bool
		// -- Maximum unavailable pods during voluntary disruption.
		maxUnavailable: *1 | int & >=1
	}

	// -- Pod labels; immutable selector labels cannot be overridden.
	podLabels: *{} | timoniv1.#Labels

	// -- Pod annotations, e.g. for an external Secret reloader.
	podAnnotations: *{} | timoniv1.#Annotations

	// -- Node selection constraints.
	nodeSelector: *{} | {[string]: string}

	// -- Scheduling tolerations.
	tolerations: *[] | [...corev1.#Toleration]

	// -- Pod affinity or anti-affinity.
	affinity: *{} | corev1.#Affinity

	// -- Topology spreading across nodes or zones.
	topologySpreadConstraints: *[] | [...corev1.#TopologySpreadConstraint]

	// -- Scheduling priority class.
	priorityClassName: *"" | string

	// -- Grace period for HTTP shutdown.
	terminationGracePeriodSeconds: *30 | int & >=0

	// -- CPU scaling applies to static file serving, not browser PDF processing.
	autoscaling: {
		// -- Create a HorizontalPodAutoscaler for static file serving.
		enabled: *false | bool
		// -- Minimum stateless replicas; use at least two with a disruption budget.
		minReplicas: *2 | int & >=1
		// -- Maximum replicas allowed by the HPA.
		maxReplicas: *5 | int & >=1
		// -- Target utilization of the bentopdf container CPU request, excluding exporter CPU.
		targetCPUUtilizationPercentage: *70 | int & >=1 & <=100
	}

	// -- Optional official NGINX exporter; measures serving traffic, not PDF content or operations.
	metrics: {
		// -- Run the NGINX Prometheus exporter and expose its private metrics Service.
		enabled: *false | bool
		// -- Image.
		image!: timoniv1.#Image
		// -- Service HTTP port.
		port: *9113 | int & >=1024 & <=65535
		// -- Resources.
		resources: corev1.#ResourceRequirements & {
			// -- Requests.
			requests: {
				// -- Cpu.
				cpu: *"10m" | timoniv1.#CPUQuantity
				// -- Memory.
				memory: *"32Mi" | timoniv1.#MemoryQuantity
			}
			// -- Limits.
			limits: {
				// -- Cpu.
				cpu: *"100m" | timoniv1.#CPUQuantity
				// -- Memory.
				memory: *"64Mi" | timoniv1.#MemoryQuantity
			}
		}
		// -- Service Monitor.
		serviceMonitor: {
			// -- Enabled.
			enabled: *false | bool
			// -- Labels.
			labels: *{} | timoniv1.#Labels
			// -- Prometheus scrape interval.
			interval: *"30s" | string & =~"^[0-9]+(ms|s|m|h)$"
			// -- Prometheus scrape timeout; keep no longer than interval.
			scrapeTimeout: *"10s" | string & =~"^[0-9]+(ms|s|m|h)$"
		}
		// -- Prometheus Rule.
		prometheusRule: {
			// -- Enabled.
			enabled: *false | bool
			// -- Labels.
			labels: *{} | timoniv1.#Labels
			// -- Additional native Prometheus alerting or recording rules.
			additionalRules: *[] | [...]
		}
		// -- Allowed ingress peers; empty allows pods in this namespace only.
		ingressFrom: *[] | [...]
	}


	// ==========================================
	// Validation rules mirroring _helpers.tpl
	// ==========================================

	// server.port 8081 is reserved for loopback stub_status
	server: port: !=8081

	// metrics.port 8081 is reserved for loopback stub_status
	metrics: port: !=8081

	// server.port and metrics.port must differ
	server: port: !=metrics.port


	// autoscaling.minReplicas cannot exceed maxReplicas
	// autoscaling requires resources.requests.cpu
	if autoscaling.enabled {
		autoscaling: minReplicas: <=autoscaling.maxReplicas
		resources: requests: cpu: string & !=""
	}

	// monitoring resources require metrics.enabled=true
	if metrics.serviceMonitor.enabled || metrics.prometheusRule.enabled {
		metrics: enabled: true
	}

	// podDisruptionBudget requires at least two replicas and maxUnavailable smaller than minimum replicas
	if podDisruptionBudget.enabled {
		if !autoscaling.enabled {
			replicaCount: >=2
			podDisruptionBudget: maxUnavailable: <replicaCount
		}
		if autoscaling.enabled {
			autoscaling: minReplicas: >=2
			podDisruptionBudget: maxUnavailable: <autoscaling.minReplicas
		}
	}
}

#ProbeConfig: {
	// -- Enabled.
	enabled: bool
	// -- Path.
	path: string & =~"^/"
	// -- Period Seconds.
	periodSeconds: int & >=1
	// -- Timeout Seconds.
	timeoutSeconds: int & >=1
	// -- Failure Threshold.
	failureThreshold: int & >=1
}

#IngressPath: {
	path:     string & =~"^/"
	pathType: "Prefix" | "Exact" | "ImplementationSpecific"
}

#IngressHost: {
	host:  string & !=""
	paths: [...#IngressPath] & [_, ...]
}

#IngressTLS: {
	hosts: [...string]
	secretName: string & !=""
}

#HTTPRouteParentRef: {
	name:         string & !=""
	namespace?:   string
	group?:       string
	kind?:        string
	sectionName?: string
	port?:        int & >=1 & <=65535
}

#HTTPRouteBackendRef: {
	name:       string & !=""
	namespace?: string
	group?:     string
	kind?:      string
	port?:      int & >=1 & <=65535
	weight?:    int & >=0
	filters?:   [...]
}

#HTTPRouteMatch: {
	path?: {
		type?:  "Exact" | "PathPrefix" | "RegularExpression"
		value?: string
	}
	headers?:     [...]
	queryParams?: [...]
	method?:      string
}

#HTTPRouteRule: {
	matches?:            [...#HTTPRouteMatch]
	filters?:            [...]
	backendRefs?:        [...#HTTPRouteBackendRef]
	omitDefaultBackend?: bool
}

#HTTPRouteConfig: {
	name?:        string
	labels?:      timoniv1.#Labels
	annotations?: timoniv1.#Annotations
	parentRefs!:  [...#HTTPRouteParentRef] & [_, ...]
	hostnames?:   [...string]
	rules?:       [...#HTTPRouteRule]
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		// ServiceAccount (serviceaccount.yaml)
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}

		// ConfigMap (configmap.yaml)
		cm: #ConfigMap & {#config: config}

		// Deployment (deployment.yaml)
		deploy: #Deployment & {#config: config}

		// Service (service.yaml)
		svc: #Service & {#config: config}

		// Metrics Service (metrics.yaml)
		if config.metrics.enabled {
			svcMetrics: #MetricsService & {#config: config}
		}

		// Gateway API HTTPRoutes (gateway-httproute.yaml)
		if config.gatewayAPI.enabled {
			for idx, r in config.gatewayAPI.httpRoutes {
				"httproute-\(idx)": #HTTPRoute & {#config: config, #route: r, #index: idx}
			}
		}

		// HorizontalPodAutoscaler (hpa.yaml)
		if config.autoscaling.enabled {
			hpa: #HorizontalPodAutoscaler & {#config: config}
		}

		// PodDisruptionBudget (pdb.yaml)
		if config.podDisruptionBudget.enabled {
			pdb: #PodDisruptionBudget & {#config: config}
		}


		// ServiceMonitor (metrics.yaml)
		if config.metrics.enabled && config.metrics.serviceMonitor.enabled {
			sm: #ServiceMonitor & {#config: config}
		}

		// PrometheusRule (metrics.yaml)
		if config.metrics.enabled && config.metrics.prometheusRule.enabled {
			pr: #PrometheusRule & {#config: config}
		}
	}

}
