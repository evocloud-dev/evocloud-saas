package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// Query current K8s version
	kubeVersion!: string
	// Check against minimum K8s version
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	// Name overrides
	nameOverride:     string
	fullnameOverride: string

	// Set module version
	moduleVersion!: string

	// Metadata common to all resources
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	// Selectors for Deployment and Service
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// Application Configuration
	image: {
		registry:   string
		repository: string
		tag:        string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
	}
	
	// Image reference computed from registry, repository, tag and digest
	#imageRef: {
		if image.digest != "" {
			"\(image.registry)/\(image.repository)@\(image.digest)"
		}
		if image.digest == "" {
			"\(image.registry)/\(image.repository):\(image.tag)"
		}
	}

	#pgImageRef: {
		if postgresql.image.digest != "" {
			"\(postgresql.image.registry)/\(postgresql.image.repository)@\(postgresql.image.digest)"
		}
		if postgresql.image.digest == "" {
			"\(postgresql.image.registry)/\(postgresql.image.repository):\(postgresql.image.tag)"
		}
	}

	#myImageRef: {
		if mysql.image.digest != "" {
			"\(mysql.image.registry)/\(mysql.image.repository)@\(mysql.image.digest)"
		}
		if mysql.image.digest == "" {
			"\(mysql.image.registry)/\(mysql.image.repository):\(mysql.image.tag)"
		}
	}
	
	replicaCount:         *1 | int & >0
	revisionHistoryLimit: *10 | int & >=0
	strategy:             *"Recreate" | "RollingUpdate"

	resources: corev1.#ResourceRequirements & {
		requests: {
			cpu:    *"100m" | string
			memory: *"128Mi" | string
		}
		limits: {
			memory: *"512Mi" | string
		}
	}
	securityContext: corev1.#SecurityContext

	serviceAccount: {
		create:      *true | bool
		annotations: {[string]: string}
		name:        *"" | string
	}
	service: {
		type: * "ClusterIP" | "NodePort" | "LoadBalancer"
		port: *3000 | int & >0 & <=65535
	}

	ingress: {
		enabled:   *false | bool
		className: string
		annotations: {[string]: string}
		hosts: [...{
			host: string
			paths: [...{
				path:     string
				pathType: *"ImplementationSpecific" | "Prefix" | "Exact"
			}]
		}]
		tls: [...{
			secretName: string
			hosts: [...string]
		}]
	}

	// Gateway API Route (Optional)
	route: [string]: {
		enabled:    *false | bool
		apiVersion: *"gateway.networking.k8s.io/v1" | string
		kind:       *"HTTPRoute" | string
		annotations: {[string]: string}
		labels: {[string]: string}
		hostnames: [...string]
		parentRefs: [...{
			name:       string
			namespace?: string
			group?:     string
			kind?:      string
		}]
		matches: [...{
			path: {
				type:  *"PathPrefix" | "Exact" | "RegularExpression"
				value: string
			}
		}]
		filters: [...{type: string, [string]: _}]
		additionalRules: [...{
			backendRefs: [...{
				name: string
				port: int
			}]
		}]
		httpsRedirect: *false | bool
	}

	autoscaling: {
		enabled:                        *false | bool
		minReplicas:                    *1 | int & >0
		maxReplicas:                    *100 | int & >0
		targetCPUUtilizationPercentage: *80 | int & >0 & <=100
		targetMemoryUtilizationPercentage: *80 | int & >0 & <=100
	}

	livenessProbe: corev1.#Probe & {
		failureThreshold: *3 | int
		httpGet: {
			path: "/"
			port: *3000 | int | string
		}
		initialDelaySeconds: *15 | int
		periodSeconds:       *10 | int
		successThreshold:    *1 | int
		timeoutSeconds:      *1 | int
	}
	readinessProbe: corev1.#Probe & {
		failureThreshold: *3 | int
		httpGet: {
			path: "/"
			port: *3000 | int | string
		}
		initialDelaySeconds: *15 | int
		periodSeconds:       *10 | int
		successThreshold:    *1 | int
		timeoutSeconds:      *1 | int
	}
	startupProbe: corev1.#Probe & {
		failureThreshold: *30 | int
		httpGet: {
			path: "/"
			port: *3000 | int | string
		}
		initialDelaySeconds: *30 | int
		periodSeconds:       *10 | int
		successThreshold:    *1 | int
		timeoutSeconds:      *1 | int
	}


	nodeSelector: {[string]: string}
	tolerations:        *[] | [...corev1.#Toleration]
	affinity:          corev1.#Affinity
	initContainers:    *[] | [...corev1.#Container]
	extraEnv:          *[] | [...corev1.#EnvVar]
	podAnnotations:    {[string]: string}
	podLabels:         {[string]: string}
	podSecurityContext: corev1.#PodSecurityContext
	imagePullSecrets:  *[] | [...timoniv1.#ObjectReference]

	umami: {
		appSecret: {
			existingSecret: string
			secret!:        string
			#secret:        secret
		}
		clientIpHeader:     string
		cloudMode:          *"0" | "1"
		collectApiEndpoint: string
		corsMaxAge:         string
		customScript: {
			enabled:   *false | bool
			data:      string
			key:       string
			mountPath: string
		}
		debug:                 string
		disableBotCheck:       *"1" | "0"
		disableLogin:          *"1" | "0"
		disableTelemetry:      *"1" | "0"
		disableUpdates:        *"1" | "0"
		enableTestConsole:     *"1" | "0"
		forceSSL:              *"1" | "0"
		hostname:              string
		ignoreHostname:        string
		ignoredIpAddresses:    string
		logQuery:              *"1" | "0"
		removeDisableLoginEnv: *true | bool
		removeTrailingSlash:   *"1" | "0"
		trackerScriptName:     *"umami" | string
		migration: v1v2: enabled: *false | bool
	}

	postgresql: {
		enabled: *true | bool
		image: {
			registry:   *"docker.io" | string
			repository: *"bitnamilegacy/postgresql" | string
			tag:        *"14" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			database: string
			password: string
			username: string
		}
		persistence: {
			enabled: *true | bool
			size:    *"8Gi" | string
		}
		livenessProbe: corev1.#Probe & {
			tcpSocket: port: 5432
			initialDelaySeconds: *30 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
			successThreshold:    *1 | int
			failureThreshold:    *6 | int
		}
		readinessProbe: corev1.#Probe & {
			tcpSocket: port: 5432
			initialDelaySeconds: *5 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
			successThreshold:    *1 | int
			failureThreshold:    *6 | int
		}
	}

	mysql: {
		enabled: *false | bool
		image: {
			registry:   *"docker.io" | string
			repository: *"bitnamilegacy/mysql" | string
			tag:        *"8.0" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			database: string
			password: string
			username: string
		}
		persistence: {
			enabled: *true | bool
			size:    *"8Gi" | string
		}
		livenessProbe: corev1.#Probe & {
			tcpSocket: port: 3306
			initialDelaySeconds: *30 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
			successThreshold:    *1 | int
			failureThreshold:    *6 | int
		}
		readinessProbe: corev1.#Probe & {
			tcpSocket: port: 3306
			initialDelaySeconds: *5 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
			successThreshold:    *1 | int
			failureThreshold:    *6 | int
		}
	}

	externalDatabase: {
		auth: {
			database: string
			password: string
			username: string
		}
		hostname: string
		port:     *5432 | int
		type:     *"postgresql" | "mysql"
	}

	database: {
		databaseUrlKey: string
		existingSecret: string
	}

	test: enabled: *false | bool
}

// Instance defines the module's Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		sa: #ServiceAccount & {#config: config}
		svc: #Service & {#config: config}
		
		if config.umami.customScript.enabled {
			cm: #ConfigMap & {#config: config}
		}

		deploy: #Deployment & {
			#config: config
			if config.umami.customScript.enabled {
				#cmName: objects.cm.metadata.name
			}
		}

		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}

		if config.autoscaling.enabled {
			hpa: #HPA & {#config: config}
		}

		if config.umami.migration.v1v2.enabled {
			job: #MigrationJob & {#config: config}
		}

		// Secrets
		if config.database.existingSecret == "" {
			dbSecret: #DatabaseSecret & {#config: config}
		}
		if config.umami.appSecret.existingSecret == "" {
			appSecret: #AppSecret & {#config: config}
		}
		// Database resources
		if config.postgresql.enabled {
			for name, obj in (#PostgreSQL & {#config: config}).objects {
				"pg-\(name)": obj
			}
		}
		if config.mysql.enabled {
			for name, obj in (#MySQL & {#config: config}).objects {
				"my-\(name)": obj
			}
		}

		// Gateway routes
		for name, r in config.route if r.enabled {
			"route-\(name)": #HTTPRoute & {#config: config, #name: name, #route: r}
		}
	}
}
