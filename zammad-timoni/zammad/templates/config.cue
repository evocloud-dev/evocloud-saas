package templates

import (
	"list"
	"strings"

	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: string
	// Using the kubeVersion you can enforce a minimum Kubernetes minor version.
	// By default, the minimum Kubernetes version is set to 1.20.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	// The moduleVersion is set from the user-supplied module version.
	// This field is used for the `app.kubernetes.io/version` label.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	// The `metadata.name` and `metadata.namespace` fields are
	// set from the user-supplied instance name and namespace.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// The labels allows adding `metadata.labels` to all resources.
	// The `app.kubernetes.io/name` and `app.kubernetes.io/version` labels
	// are automatically generated and can't be overwritten.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// -------------------------------------------------------------------------
	// Image
	// -------------------------------------------------------------------------
	image: {
		repository: string
		tag:        string
		digest:     string | *""
		pullPolicy: "IfNotPresent" | "Always" | "Never"

		// Computed image reference used by all containers.
		reference: string
		if digest != "" {
			reference: "\(repository)@\(digest)"
		}
		if digest == "" && tag != "" {
			reference: "\(repository):\(tag)"
		}
		if digest == "" && tag == "" {
			reference: repository
		}

		imagePullSecrets?: [...corev1.#LocalObjectReference]
	}

	// -------------------------------------------------------------------------
	// Service
	// -------------------------------------------------------------------------
	service: {
		type:        string | *"ClusterIP"
		port:        int | *8080
		appProtocol: string | *"kubernetes.io/ws"
	}

	// -------------------------------------------------------------------------
	// Ingress
	// -------------------------------------------------------------------------
	ingress: {
		enabled:   bool | *false
		className: string | *""
		annotations?: {[string]: string}
		labels?: {[string]: string}
		hosts: [...{
			host: string
			paths: [...{
				path:     string
				pathType: string | *""
			}]
		}]
		tls: [...{
			secretName: string
			hosts: [...string]
		}]
	}

	// -------------------------------------------------------------------------
	// Secrets config
	// -------------------------------------------------------------------------
	secrets: {
		autowizard: {
			useExisting: bool | *false
			secretKey:   string | *"autowizard"
			secretName:  string | *"autowizard"
		}
		elasticsearch: {
			useExisting: bool | *false
			secretKey:   string | *"password"
			secretName:  string | *"elastic-credentials"
		}
		postgresql: {
			useExisting: bool | *false
			secretKey:   string | *"postgresql-pass"
			secretName:  string | *"postgresql-pass"
		}
		redis: {
			useExisting: bool | *false
			secretKey:   string | *"redis-password"
			secretName:  string | *"redis-pass"
			sentinel: {
				useExisting: bool | *false
				secretKey:   string | *"redis-sentinel-password"
				secretName:  string | *"redis-sentinel-pass"
			}
		}
		s3: {
			useExisting: bool | *false
			secretKey:   string | *"s3-url"
			secretName:  string | *"s3-url"
		}
	}

	// -------------------------------------------------------------------------
	// Pod-level security context (applied to all Zammad pods)
	// -------------------------------------------------------------------------
	securityContext: {
		fsGroup:             int | *1000
		fsGroupChangePolicy: string | *"Always"
		runAsUser:           int | *1000
		runAsNonRoot:        bool | *true
		runAsGroup:          int | *1000
		seccompProfile?: corev1.#SeccompProfile
	}

	// -------------------------------------------------------------------------
	// Zammad-specific application configuration
	// -------------------------------------------------------------------------
	zammadConfig: {
		elasticsearch: {
			enabled:        bool | *true
			host:           string | *"zammad-elasticsearch-master"
			initialisation: bool | *true
			pass:           string | *""
			port:           int | *9200
			reindex:        bool | *false
			schema:         string | *"http"
			user:           string | *""
		}

		memcached: {
			enabled: bool | *true
			host:    string | *"zammad-memcached"
			port:    int | *11211
		}

		minio: {
			enabled:      bool | *false
			externalS3Url?: string
		}

		nginx: {
			replicas:              int | *1
			trustedProxies:        [...string]
			extraHeaders:          [...string]
			websocketExtraHeaders: [...string]
			clientMaxBodySize:     string | *"50M"
			knowledgeBaseUrl:      string | *""
			listenIpv4:            bool | *true
			listenIpv6:            bool | *true
			startupProbe?:         corev1.#Probe
			livenessProbe?:        corev1.#Probe
			readinessProbe?:       corev1.#Probe
			resources?:            corev1.#ResourceRequirements
			securityContext?:      corev1.#SecurityContext
			sidecars?:             [...corev1.#Container]
			extraEnv?:             [...corev1.#EnvVar]
			podLabels?:            {[string]: string}
			podAnnotations?:       {[string]: string}
			nodeSelector?:         {[string]: string}
			tolerations?:          [...corev1.#Toleration]
			affinity?:             corev1.#Affinity
			topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
		}

		postgresql: {
			enabled: bool | *true
			db:      string | *"zammad_production"
			host:    string | *"zammad-postgresql"
			pass:    string | *"zammad"
			port:    int | *5432
			user:    string | *"zammad"
			options: string | *"pool=50"
		}

		railsserver: {
			replicas:              int | *1
			startupProbe?:         corev1.#Probe
			livenessProbe?:        corev1.#Probe
			readinessProbe?:       corev1.#Probe
			resources?:            corev1.#ResourceRequirements
			securityContext?:      corev1.#SecurityContext
			sidecars?:             [...corev1.#Container]
			trustedProxies:        string | *"['127.0.0.1', '::1']"
			listenAddress:         string | *"[::]"
			webConcurrency:        int | *0
			extraEnv?:             [...corev1.#EnvVar]
			tmpdir:                string | *"/opt/zammad/tmp"
			podLabels?:            {[string]: string}
			podAnnotations?:       {[string]: string}
			nodeSelector?:         {[string]: string}
			tolerations?:          [...corev1.#Toleration]
			affinity?:             corev1.#Affinity
			topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
		}

		redis: {
			enabled:  bool | *true
			host:     string | *"zammad-redis-master"
			port:     int | *6379
			username: string | *""
			pass:     string | *"zammad"
			tls:      bool | *false
			sentinel: {
				enabled:    bool | *false
				sentinels:  [...string]
				masterName: string | *"mymaster"
				username:   string | *""
				pass:       string | *"zammad"
			}
		}

		scheduler: {
			resources?:            corev1.#ResourceRequirements
			securityContext?:      corev1.#SecurityContext
			sidecars?:             [...corev1.#Container]
			extraEnv?:             [...corev1.#EnvVar]
			podLabels?:            {[string]: string}
			podAnnotations?:       {[string]: string}
			nodeSelector?:         {[string]: string}
			tolerations?:          [...corev1.#Toleration]
			affinity?:             corev1.#Affinity
			topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
		}

		storageVolume: {
			enabled:        bool | *false
			existingClaim?: string
		}

		tmpDirVolume: {
			emptyDir: {
				sizeLimit: string | *"100Mi"
				medium?:   string
			}
		}

		customVolumes?:      [...corev1.#Volume]
		customVolumeMounts?: [...corev1.#VolumeMount]

		websocket: {
			startupProbe?:    corev1.#Probe
			livenessProbe?:   corev1.#Probe
			readinessProbe?:  corev1.#Probe
			resources?:       corev1.#ResourceRequirements
			securityContext?: corev1.#SecurityContext
			listenAddress:    string | *"::"
			sidecars?:        [...corev1.#Container]
			extraEnv?:        [...corev1.#EnvVar]
			podLabels?:       {[string]: string}
			podAnnotations?:  {[string]: string}
			nodeSelector?:    {[string]: string}
			tolerations?:     [...corev1.#Toleration]
			affinity?:        corev1.#Affinity
			topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
		}

		initContainers: {
			elasticsearch: {
				resources?:       corev1.#ResourceRequirements
				securityContext?: corev1.#SecurityContext
			}
			postgresql: {
				resources?:       corev1.#ResourceRequirements
				securityContext?: corev1.#SecurityContext
			}
			volumePermissions: {
				enabled: bool | *true
				image: {
					repository: string | *"alpine"
					tag:        string | *"3.23.4"
					pullPolicy: string | *"IfNotPresent"
				}
				command:          [...string]
				resources?:       corev1.#ResourceRequirements
				securityContext?: corev1.#SecurityContext
			}
			zammad: {
				resources?:       corev1.#ResourceRequirements
				securityContext?: corev1.#SecurityContext
				customInit:       string | *""
			}
		}

		initJob: {
			randomName:              bool | *true
			ttlSecondsAfterFinished: int | *300
			annotations:             {[string]: string} | *{}
			podLabels:               {[string]: string} | *{}
			podAnnotations:          {[string]: string} | *{}
			podSpec:                 {} | *{}
			nodeSelector?:           {[string]: string}
			tolerations?:            [...corev1.#Toleration]
			affinity?:               corev1.#Affinity
			topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
		}

		cronJob: {
			reindex: {
				schedule:       string | *"@weekly"
				suspend:        bool | *true
				annotations:    {[string]: string} | *{}
				podLabels:      {[string]: string} | *{}
				podAnnotations: {[string]: string} | *{}
				podSpec:        {} | *{}
			}
		}
	}

	extraEnv: [...corev1.#EnvVar] | *[]
	replicas: int | *1

	// Resource requirements for the scaffold generic deployment container.
	resources?: corev1.#ResourceRequirements

	// Pod-level security context for the scaffold generic deployment/test job.
	podSecurityContext?: corev1.#PodSecurityContext

	// Test job configuration (used by timoni.cue conditional apply).
	test: {
		enabled: bool | *false
		image: {
			repository: string | *"docker.io/curlimages/curl"
			tag:        string | *"latest"
			digest:     string | *""
			pullPolicy: "IfNotPresent" | "Always" | "Never" | *"IfNotPresent"

			// Computed reference for the test job curl container.
			reference: string
			if digest != "" {
				reference: "\(repository)@\(digest)"
			}
			if digest == "" && tag != "" {
				reference: "\(repository):\(tag)"
			}
			if digest == "" && tag == "" {
				reference: repository
			}
		}
	}
	autoWizard: {
		enabled: bool | *true
		config:  string | *""
	}
	affinity?:     corev1.#Affinity
	nodeSelector?: {[string]: string}
	tolerations?:  [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]

	commonAnnotations: {[string]: string} | *{}
	commonLabels:      {[string]: string} | *{}
	podAnnotations:    {[string]: string} | *{}
	podLabels:         {[string]: string} | *{}

	serviceAccount: {
		create:      bool | *false
		annotations: {[string]: string} | *{}
		name:        string | *""
	}

	initContainers:    [...corev1.#Container] | *[]
	imagePullSecrets:  [...corev1.#LocalObjectReference] | *[]

	// -------------------------------------------------------------------------
	// Dependency chart config (1:1 parity with values.yaml lines 689–839)
	// These are Helm subchart configurations. In Timoni, deploy dependencies
	// as separate modules. Fields use open structs for full schema flexibility.
	// -------------------------------------------------------------------------
	elasticsearch: {
		image: {
			registry:   string | *"docker.io"
			repository: string | *"bitnamilegacy/elasticsearch"
			tag:        string | *"8.18.0-debian-12-r2"
			digest:     string | *""
			pullPolicy: string | *"IfNotPresent"
		}
		[string]: _
	}
	memcached?:     {[string]: _}
	minio: {
		image: {
			registry:   string | *"docker.io"
			repository: string | *"bitnamilegacy/minio"
			tag:        string | *"2025.7.23-debian-12-r5"
			digest:     string | *""
			pullPolicy: string | *"IfNotPresent"
		}
		auth: {
			rootUser:       string | *"zammadadmin"
			rootPassword:   string | *"zammadadmin"
			existingSecret: string | *""
		}
		persistence: {
			enabled: bool | *false
			size:    string | *"10Gi"
		}
		[string]: _
	}
	postgresql?:    {[string]: _}
	redis: {
		image: {
			registry:   string | *"docker.io"
			repository: string | *"valkey/valkey"
			tag:        string | *"9.1.0-alpine"
			digest:     string | *""
			pullPolicy: string | *"Always"
		}
		[string]: _
	}

	// -------------------------------------------------------------------------
	// Computed helper: secret name resolution
	// -------------------------------------------------------------------------
	_autowizardSecretName: string
	if secrets.autowizard.useExisting {
		_autowizardSecretName: secrets.autowizard.secretName
	}
	if !secrets.autowizard.useExisting {
		_autowizardSecretName: "\(metadata.name)-autowizard"
	}

	_elasticsearchSecretName: string
	if secrets.elasticsearch.useExisting {
		_elasticsearchSecretName: secrets.elasticsearch.secretName
	}
	if !secrets.elasticsearch.useExisting {
		_elasticsearchSecretName: "\(metadata.name)-elasticsearch"
	}

	_postgresqlSecretName: string
	if secrets.postgresql.useExisting {
		_postgresqlSecretName: secrets.postgresql.secretName
	}
	if !secrets.postgresql.useExisting {
		_postgresqlSecretName: "\(metadata.name)-postgresql"
	}

	_redisSecretName: string
	if secrets.redis.useExisting {
		_redisSecretName: secrets.redis.secretName
	}
	if !secrets.redis.useExisting {
		_redisSecretName: "\(metadata.name)-redis"
	}

	_redisSentinelSecretName: string
	if secrets.redis.sentinel.useExisting {
		_redisSentinelSecretName: secrets.redis.sentinel.secretName
	}
	if !secrets.redis.sentinel.useExisting {
		_redisSentinelSecretName: "\(metadata.name)-redis-sentinel"
	}

	_redisImageRef: string
	if redis.image.digest != "" {
		if redis.image.registry != "" && !strings.HasPrefix(redis.image.repository, redis.image.registry) {
			_redisImageRef: "\(redis.image.registry)/\(redis.image.repository):\(redis.image.tag)@\(redis.image.digest)"
		}
		if redis.image.registry == "" || strings.HasPrefix(redis.image.repository, redis.image.registry) {
			_redisImageRef: "\(redis.image.repository):\(redis.image.tag)@\(redis.image.digest)"
		}
	}
	if redis.image.digest == "" {
		if redis.image.registry != "" && !strings.HasPrefix(redis.image.repository, redis.image.registry) {
			_redisImageRef: "\(redis.image.registry)/\(redis.image.repository):\(redis.image.tag)"
		}
		if redis.image.registry == "" || strings.HasPrefix(redis.image.repository, redis.image.registry) {
			_redisImageRef: "\(redis.image.repository):\(redis.image.tag)"
		}
	}

	_minioImageRef: string
	if minio.image.digest != "" {
		if minio.image.registry != "" && !strings.HasPrefix(minio.image.repository, minio.image.registry) {
			_minioImageRef: "\(minio.image.registry)/\(minio.image.repository):\(minio.image.tag)@\(minio.image.digest)"
		}
		if minio.image.registry == "" || strings.HasPrefix(minio.image.repository, minio.image.registry) {
			_minioImageRef: "\(minio.image.repository):\(minio.image.tag)@\(minio.image.digest)"
		}
	}
	if minio.image.digest == "" {
		if minio.image.registry != "" && !strings.HasPrefix(minio.image.repository, minio.image.registry) {
			_minioImageRef: "\(minio.image.registry)/\(minio.image.repository):\(minio.image.tag)"
		}
		if minio.image.registry == "" || strings.HasPrefix(minio.image.repository, minio.image.registry) {
			_minioImageRef: "\(minio.image.repository):\(minio.image.tag)"
		}
	}

	_elasticsearchImageRef: string
	if elasticsearch.image.digest != "" {
		if elasticsearch.image.registry != "" && !strings.HasPrefix(elasticsearch.image.repository, elasticsearch.image.registry) {
			_elasticsearchImageRef: "\(elasticsearch.image.registry)/\(elasticsearch.image.repository)@\(elasticsearch.image.digest)"
		}
		if elasticsearch.image.registry == "" || strings.HasPrefix(elasticsearch.image.repository, elasticsearch.image.registry) {
			_elasticsearchImageRef: "\(elasticsearch.image.repository)@\(elasticsearch.image.digest)"
		}
	}
	if elasticsearch.image.digest == "" {
		if strings.Contains(elasticsearch.image.repository, ":") {
			if elasticsearch.image.registry != "" && !strings.HasPrefix(elasticsearch.image.repository, elasticsearch.image.registry) {
				_elasticsearchImageRef: "\(elasticsearch.image.registry)/\(elasticsearch.image.repository)"
			}
			if elasticsearch.image.registry == "" || strings.HasPrefix(elasticsearch.image.repository, elasticsearch.image.registry) {
				_elasticsearchImageRef: elasticsearch.image.repository
			}
		}
		if !strings.Contains(elasticsearch.image.repository, ":") {
			if elasticsearch.image.registry != "" && !strings.HasPrefix(elasticsearch.image.repository, elasticsearch.image.registry) {
				_elasticsearchImageRef: "\(elasticsearch.image.registry)/\(elasticsearch.image.repository):\(elasticsearch.image.tag)"
			}
			if elasticsearch.image.registry == "" || strings.HasPrefix(elasticsearch.image.repository, elasticsearch.image.registry) {
				_elasticsearchImageRef: "\(elasticsearch.image.repository):\(elasticsearch.image.tag)"
			}
		}
	}

	_minioSecretName: string
	if minio.auth.existingSecret != "" {
		_minioSecretName: minio.auth.existingSecret
	}
	if minio.auth.existingSecret == "" {
		_minioSecretName: "\(metadata.name)-minio"
	}

	// -------------------------------------------------------------------------
	// Computed helper: Elasticsearch host
	// -------------------------------------------------------------------------
	_elasticsearchHost: string
	if zammadConfig.elasticsearch.enabled {
		_elasticsearchHost: "\(metadata.name)-elasticsearch"
	}
	if !zammadConfig.elasticsearch.enabled {
		_elasticsearchHost: zammadConfig.elasticsearch.host
	}

	// -------------------------------------------------------------------------
	// Computed helper: Redis URL
	// -------------------------------------------------------------------------
	_redisSchema: string
	if zammadConfig.redis.tls {
		_redisSchema: "rediss"
	}
	if !zammadConfig.redis.tls {
		_redisSchema: "redis"
	}

	_redisAuth: string
	if zammadConfig.redis.username != "" && (zammadConfig.redis.pass != "" || secrets.redis.useExisting) {
		_redisAuth: "\(zammadConfig.redis.username):\(zammadConfig.redis.pass)@"
	}
	if zammadConfig.redis.username == "" && (zammadConfig.redis.pass != "" || secrets.redis.useExisting) {
		_redisAuth: ":\(zammadConfig.redis.pass)@"
	}
	if zammadConfig.redis.username == "" && zammadConfig.redis.pass == "" && !secrets.redis.useExisting {
		_redisAuth: ""
	}

	_redisHost: string
	if zammadConfig.redis.enabled {
		_redisHost: "\(metadata.name)-redis-master"
	}
	if !zammadConfig.redis.enabled {
		_redisHost: zammadConfig.redis.host
	}

	_postgresqlHost: string
	if zammadConfig.postgresql.enabled {
		_postgresqlHost: "\(metadata.name)-postgresql"
	}
	if !zammadConfig.postgresql.enabled {
		_postgresqlHost: zammadConfig.postgresql.host
	}

	_memcachedHost: string
	if zammadConfig.memcached.enabled {
		_memcachedHost: "\(metadata.name)-memcached"
	}
	if !zammadConfig.memcached.enabled {
		_memcachedHost: zammadConfig.memcached.host
	}

	// -------------------------------------------------------------------------
	// Computed helper: Zammad environment variables (zammad.env equivalent)
	// -------------------------------------------------------------------------
	_zammadEnv: [...corev1.#EnvVar]
	_zammadEnv: list.Concat([
		// POSTGRESQL
		[{
			name:  "POSTGRESQL_HOST"
			value: _postgresqlHost
		}, {
			name:  "POSTGRESQL_PORT"
			value: "\(zammadConfig.postgresql.port)"
		}, {
			name:  "POSTGRESQL_DB"
			value: zammadConfig.postgresql.db
		}, {
			name:  "POSTGRESQL_USER"
			value: zammadConfig.postgresql.user
		}, {
			name: "POSTGRESQL_PASS"
			valueFrom: secretKeyRef: {
				name: _postgresqlSecretName
				key:  secrets.postgresql.secretKey
			}
		}, {
			name:  "POSTGRESQL_OPTIONS"
			value: zammadConfig.postgresql.options
		}],
		// ELASTICSEARCH
		[{
			name:  "ELASTICSEARCH_HOST"
			value: _elasticsearchHost
		}, {
			name:  "ELASTICSEARCH_PORT"
			value: "\(zammadConfig.elasticsearch.port)"
		}, {
			name:  "ELASTICSEARCH_SCHEMA"
			value: zammadConfig.elasticsearch.schema
		}, {
			name:  "ELASTICSEARCH_USER"
			value: zammadConfig.elasticsearch.user
		}],
		// REDIS
		if zammadConfig.redis.sentinel.enabled {
			list.Concat([
				[{
					name: "REDIS_SENTINELS"
					if zammadConfig.redis.enabled {
						value: "\(metadata.name)-redis:26379"
					}
					if !zammadConfig.redis.enabled {
						value: strings.Join(zammadConfig.redis.sentinel.sentinels, ",")
					}
				}, {
					name:  "REDIS_SENTINEL_NAME"
					value: zammadConfig.redis.sentinel.masterName
				}],
				if zammadConfig.redis.sentinel.username != "" {
					[{
						name:  "REDIS_SENTINEL_USERNAME"
						value: zammadConfig.redis.sentinel.username
					}]
				},
				if ! (zammadConfig.redis.sentinel.username != "") {
					[]
				},
				if zammadConfig.redis.sentinel.pass != "" || secrets.redis.sentinel.useExisting {
					[{
						name: "REDIS_SENTINEL_PASSWORD"
						valueFrom: secretKeyRef: {
							name: _redisSentinelSecretName
							key:  secrets.redis.sentinel.secretKey
						}
					}]
				},
				if ! (zammadConfig.redis.sentinel.pass != "" || secrets.redis.sentinel.useExisting) {
					[]
				},
				if zammadConfig.redis.username != "" {
					[{
						name:  "REDIS_USERNAME"
						value: zammadConfig.redis.username
					}]
				},
				if ! (zammadConfig.redis.username != "") {
					[]
				},
				if zammadConfig.redis.pass != "" || secrets.redis.useExisting {
					[{
						name: "REDIS_PASSWORD"
						valueFrom: secretKeyRef: {
							name: _redisSecretName
							key:  secrets.redis.secretKey
						}
					}]
				},
				if ! (zammadConfig.redis.pass != "" || secrets.redis.useExisting) {
					[]
				},
			])
		}
		if !zammadConfig.redis.sentinel.enabled {
			[{
				name:  "REDIS_URL"
				value: "\(_redisSchema)://\(_redisAuth)\(_redisHost):\(zammadConfig.redis.port)"
			}]
		},
		// S3 / MINIO
		if zammadConfig.minio.externalS3Url != _|_ {
			[{
				name:  "S3_URL"
				value: zammadConfig.minio.externalS3Url
			}]
		}
		if zammadConfig.minio.externalS3Url == _|_ {
			if zammadConfig.minio.enabled {
				list.Concat([
					if secrets.s3.useExisting {
						[{
							name: "S3_URL"
							valueFrom: secretKeyRef: {
								name: secrets.s3.secretName
								key:  secrets.s3.secretKey
							}
						}]
					},
					if !secrets.s3.useExisting {
						[{
							name: "MINIO_ROOT_USER"
							valueFrom: secretKeyRef: {
								name: "\(metadata.name)-minio"
								key:  "root-user"
							}
						}, {
							name: "MINIO_ROOT_PASSWORD"
							valueFrom: secretKeyRef: {
								name: "\(metadata.name)-minio"
								key:  "root-password"
							}
						}, {
							name:  "S3_URL"
							value: "http://$(MINIO_ROOT_USER):$(MINIO_ROOT_PASSWORD)@\(metadata.name)-minio:9000/zammad?region=zammad&force_path_style=true"
						}]
					}
				])
			}
			if !zammadConfig.minio.enabled {
				if secrets.s3.useExisting {
					[{
						name: "S3_URL"
						valueFrom: secretKeyRef: {
							name: secrets.s3.secretName
							key:  secrets.s3.secretKey
						}
					}]
				}
				if !secrets.s3.useExisting {
					[]
				}
			}
		},
		// MEMCACHED
		[{
			name:  "MEMCACHE_SERVERS"
			value: "\(_memcachedHost):\(zammadConfig.memcached.port)"
		}],
		// RAILS_TRUSTED_PROXIES
		[{
			name:  "RAILS_TRUSTED_PROXIES"
			value: zammadConfig.railsserver.trustedProxies
		}],
		// Global extraEnv
		[
			if extraEnv != _|_ for e in extraEnv {e},
		],
		// TMP
		[{
			name:  "TMP"
			value: "/opt/zammad/tmp"
		}],
	])

	// Computed: RAILS_CHECK_PENDING_MIGRATIONS env array
	_zammadEnvFailOnPendingMigrations: [...corev1.#EnvVar]
	_zammadEnvFailOnPendingMigrations: [{
		name:  "RAILS_CHECK_PENDING_MIGRATIONS"
		value: "true"
	}]

	// -------------------------------------------------------------------------
	// Computed helper: Volume permissions init container
	// -------------------------------------------------------------------------
	_zammadVolumePermissionsInitContainer: corev1.#Container & {
		name:            "zammad-volume-permissions"
		image:           "\(zammadConfig.initContainers.volumePermissions.image.repository):\(zammadConfig.initContainers.volumePermissions.image.tag)"
		imagePullPolicy: zammadConfig.initContainers.volumePermissions.image.pullPolicy
		command:         zammadConfig.initContainers.volumePermissions.command
		if zammadConfig.initContainers.volumePermissions.resources != _|_ {
			resources: zammadConfig.initContainers.volumePermissions.resources
		}
		if zammadConfig.initContainers.volumePermissions.securityContext != _|_ {
			securityContext: zammadConfig.initContainers.volumePermissions.securityContext
		}
		volumeMounts: _zammadVolumeMounts
	}

	// -------------------------------------------------------------------------
	// Computed helper: Shared volume mounts for all Zammad containers
	// -------------------------------------------------------------------------
	_zammadVolumeMounts: [...corev1.#VolumeMount]
	_zammadVolumeMounts: list.Concat([
		// tmpDir
		[{
			name:      "\(metadata.name)-tmp"
			mountPath: "/tmp"
		}, {
			name:      "\(metadata.name)-tmp"
			mountPath: zammadConfig.railsserver.tmpdir
		}],
		// storageVolume (optional)
		if zammadConfig.storageVolume.enabled {
			[{
				name:      "\(metadata.name)-storage"
				mountPath: "/opt/zammad/storage"
			}]
		},
		if !zammadConfig.storageVolume.enabled {
			[]
		},
		// customVolumeMounts
		if zammadConfig.customVolumeMounts != _|_ {
			zammadConfig.customVolumeMounts
		},
		if zammadConfig.customVolumeMounts == _|_ {
			[]
		},
	])

	// -------------------------------------------------------------------------
	// Computed helper: Shared volumes for all Zammad pods
	// -------------------------------------------------------------------------
	_zammadVolumes: [...corev1.#Volume]
	_zammadVolumes: list.Concat([
		// tmpDir volume
		[{
			name: "\(metadata.name)-tmp"
			emptyDir: {
				sizeLimit: zammadConfig.tmpDirVolume.emptyDir.sizeLimit
				if zammadConfig.tmpDirVolume.emptyDir.medium != _|_ {
					medium: zammadConfig.tmpDirVolume.emptyDir.medium
				}
			}
		}],
		// storageVolume (optional)
		if zammadConfig.storageVolume.enabled {
			[{
				name: "\(metadata.name)-storage"
				persistentVolumeClaim: claimName: zammadConfig.storageVolume.existingClaim
			}]
		},
		if !zammadConfig.storageVolume.enabled {
			[]
		},
		// customVolumes
		if zammadConfig.customVolumes != _|_ {
			zammadConfig.customVolumes
		},
		if zammadConfig.customVolumes == _|_ {
			[]
		},
	])

	let _podSecurityContext = securityContext

	// -------------------------------------------------------------------------
	// Computed helper: Common pod spec for all Zammad Deployments
	// -------------------------------------------------------------------------
	_zammadPodSpecDeployment: corev1.#PodSpec & {
		securityContext: {
			fsGroup:             _podSecurityContext.fsGroup
			fsGroupChangePolicy: _podSecurityContext.fsGroupChangePolicy
			runAsUser:           _podSecurityContext.runAsUser
			runAsNonRoot:        _podSecurityContext.runAsNonRoot
			runAsGroup:          _podSecurityContext.runAsGroup
			if _podSecurityContext.seccompProfile != _|_ {
				seccompProfile: _podSecurityContext.seccompProfile
			}
		}
		if len(imagePullSecrets) > 0 {
			imagePullSecrets: imagePullSecrets
		}
		if serviceAccount.create {
			serviceAccountName: serviceAccount.name
		}

		if zammadConfig.initContainers.volumePermissions.enabled {
			initContainers: [
				{
					name:            "zammad-volume-permissions"
					image:           "\(zammadConfig.initContainers.volumePermissions.image.repository):\(zammadConfig.initContainers.volumePermissions.image.tag)"
					imagePullPolicy: zammadConfig.initContainers.volumePermissions.image.pullPolicy
					command:         zammadConfig.initContainers.volumePermissions.command
					if zammadConfig.initContainers.volumePermissions.resources != _|_ {
						resources: zammadConfig.initContainers.volumePermissions.resources
					}
					if zammadConfig.initContainers.volumePermissions.securityContext != _|_ {
						securityContext: zammadConfig.initContainers.volumePermissions.securityContext
					}
					volumeMounts: _zammadVolumeMounts
				}
			]
		}
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		svcNginx:       #ServiceNginx & {#config: config}
		svcRailsserver: #ServiceRailsserver & {#config: config}
		svcWebsocket:   #ServiceWebsocket & {#config: config}

		cmInit:  #ConfigMapInit & {#config: config}
		cmNginx: #ConfigMapNginx & {#config: config}
		initJob: #InitJob & {#config: config}
		if config.autoWizard.enabled && !config.secrets.autowizard.useExisting {
			secretAutowizard: #SecretAutowizard & {#config: config}
		}
		if config.zammadConfig.elasticsearch.pass != "" && !config.secrets.elasticsearch.useExisting {
			secretElasticsearch: #SecretElasticsearch & {#config: config}
		}
		if !config.secrets.postgresql.useExisting {
			secretPostgresql: #SecretPostgresql & {#config: config}
		}
		if config.zammadConfig.redis.pass != "" && !config.secrets.redis.useExisting {
			secretRedis: #SecretRedis & {#config: config}
		}
		if config.zammadConfig.redis.sentinel.enabled && config.zammadConfig.redis.sentinel.pass != "" && !config.secrets.redis.sentinel.useExisting {
			secretRedisSentinel: #SecretRedisSentinel & {#config: config}
		}
		cronReindex:      #CronJobReindex & {#config: config}
		deployNginx:      #DeploymentNginx & {#config: config}
		deployRailsserver: #DeploymentRailsserver & {#config: config}
		deployScheduler:  #DeploymentScheduler & {#config: config}
		deployWebsocket:  #DeploymentWebsocket & {#config: config}

		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}

		if config.zammadConfig.elasticsearch.enabled {
			depElasticsearchStatefulSet: #ElasticsearchStatefulSet & {#config: config}
			depElasticsearchService:    #ElasticsearchService & {#config: config}
			depElasticsearchHLService: #ElasticsearchHeadlessService & {#config: config}
		}
		if config.zammadConfig.memcached.enabled {
			depMemcachedSA:         #MemcachedServiceAccount & {#config: config}
			depMemcachedDeployment: #MemcachedDeployment & {#config: config}
			depMemcachedService:    #MemcachedService & {#config: config}
		}
		if config.zammadConfig.minio.enabled {
			if config.minio.auth.existingSecret == "" {
				depMinioSecret: #MinioSecret & {#config: config}
			}
			if config.minio.persistence.enabled {
				depMinioPVC: #MinioPVC & {#config: config}
			}
			depMinioService:    #MinioService & {#config: config}
			depMinioDeployment: #MinioDeployment & {#config: config}
		}
		if config.zammadConfig.postgresql.enabled {
			depPostgresqlStatefulSet: #PostgresqlStatefulSet & {#config: config}
			depPostgresqlService:    #PostgresqlService & {#config: config}
			depPostgresqlHLService: #PostgresqlHeadlessService & {#config: config}
		}
		if config.zammadConfig.redis.enabled {
			depRedisStatefulSet: #RedisStatefulSet & {#config: config}
			depRedisConfigMap:   #RedisConfigMap & {#config: config}
			depRedisService:    #RedisService & {#config: config}
			depRedisHLService: #RedisHeadlessService & {#config: config}
			if config.zammadConfig.redis.sentinel.enabled {
				depRedisSentinelService: #RedisSentinelService & {#config: config}
			}
		}
	}

	tests: {
		"test-svc": #TestJob & {#config: config}
	}
}
