package templates

import (
	"list"
	"strings"

	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#ExtraEnvVar: corev1.#EnvVar & {
	name: string & !~"^(PG|REDIS_|AFFINE_|HF_|OTEL_|NODE_|SERVER_|DEPLOYMENT_)" & !="HOME" & !="DATABASE_URL" & !="LISTEN_ADDR"
}

// Config defines the schema, defaults and validations for the Instance values.
#Config: {
	// The kubeVersion is set at apply-time via timoni.cue by querying the Kubernetes API.
	kubeVersion!: string
	// Enforce minimum Kubernetes version >=1.26.0 matching Helm chart.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.26.0"}

	// The moduleVersion is set from the user-supplied module version or default.
	moduleVersion!: string

	// Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	// Overrides
	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels:     *{...} | {[string]: string}

	// Workload replicas: AFFiNE local storage requires exactly one replica.
	replicaCount: *1 | 1

	// Container images
	image: timoniv1.#Image

	// ServiceAccount settings
	serviceAccount: {
		create:                       *true | bool
		name:                         *"" | string
		annotations:                  *{...} | {[string]: string}
		automountServiceAccountToken: *false | bool
	}

	// Service settings
	service: {
		type:           *"ClusterIP" | string
		port:           *3010 | int & >0 & <=65535
		annotations:    *{...} | {[string]: string}
		ipFamilyPolicy: *"" | string
		ipFamilies:     *[...] | [...string]
	}

	// Gateway API settings
	#HTTPRouteItem: {
		name?:        string
		labels?:      {[string]: string}
		annotations?: {[string]: string}
		parentRefs!:  [...{...}] & [_, ...]
		hostnames?:   [...string]
		rules?: [...{
			matches?: [...]
			filters?: [...]
			backendRefs?: [...]
			omitDefaultBackend: *false | bool
		}]
	}

	gatewayAPI: {
		enabled:          *false | bool
		gatewayClassName: *"" | string
		httpRoutes:       *[...] | [...#HTTPRouteItem]
	}

	// ExternalSecrets settings
	#ExternalSecretItem: {
		name?:             string
		fullnameOverride?: string
		labels?:           {[string]: string}
		annotations?:      {[string]: string}
		spec!: {
			refreshInterval?: string
			secretStoreRef?:  {name!: string, ...}
			target?:          {name?: string, ...}
			...
		}
	}

	externalSecrets: {
		enabled:         *false | bool
		refreshInterval: *"1h" | string
		items:           *[...] | [...#ExternalSecretItem]
	}

	// Probes
	probes: {
		startup: {
			enabled:              *true | bool
			failureThreshold:     *60 | int
			periodSeconds:        *5 | int
			timeoutSeconds:       *5 | int
			initialDelaySeconds?: int
			successThreshold?:    int
		}
		readiness: {
			enabled:              *true | bool
			failureThreshold:     *3 | int
			periodSeconds:        *10 | int
			timeoutSeconds:       *5 | int
			initialDelaySeconds?: int
			successThreshold?:    int
		}
		liveness: {
			enabled:              *true | bool
			failureThreshold:     *3 | int
			periodSeconds:        *20 | int
			timeoutSeconds:       *5 | int
			initialDelaySeconds?: int
			successThreshold?:    int
		}
	}

	// Resources
	resources: corev1.#ResourceRequirements & {
		requests: {
			cpu:    *"500m" | string
			memory: *"1Gi" | string
		}
		limits: {
			cpu:    *"2" | string
			memory: *"3Gi" | string
		}
	}

	// Security contexts
	podSecurityContext: corev1.#PodSecurityContext & {
		runAsNonRoot:        *true | bool
		runAsUser:           *1000 | int
		runAsGroup:          *1000 | int
		fsGroup:             *1000 | int
		fsGroupChangePolicy: *"OnRootMismatch" | string
		seccompProfile: {
			type: *"RuntimeDefault" | string
		}
	}

	securityContext: corev1.#SecurityContext & {
		allowPrivilegeEscalation: *false | bool
		readOnlyRootFilesystem:   *true | bool
		capabilities: drop: *["ALL"] | [...string]
	}

	// Pod scheduling and metadata
	podLabels: *{...} | {
		[=~"^(app\\.kubernetes\\.io/(name|instance))$"]: _|_
		[string]:                                        string
	}
	podAnnotations:            *{...} | {[string]: string}
	nodeSelector:              *{...} | {[string]: string}
	tolerations:               *[...] | [...corev1.#Toleration]
	affinity:                  *{...} | corev1.#Affinity
	topologySpreadConstraints: *[...] | [...corev1.#TopologySpreadConstraint]
	priorityClassName:         *"" | string
	terminationGracePeriodSeconds: *30 | int & >=0
	imagePullSecrets:          *[...] | [...corev1.#LocalObjectReference]

	// Extra environment variables with reserved key protection
	extraEnv: *[...] | [...#ExtraEnvVar]

	// Persistence: must be enabled
	persistence: {
		enabled:       *true | true
		existingClaim: *"" | string
		storageClass:  *"" | string
		size:          *"20Gi" | string
		accessModes:   *["ReadWriteOnce"] | [...string]
		retain:        *true | bool
		annotations:   *{...} | {[string]: string}
	}

	// Runtime temporary size
	runtime: {
		temporarySize: *"1Gi" | string
	}

	// Application server
	server: {
		port:      *3010 | int & >0 & <=65535
		publicUrl: *"" | string
	}

	// Administrator bootstrap
	bootstrap: {
		name:           *"Administrator" | string
		email:          *"admin@example.test" | string
		password:       *"" | string
		existingSecret: *"" | string
		passwordKey:    *"admin-password" | string
	}

	// External PostgreSQL settings
	database: {
		host:           *"" | string
		port:           *5432 | int
		name:           *"affine" | string
		username:       *"affine" | string
		passwordSecret: *"" | string
		passwordKey:    *"password" | string
		tls: {
			enabled:  *true | bool
			caSecret: *"" | string
			caKey:    *"ca.crt" | string
		}
	}

	// External Redis settings
	cache: {
		host:           *"" | string
		port:           *6379 | int
		username:       *"" | string
		passwordSecret: *"" | string
		passwordKey:    *"redis-password" | string
		database:       *0 | int
		tls: {
			enabled:  *true | bool
			caSecret: *"" | string
			caKey:    *"ca.crt" | string
		}
	}

	// Bundled PostgreSQL subchart configuration
	postgresql: {
		enabled: *true | bool
		service: port: *5432 | int
		auth: {
			database:                      *"affine" | string
			username:                      *"affine" | string
			password:                      *"" | string
			postgresPassword:              *"" | string
			existingSecret:                *"" | string
			existingSecretUserPasswordKey: *"user-password" | string
		}
		image: timoniv1.#Image
		initdb: {
			scripts: *{
				"20-affine-vector.sh": """
					#!/bin/bash
					set -euo pipefail
					export PGPASSWORD="${POSTGRES_PASSWORD}"
					psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${APP_DATABASE}" <<'SQL'
					CREATE EXTENSION IF NOT EXISTS vector;
					SQL

					"""
			} | {[string]: string}
		}
		networkPolicy: {
			enabled: *true | bool
			egress: {
				enabled:                      *true | bool
				allowDNS:                     *true | bool
				allowSameNamespacePostgreSQL: *false | bool
				allowHTTPS:                   *false | bool
			}
		}
		podSecurityContext: corev1.#PodSecurityContext & {
			fsGroup:             *999 | int
			fsGroupChangePolicy: *"OnRootMismatch" | string
			seccompProfile: {
				type: *"RuntimeDefault" | string
			}
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *true | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *999 | int
			runAsGroup:               *999 | int
			capabilities: drop: *["ALL"] | [...string]
		}
		resources: corev1.#ResourceRequirements & {
			requests: {
				cpu:    *"250m" | string
				memory: *"512Mi" | string
			}
			limits: {
				cpu:    *"500m" | string
				memory: *"1Gi" | string
			}
		}
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"8Gi" | string
			}
			resources: *postgresql.resources | corev1.#ResourceRequirements
		}
		tls: {
			enabled: *false | bool
		}
		...
	}

	// Bundled Redis subchart configuration
	redis: {
		enabled:      *true | bool
		architecture: *"standalone" | string
		image:        timoniv1.#Image
		serviceAccount: {
			create: *true | bool
			name:   *"" | string
		}
		service: ports: redis: *6379 | int
		auth: {
			enabled:                   *true | bool
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"redis-password" | string
		}
		podSecurityContext: corev1.#PodSecurityContext & {
			fsGroup: *999 | int
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *true | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *999 | int
			runAsGroup:               *999 | int
			capabilities: drop: *["ALL"] | [...string]
			seccompProfile: {
				type: *"RuntimeDefault" | string
			}
		}
		resources: corev1.#ResourceRequirements & {
			requests: {
				cpu:    *"100m" | string
				memory: *"128Mi" | string
			}
			limits: {
				cpu:    *"500m" | string
				memory: *"512Mi" | string
			}
		}
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"5Gi" | string
			}
			resources: *redis.resources | corev1.#ResourceRequirements
		}
		config: redis: *"" | string
		tls: {
			enabled: *false | bool
		}
		networkPolicy: {
			enabled: *true | bool
		}
		...
	}

	// Metrics and observability
	metrics: {
		enabled: *false | bool
		port:    *9464 | int
		serviceMonitor: {
			enabled:       *false | bool
			labels:        *{...} | {[string]: string}
			interval:      *"30s" | string
			scrapeTimeout: *"10s" | string
		}
		prometheusRule: {
			enabled:         *false | bool
			labels:          *{...} | {[string]: string}
			additionalRules: *[...] | [...]
		}
	}

	// --- Validations ---

	// Bootstrap credentials exclusivity
	if bootstrap.password != "" && bootstrap.existingSecret != "" {
		bootstrap: password: _|_ // Bootstrap password and existing Secret are mutually exclusive
	}
	if bootstrap.password != "" {
		bootstrap: password: strings.MinRunes(16) & strings.MaxRunes(32)
	}

	// PostgreSQL CA requires database.tls.enabled
	if database.tls.caSecret != "" && !database.tls.enabled {
		database: tls: caSecret: _|_ // A PostgreSQL CA requires database.tls.enabled
	}

	// PostgreSQL mutually exclusive settings
	if postgresql.enabled {
		if database.host != "" {
			database: host: _|_ // Bundled PostgreSQL and external database settings are mutually exclusive
		}
		if database.passwordSecret != "" {
			database: passwordSecret: _|_ // Bundled PostgreSQL and external database settings are mutually exclusive
		}
		if database.tls.caSecret != "" {
			database: tls: caSecret: _|_ // Bundled PostgreSQL and external database settings are mutually exclusive
		}
		if postgresql.tls.enabled {
			postgresql: tls: enabled: _|_ // Use the validated external PostgreSQL TLS mode for encrypted database connections
		}
	}

	// External PostgreSQL requirements
	if !postgresql.enabled {
		database: {
			host:           string & != ""
			name:           string & != ""
			username:       string & != ""
			passwordSecret: string & != ""
		}
	}

	// Redis CA requires cache.tls.enabled
	if cache.tls.caSecret != "" && !cache.tls.enabled {
		cache: tls: caSecret: _|_ // A Redis CA requires cache.tls.enabled
	}

	// Redis mutually exclusive settings & topology
	if redis.enabled {
		if cache.host != "" {
			cache: host: _|_ // Bundled Redis and external cache settings are mutually exclusive
		}
		if cache.passwordSecret != "" {
			cache: passwordSecret: _|_ // Bundled Redis and external cache settings are mutually exclusive
		}
		if cache.tls.caSecret != "" {
			cache: tls: caSecret: _|_ // Bundled Redis and external cache settings are mutually exclusive
		}
		if redis.tls.enabled {
			redis: tls: enabled: _|_ // Use the validated external Redis TLS mode for encrypted cache connections
		}
		if !redis.auth.enabled {
			redis: auth: enabled: _|_ // AFFiNE Redis requires authentication
		}
		if redis.architecture != "standalone" {
			redis: architecture: _|_ // AFFiNE requires a validated standalone Redis logical-database contract
		}
	}

	// External Redis requirements
	if !redis.enabled {
		cache: {
			host:           string & != ""
			passwordSecret: string & != ""
		}
	}

	// Metrics validations
	if !metrics.enabled {
		if metrics.serviceMonitor.enabled {
			metrics: serviceMonitor: enabled: _|_ // ServiceMonitor and PrometheusRule require metrics.enabled
		}
		if metrics.prometheusRule.enabled {
			metrics: prometheusRule: enabled: _|_ // ServiceMonitor and PrometheusRule require metrics.enabled
		}
	}
	if metrics.enabled {
		if metrics.port == server.port {
			metrics: port: _|_ // Metrics must use a separate private port
		}
	}

	// HTTPRoute unique names validation
	if gatewayAPI.enabled {
		let _computedRouteNames = [for i, r in gatewayAPI.httpRoutes {
			let _n = [
				if r.name != _|_ && r.name != "" {r.name},
				if (r.name == _|_ || r.name == "") && i > 0 {"\(_fullname)-\(i)"},
				if (r.name == _|_ || r.name == "") && i == 0 {_fullname},
			][0]
			_n
		}]
		_uniqueRouteNames: _computedRouteNames & list.UniqueItems()
	}

	// --- Computed helpers ---

	_name: string
	if nameOverride != "" {
		_name: nameOverride
	}
	if nameOverride == "" {
		_name: "affine"
	}

	_fullname: string
	if fullnameOverride != "" {
		_fullname: fullnameOverride
	}
	if fullnameOverride == "" {
		_fullname: "\(metadata.name)-\(_name)"
	}

	_selectorLabels: {
		"app.kubernetes.io/name":     _name
		"app.kubernetes.io/instance": metadata.name
	}

	_labels: {
		_selectorLabels
		"app.kubernetes.io/version":    moduleVersion
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/part-of":    "helmforge"
		for k, v in commonLabels {
			"\(k)": v
		}
	}

	_serviceAccountName: string
	if serviceAccount.create {
		if serviceAccount.name != "" {
			_serviceAccountName: serviceAccount.name
		}
		if serviceAccount.name == "" {
			_serviceAccountName: _fullname
		}
	}
	if !serviceAccount.create {
		if serviceAccount.name != "" {
			_serviceAccountName: serviceAccount.name
		}
		if serviceAccount.name == "" {
			_serviceAccountName: "default"
		}
	}

	_claimName: string
	if persistence.existingClaim != "" {
		_claimName: persistence.existingClaim
	}
	if persistence.existingClaim == "" {
		_claimName: _fullname
	}

	_bootstrapSecretName: string
	if bootstrap.existingSecret != "" {
		_bootstrapSecretName: bootstrap.existingSecret
	}
	if bootstrap.existingSecret == "" {
		_bootstrapSecretName: "\(_fullname)-bootstrap"
	}

	_bootstrapPassword: string
	if bootstrap.password != "" {
		_bootstrapPassword: bootstrap.password
	}
	if bootstrap.password == "" {
		_bootstrapPassword: "affineAdminInitialPassword32Char"
	}

	_bootstrapConfigMapName: "\(_fullname)-bootstrap"

	_publicUrl: string
	if server.publicUrl != "" {
		_publicUrl: server.publicUrl
	}
	if server.publicUrl == "" {
		_publicUrl: "http://\(_fullname).\(metadata.namespace).svc:\(service.port)"
	}

	// Dependency connections
	_databaseHost: string
	if postgresql.enabled {
		_databaseHost: "\(metadata.name)-postgresql"
	}
	if !postgresql.enabled {
		_databaseHost: database.host
	}

	_databasePort: int
	if postgresql.enabled {
		_databasePort: postgresql.service.port
	}
	if !postgresql.enabled {
		_databasePort: database.port
	}

	_databaseName: string
	if postgresql.enabled {
		_databaseName: postgresql.auth.database
	}
	if !postgresql.enabled {
		_databaseName: database.name
	}

	_databaseUsername: string
	if postgresql.enabled {
		_databaseUsername: postgresql.auth.username
	}
	if !postgresql.enabled {
		_databaseUsername: database.username
	}

	_databasePasswordSecret: string
	if postgresql.enabled {
		if postgresql.auth.existingSecret != "" {
			_databasePasswordSecret: postgresql.auth.existingSecret
		}
		if postgresql.auth.existingSecret == "" {
			_databasePasswordSecret: "\(metadata.name)-postgresql-auth"
		}
	}
	if !postgresql.enabled {
		_databasePasswordSecret: database.passwordSecret
	}

	_databasePasswordKey: string
	if postgresql.enabled {
		_databasePasswordKey: postgresql.auth.existingSecretUserPasswordKey
	}
	if !postgresql.enabled {
		_databasePasswordKey: database.passwordKey
	}

	_cacheHost: string
	if redis.enabled {
		_cacheHost: "\(metadata.name)-redis-client"
	}
	if !redis.enabled {
		_cacheHost: cache.host
	}

	_cachePort: int
	if redis.enabled {
		_cachePort: redis.service.ports.redis
	}
	if !redis.enabled {
		_cachePort: cache.port
	}

	_cachePasswordSecret: string
	if redis.enabled {
		if redis.auth.existingSecret != "" {
			_cachePasswordSecret: redis.auth.existingSecret
		}
		if redis.auth.existingSecret == "" {
			_cachePasswordSecret: "\(metadata.name)-redis-auth"
		}
	}
	if !redis.enabled {
		_cachePasswordSecret: cache.passwordSecret
	}

	_postgresLabels: {
		"helm.sh/chart":                "postgresql-2.0.5"
		"app.kubernetes.io/name":       "postgresql"
		"app.kubernetes.io/instance":   metadata.name
		"app.kubernetes.io/version":    "18.6"
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/part-of":    "helmforge"
		for k, v in commonLabels {
			"\(k)": v
		}
	}

	_postgresSelectorLabels: {
		"app.kubernetes.io/name":      "postgresql"
		"app.kubernetes.io/instance":  metadata.name
		"app.kubernetes.io/component": "postgresql"
		"app.kubernetes.io/part-of":   "postgresql"
		"app.kubernetes.io/role":      "standalone"
	}


	_postgresPassword: string
	if postgresql.auth.postgresPassword != "" {
		_postgresPassword: postgresql.auth.postgresPassword
	}
	if postgresql.auth.postgresPassword == "" {
		_postgresPassword: "nvBgYE9BOhgY4vdd0CJMElD7qijETkcb"
	}

	_userPassword: string
	if postgresql.auth.password != "" {
		_userPassword: postgresql.auth.password
	}
	if postgresql.auth.password == "" {
		_userPassword: "nxwFIyxzXJSVbLsswruP9yz0BsNISb3"
	}

	_redisLabels: {
		"helm.sh/chart":                "redis-3.0.0"
		"app.kubernetes.io/name":       "redis"
		"app.kubernetes.io/instance":   metadata.name
		"app.kubernetes.io/version":    "8.10.1"
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/part-of":    "helmforge"
		for k, v in commonLabels {
			"\(k)": v
		}
	}

	_redisSelectorLabels: {
		"app.kubernetes.io/name":      "redis"
		"app.kubernetes.io/instance":  metadata.name
		"app.kubernetes.io/component": "redis"
		"app.kubernetes.io/part-of":   "redis"
		"app.kubernetes.io/role":      "standalone"
	}


	_redisPassword: string
	if redis.auth.password != "" {
		_redisPassword: redis.auth.password
	}
	if redis.auth.password == "" {
		_redisPassword: "7mFGdjTVnvZ56WFgTOWkkyiF0rMALGNg"
	}

	_cachePasswordKey: string
	if redis.enabled {
		_cachePasswordKey: redis.auth.existingSecretPasswordKey
	}
	if !redis.enabled {
		_cachePasswordKey: cache.passwordKey
	}

	_environment: [
		{name: "HOME", value: "/home/node"},
		{name: "HF_POSTGRES_TLS", value: "\( !postgresql.enabled && database.tls.enabled )"},
		{name: "HF_REDIS_TLS", value: "\( !redis.enabled && cache.tls.enabled )"},
		{name: "HF_METRICS_ENABLED", value: "\( metrics.enabled )"},
		{name: "OTEL_EXPORTER_PROMETHEUS_HOST", value: "0.0.0.0"},
		{name: "OTEL_EXPORTER_PROMETHEUS_PORT", value: "\( metrics.port )"},
		if !postgresql.enabled && database.tls.caSecret != "" {
			name:  "HF_POSTGRES_CA"
			value: "/postgres-tls/ca.crt"
		},
		if !redis.enabled && cache.tls.caSecret != "" {
			name:  "HF_REDIS_CA"
			value: "/redis-tls/ca.crt"
		},
		{name: "XDG_CACHE_HOME", value: "/tmp/cache"},
		{name: "AFFINE_SERVER_PORT", value: "\( server.port )"},
		{name: "AFFINE_SERVER_EXTERNAL_URL", value: _publicUrl},
		{name: "PGHOST", value: _databaseHost},
		{name: "PGPORT", value: "\( _databasePort )"},
		{name: "PGDATABASE", value: _databaseName},
		{name: "PGUSER", value: _databaseUsername},
		{
			name: "PGPASSWORD"
			valueFrom: secretKeyRef: {
				name: _databasePasswordSecret
				key:  _databasePasswordKey
			}
		},
		{name: "REDIS_SERVER_HOST", value: _cacheHost},
		{name: "REDIS_SERVER_PORT", value: "\( _cachePort )"},
		{name: "REDIS_SERVER_DATABASE", value: "\( cache.database )"},
		{name: "REDIS_SERVER_USERNAME", value: cache.username},
		{
			name: "REDIS_SERVER_PASSWORD"
			valueFrom: secretKeyRef: {
				name: _cachePasswordSecret
				key:  _cachePasswordKey
			}
		},
		for envVar in extraEnv {envVar},
	]

	_mounts: [
		{name: "workspace", mountPath: "/home/node/.affine"},
		{name: "tmp", mountPath: "/tmp"},
		{name: "generated-schema", mountPath: "/app/src"},
		if !postgresql.enabled && database.tls.caSecret != "" {
			name:      "postgres-ca"
			mountPath: "/postgres-tls"
			readOnly:  true
		},
		if !redis.enabled && cache.tls.caSecret != "" {
			name:      "redis-ca"
			mountPath: "/redis-tls"
			readOnly:  true
		},
		{name: "bootstrap-script", mountPath: "/helmforge", readOnly: true},
	]
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		deploy: #Deployment & {#config: config}
		cm:     #ConfigMap & {#config: config}
		svc:    #Service & {#config: config}

		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		if config.bootstrap.existingSecret == "" {
			secret: #BootstrapSecret & {#config: config}
		}
		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PersistentVolumeClaim & {#config: config}
		}
		if config.gatewayAPI.enabled {
			for idx, route in config.gatewayAPI.httpRoutes {
				"httproute_\(idx)": #HTTPRoute & {#config: config, #route: route, #index: idx}
			}
		}
		if config.externalSecrets.enabled {
			for idx, item in config.externalSecrets.items {
				"externalsecret_\(idx)": #ExternalSecret & {#config: config, #item: item}
			}
		}
		if config.metrics.enabled {
			svcMetrics: #MetricsService & {#config: config}
			if config.metrics.serviceMonitor.enabled {
				sm: #ServiceMonitor & {#config: config}
			}
			if config.metrics.prometheusRule.enabled {
				pr: #PrometheusRule & {#config: config}
			}
		}

		if config.postgresql.enabled {
			if config.postgresql.networkPolicy.enabled {
				pgNetpol: #PostgresNetworkPolicy & {#config: config}
			}
			if config.postgresql.auth.existingSecret == "" {
				pgSecret: #PostgresSecret & {#config: config}
			}
			pgConfigMap:       #PostgresConfigMap & {#config: config}
			pgInitdbConfigMap: #PostgresInitdbConfigMap & {#config: config}
			pgHeadlessSvc:     #PostgresHeadlessService & {#config: config}
			pgSvc:             #PostgresService & {#config: config}
			pgStatefulSet:     #PostgresStatefulSet & {#config: config}
		}

		if config.redis.enabled {
			if config.redis.networkPolicy.enabled {
				redisNetpol: #RedisNetworkPolicy & {#config: config}
			}
			if config.redis.serviceAccount.create {
				redisSa: #RedisServiceAccount & {#config: config}
			}
			if config.redis.auth.existingSecret == "" {
				redisSecret: #RedisSecret & {#config: config}
			}
			redisConfigMap:   #RedisConfigMap & {#config: config}
			redisHeadlessSvc: #RedisHeadlessService & {#config: config}
			redisClientSvc:   #RedisClientService & {#config: config}
			redisStatefulSet: #RedisStatefulSet & {#config: config}
		}
	}
}
