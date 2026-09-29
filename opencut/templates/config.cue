package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the OpenCut Instance values.
#Config: {
	// The kubeVersion is set at apply-time via timoni.cue.
	kubeVersion!: string
	// OpenCut requires Kubernetes >= 1.26.0
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.26.0"}

	// The moduleVersion is set from the user-supplied module version.
	moduleVersion!: string

	// Common metadata for all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels:       timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	// Naming overrides.
	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	// Additional labels applied to all resources.
	commonLabels: *{} | {[string]: string}

	// Computed names and labels.
	#fullname: string
	if fullnameOverride != "" {
		#fullname: fullnameOverride
	}
	if fullnameOverride == "" {
		#fullname: metadata.name
	}

	#name: string
	if nameOverride != "" {
		#name: nameOverride
	}
	if nameOverride == "" {
		#name: "opencut"
	}

	#allLabels: {[string]: string} & {
		"app.kubernetes.io/name":       metadata.name
		"app.kubernetes.io/version":    moduleVersion
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/part-of":    "helmforge"
		for k, v in commonLabels {
			(k): v
		}
	}

	#webSelectorLabels: {[string]: string} & {
		"app.kubernetes.io/name":      metadata.name
		"app.kubernetes.io/component": "web"
	}

	#redisHttpSelectorLabels: {[string]: string} & {
		"app.kubernetes.io/name":      metadata.name
		"app.kubernetes.io/component": "redis-http"
	}

	#postgresqlLabels: {[string]: string} & {
		"app.kubernetes.io/name":       "postgresql"
		"app.kubernetes.io/instance":   #fullname
		"app.kubernetes.io/version":    "18.6"
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/part-of":    "helmforge"
	}

	#postgresqlSelectorLabels: {[string]: string} & {
		"app.kubernetes.io/name":      "postgresql"
		"app.kubernetes.io/instance":  #fullname
		"app.kubernetes.io/component": "postgresql"
		"app.kubernetes.io/part-of":   "postgresql"
		"app.kubernetes.io/role":      "standalone"
	}

	#redisLabels: {[string]: string} & {
		"app.kubernetes.io/name":       "redis"
		"app.kubernetes.io/instance":   #fullname
		"app.kubernetes.io/version":    "8.10.1"
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/part-of":    "helmforge"
	}

	#redisSelectorLabels: {[string]: string} & {
		"app.kubernetes.io/name":      "redis"
		"app.kubernetes.io/instance":  #fullname
		"app.kubernetes.io/component": "redis"
		"app.kubernetes.io/part-of":   "redis"
		"app.kubernetes.io/role":      "standalone"
	}

	#serviceAccountName: string
	if serviceAccount.create {
		if serviceAccount.name != "" {
			#serviceAccountName: serviceAccount.name
		}
		if serviceAccount.name == "" {
			#serviceAccountName: #fullname
		}
	}
	if !serviceAccount.create {
		if serviceAccount.name != "" {
			#serviceAccountName: serviceAccount.name
		}
		if serviceAccount.name == "" {
			#serviceAccountName: "default"
		}
	}

	#secretName:    "\(#fullname)-app"
	#redisHttpName: "\(#fullname)-redis-http"
	#testName:      "\(#fullname)-test"

	// Database resolution
	#databaseMode: string
	if database.external.host != "" {
		#databaseMode: "external"
	}
	if database.external.host == "" {
		#databaseMode: "postgresql"
	}

	#postgresqlName: string
	if postgresql.nameOverride != "" {
		#postgresqlName: postgresql.nameOverride
	}
	if postgresql.nameOverride == "" {
		#postgresqlName: "postgresql"
	}

	#postgresqlFullname: string
	if postgresql.fullnameOverride != "" {
		#postgresqlFullname: postgresql.fullnameOverride
	}
	if postgresql.fullnameOverride == "" {
		#postgresqlFullname: "\(metadata.name)-\(#postgresqlName)"
	}

	#postgresqlServiceName: string
	if postgresql.architecture == "replication" {
		#postgresqlServiceName: "\(#postgresqlFullname)-primary"
	}
	if postgresql.architecture != "replication" {
		#postgresqlServiceName: #postgresqlFullname
	}

	#databaseHost: string
	if #databaseMode == "external" {
		#databaseHost: database.external.host
	}
	if #databaseMode != "external" {
		#databaseHost: #postgresqlServiceName
	}

	#databasePort: int
	if #databaseMode == "external" {
		#databasePort: database.external.port
	}
	if #databaseMode != "external" {
		#databasePort: 5432
	}

	#databaseName: string
	if #databaseMode == "external" {
		#databaseName: database.external.name
	}
	if #databaseMode != "external" {
		#databaseName: postgresql.auth.database
	}

	#databaseUsername: string
	if #databaseMode == "external" {
		#databaseUsername: database.external.username
	}
	if #databaseMode != "external" {
		#databaseUsername: postgresql.auth.username
	}

	#databaseSecretName: string
	if #databaseMode == "external" {
		if database.external.existingSecret != "" {
			#databaseSecretName: database.external.existingSecret
		}
		if database.external.existingSecret == "" {
			#databaseSecretName: "\(#fullname)-database"
		}
	}
	if #databaseMode != "external" {
		if postgresql.auth.existingSecret != "" {
			#databaseSecretName: postgresql.auth.existingSecret
		}
		if postgresql.auth.existingSecret == "" {
			if postgresql.externalSecrets.enabled && postgresql.externalSecrets.auth.enabled && postgresql.externalSecrets.auth.targetName != "" {
				#databaseSecretName: postgresql.externalSecrets.auth.targetName
			}
			if !(postgresql.externalSecrets.enabled && postgresql.externalSecrets.auth.enabled && postgresql.externalSecrets.auth.targetName != "") {
				#databaseSecretName: "\(#postgresqlFullname)-auth"
			}
		}
	}

	#databaseSecretKey: string
	if #databaseMode == "external" {
		if database.external.existingSecret != "" {
			#databaseSecretKey: database.external.existingSecretPasswordKey
		}
		if database.external.existingSecret == "" {
			#databaseSecretKey: "database-password"
		}
	}
	if #databaseMode != "external" {
		#databaseSecretKey: postgresql.auth.existingSecretUserPasswordKey
	}

	#databaseUserPassword: string
	if postgresql.auth.password != "" {
		#databaseUserPassword: postgresql.auth.password
	}
	if postgresql.auth.password == "" {
		#databaseUserPassword: "opencut-database-password-change-me"
	}

	#databaseAdminPassword: string
	if postgresql.auth.postgresPassword != "" {
		#databaseAdminPassword: postgresql.auth.postgresPassword
	}
	if postgresql.auth.postgresPassword == "" {
		#databaseAdminPassword: "postgres-super-password-change-me"
	}

	#postgresResources: corev1.#ResourceRequirements & {
		if postgresql.standalone.resourcesPreset == "small" {
			requests: {
				cpu:    "250m"
				memory: "512Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "1Gi"
			}
		}
		if postgresql.standalone.resourcesPreset == "medium" {
			requests: {
				cpu:    "500m"
				memory: "1Gi"
			}
			limits: {
				cpu:    "1"
				memory: "2Gi"
			}
		}
		if postgresql.standalone.resourcesPreset == "large" {
			requests: {
				cpu:    "1"
				memory: "2Gi"
			}
			limits: {
				cpu:    "2"
				memory: "4Gi"
			}
		}
		if postgresql.standalone.resourcesPreset != "small" && postgresql.standalone.resourcesPreset != "medium" && postgresql.standalone.resourcesPreset != "large" {
			requests: {
				cpu:    "250m"
				memory: "512Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "1Gi"
			}
		}
	}

	// Redis resolution
	#redisName: string
	if redis.nameOverride != "" {
		#redisName: redis.nameOverride
	}
	if redis.nameOverride == "" {
		#redisName: "redis"
	}

	#redisFullname: string
	if redis.fullnameOverride != "" {
		#redisFullname: redis.fullnameOverride
	}
	if redis.fullnameOverride == "" {
		#redisFullname: "\(#fullname)-\(#redisName)"
	}

	#redisServiceName: string
	if redis.architecture == "replication" {
		#redisServiceName: "\(#redisFullname)-primary"
	}
	if redis.architecture != "replication" {
		#redisServiceName: "\(#redisFullname)-client"
	}

	#redisHost: string
	if redis.external.host != "" {
		#redisHost: redis.external.host
	}
	if redis.external.host == "" {
		#redisHost: #redisServiceName
	}

	#redisPort: int
	if redis.external.host != "" {
		#redisPort: redis.external.port
	}
	if redis.external.host == "" {
		#redisPort: 6379
	}

	#redisAuthEnabled: bool
	if redis.external.host == "" && redis.auth.enabled {
		#redisAuthEnabled: true
	}
	if redis.external.host != "" {
		if redis.external.password != "" || redis.external.existingSecret != "" {
			#redisAuthEnabled: true
		}
		if !(redis.external.password != "" || redis.external.existingSecret != "") {
			#redisAuthEnabled: false
		}
	}
	if redis.external.host == "" && !redis.auth.enabled {
		#redisAuthEnabled: false
	}

	#redisSecretName: string
	if redis.external.existingSecret != "" {
		#redisSecretName: redis.external.existingSecret
	}
	if redis.external.existingSecret == "" {
		if redis.external.password != "" {
			#redisSecretName: #secretName
		}
		if redis.external.password == "" {
			if redis.auth.existingSecret != "" {
				#redisSecretName: redis.auth.existingSecret
			}
			if redis.auth.existingSecret == "" {
				#redisSecretName: "\(#redisFullname)-auth"
			}
		}
	}

	#redisSecretKey: string
	if redis.external.existingSecret != "" {
		#redisSecretKey: redis.external.existingSecretPasswordKey
	}
	if redis.external.existingSecret == "" {
		if redis.external.password != "" {
			#redisSecretKey: "redis-password"
		}
		if redis.external.password == "" {
			#redisSecretKey: redis.auth.existingSecretPasswordKey
		}
	}

	#redisPassword: string
	if redis.auth.password != "" {
		#redisPassword: redis.auth.password
	}
	if redis.auth.password == "" {
		#redisPassword: "redis-password-change-me"
	}

	#redisRestExternalSecretName: string
	if redisHttp.external.existingSecret != "" {
		#redisRestExternalSecretName: redisHttp.external.existingSecret
	}
	if redisHttp.external.existingSecret == "" {
		#redisRestExternalSecretName: #secretName
	}

	#redisRestExternalSecretKey: string
	if redisHttp.external.existingSecretTokenKey != "" {
		#redisRestExternalSecretKey: redisHttp.external.existingSecretTokenKey
	}
	if redisHttp.external.existingSecretTokenKey == "" {
		#redisRestExternalSecretKey: "redis-rest-token"
	}

	#redisRestEgressPort: int
	if redisHttp.enabled {
		#redisRestEgressPort: redisHttp.service.port
	}
	if !redisHttp.enabled {
		if (redisHttp.external.url =~ "^http://") {
			#redisRestEgressPort: 80
		}
		if !(redisHttp.external.url =~ "^http://") {
			#redisRestEgressPort: 443
		}
	}

	#siteUrl: string
	if opencut.siteUrl != "" {
		#siteUrl: opencut.siteUrl
	}
	if opencut.siteUrl == "" {
		if gateway.enabled && len(gateway.hostnames) > 0 {
			#siteUrl: "https://\(gateway.hostnames[0])"
		}
		if !(gateway.enabled && len(gateway.hostnames) > 0) {
			#siteUrl: "http://localhost:3000"
		}
	}

	#betterAuthSecret: string
	if opencut.betterAuthSecret != "" {
		#betterAuthSecret: opencut.betterAuthSecret
	}
	if opencut.betterAuthSecret == "" {
		#betterAuthSecret: "betterauth-secret-change-me-minimum-32-chars-long"
	}

	#redisRestToken: string
	if !redisHttp.enabled && redisHttp.external.token != "" {
		#redisRestToken: redisHttp.external.token
	}
	if !(!redisHttp.enabled && redisHttp.external.token != "") {
		if redisHttp.token != "" {
			#redisRestToken: redisHttp.token
		}
		if redisHttp.token == "" {
			#redisRestToken: "redis-rest-token-default-change-me-32chars"
		}
	}

	// Replicas & limits
	replicaCount:         *1 | int & >=1
	revisionHistoryLimit: *3 | int & >=0

	// Images
	image: timoniv1.#Image & {
		repository: *"docker.io/helmforge/opencut" | string
		tag:        *"v0.3.0" | string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
	}
	imagePullSecrets: *[] | [...corev1.#LocalObjectReference]

	// OpenCut application settings
	opencut: {
		siteUrl:            *"" | string
		betterAuthSecret:   *"" | string
		marbleApiUrl:       *"https://api.marblecms.com" | string
		marbleWorkspaceKey: *"placeholder" | string
		freesoundClientId:  *"" | string
		freesoundApiKey:    *"" | string
		extraEnv: *[] | [...corev1.#EnvVar]
	}

	// Database settings
	database: {
		mode: *"auto" | string
		external: {
			host:                      *"" | string
			port:                      *5432 | int & >0 & <=65535
			name:                      *"opencut" | string
			username:                  *"opencut" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"database-password" | string
		}
	}

	// PostgreSQL subchart compatibility settings
	postgresql: {
		enabled:          *true | bool
		nameOverride:     *"" | string
		fullnameOverride: *"" | string
		image: timoniv1.#Image & {
			repository: *"docker.io/library/postgres" | string
			tag:        *"18.6-trixie" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		extraEnv: *[{name: "POSTGRES_INITDB_ARGS", value: "--auth-local=scram-sha-256 --auth-host=scram-sha-256"}] | [...corev1.#EnvVar]
		architecture: *"standalone" | "replication"
		auth: {
			database:                      *"opencut" | string
			username:                      *"opencut" | string
			password:                      *"" | string
			postgresPassword:              *"" | string
			existingSecret:                *"" | string
			existingSecretUserPasswordKey: *"user-password" | string
		}
		standalone: {
			resourcesPreset: *"small" | string
			persistence: {
				enabled: *true | bool
				size:    *"8Gi" | string
			}
		}
		replication: {
			primary: {
				resourcesPreset: *"small" | string
			}
			readReplicas: {
				resourcesPreset: *"small" | string
			}
		}
		externalSecrets: {
			enabled: *false | bool
			auth: {
				enabled:    *false | bool
				targetName: *"" | string
			}
		}
	}

	// ExternalSecrets settings
	externalSecrets: {
		enabled:         *false | bool
		apiVersion:      *"external-secrets.io/v1" | string
		refreshInterval: *"0" | string
		secretStoreRef: {
			name: *"" | string
			kind: *"SecretStore" | "ClusterSecretStore"
		}
		target: {
			creationPolicy: *"Owner" | string
		}
		data: *[] | [...{
			secretKey: string
			remoteRef: {
				key:       string
				property?: string
				version?:  string
			}
		}]
	}

	// Redis settings
	redis: {
		enabled:          *true | bool
		nameOverride:     *"" | string
		fullnameOverride: *"" | string
		image: timoniv1.#Image & {
			repository: *"docker.io/library/redis" | string
			tag:        *"8.10.1" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		architecture: *"standalone" | "replication"
		auth: {
			enabled:                   *true | bool
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"redis-password" | string
		}
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"1Gi" | string
			}
			resources: corev1.#ResourceRequirements & {
				requests: {
					cpu:    *"50m" | string
					memory: *"128Mi" | string
				}
				limits: {
					cpu:    *"250m" | string
					memory: *"256Mi" | string
				}
			}
		}
		replication: {
			primary: {
				persistence: {
					enabled: *true | bool
				}
				resources: timoniv1.#ResourceRequirements & {
					requests: {
						cpu:    *"50m" | timoniv1.#CPUQuantity
						memory: *"128Mi" | timoniv1.#MemoryQuantity
					}
					limits: {
						cpu:    *"250m" | timoniv1.#CPUQuantity
						memory: *"256Mi" | timoniv1.#MemoryQuantity
					}
				}
			}
			replica: {
				persistence: {
					enabled: *true | bool
				}
				resources: timoniv1.#ResourceRequirements & {
					requests: {
						cpu:    *"50m" | timoniv1.#CPUQuantity
						memory: *"128Mi" | timoniv1.#MemoryQuantity
					}
					limits: {
						cpu:    *"250m" | timoniv1.#CPUQuantity
						memory: *"256Mi" | timoniv1.#MemoryQuantity
					}
				}
			}
		}
		securityContext: corev1.#SecurityContext & {
			runAsUser:                *999 | int
			runAsGroup:               *999 | int
			runAsNonRoot:             *true | bool
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *false | bool
			capabilities: drop: *["ALL"] | [...string]
			seccompProfile: type: *"RuntimeDefault" | string
		}
		external: {
			host:                      *"" | string
			port:                      *6379 | int & >0 & <=65535
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"redis-password" | string
		}
	}

	// Redis HTTP bridge
	redisHttp: {
		enabled: *true | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/hiett/serverless-redis-http" | string
			tag:        *"0.0.10" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		token: *"" | string
		external: {
			url:                    *"" | string
			token:                  *"" | string
			existingSecret:         *"" | string
			existingSecretTokenKey: *"redis-rest-token" | string
		}
		service: {
			port: *80 | int & >0 & <=65535
		}
		probes: {
			startup: {
				enabled:             *true | bool
				path:                *"/" | string
				initialDelaySeconds: *60 | int
				periodSeconds:       *5 | int
				timeoutSeconds:      *3 | int
				failureThreshold:    *12 | int
			}
			readiness: {
				enabled:             *true | bool
				path:                *"/" | string
				initialDelaySeconds: *60 | int
				periodSeconds:       *10 | int
				timeoutSeconds:      *3 | int
				failureThreshold:    *6 | int
			}
			liveness: {
				enabled:             *true | bool
				path:                *"/" | string
				initialDelaySeconds: *90 | int
				periodSeconds:       *20 | int
				timeoutSeconds:      *3 | int
				failureThreshold:    *3 | int
			}
		}
		resources: corev1.#ResourceRequirements & {
			requests: {
				cpu:    *"500m" | string
				memory: *"1Gi" | string
			}
			limits: {
				cpu:    *"4" | string
				memory: *"4Gi" | string
			}
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *true | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *1000 | int
			runAsGroup:               *1000 | int
			capabilities: drop: *["ALL"] | [...string]
		}
	}

	// Service Account
	serviceAccount: {
		create: *true | bool
		name:   *"" | string
		annotations: *{} | {[string]: string}
		automountServiceAccountToken: *false | bool
	}

	// Service
	service: {
		type: *"ClusterIP" | "NodePort" | "LoadBalancer" | "ExternalName"
		port: *80 | int & >0 & <=65535
		annotations: *{} | {[string]: string}
		ipFamilyPolicy: *"" | "SingleStack" | "PreferDualStack" | "RequireDualStack"
		ipFamilies: *[] | [...string]
	}

	// Gateway API HTTPRoute
	gateway: {
		enabled: *false | bool
		annotations: *{} | {[string]: string}
		parentRefs: *[] | [...{
			name:         string
			group?:       string
			kind?:        string
			namespace?:   string
			sectionName?: string
			port?:        int
		}]
		hostnames: *[] | [...string]
		path:     *"/" | string
		pathType: *"PathPrefix" | "Exact" | "RegularExpression"
	}

	// Autoscaling
	autoscaling: {
		enabled:                           *false | bool
		minReplicas:                       *1 | int & >=1
		maxReplicas:                       *4 | int & >=1
		targetCPUUtilizationPercentage:    *70 | int & >0 & <=100
		targetMemoryUtilizationPercentage: *80 | int & >0 & <=100
	}

	// PodDisruptionBudget
	pdb: {
		enabled:      *true | bool
		minAvailable: *1 | int | string
	}

	// Probes
	probes: {
		startup: {
			enabled:             *true | bool
			path:                *"/api/health" | string
			initialDelaySeconds: *20 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *18 | int
		}
		liveness: {
			enabled:             *true | bool
			path:                *"/api/health" | string
			initialDelaySeconds: *30 | int
			periodSeconds:       *20 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *3 | int
		}
		readiness: {
			enabled:             *true | bool
			path:                *"/api/health" | string
			initialDelaySeconds: *10 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *6 | int
		}
	}

	// Container & Pod resources and security
	resources: corev1.#ResourceRequirements & {
		requests: {
			cpu:    *"100m" | string
			memory: *"256Mi" | string
		}
		limits: {
			cpu:    *"1" | string
			memory: *"1Gi" | string
		}
	}

	podSecurityContext: corev1.#PodSecurityContext & {
		runAsNonRoot: *true | bool
		runAsUser:    *1001 | int
		runAsGroup:   *1001 | int
		fsGroup:      *1001 | int
		seccompProfile: type: *"RuntimeDefault" | string
	}

	securityContext: corev1.#SecurityContext & {
		allowPrivilegeEscalation: *false | bool
		readOnlyRootFilesystem:   *true | bool
		capabilities: drop: *["ALL"] | [...string]
	}

	// Scheduling & Pod options
	podAnnotations: *{} | {[string]: string}
	podLabels: *{} | {[string]: string}
	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *30 | int & >=1
	nodeSelector: *{} | {[string]: string}
	tolerations: *[] | [...corev1.#Toleration]
	affinity: *{} | corev1.#Affinity
	topologySpreadConstraints: *[] | [...corev1.#TopologySpreadConstraint]
	extraVolumes: *[] | [...corev1.#Volume]
	extraVolumeMounts: *[] | [...corev1.#VolumeMount]

	// Tests
	test: {
		enabled: *false | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/library/busybox" | string
			tag:        *"1.37.0" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
	}

	// Extra Objects
	extraObjects: *[] | [...{[string]: _}]
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		// OpenCut app secret
		secret: #Secret & {#config: config}

		// External database secret if needed
		if config.#databaseMode == "external" && config.database.external.existingSecret == "" && config.database.external.password != "" {
			"database-secret": #DatabaseSecret & {#config: config}
		}

		// ServiceAccount
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}

		// Web Service
		svc: #Service & {#config: config}

		// Web Deployment
		deploy: #Deployment & {#config: config}

		// Redis HTTP bridge
		if config.redisHttp.enabled {
			"redis-http-deploy": #RedisHttpDeployment & {#config: config}
			"redis-http-svc": #RedisHttpService & {#config: config}
		}

		// Gateway API HTTPRoute
		if config.gateway.enabled {
			httproute: #HTTPRoute & {#config: config}
		}

		// Autoscaling (HPA)
		if config.autoscaling.enabled {
			hpa: #HorizontalPodAutoscaler & {#config: config}
		}

		// PodDisruptionBudget
		if config.pdb.enabled {
			pdb: #PodDisruptionBudget & {#config: config}
		}

		// ExternalSecrets
		if config.externalSecrets.enabled {
			"external-secret": #ExternalSecret & {#config: config}
		}

		// Bundled PostgreSQL resources when enabled
		if config.postgresql.enabled && config.#databaseMode != "external" {
			if config.postgresql.auth.existingSecret == "" && !(config.postgresql.externalSecrets.enabled && config.postgresql.externalSecrets.auth.enabled) {
				"postgresql-auth": #PostgresSecret & {#config: config}
			}
			"postgresql-config": #PostgresConfigMap & {#config: config}
			"postgresql-initdb": #PostgresInitdbConfigMap & {#config: config}
			"postgresql-headless": #PostgresHeadlessService & {#config: config}
			"postgresql-svc": #PostgresService & {#config: config}
			"postgresql-sts": #PostgresStatefulSet & {#config: config}
		}

		// Bundled Redis resources when enabled
		if config.redis.enabled && config.redis.external.host == "" {
			if config.redis.auth.enabled && config.redis.auth.existingSecret == "" {
				"redis-auth": #RedisSecret & {#config: config}
			}
			"redis-config": #RedisConfigMap & {#config: config}
			"redis-headless": #RedisHeadlessService & {#config: config}
			"redis-client": #RedisClientService & {#config: config}
			"redis-sts": #RedisStatefulSet & {#config: config}
		}

		// Extra Objects
		for i, obj in config.extraObjects {
			"extra-\(i)": obj
		}
	}

	tests: {
		"test-connection": #TestJob & {#config: config}
	}
}
