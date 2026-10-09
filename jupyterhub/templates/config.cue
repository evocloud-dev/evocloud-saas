package templates

import (
	"encoding/json"
	"list"
	"strings"

	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for JupyterHub.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.26.0"}

	// The moduleVersion is set from the user-supplied module version.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// The labels allows adding `metadata.labels` to all resources.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// Name and resource naming overrides
	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels:     *{...} | {[string]: string}
	annotations?:     timoniv1.#Annotations
	podLabels:        *{...} | {[string]: string}
	podAnnotations:   *{...} | {[string]: string}

	// Computed helper fields (following standard Timoni / Moodle patterns)
	#name: *(metadata.name) | string
	if nameOverride != "" {
		#name: nameOverride
	}

	#fullname: *(metadata.name) | string
	if fullnameOverride != "" {
		#fullname: fullnameOverride
	}

	#hubFullname:      *(#fullname + "-hub") | string
	#proxyFullname:    *(#fullname + "-proxy") | string
	#proxyApiFullname: *(#fullname + "-proxy-api") | string
	#proxyServiceName: *(#fullname) | string
	#cmName:           *(#fullname + "-hub-config") | string
	#hubDataClaimName: *(#fullname + "-hub-data") | string
	if hub.persistence.existingClaim != "" {
		#hubDataClaimName: hub.persistence.existingClaim
	}

	#secretName: *(#fullname + "-proxy") | string
	if proxy.existingSecret != "" {
		#secretName: proxy.existingSecret
	}

	#serviceAccountName: *(#fullname) | string
	if serviceAccount.name != "" {
		#serviceAccountName: serviceAccount.name
	}
	if !serviceAccount.create && serviceAccount.name == "" {
		#serviceAccountName: "default"
	}

	// Path helpers
	let _hubBase = strings.TrimSuffix(hub.baseUrl, "/")
	#hubHealthPath: *"/hub/health" | string
	if _hubBase != "" {
		#hubHealthPath: "\(_hubBase)/hub/health"
	}

	#hubMetricsPath: *"/hub/metrics" | string
	if _hubBase != "" {
		#hubMetricsPath: "\(_hubBase)/hub/metrics"
	}

	#hubErrorPath: *"/hub/error" | string
	if _hubBase != "" {
		#hubErrorPath: "\(_hubBase)/hub/error"
	}

	// Network & IP bind helpers
	#hasIPv6: list.Contains(service.ipFamilies, "IPv6")
	#isDual:  service.ipFamilyPolicy == "PreferDualStack" || service.ipFamilyPolicy == "RequireDualStack"
	#proxyDefaultBindIp: string
	if #hasIPv6 || #isDual {
		#proxyDefaultBindIp: "::"
	}
	if !#hasIPv6 && !#isDual {
		#proxyDefaultBindIp: "0.0.0.0"
	}

	#proxyBindIp: *#proxyDefaultBindIp | string
	if proxy.bind.ip != "" {
		#proxyBindIp: proxy.bind.ip
	}

	#proxyApiBindIp: *#proxyDefaultBindIp | string
	if proxy.bind.apiIp != "" {
		#proxyApiBindIp: proxy.bind.apiIp
	}

	// InitContainer curl helper configuration
	#initCurlImage:           *"docker.io/curlimages/curl:8.21.0" | string
	#initCurlImagePullPolicy: *corev1.#PullIfNotPresent | string
	#initCurlResources: {
		requests: {
			cpu:    *"10m" | string
			memory: *"32Mi" | string
		}
		limits: {
			cpu:    *"100m" | string
			memory: *"128Mi" | string
		}
	}
	#initCurlSecurityContext: corev1.#SecurityContext & {
		runAsUser:                1000
		runAsGroup:               1000
		runAsNonRoot:             true
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		capabilities: drop: ["ALL"]
		seccompProfile: type: "RuntimeDefault"
	}

	// HA & Database helpers
	#hasExternalHubDb:    strings.Contains(hub.extraConfig, "db_url")
	#haHubWithExternalDb: hub.replicaCount > 1 && #hasExternalHubDb
	#singleWriterHubPVC:  list.Contains(hub.persistence.accessModes, "ReadWriteOnce") || list.Contains(hub.persistence.accessModes, "ReadWriteOncePod")

	// Standard Labels & Selectors
	#labels: {[string]: string} & {
		"app.kubernetes.io/name":       #name
		"app.kubernetes.io/instance":   metadata.name
		"app.kubernetes.io/version":    moduleVersion
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/part-of":    "helmforge"
		if commonLabels != _|_ {
			for k, v in commonLabels {
				"\(k)": v
			}
		}
	}

	#componentLabels: {
		#component!: string
		"app.kubernetes.io/name":       #name
		"app.kubernetes.io/instance":   metadata.name
		"app.kubernetes.io/version":    moduleVersion
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/part-of":    "helmforge"
		"app.kubernetes.io/component":  #component
		if commonLabels != _|_ {
			for k, v in commonLabels {
				"\(k)": v
			}
		}
	}

	#selectorLabels: {
		#component!: string
		"app.kubernetes.io/name":      #name
		"app.kubernetes.io/instance":  metadata.name
		"app.kubernetes.io/component": #component
	}

	#podLabels: {
		#component!: string
		"app.kubernetes.io/name":      #name
		"app.kubernetes.io/instance":  metadata.name
		"app.kubernetes.io/component": #component
		if podLabels != _|_ {
			for k, v in podLabels {
				if k != "app.kubernetes.io/name" && k != "app.kubernetes.io/instance" && k != "app.kubernetes.io/component" {
					"\(k)": v
				}
			}
		}
	}

	// ConfigMap Python configuration helpers
	#cleanupServersStr: string
	if hub.cleanupServers {
		#cleanupServersStr: "True"
	}
	if !hub.cleanupServers {
		#cleanupServersStr: "False"
	}

	#authPrometheusStr: string
	if metrics.authenticatePrometheus {
		#authPrometheusStr: "True"
	}
	if !metrics.authenticatePrometheus {
		#authPrometheusStr: "False"
	}

	#cookieSecretLine: string
	if hub.cookieSecret.existingSecret != "" {
		#cookieSecretLine: "c.JupyterHub.cookie_secret_file = \"/srv/jupyterhub/\(hub.cookieSecret.fileName)\"\n"
	}
	if hub.cookieSecret.existingSecret == "" {
		#cookieSecretLine: ""
	}

	#authLines: string
	if auth.type == "dummy" {
		#authLines: "c.JupyterHub.authenticator_class = \"dummy\"\nc.DummyAuthenticator.password = os.environ.get(\"DUMMY_PASSWORD\", \"\")\n\n"
	}
	if auth.type != "dummy" {
		#authLines: ""
	}

	#extraLabelsMap: {
		"app.kubernetes.io/name":      #name
		"app.kubernetes.io/instance":  metadata.name
		"app.kubernetes.io/component": "singleuser"
		if podLabels != _|_ {
			for k, v in podLabels {
				if k != "app.kubernetes.io/name" && k != "app.kubernetes.io/instance" && k != "app.kubernetes.io/component" {
					(k): v
				}
			}
		}
	}
	#extraLabelsLines: strings.Join([
		for k, v in #extraLabelsMap {
			"    \(json.Marshal(k)): \(json.Marshal(v)),"
		}
	], "\n")

	#imagePullSecretsLine: string
	if len(imagePullSecrets) > 0 {
		#imagePullSecretsLine: "c.KubeSpawner.image_pull_secrets = \(json.Marshal(imagePullSecrets))\n"
	}
	if len(imagePullSecrets) == 0 {
		#imagePullSecretsLine: ""
	}

	#singleuserStorageLines: string
	if !singleuser.storage.enabled {
		#singleuserStorageLines: ""
	}
	if singleuser.storage.enabled {
		#singleuserStorageLines: strings.Join(list.Concat([
			[
				"c.KubeSpawner.storage_pvc_ensure = True",
				"c.KubeSpawner.storage_capacity = \"\(singleuser.storage.capacity)\"",
				"c.KubeSpawner.storage_access_modes = \(json.Marshal(singleuser.storage.accessModes))",
			],
			if singleuser.storage.storageClass != "" {
				["c.KubeSpawner.storage_class = \"\(singleuser.storage.storageClass)\""]
			},
			[
				"c.KubeSpawner.pvc_name_template = \"\(#fullname)-claim-{username}\"",
				"c.KubeSpawner.volumes = [{\"name\": \"home\", \"persistentVolumeClaim\": {\"claimName\": \"\(#fullname)-claim-{username}\"}}]",
				"c.KubeSpawner.volume_mounts = [{\"name\": \"home\", \"mountPath\": \"/home/jovyan\"}]",
				"",
			],
		]), "\n") + "\n"
	}

	#singleuserProfilesLine: string
	if len(singleuser.profiles) > 0 {
		#singleuserProfilesLine: "c.KubeSpawner.profile_list = json.loads(\(json.Marshal(json.Marshal(singleuser.profiles))))\n"
	}
	if len(singleuser.profiles) == 0 {
		#singleuserProfilesLine: ""
	}

	#hubExtraConfigLines: string
	if hub.extraConfig != "" {
		#hubExtraConfigLines: "\n" + strings.TrimSpace(hub.extraConfig) + "\n"
	}
	if hub.extraConfig == "" {
		#hubExtraConfigLines: ""
	}

	#dbUrlLine: "c.JupyterHub.db_url = \"sqlite:///\(hub.dbPath)\"\n"

	// Hub configuration
	hub: {
		replicaCount: *1 | int & >=1
		image!:       timoniv1.#Image
		baseUrl:      *"/" | string & =~"^/.*"
		dbPath:       *"/srv/jupyterhub/jupyterhub.sqlite" | string
		cookieSecret: {
			existingSecret:    *"" | string
			existingSecretKey: *"cookie-secret" | string
			fileName:          *"jupyterhub_cookie_secret" | string
		}
		logLevel:       *"INFO" | "DEBUG" | "INFO" | "WARN" | "ERROR"
		cleanupServers: *false | bool
		extraConfig:    *"" | string
		persistence: {
			enabled:       *true | bool
			existingClaim: *"" | string
			storageClass:  *"" | string
			accessModes:   *["ReadWriteOnce"] | [...string]
			size:          *"10Gi" | string
		}
		resources: {
			requests: {
				cpu:    *"100m" | string
				memory: *"256Mi" | string
			}
			limits: {
				cpu:    *"1" | string
				memory: *"1Gi" | string
			}
		}
	}

	// Proxy configuration
	proxy: {
		image!:                 timoniv1.#Image
		secretToken:            *"41208fbba9f3e4ca1701e6b8c8d8b9e4a3c2d1e0f7b6a5c4d3e2f1a0b9c8d7e6" | string & strings.MinRunes(16)
		secretData:             *null | bytes
		existingSecret:         *"" | string
		existingSecretTokenKey: *"proxy-token" | string
		logLevel:               *"warn" | "debug" | "info" | "warn" | "error"
		bind: {
			ip:    *"" | string
			apiIp: *"" | string
		}
		resources: {
			requests: {
				cpu:    *"50m" | string
				memory: *"128Mi" | string
			}
			limits: {
				cpu:    *"500m" | string
				memory: *"512Mi" | string
			}
		}
	}

	// Authentication configuration
	auth: {
		type:               *"dummy" | "custom" | string
		dummyPassword:      *"" | string
		allowInsecureDummy: *false | bool
	}

	// Singleuser spawner configuration
	singleuser: {
		image: {
			name:       *"quay.io/jupyter/base-notebook" | string
			tag:        *"2026-10-05" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		cpu: {
			guarantee: *0.1 | number
			limit:     *1 | number
		}
		memory: {
			guarantee: *"512M" | string
			limit:     *"2G" | string
		}
		storage: {
			enabled:      *false | bool
			capacity:     *"10Gi" | string
			storageClass: *"" | string
			accessModes:  *["ReadWriteOnce"] | [...string]
		}
		startTimeout: *300 | int
		defaultUrl:   *"/lab" | string
		profiles:     *[] | [...]
	}

	// Image pull secrets
	imagePullSecrets: *[] | [...corev1.#LocalObjectReference]

	// Service
	service: {
		type:           *"ClusterIP" | "NodePort" | "LoadBalancer"
		annotations?:   timoniv1.#Annotations
		port:           *80 | int & >0 & <=65535
		proxyApiPort:   *8001 | int & >0 & <=65535
		ipFamilies:     *[] | [...string]
		ipFamilyPolicy: *"" | "SingleStack" | "PreferDualStack" | "RequireDualStack"
	}

	// Gateway API HTTPRoute
	gateway: {
		enabled:      *false | bool
		apiVersion:   *"gateway.networking.k8s.io/v1" | string
		parentRefs:   *[] | [...]
		hostnames:    *[] | [...string]
		annotations?: timoniv1.#Annotations
		labels?:      timoniv1.#Labels
		rules: *[{
			matches: [{
				path: {
					type:  *"PathPrefix" | "Exact" | "RegularExpression"
					value: *"/" | string
				}
			}]
		}] | [...]
	}

	// ServiceAccount & RBAC
	serviceAccount: {
		create:       *true | bool
		name:         *"" | string
		annotations?: timoniv1.#Annotations
	}

	rbac: create: *true | bool

	// Metrics & ServiceMonitor
	metrics: {
		authenticatePrometheus:               *true | bool
		allowPublicUnauthenticatedPrometheus: *false | bool
		serviceMonitor: {
			enabled:  *false | bool
			interval: *"30s" | string
			labels:   timoniv1.#Labels
		}
	}

	// Pod Security Context
	podSecurityContext: corev1.#PodSecurityContext & {
		fsGroup:             *1000 | int
		fsGroupChangePolicy: *"OnRootMismatch" | string
		seccompProfile: {
			type: *"RuntimeDefault" | "Unconfined" | "Localhost"
		}
	}

	// Container Security Context
	securityContext: corev1.#SecurityContext & {
		runAsUser:                *1000 | int
		runAsGroup:               *1000 | int
		runAsNonRoot:             *true | bool
		allowPrivilegeEscalation: *false | bool
		readOnlyRootFilesystem:   *true | bool
		capabilities: {
			drop: *["ALL"] | [...string]
		}
	}

	// Probes
	livenessProbe: {
		initialDelaySeconds: *30 | int
		periodSeconds:       *20 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *6 | int
	}

	readinessProbe: {
		initialDelaySeconds: *10 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *6 | int
	}

	startupProbe: {
		initialDelaySeconds: *30 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *60 | int
	}

	// Scheduling & Placement
	nodeSelector:                  timoniv1.#Labels
	tolerations:                   *[] | [...corev1.#Toleration]
	affinity:                      *{} | timoniv1.#AffinityValues | corev1.#Affinity
	topologySpreadConstraints:     *[] | [...corev1.#TopologySpreadConstraint]
	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *30 | int

	// PodDisruptionBudget
	pdb: {
		enabled:      *false | bool
		minAvailable: *1 | int | string
	}

	// Custom environment and mounts
	extraEnv:           *[] | [...corev1.#EnvVar]
	extraVolumes:       *[] | [...corev1.#Volume]
	extraVolumeMounts:  *[] | [...corev1.#VolumeMount]
	extraManifests:     *[] | [...]

	// External Secrets
	externalSecrets: {
		enabled:         *false | bool
		apiVersion:      *"external-secrets.io/v1" | string
		refreshInterval: *"0" | string
		secretStoreRef: {
			name: *"" | string
			kind: *"SecretStore" | "ClusterSecretStore" | string
		}
		target: creationPolicy: *"Owner" | "Merge" | "None"
		data:     *[] | [...]
		dataFrom: *[] | [...]
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			serviceAccount: #ServiceAccount & {#config: config}
		}
		if config.rbac.create {
			role:        #Role & {#config: config}
			roleBinding: #RoleBinding & {#config: config}
		}
		if config.proxy.existingSecret == "" {
			secret: #Secret & {#config: config}
		}
		configMap: #ConfigMap & {#config: config}
		if config.hub.persistence.enabled && config.hub.persistence.existingClaim == "" {
			pvc: #HubPVC & {#config: config}
		}
		serviceProxy:    #ProxyService & {#config: config}
		serviceProxyApi: #ProxyApiService & {#config: config}
		serviceHub:      #HubService & {#config: config}
		deploymentHub:   #HubDeployment & {#config: config}
		deploymentProxy: #ProxyDeployment & {#config: config}
		if config.gateway.enabled {
			httpRoute: #HTTPRoute & {#config: config}
		}
		if config.pdb.enabled {
			pdb: #PodDisruptionBudget & {#config: config}
		}
		if config.metrics.serviceMonitor.enabled {
			serviceMonitor: #ServiceMonitor & {#config: config}
		}
		if config.externalSecrets.enabled {
			externalSecret: #ExternalSecret & {#config: config}
		}
		for i, m in config.extraManifests {
			"extra-\(i)": m
		}
	}
}
