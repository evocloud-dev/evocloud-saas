package templates

import (
	"strings"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: string
	// Using the kubeVersion you can enforce a minimum Kubernetes minor version.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	// The moduleVersion is set from the user-supplied module version.
	// This field is used for the `app.kubernetes.io/version` label.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	// The `metadata.name` and `metadata.namespace` fields are
	// set from the user-supplied instance name and namespace.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// The labels allows adding `metadata.labels` to all resources.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	selector: timoniv1.#Selector & {
		#Name: metadata.name
		labels: {
			type: "main"
		}
	}

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	image!: timoniv1.#Image

	// Name overrides from upstream
	nameOverride?:     string
	fullnameOverride?: string

	// ServiceAccount settings from upstream
	serviceAccount: {
		create:       *false | bool
		name:         *"" | string
		annotations?: {[string]: string}
	}

	// DaemonSet ServiceAccount settings from upstream
	daemonSetServiceAccount: {
		create:       *false | bool
		name:         *"" | string
		annotations?: {[string]: string}
	}

	_serviceAccountName: [
		if serviceAccount.name != "" {serviceAccount.name},
		if serviceAccount.create {metadata.name},
		"default",
	][0]

	_daemonSetServiceAccountName: [
		if daemonSetServiceAccount.name != "" {daemonSetServiceAccount.name},
		if daemonSetServiceAccount.create {"\(metadata.name)-daemonset"},
		"default",
	][0]

	// Collabora-specific configuration options mirroring upstream.
	collabora: #CollaboraConfig

	// Container security context mirroring TrueCharts working configuration with Kubesec score 4 hardening.
	securityContext: corev1.#SecurityContext & {
		readOnlyRootFilesystem:   *false | bool
		privileged:               *false | bool
		capabilities: {
			drop: [
				*"ALL" | string
			]
		}
		runAsNonRoot:             *true | bool
		runAsUser:                *1001 | int
		allowPrivilegeEscalation: *false | bool
		seccompProfile: {
			type: *"RuntimeDefault" | string
		}
	}

	// Pod security context mirroring upstream recommendation.
	podSecurityContext: corev1.#PodSecurityContext & {
		fsGroup: *1001 | int
		fsGroupChangePolicy: *"OnRootMismatch" | string
		seccompProfile: {
			type: *"RuntimeDefault" | string
		}
	}

	// Service settings mirroring upstream service.yaml.
	service: {
		type:         *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
		port:         *9980 | int & >0 & <=65535
		annotations?: timoniv1.#Annotations
	}

	// The number of pod replicas (mirroring replicaCount from upstream).
	replicaCount: *1 | int & >0
	replicas:     *replicaCount | int & >0

	// The revision history limit for Deployment.
	revisionHistoryLimit: *3 | int & >=0

	// Strategy defines the deployment strategy.
	strategy: appsv1.#DeploymentStrategy & {
		type: *"RollingUpdate" | "Recreate"
	}

	// Deployment-level options from upstream
	deployment: {
		kind:            *"Deployment" | "StatefulSet"
		minReadySeconds: *0 | int
		containerPort:   *9980 | int
		type:            *"RollingUpdate" | "Recreate" | string
		maxUnavailable:  *0 | int | string
		maxSurge:        *1 | int | string
		annotations?:    {[string]: string}
		labels?:         {[string]: string}
		hostAliases?:    [...corev1.#HostAlias]
		customFonts: {
			enabled: *false | bool
			pvc: {
				size:              *"1Gi" | string
				accessMode:        *"ReadWriteOnce" | string
				storageClassName?: string
			}
			image: {
				repository: *"docker.io/alpine" | string
				tag:        *"3.22.0" | string
			}
			securityContext?: corev1.#SecurityContext & {
				runAsUser: *1001 | string
				allowPrivilegeEscalation: *false | string
				privileged: *false | string
				readOnlyRootFilesystem: *false | string
				seccompProfile: {
					type: *"RuntimeDefault" | string
				}
				capabilities: {
					drop: [
						*"ALL" | string
					]
				}
			}
		}
	}

	priorityClassName: *"" | string

	// Optional DaemonSet to install node seccomp profile (from upstream)
	installCOOLSeccompProfile: *true | bool

	// Pod settings
	serviceAccountName:           *_serviceAccountName | string
	automountServiceAccountToken: *false | bool
	hostNetwork:                  *false | bool
	hostPID:                      *false | bool
	hostIPC:                      *false | bool
	shareProcessNamespace:        *false | bool
	enableServiceLinks:           *false | bool
	restartPolicy:                *"Always" | string
	nodeSelector:                 *{"kubernetes.io/arch": "amd64"} | {[string]: string}
	topologySpreadConstraints?:   [...corev1.#TopologySpreadConstraint]

	// The affinity rules.
	affinity: *{podAntiAffinity: "soft"} | (timoniv1.#AffinityValues & {
		podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}) | corev1.#Affinity

	tolerations: *[] | [...corev1.#Toleration]
	dnsPolicy:                     *"ClusterFirst" | string
	dnsConfig?:                    corev1.#PodDNSConfig
	terminationGracePeriodSeconds: *60 | int
	hostUsers:                     *true | bool
	imagePullSecrets: *[] | [...timoniv1.#ObjectReference]

	podAnnotations?: {[string]: string}
	podLabels?:      {[string]: string}

	// The resources allows setting the container resource requirements.
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"75m" | timoniv1.#CPUQuantity
			memory: *"200Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			cpu:    *"1500m" | timoniv1.#CPUQuantity
			memory: *"2400Mi" | timoniv1.#MemoryQuantity
		}
	}

	// Autoscaling (HPA) from upstream
	autoscaling: {
		enabled:                            *false | bool
		minReplicas:                        *2 | int & >0
		maxReplicas:                        *100 | int & >0
		targetCPUUtilizationPercentage?:    int & >0 & <=100
		targetMemoryUtilizationPercentage?: int & >0 & <=100
		scaleDownDisabled:                  *false | bool
	}

	// PodDisruptionBudget (PDB) from upstream
	podDisruptionBudget: {
		enabled:         *false | bool
		minAvailable?:   int | string
		maxUnavailable?: int | string
	}

	// NetworkPolicy from upstream
	networkPolicy: {
		enabled:  *false | bool
		ingress?: [...]
		egress?:  [...]
	}

	// Ingress from upstream
	ingress: {
		enabled:      *false | bool
		className:    *"" | string
		annotations?: {[string]: string}
		hosts?: [...{
			host: string
			paths: [...{
				path:     string
				pathType: *"ImplementationSpecific" | "Prefix" | "Exact" | string
			}]
		}]
		tls?: [...networkingv1.#IngressTLS]
	}

	// Prometheus monitoring from upstream
	prometheus: {
		servicemonitor: {
			enabled: *false | bool
			labels?: {[string]: string}
		}
		rules: {
			enabled:           *false | bool
			namespace?:        string
			additionalLabels:  *{[string]: string} | {[string]: string}
			defaults: {
				enabled: *true | bool
				docs: {
					duplicated: *0 | int
					pod: {
						critical: *10 | int
						warning:  *8 | int
						info:     *5 | int
						[string]: int
					}
					sum: {
						critical: *500 | int
						warning:  *200 | int
						info:     *50 | int
						[string]: int
					}
				}
				errorServiceUnavailable: {
					critical: *50 | int
					warning:  *2 | int
					info:     *0 | int
					[string]: int
				}
				errorUnauthorizedRequest: {
					observationInterval: *"60m" | string
					eventCounter:        *8 | int
				}
				errorStorageConnections: {
					critical: *50 | int
					warning:  *2 | int
					info:     *0 | int
					[string]: int
				}
				viewers: {
					pod: {
						critical: *100 | int
						warning:  *80 | int
						info:     *60 | int
						[string]: int
					}
					doc: {
						critical: *50 | int
						warning:  *40 | int
						info:     *30 | int
						[string]: int
					}
					sum: {
						critical: *15000 | int
						warning:  *12000 | int
						info:     *5000 | int
						[string]: int
					}
				}
			}
			additionalRules: *[] | [...]
		}
	}

	// Grafana dashboards from upstream
	grafana: {
		dashboards: {
			enabled:      *false | bool
			labels?:      {[string]: string}
			annotations?: {[string]: string}
			data?:        {[string]: string}
		}
	}

	// Logging flow for Logging-Operator from upstream
	logging: {
		enabled:           *false | bool
		ecs:               *false | bool
		dedot?:            null | string
		additionalFilters: *[] | [...]
		localOutputRefs:   *[] | [...string]
		globalOutputRefs:  *["default"] | [...string]
	}

	// Nginx Deny Service from upstream
	nginxDeny: {
		enabled: *false | bool
		image: {
			repository: *"docker.io/nginx" | string
			tag:        *"stable-alpine" | string
			pullPolicy: *"IfNotPresent" | string
		}
		replicaCount:  *1 | int
		containerPort: *80 | int
		podAnnotations?: {[string]: string}
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
		env:                 *[] | [...corev1.#EnvVar]
		resources?:          timoniv1.#ResourceRequirements
		nodeSelector:        *{[string]: string} | {[string]: string}
		tolerations:         *[] | [...corev1.#Toleration]
		affinity?:           corev1.#Affinity
		service: port: *8080 | int
		ingress: {
			enabled:      *false | bool
			className:    *"" | string
			annotations?: {[string]: string}
			hosts?: [...{
				host: string
				paths: [...{
					path:     string
					pathType: *"ImplementationSpecific" | "Prefix" | "Exact" | string
				}]
			}]
			tls?: [...networkingv1.#IngressTLS]
		}
	}

	// Reverse Proxy from upstream
	reverseProxy: {
		enabled: *false | bool
		image: {
			repository: *"docker.io/nginxinc/nginx-unprivileged" | string
			tag:        *"stable" | string
			pullPolicy: *"IfNotPresent" | string
		}
		replicaCount:  *1 | int
		containerPort: *8080 | int
		hashParam:     *"WOPISrc" | string
		upstreamPort:  *9980 | int
		proxyTimeout:  *"3600s" | string
		controller: {
			enabled:  *false | bool
			upstream: *"" | string
		}
		nginxConfigOverride: *"" | string
		podAnnotations?:     {[string]: string}
		podSecurityContext: corev1.#PodSecurityContext & {
			runAsNonRoot: *true | bool
			seccompProfile: {
				type: *"RuntimeDefault" | string
			}
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
			capabilities: {
				drop: *["ALL"] | [...string]
			}
			seccompProfile: {
				type: *"RuntimeDefault" | string
			}
		}
		resources?: timoniv1.#ResourceRequirements
		nodeSelector: *{[string]: string} | {[string]: string}
		tolerations:  *[] | [...corev1.#Toleration]
		affinity?:    corev1.#Affinity
		service: {
			type: *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
			port: *8080 | int
		}
		endpointReloader: {
			enabled: *true | bool
			image: {
				repository: *"docker.io/alpine/k8s" | string
				tag:        *"1.31.1" | string
				pullPolicy: *"IfNotPresent" | string
			}
		}
		ingress: {
			enabled:      *false | bool
			className:    *"" | string
			annotations?: {[string]: string}
			hosts?: [...{
				host: string
				paths: [...{
					path:     string
					pathType: *"ImplementationSpecific" | "Prefix" | "Exact" | string
				}]
			}]
			tls?: [...networkingv1.#IngressTLS]
		}
		route: {
			enabled:      *false | bool
			host:         *"" | string
			annotations?: {[string]: string}
			tls?:         {...}
		}
	}

	// DynamicConfig from upstream
	dynamicConfig: {
		enabled:       *false | bool
		configuration: *"{}" | string
		logging: {
			enabled:           *false | bool
			ecs:               *false | bool
			dedot?:            null | string
			additionalFilters: *[] | [...]
			localOutputRefs:   *[] | [...string]
			globalOutputRefs:  *["default"] | [...string]
		}
		image: {
			repository: *"docker.io/nginx" | string
			tag:        *"1.25" | string
			pullPolicy: *"IfNotPresent" | string
		}
		replicaCount:  *1 | int
		containerPort: *80 | int
		podAnnotations?: {[string]: string}
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
		existingConfigMap: {
			enabled: *false | bool
			name:    *"" | string
		}
		upload: {
			enabled: *false | bool
			image: {
				repository: *"docker.io/twostoryrobot/simple-file-upload" | string
				tag:        *"latest" | string
				digest:     *"sha256:547fc4360b31d8604b7a26202914e87cd13609cc938fd83f412c77eb44aa1cc4" | string
			}
			key: *"TESTKEY" | string
			pvc: {
				size:              *"1Gi" | string
				accessMode:        *"ReadWriteOnce" | string
				storageClassName?: string
			}
			service: port: *8090 | int
			ingress: {
				enabled:      *false | bool
				className:    *"" | string
				annotations?: {[string]: string}
				hosts?: [...{
					host: string
					paths: [...{
						path:     string
						pathType: *"ImplementationSpecific" | "Prefix" | "Exact" | string
					}]
				}]
				tls?: [...networkingv1.#IngressTLS]
			}
			logging: {
				enabled:           *false | bool
				ecs:               *false | bool
				dedot?:            null | string
				additionalFilters: *[] | [...]
				localOutputRefs:   *[] | [...string]
				globalOutputRefs:  *["default"] | [...string]
			}
		}
		probes: {
			scheme: *"HTTP" | string
			startup: {
				enabled:          *true | bool
				failureThreshold: *30 | int
				periodSeconds:    *2 | int
			}
			readiness: {
				enabled:             *true | bool
				initialDelaySeconds: *0 | int
				periodSeconds:       *10 | int
				timeoutSeconds:      *30 | int
				successThreshold:    *1 | int
				failureThreshold:    *2 | int
			}
			liveness: {
				enabled:             *true | bool
				initialDelaySeconds: *0 | int
				periodSeconds:       *10 | int
				timeoutSeconds:      *30 | int
				successThreshold:    *1 | int
				failureThreshold:    *4 | int
			}
		}
		env:          *[] | [...corev1.#EnvVar]
		resources?:   timoniv1.#ResourceRequirements
		nodeSelector: *{[string]: string} | {[string]: string}
		tolerations:  *[] | [...corev1.#Toleration]
		affinity?:    corev1.#Affinity
		service: port: *8080 | int
		ingress: {
			enabled:      *false | bool
			className:    *"" | string
			annotations?: {[string]: string}
			hosts?: [...{
				host: string
				paths: [...{
					path:     string
					pathType: *"ImplementationSpecific" | "Prefix" | "Exact" | string
				}]
			}]
			tls?: [...networkingv1.#IngressTLS]
		}
	}

	// Environment variables for Collabora container.
	extraEnvVars: *[] | [...corev1.#EnvVar]

	// Extra volumes and volume mounts from user
	extraVolumes:      *[] | [...corev1.#Volume]
	extraVolumeMounts: *[] | [...corev1.#VolumeMount]

	// Default volumes from upstream
	_defaultVolumes: [
		{
			name:     "tmp"
			emptyDir: {}
		},
	]

	_allVolumes: [
		for v in _defaultVolumes {v},
		if (collabora.coolkitconfig_xcu_content != _|_ && collabora.coolkitconfig_xcu_content != "") || (collabora.coolwsd_xml_content != _|_ && collabora.coolwsd_xml_content != "") {
			{
				name: "coolwsd-config"
				configMap: {
					name: metadata.name
					items: [
						if collabora.coolkitconfig_xcu_content != _|_ && collabora.coolkitconfig_xcu_content != "" {
							key:  "coolkitconfig.xcu"
							path: "coolkitconfig.xcu"
						},
						if collabora.coolwsd_xml_content != _|_ && collabora.coolwsd_xml_content != "" {
							key:  "coolwsd.xml"
							path: "coolwsd.xml"
						},
					]
				}
			}
		},
		if collabora.proofKeyGeneration.enabled || (collabora.proofKeysSecretRef != _|_ && collabora.proofKeysSecretRef != "") {
			{
				name: "wopi-proof"
				secret: {
					secretName: [
						if collabora.proofKeyGeneration.enabled {
							if collabora.proofKeyGeneration.secretName != "" {collabora.proofKeyGeneration.secretName}
							"\(metadata.name)-wopi-proof"
						},
						collabora.proofKeysSecretRef,
					][0]
				}
			}
		},
		if deployment.customFonts.enabled {
			{
				name: "custom-fonts"
				persistentVolumeClaim: claimName: "\(metadata.name)-custom-fonts"
			}
		},
		for v in extraVolumes {v},
	]

	// Default volume mounts from upstream
	_defaultVolumeMounts: [
		{name: "tmp", mountPath: "/tmp"},
	]

	_allVolumeMounts: [
		for vm in _defaultVolumeMounts {vm},
		if collabora.coolkitconfig_xcu_content != _|_ && collabora.coolkitconfig_xcu_content != "" {
			{name: "coolwsd-config", mountPath: "/etc/coolwsd/coolkitconfig.xcu", subPath: "coolkitconfig.xcu"}
		},
		if collabora.coolwsd_xml_content != _|_ && collabora.coolwsd_xml_content != "" {
			{name: "coolwsd-config", mountPath: "/etc/coolwsd/coolwsd.xml", subPath: "coolwsd.xml"}
		},
		if collabora.proofKeyGeneration.enabled || (collabora.proofKeysSecretRef != _|_ && collabora.proofKeysSecretRef != "") {
			{name: "wopi-proof", mountPath: "/etc/coolwsd/proof_key", subPath: "proof_key"}
			if !collabora.proofKeyGeneration.enabled {
				{name: "wopi-proof", mountPath: "/etc/coolwsd/proof_key.pub", subPath: "proof_key.pub"}
			}
		},
		if deployment.customFonts.enabled {
			{name: "custom-fonts", mountPath: "/usr/share/fonts/custom", readOnly: true}
			{name: "custom-fonts", mountPath: "/opt/cool/systemplate/usr/share/fonts/custom", readOnly: true}
		},
		for vm in extraVolumeMounts {vm},
	]

	// Probes configuration mirroring upstream
	probes: {
		scheme: *"" | string
		_extraParamsStr: [
			if (collabora.extra_params & string) != _|_ {collabora.extra_params},
			if (collabora.extra_params & [...string]) != _|_ {strings.Join(collabora.extra_params, " ")},
			"",
		][0]
		_scheme: [
			if scheme != "" {scheme},
			if collabora.ssl_enable != _|_ && !collabora.ssl_enable {"HTTP"},
			if strings.Contains(strings.ToLower(_extraParamsStr), "ssl.enable=false") {"HTTP"},
			"HTTPS",
		][0]
		startup: {
			enabled:          *true | bool
			failureThreshold: *30 | int
			periodSeconds:    *3 | int
			path:             *"/" | string
		}
		readiness: {
			enabled:             *true | bool
			initialDelaySeconds: *0 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *30 | int
			successThreshold:    *1 | int
			failureThreshold:    *2 | int
			path:                *"/" | string
		}
		liveness: {
			enabled:             *true | bool
			initialDelaySeconds: *0 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *30 | int
			successThreshold:    *1 | int
			failureThreshold:    *4 | int
			path:                *"/" | string
		}
	}

	// Gateway API HTTPRoute mirroring upstream route.yaml
	route: {
		enabled:      *false | bool
		apiVersion:   *"gateway.networking.k8s.io/v1" | string
		kind:         *"HTTPRoute" | string
		annotations?: {[string]: string}
		labels?:      {[string]: string}
		parentRefs?: [...{
			name:         string
			namespace?:   string
			group?:       string
			kind?:        string
			sectionName?: string
			port?:        int
		}]
		hostnames?: [...string]
		path:     *"/" | string
		pathType: *"PathPrefix" | "Exact" | string
		matches?: [...]
		filters?: [...]
		additionalRules?: [...]
	}

	trusted_certs_install: {
		enabled:       *false | bool
		trusted_certs: *[] | [...string]
	}

	extraObjects: *[] | [...]

	// Test Job
	test: {
		enabled: *false | bool
		image:   *({
			repository: "docker.io/curlimages/curl"
			tag:        "latest"
			pullPolicy: "IfNotPresent"
		}) | timoniv1.#Image
	}

	// Optional compatibility fields for legacy values
	workload?: _
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		if config.daemonSetServiceAccount.create {
			daemonSetSA: #DaemonSetServiceAccount & {#config: config}
		}
		if !config.collabora.existingSecret.enabled {
			secret: #Secret & {#config: config}
		}
		cm:  #ConfigMap & {#config: config}
		svc: #Service & {#config: config}
		if config.route.enabled {
			httpRoute: #HTTPRoute & {#config: config}
		}
		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}
		if config.autoscaling.enabled {
			hpa: #HorizontalPodAutoscaler & {#config: config}
		}
		if config.podDisruptionBudget.enabled {
			pdb: #PodDisruptionBudget & {#config: config}
		}
		if config.networkPolicy.enabled {
			networkPolicy: #NetworkPolicy & {#config: config}
		}
		if config.prometheus.servicemonitor.enabled {
			serviceMonitor: #ServiceMonitor & {#config: config}
		}
		if config.prometheus.rules.enabled {
			prometheusRules: #PrometheusRule & {#config: config}
		}
		if config.grafana.dashboards.enabled {
			grafanaDashboards: #GrafanaDashboardsConfigMap & {#config: config}
		}
		if config.logging.enabled {
			loggingFlow: #LoggingFlow & {#config: config}
		}
		if config.collabora.proofKeyGeneration.enabled {
			proofKeySecret: #ProofKeySecret & {#config: config}
		}
		if config.installCOOLSeccompProfile {
			seccompDaemonSet: #SeccompProfileDaemonSet & {#config: config}
		}
		if config.deployment.customFonts.enabled {
			customFontsPVC: #CustomFontsPVC & {#config: config}
			customFontsPod: #CustomFontsPod & {#config: config}
		}
		if config.nginxDeny.enabled {
			nginxDenyCM:     #NginxDenyConfigMap & {#config: config}
			nginxDenyDeploy: #NginxDenyDeployment & {#config: config}
			nginxDenySvc:    #NginxDenyService & {#config: config}
			if config.nginxDeny.ingress.enabled {
				nginxDenyIngress: #NginxDenyIngress & {#config: config}
			}
		}
		if config.reverseProxy.enabled {
			if config.reverseProxy.endpointReloader.enabled {
				reverseProxySA:          #ReverseProxyServiceAccount & {#config: config}
				reverseProxyRole:        #ReverseProxyRole & {#config: config}
				reverseProxyRoleBinding: #ReverseProxyRoleBinding & {#config: config}
			}
			reverseProxyCM:       #ReverseProxyConfigMap & {#config: config}
			reverseProxyDeploy:   #ReverseProxyDeployment & {#config: config}
			reverseProxySvc:      #ReverseProxyService & {#config: config}
			reverseProxyHeadless: #ReverseProxyHeadlessService & {#config: config}
			if config.reverseProxy.ingress.enabled {
				reverseProxyIngress: #ReverseProxyIngress & {#config: config}
			}
			if config.reverseProxy.route.enabled {
				reverseProxyRoute: #ReverseProxyRoute & {#config: config}
			}
		}
		if config.dynamicConfig.enabled {
			if !config.dynamicConfig.existingConfigMap.enabled {
				dynconfigCM: #DynamicConfigMap & {#config: config}
			}
			dynconfigSvc: #DynamicConfigService & {#config: config}
			if !config.dynamicConfig.upload.enabled {
				dynconfigDeploy: #DynamicConfigDeployment & {#config: config}
			}
			if config.dynamicConfig.upload.enabled {
				dynconfigStatefulSet:  #DynamicConfigStatefulSet & {#config: config}
				dynconfigUploadSecret: #DynamicConfigUploadSecret & {#config: config}
				if config.dynamicConfig.upload.ingress.enabled {
					dynconfigUploadIngress: #DynamicConfigUploadIngress & {#config: config}
				}
				if config.dynamicConfig.upload.logging.enabled {
					dynconfigUploadFlow: #DynamicConfigUploadFlow & {#config: config}
				}
			}
			if config.dynamicConfig.ingress.enabled {
				dynconfigIngress: #DynamicConfigIngress & {#config: config}
			}
			if config.dynamicConfig.logging.enabled {
				dynconfigFlow: #DynamicConfigFlow & {#config: config}
			}
		}
		if config.deployment.kind == "Deployment" {
			deploy: #Deployment & {
				#config:     config
				#cmName:     objects.cm.metadata.name
				#secretName: [if config.collabora.existingSecret.enabled {config.collabora.existingSecret.secretName}, objects.secret.metadata.name][0]
			}
		}
		if config.deployment.kind == "StatefulSet" {
			statefulset: #StatefulSet & {
				#config:     config
				#cmName:     objects.cm.metadata.name
				#secretName: [if config.collabora.existingSecret.enabled {config.collabora.existingSecret.secretName}, objects.secret.metadata.name][0]
			}
		}
	}

	tests: {}
}

// CollaboraConfig defines the schema and validations for Collabora-specific settings.
#CollaboraConfig: {
	username:     *"admin" | string
	password:     *"examplepass" | (string & strings.MinRunes(8) & !~"\\$")
	server_name:  *"" | string
	aliasgroups:  *[] | [...{host: string, aliases?: [...string]}]
	aliasgroup1?: string | [...string]
	extra_params: *"--o:ssl.enable=false" | string | [...string]
	existingSecret: {
		enabled:     *false | bool
		secretName:  *"" | string
		usernameKey: *"username" | string
		passwordKey: *"password" | string
	}
	env: *[] | [...corev1.#EnvVar]
	proofKeysSecretRef: *"" | string
	proofKeyGeneration: {
		enabled:    *false | bool
		secretName: *"" | string
	}
	coolkitconfig_xcu_content: *"" | string
	coolwsd_xml_content:       *"" | string
	dictionaries?:             [...string]
	no_gen_ssl?:               bool
	interface?:                string
	proofKey?:                 string
	ssl_enable?:               bool
	ssl_termination?:          bool
}

