package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Discourse Instance values.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: string
	// Using the kubeVersion you can enforce a minimum Kubernetes minor version.
	// By default, the minimum Kubernetes version is set to 1.20.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.26.0"}

	// The moduleVersion is set from the user-supplied module version.
	// This field is used for the `app.kubernetes.io/version` label.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	// The `metadata.name` and `metadata.namespace` fields are
	// set from the user-supplied instance name and namespace.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// The labels allows adding `metadata.labels` to all resources.
	metadata: labels: timoniv1.#Labels & {
		"app.kubernetes.io/part-of": *"helmforge" | string
	}
	if commonLabels != _|_ {
		for k, v in commonLabels {
			metadata: labels: (k): v
		}
	}

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}
	selector: labels: "app.kubernetes.io/component": "discourse"

	// Overrides
	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels: *{...} | {[string]: string}

	// Number of Discourse replicas. Supported only as singleton (1).
	replicaCount: *1 | 1

	// Container image configuration
	image!: timoniv1.#Image
	image: digest: string & !=""
	imagePullSecrets: *[] | [...corev1.#LocalObjectReference]

	// Discourse application configuration
	discourse: {
		hostname:          *"discourse.localhost" | (string & !="")
		developerEmails:   *"admin@example.com" | string
		secretKeyBase:     *"" | string
		existingSecret:    *"" | string
		existingSecretKey: *"secret-key-base" | string
		skipEmailSetup:    *true | bool
		unicornWorkers:    *2 | int & >0
		unicornSidekiqs:   *1 | int & >=0
		extraEnv: *[] | [...corev1.#EnvVar]
		extraEnvFrom: *[] | [...corev1.#EnvFromSource]
	}

	// Database configuration
	database: {
		mode: *"postgresql" | "external"
		external: {
			host:                      *"" | string
			port:                      *5432 | int & >0 & <=65535
			name:                      *"discourse" | string
			username:                  *"discourse" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"database-password" | string
		}
	}

	// PostgreSQL subchart deployment
	postgresql: {
		enabled:      *true | bool
		architecture: *"standalone" | string
		image: timoniv1.#Image & {
			repository: *"docker.io/pgvector/pgvector" | string
			tag:        *"0.8.7-pg18-trixie@sha256:5895949dfcdf308eb0cd31c950c93c14895c77f33fbedfecf1fa511ab1d4bcd2" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | string
		}
		podSecurityContext: corev1.#PodSecurityContext & {
			fsGroup:             *999 | int
			fsGroupChangePolicy: *"OnRootMismatch" | string
			seccompProfile: type: *corev1.#SeccompProfileTypeRuntimeDefault | corev1.#SeccompProfileType
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			capabilities: drop: *[corev1.#Capability("ALL")] | [...corev1.#Capability]
			readOnlyRootFilesystem: *false | bool
			runAsGroup:             *999 | int
			runAsNonRoot:           *true | bool
			runAsUser:              *999 | int
		}
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"100m" | string
				memory: *"256Mi" | string
			}
			limits: {
				cpu:    *"1000m" | string
				memory: *"1Gi" | string
			}
		}
		auth: {
			database:                      *"discourse" | string
			username:                      *"discourse" | string
			password:                      *"" | string
			postgresPassword:              *"" | string
			existingSecret:                *"" | string
			existingSecretUserPasswordKey: *"user-password" | string
		}
		initdb?: scripts?: {[string]: string}
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"8Gi" | string
			}
			resources?: timoniv1.#ResourceRequirements
		}
	}

	// Redis subchart deployment
	redis: {
		enabled:      *true | bool
		architecture: *"standalone" | string
		image: timoniv1.#Image & {
			repository: *"docker.io/library/redis" | string
			tag:        *"8.10.2" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | string
		}
		podSecurityContext: corev1.#PodSecurityContext & {
			fsGroup: *999 | int
			seccompProfile: type: *corev1.#SeccompProfileTypeRuntimeDefault | corev1.#SeccompProfileType
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			capabilities: drop: *[corev1.#Capability("ALL")] | [...corev1.#Capability]
			readOnlyRootFilesystem: *false | bool
			runAsGroup:             *999 | int
			runAsNonRoot:           *true | bool
			runAsUser:              *999 | int
		}
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"50m" | string
				memory: *"128Mi" | string
			}
			limits: {
				cpu:    *"500m" | string
				memory: *"512Mi" | string
			}
		}
		auth: {
			enabled:  *false | bool
			password: *"" | string
		}
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"1Gi" | string
			}
			resources?: timoniv1.#ResourceRequirements
		}
		external: {
			host:                      *"" | string
			port:                      *6379 | int & >0 & <=65535
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"redis-password" | string
		}
	}

	// Persistence for /shared
	persistence: {
		enabled:       *true | bool
		existingClaim: *"" | string
		storageClass:  *"" | string
		accessModes: *["ReadWriteOnce"] | [...string]
		size: *"10Gi" | string
		annotations: *{...} | {[string]: string}
	}

	// Service configuration
	service: {
		type: *"ClusterIP" | corev1.#ServiceType
		port: *80 | int & >0 & <=65535
		annotations?: {[string]: string}
		ipFamilyPolicy: *"" | string
		ipFamilies: *[] | [...string]
	}

	// Gateway API HTTPRoute configuration
	gatewayAPI: {
		enabled:    *false | bool
		apiVersion: *"gateway.networking.k8s.io/v1" | string
		annotations?: {[string]: string}
		parentRefs: *[] | [...]
		hostnames: *[] | [...string]
		matches: *[{
			path: {
				type:  *"PathPrefix" | string
				value: *"/" | string
			}
		}] | [...]
	}

	// ServiceAccount configuration
	serviceAccount: {
		create: *true | bool
		name:   *"" | string
		annotations?: {[string]: string}
		automountServiceAccountToken: *false | bool
	}

	// Pod security context
	podSecurityContext: corev1.#PodSecurityContext & {
		fsGroup:             *1000 | int
		fsGroupChangePolicy: *"OnRootMismatch" | string
	}

	// Container security context
	securityContext: corev1.#SecurityContext & {
		runAsUser:                *0 | 0
		runAsNonRoot:             *false | false
		readOnlyRootFilesystem:   *false | false
		allowPrivilegeEscalation: *false | bool
		capabilities: {
			drop: *["ALL"] | [...string]
			add: *["CHOWN", "DAC_OVERRIDE", "FOWNER", "NET_BIND_SERVICE", "SETGID", "SETUID"] | [...string]
		}
	}

	// WaitForServices init container
	waitForServices: {
		image!: timoniv1.#Image
		securityContext: corev1.#SecurityContext & {
			runAsUser:                *65534 | int
			runAsGroup:               *65534 | int
			runAsNonRoot:             *true | bool
			readOnlyRootFilesystem:   *true | bool
			allowPrivilegeEscalation: *false | bool
			capabilities: drop: *["ALL"] | [...string]
		}
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"5m" | timoniv1.#CPUQuantity
				memory: *"8Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"50m" | timoniv1.#CPUQuantity
				memory: *"32Mi" | timoniv1.#MemoryQuantity
			}
		}
	}

	// Probes
	startupProbe: {
		enabled:          *true | bool
		path:             *"/srv/status" | string
		periodSeconds:    *10 | int & >0
		timeoutSeconds:   *5 | int & >0
		failureThreshold: *60 | int & >0
	}

	livenessProbe: {
		enabled:          *true | bool
		path:             *"/srv/status" | string
		periodSeconds:    *20 | int & >0
		timeoutSeconds:   *5 | int & >0
		failureThreshold: *6 | int & >0
	}

	readinessProbe: {
		enabled:          *true | bool
		path:             *"/srv/status" | string
		periodSeconds:    *10 | int & >0
		timeoutSeconds:   *5 | int & >0
		failureThreshold: *6 | int & >0
	}

	// Resource requests and limits
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"250m" | timoniv1.#CPUQuantity
			memory: *"1Gi" | timoniv1.#MemoryQuantity
		}
		limits: {
			cpu:    *"2000m" | timoniv1.#CPUQuantity
			memory: *"3Gi" | timoniv1.#MemoryQuantity
		}
	}

	terminationGracePeriodSeconds: *120 | int & >=0
	progressDeadlineSeconds:       *1800 | int & >0
	podLabels: *{...} | {[string]: string}
	podAnnotations: *{...} | {[string]: string}
	priorityClassName: *"" | string
	nodeSelector: *{...} | {[string]: string}
	tolerations: *[] | [...corev1.#Toleration]
	affinity: *{...} | corev1.#Affinity
	topologySpreadConstraints: *[] | [...corev1.#TopologySpreadConstraint]
	extraVolumes: *[] | [...corev1.#Volume]
	extraVolumeMounts: *[] | [...corev1.#VolumeMount]
	extraManifests: *[] | [...]

	// ExternalSecrets configuration
	externalSecrets: {
		enabled:         *false | bool
		apiVersion:      *"external-secrets.io/v1" | string
		refreshInterval: *"1h" | string
		items?: [...]
	}

	// Global values accepted for parent-chart composition
	global: *{...} | {[string]: _}

	// Validation constraints
	if database.mode == "postgresql" {
		postgresql: enabled: true
	}
	if database.mode == "external" {
		postgresql: enabled: false
		database: external: host: string & !=""
	}
	if !redis.enabled {
		redis: external: host: string & !=""
	}
	if gatewayAPI.enabled {
		gatewayAPI: parentRefs: [_, ...]
	}
	if !persistence.enabled {
		persistence: existingClaim: string & !=""
	}

	// Helper fields
	#fullname: string
	if fullnameOverride != "" {
		#fullname: fullnameOverride
	}
	if fullnameOverride == "" {
		#fullname: metadata.name
	}

	#secretKeyBaseValue: string
	if discourse.secretKeyBase != "" {
		#secretKeyBaseValue: discourse.secretKeyBase
	}
	if discourse.secretKeyBase == "" {
		#secretKeyBaseValue: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
	}

	#sharedClaimName: string
	if persistence.existingClaim != "" {
		#sharedClaimName: persistence.existingClaim
	}
	if persistence.existingClaim == "" {
		#sharedClaimName: "\(#fullname)-shared"
	}

	#secretName: string
	if discourse.existingSecret != "" {
		#secretName: discourse.existingSecret
	}
	if discourse.existingSecret == "" {
		#secretName: "\(#fullname)-app"
	}

	#secretKey: string
	if discourse.existingSecret != "" {
		#secretKey: discourse.existingSecretKey
	}
	if discourse.existingSecret == "" {
		#secretKey: "secret-key-base"
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

	#dbHost: string
	if database.mode == "external" {
		#dbHost: database.external.host
	}
	if database.mode == "postgresql" {
		#dbHost: "\(#fullname)-postgresql"
	}

	#dbPort: int
	if database.mode == "external" {
		#dbPort: database.external.port
	}
	if database.mode == "postgresql" {
		#dbPort: 5432
	}

	#dbName: string
	if database.mode == "external" {
		#dbName: database.external.name
	}
	if database.mode == "postgresql" {
		#dbName: postgresql.auth.database
	}

	#dbUser: string
	if database.mode == "external" {
		#dbUser: database.external.username
	}
	if database.mode == "postgresql" {
		#dbUser: postgresql.auth.username
	}

	#dbSecretName: string
	if database.mode == "external" {
		if database.external.existingSecret != "" {
			#dbSecretName: database.external.existingSecret
		}
		if database.external.existingSecret == "" {
			#dbSecretName: "\(#fullname)-database"
		}
	}
	if database.mode == "postgresql" {
		if postgresql.auth.existingSecret != "" {
			#dbSecretName: postgresql.auth.existingSecret
		}
		if postgresql.auth.existingSecret == "" {
			#dbSecretName: "\(#fullname)-postgresql-auth"
		}
	}

	#dbSecretKey: string
	if database.mode == "external" {
		if database.external.existingSecret != "" {
			#dbSecretKey: database.external.existingSecretPasswordKey
		}
		if database.external.existingSecret == "" {
			#dbSecretKey: "database-password"
		}
	}
	if database.mode == "postgresql" {
		#dbSecretKey: postgresql.auth.existingSecretUserPasswordKey
	}

	#redisHost: string
	if redis.enabled {
		#redisHost: "\(#fullname)-redis-client"
	}
	if !redis.enabled {
		#redisHost: redis.external.host
	}

	#redisPort: int
	if redis.enabled {
		#redisPort: 6379
	}
	if !redis.enabled {
		#redisPort: redis.external.port
	}

	#redisSecretName: string
	if redis.external.existingSecret != "" {
		#redisSecretName: redis.external.existingSecret
	}
	if redis.external.existingSecret == "" {
		#redisSecretName: "\(#fullname)-redis"
	}

	#redisSecretKey: string
	if redis.external.existingSecret != "" {
		#redisSecretKey: redis.external.existingSecretPasswordKey
	}
	if redis.external.existingSecret == "" {
		#redisSecretKey: "redis-password"
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		sa: #ServiceAccount & {#config: config}
		deploy: #Deployment & {#config: config}
		svc: #Service & {#config: config}

		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PersistentVolumeClaim & {#config: config}
		}

		if config.discourse.existingSecret == "" {
			appSecret: #AppSecret & {#config: config}
		}

		if config.database.mode == "external" && config.database.external.existingSecret == "" {
			dbSecret: #DatabaseSecret & {#config: config}
		}

		if !config.redis.enabled && config.redis.external.password != "" && config.redis.external.existingSecret == "" {
			redisSecret: #RedisSecret & {#config: config}
		}

		if config.gatewayAPI.enabled {
			httpRoute: #HTTPRoute & {#config: config}
		}

		if config.externalSecrets.enabled && config.externalSecrets.items != _|_ {
			for i, item in config.externalSecrets.items {
				"ext-secret-\(i)": #ExternalSecret & {
					#config: config
					#item:   item
					#index:  i
				}
			}
		}

		if config.postgresql.enabled {
			if config.postgresql.auth.existingSecret == "" {
				postgresqlAuth: #PostgresqlAuthSecret & {#config: config}
			}
			postgresqlConfig: #PostgresqlConfigMap & {#config: config}
			postgresqlInitdb: #PostgresqlInitdbConfigMap & {#config: config}
			postgresqlHeadless: #PostgresqlHeadlessService & {#config: config}
			postgresqlService: #PostgresqlService & {#config: config}
			postgresqlStatefulSet: #PostgresqlStatefulSet & {#config: config}
		}

		if config.redis.enabled {
			redisConfig: #RedisConfigMap & {#config: config}
			redisHeadless: #RedisHeadlessService & {#config: config}
			redisClient: #RedisClientService & {#config: config}
			redisStatefulSet: #RedisStatefulSet & {#config: config}
		}

		if len(config.extraManifests) > 0 {
			for i, manifest in config.extraManifests {
				"extra-\(i)": manifest
			}
		}
	}
}
