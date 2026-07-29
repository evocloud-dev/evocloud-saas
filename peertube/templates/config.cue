// Reference: https://github.com/zendet/peertube-helm/blob/main/values.yaml
package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema for the Instance values.
#Config: {
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}
	moduleVersion!: string

	// Metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels:       timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// 1:1 values.yaml parity config mapping
	global: {
		image: {
			registry?:   null | string
			pullPolicy?: null | string
		}
		imagePullSecrets: [...corev1.#LocalObjectReference]
		nameOverride?:      null | string
		fullnameOverride?:  null | string
		namespaceOverride?: null | string
		extraEnvVars: [...corev1.#EnvVar]
		tolerations: [...corev1.#Toleration]
		nodeSelector: {[string]: string}
	}

	server: {
		enabled:  *true | bool
		replicas: *1 | int & >0

		imagePullSecrets: [...corev1.#LocalObjectReference]

		container: {
			image: {
				registry:    *"" | string
				repository:  *"" | string
				pullPolicy?: null | string
				tag:         *"" | string
			}
			resources?:       corev1.#ResourceRequirements
			securityContext?: corev1.#SecurityContext
			extraEnvVars: [...corev1.#EnvVar]
			extraArgs: {[string]: string}
		}

		extraContainers: [...corev1.#Container]
		annotations: {[string]: string}
		podAnnotations: {[string]: string}
		podLabels: {[string]: string}

		podSecurityContext?: corev1.#PodSecurityContext

		podDisruptionBudget: {
			enabled:                     *false | bool
			minAvailable?:               null | int | string
			maxUnavailable?:             null | int | string
			unhealthyPodEvictionPolicy?: null | string
		}

		tolerations: [...corev1.#Toleration]
		nodeSelector: {[string]: string}

		antiAffinity: {
			enabled: *true | bool
		}
		podAntiAffinity?: corev1.#PodAntiAffinity
		podAffinity?:     corev1.#PodAffinity
		nodeAffinity?:    corev1.#NodeAffinity

		grafana: {
			namespace?: null | string
			annotations: {[string]: string}
			labels: {[string]: string}
			grafanaDashboard: {
				enabled:                   *false | bool
				folder:                    *"peertube" | string
				allowCrossNamespaceImport: *true | bool
				matchLabels: {[string]: string}
			}
			dashboards: {
				metrics: {
					createConfigMap: *false | bool
					configMapName:   *"" | string
				}
			}
		}

		containerPort: *9000 | int & >0 & <=65535
		metricsPort:   *9091 | int & >0 & <=65535
		rtmpPort:      *1935 | int & >0 & <=65535
		rtmpsPort:     *1936 | int & >0 & <=65535

		config: {
			createConfigMap: *true | bool
			configMapName?:  null | string
			configMapAnnotations: {[string]: string}
			admin: {
				password:       *"" | string
				existingSecret: *"" | string
			}
			secrets: {
				peertube:       *"" | string
				existingSecret: *"" | string
			}
			raw: string
		}

		objectStorage: {
			enabled: *false | bool
			config?: null | {[string]: _}
			existingSecret: *"" | string
		}

		externalPostgres: {
			hostname:       *"" | string
			port:           *5432 | int
			ssl:            *null | bool
			suffix:         *"" | string
			db:             *"" | string
			username:       *"" | string
			password:       *"" | string
			existingSecret: *"" | string
			pool: {
				max: *5 | int
			}
		}

		externalRedis: {
			hostname:       *"" | string
			port:           *6379 | int
			db:             *null | int
			password:       *"" | string
			existingSecret: *"" | string
			sentinel: {
				enabled?:    bool
				enableTls?:  bool
				masterName?: string
				hostname?:   string
				port?:       int
			}
		}

		service: {
			type: *"ClusterIP" | string
			annotations: {[string]: string}
			nodePort?:            null | int
			port:                 *9000 | int
			appProtocol?:         string
			trafficDistribution?: null | string
		}

		metricsService: {
			create:    *false | bool
			port:      *9091 | int
			type:      *"ClusterIP" | string
			nodePort?: null | int
			annotations: {[string]: string}
			appProtocol?:         null | string
			trafficDistribution?: null | string
		}

		liveService: {
			create:         *false | bool
			portRtmp:       *1935 | int
			portRtmps:      *1936 | int
			type:           *"NodePort" | string
			nodePortRtmp?:  int
			nodePortRtmps?: int
			annotations: {[string]: string}
			appProtocol?:         string
			trafficDistribution?: null | string
		}

		serviceMonitor: {
			enabled: *false | bool
			additionalAnnotations: {[string]: string}
			additionalLabels: {[string]: string}
			namespace?:    null | string
			interval:      *"30s" | string
			scrapeTimeout: *"25s" | string
			secure:        *false | bool
			tlsConfig: {[string]: _}
			relabelings: [...]
			metricRelabelings: [...]
		}

		hostNetwork: *false | bool
		dnsPolicy?:  null | string
		dnsConfig?:  null | corev1.#PodDNSConfig

		persistence: {
			enabled: *true | bool
			annotations: {[string]: string}
			size:          *"200Gi" | string
			storageClass:  *"" | string
			volumeName:    *"" | string
			accessMode:    *"ReadWriteOnce" | string
			existingClaim: *"" | string
		}

		rbac: {
			create: *false | bool
		}

		serviceAccount: {
			create: *true | bool
			name:   *"" | string
			annotations: {[string]: string}
		}

		networkPolicy: {
			enabled: *false | bool
			ingress: [...]
			egress: [...]
		}

		topologySpreadConstraints: [...corev1.#TopologySpreadConstraint]

		deploymentStrategy?: {
			type?: string
			rollingUpdate?: {
				maxSurge?:       string | int
				maxUnavailable?: string | int
			}
		}

		updateStrategy?: {
			type?: string
			rollingUpdate?: {
				maxSurge?:       string | int
				maxUnavailable?: string | int
			}
		}

		autoscaling: {
			enabled:     *false | bool
			minReplicas: *1 | int
			maxReplicas: *10 | int
			metrics: {[string]: _}
			behavior: {[string]: _}
		}

		vpa: {
			enabled: *false | bool
			annotations: {[string]: string}
			updateMode: *"Initial" | string
			resourcePolicy: {[string]: _}
		}

		ingress: {
			enabled:          *false | bool
			ingressClassName: *"" | string
			annotations: {[string]: string}
			hosts: [...string]
			path:     *"/" | string
			pathType: *"Prefix" | string
			tls: *false | bool | [...]
			extraHosts: [...]
			extraPaths: [...]
			extraRules: [...]
			extraTls: [...]
		}

		httpRoute: {
			enabled: *false | bool
			annotations: {[string]: string}
			parentRefs: [...]
			hostnames: [...string]
			matches: [...]
			filters: [...]
			extraRules: [...]
		}

		tcpRoute: {
			enabled: *false | bool
			annotations: {[string]: string}
			rtmp: {
				enabled: *true | bool
				parentRefs: [...]
			}
			rtmps: {
				enabled: *true | bool
				parentRefs: [...]
			}
		}

		certificate: {
			enabled: *false | bool
			domain:  *"" | string
			additionalHosts: [...string]
			duration:    *"" | string
			renewBefore: *"" | string
			issuer: {
				group: *"" | string
				kind:  *"" | string
				name:  *"" | string
			}
			privateKey: {
				rotationPolicy: *"Never" | string
				encoding:       *"PKCS1" | string
				algorithm:      *"RSA" | string
				size:           *2048 | int
			}
			annotations: {[string]: string}
			usages: [...string]
			secretTemplateAnnotations: {[string]: string}
		}

		certificateSecret: {
			enabled: *false | bool
			annotations: {[string]: string}
			key: *"" | string
			crt: *"" | string
		}

		startupProbe?:   corev1.#Probe
		livenessProbe?:  corev1.#Probe
		readinessProbe?: corev1.#Probe

		revisionHistoryLimit: *10 | int
		priorityClassName:    *"" | string
	}

	runner: {
		enabled: *false | bool

		imagePullSecrets: [...corev1.#LocalObjectReference]

		persistence: {
			enabled: *true | bool
			annotations: {[string]: string}
			size:          *"20Gi" | string
			storageClass:  *"" | string
			volumeName:    *"" | string
			accessMode:    *"ReadWriteOnce" | string
			existingClaim: *"" | string
		}

		serviceAccount: {
			create: *true | bool
			name:   *"" | string
			annotations: {[string]: string}
		}

		networkPolicy: {
			enabled: *false | bool
			ingress: [...]
			egress: [...]
		}

		initContainer: {
			image: {
				registry:   *"docker.io" | string
				repository: *"zendet/peertube-runner" | string
				pullPolicy: *"IfNotPresent" | string
				tag:        *"0.4.0-ctranslate2" | string
			}
			resources?: corev1.#ResourceRequirements
			extraEnvVars: [...corev1.#EnvVar]
		}

		container: {
			image: {
				registry:   *"docker.io" | string
				repository: *"zendet/peertube-runner" | string
				pullPolicy: *"IfNotPresent" | string
				tag:        *"0.4.0-ctranslate2" | string
			}
			resources?: corev1.#ResourceRequirements
			extraEnvVars: [...corev1.#EnvVar]
		}

		extraInitContainers: [...corev1.#Container]
		extraContainers: [...corev1.#Container]
		annotations: {[string]: string}
		podAnnotations: {[string]: string}
		podLabels: {[string]: string}

		podSecurityContext?: corev1.#PodSecurityContext

		hostNetwork: *false | bool
		dnsPolicy?:  null | string
		dnsConfig?:  null | corev1.#PodDNSConfig

		service: {
			annotations: {[string]: string}
		}

		kedaDefaults: {
			enabled:         *false | bool
			minReplicas:     *1 | int
			maxReplicas:     *20 | int
			cooldownPeriod:  *300 | int
			pollingInterval: *30 | int

			postgresql: {
				host:             *"" | string
				port:             *"" | string
				userName:         *"" | string
				dbName:           *"" | string
				sslmode:          *"disable" | string
				targetQueryValue: *"1" | string
				existingSecret:   *"" | string
				passwordKey:      *"" | string
				query:            *"SELECT COALESCE(COUNT(*),0)::integer FROM \"runnerJob\" WHERE state IN (1, 5) AND \"type\" IN ('vod-web-video-transcoding', 'vod-hls-transcoding', 'vod-audio-merge-transcoding')" | string
			}
			advanced?: null | {[string]: _}
			cpu: {
				enabled:                         *false | bool
				targetCPUUtilizationPercentage?: int
			}
		}

		podDisruptionBudget: {
			enabled:                     *false | bool
			minAvailable?:               null | int | string
			maxUnavailable?:             null | int | string
			unhealthyPodEvictionPolicy?: null | string
		}

		tolerations: [...corev1.#Toleration]
		nodeSelector: {[string]: string}

		antiAffinity: {
			enabled: *true | bool
		}
		podAntiAffinity?: corev1.#PodAntiAffinity
		podAffinity?:     corev1.#PodAffinity
		nodeAffinity?:    corev1.#NodeAffinity

		startupProbe?:   corev1.#Probe
		livenessProbe?:  corev1.#Probe
		readinessProbe?: corev1.#Probe

		vpa: {
			enabled:    *false | bool
			updateMode: *"Initial" | string
			resourcePolicy: {[string]: _}
		}

		runnerGroups: [...{
			name:     string
			id:       string
			replicas: *1 | int
			jobTypes: [...string]
			keda?: {
				enabled?:     bool
				maxReplicas?: int
			}
			config: {
				createConfigMap: *true | bool
				configMapName?:  null | string
				configMapAnnotations: {[string]: string}
				unregisterOnExit: *false | bool
				raw:              string
				existingSecret:   *"" | string
				registrationToken: *"peertubemockregistrationtoken" | string
			}
		}]
	}
	test: {
		enabled: *false | bool
	}

	postgresql: {
		enabled: *false | bool
		image: {
			registry:   *"docker.io" | string
			repository: *"postgres" | string
			tag:        *"16-alpine" | string
		}
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"100m" | timoniv1.#CPUQuantity
				memory: *"256Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"1" | timoniv1.#CPUQuantity
				memory: *"1Gi" | timoniv1.#MemoryQuantity
			}
		}
		persistence: {
			enabled:      *true | bool
			size:         *"10Gi" | string
			storageClass: *"" | string
			accessModes: *["ReadWriteOnce"] | [...string]
			existingClaim: *"" | string
		}
		service: {
			port: *5432 | int
		}
	}

	redis: {
		enabled: *false | bool
		image: {
			registry:   *"docker.io" | string
			repository: *"redis" | string
			tag:        *"7-alpine" | string
		}
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"100m" | timoniv1.#CPUQuantity
				memory: *"128Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"500m" | timoniv1.#CPUQuantity
				memory: *"512Mi" | timoniv1.#MemoryQuantity
			}
		}
		persistence: {
			enabled:      *true | bool
			size:         *"5Gi" | string
			storageClass: *"" | string
			accessModes: *["ReadWriteOnce"] | [...string]
			existingClaim: *"" | string
		}
		service: {
			port: *6379 | int
		}
	}
}

// Instance outputs Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.server.enabled {
			if config.server.config.admin.existingSecret == "" && config.server.config.admin.password != "" {
				"server-admin-secret": #ServerAdminSecret & {#config: config}
			}
			if config.redis.enabled || (config.server.externalRedis.existingSecret == "" && config.server.externalRedis.password != "") {
				"server-redis-secret": #ServerRedisSecret & {#config: config}
			}
			if config.postgresql.enabled || (config.server.externalPostgres.existingSecret == "" && config.server.externalPostgres.password != "") {
				"server-postgres-secret": #ServerPostgresSecret & {#config: config}
			}
			if config.server.config.secrets.existingSecret == "" && config.server.config.secrets.peertube != "" {
				"server-peertube-secret": #ServerPeertubeSecret & {#config: config}
			}
			if config.server.serviceAccount.create {
				"server-sa": #ServerServiceAccount & {#config: config}
			}
			if config.server.persistence.enabled && config.server.persistence.existingClaim == "" {
				"server-pvc": #ServerPVC & {#config: config}
			}
			"server-configmap": #ServerConfigMap & {#config: config}
			"server-deployment": #ServerDeployment & {#config: config}
			"server-svc": #ServerService & {#config: config}
			if config.server.metricsService.create {
				"server-metrics-svc": #ServerMetricsService & {#config: config}
			}
			if config.server.liveService.create {
				"server-live-svc": #ServerLiveService & {#config: config}
			}
			if config.server.ingress.enabled {
				"server-ingress": #ServerIngress & {#config: config}
			}
			if config.server.httpRoute.enabled {
				"server-httproute": #ServerHTTPRoute & {#config: config}
			}
			if config.server.tcpRoute.enabled {
				if config.server.tcpRoute.rtmp.enabled {
					"server-tcproute-rtmp": #ServerTCPRouteRtmp & {#config: config}
				}
				if config.server.tcpRoute.rtmps.enabled {
					"server-tcproute-rtmps": #ServerTCPRouteRtmps & {#config: config}
				}
			}
			if config.server.certificate.enabled {
				"server-certificate": #ServerCertificate & {#config: config}
			}
			if config.server.autoscaling.enabled {
				"server-hpa": #ServerHPA & {#config: config}
			}
			if config.server.vpa.enabled {
				"server-vpa": #ServerVPA & {#config: config}
			}
			if config.server.podDisruptionBudget.enabled {
				"server-pdb": #ServerPDB & {#config: config}
			}
			if config.server.networkPolicy.enabled {
				"server-networkpolicy": #ServerNetworkPolicy & {#config: config}
			}
			if config.server.serviceMonitor.enabled {
				"server-servicemonitor": #ServerServiceMonitor & {#config: config}
			}
			if config.server.grafana.dashboards.metrics.createConfigMap {
				"server-grafana-dashboard-configmap": #ServerGrafanaDashboardConfigMap & {#config: config}
			}
			if config.server.grafana.grafanaDashboard.enabled {
				"server-grafana-dashboard": #ServerGrafanaDashboard & {#config: config}
			}
		}

		if config.runner.enabled {
			if config.runner.serviceAccount.create {
				"runner-sa": #RunnerServiceAccount & {#config: config}
			}
			"runner-headless-svc": #RunnerHeadlessService & {#config: config}
			if config.runner.podDisruptionBudget.enabled {
				"runner-pdb": #RunnerPDB & {#config: config}
			}
			if config.runner.networkPolicy.enabled {
				"runner-networkpolicy": #RunnerNetworkPolicy & {#config: config}
			}
			if config.runner.vpa.enabled {
				"runner-vpa": #RunnerVPA & {#config: config}
			}
			#pgHost: {
				if config.postgresql.enabled && config.runner.kedaDefaults.postgresql.host == "" {
					"\(config.metadata.name)-postgresql"
				}
				if !(config.postgresql.enabled && config.runner.kedaDefaults.postgresql.host == "") {
					config.runner.kedaDefaults.postgresql.host
				}
			}
			#pgSecret: {
				if config.postgresql.enabled && config.runner.kedaDefaults.postgresql.existingSecret == "" {
					"\(config.metadata.name)-server-postgres"
				}
				if !(config.postgresql.enabled && config.runner.kedaDefaults.postgresql.existingSecret == "") {
					config.runner.kedaDefaults.postgresql.existingSecret
				}
			}
			if config.runner.kedaDefaults.enabled && #pgSecret != "" && #pgHost != "" {
				"runner-keda-pg-auth": #RunnerTriggerAuthentication & {#config: config}
			}
			for g in config.runner.runnerGroups {
				if g.config.createConfigMap {
					"runner-configmap-\(g.id)": #RunnerConfigMap & {#config: config, #group: g}
				}
				if g.config.existingSecret == "" {
					"runner-secret-\(g.id)": #RunnerSecret & {#config: config, #group: g}
				}
				"runner-statefulset-\(g.id)": #RunnerStatefulSet & {#config: config, #group: g}
				#kedaEnabled: *config.runner.kedaDefaults.enabled | bool
				if g.keda != _|_ && g.keda.enabled != _|_ {
					#kedaEnabled: g.keda.enabled
				}
				if #kedaEnabled {
					"runner-scaledobject-\(g.id)": #RunnerScaledObject & {#config: config, #group: g}
				}
			}
		}
		if config.postgresql.enabled {
			"postgresql-sts": #PostgresqlStatefulSet & {#config: config}
			"postgresql-svc": #PostgresqlService & {#config: config}
		}

		if config.redis.enabled {
			"redis-sts": #RedisStatefulSet & {#config: config}
			"redis-svc": #RedisService & {#config: config}
		}
	}

	tests: {[string]: _}
}
