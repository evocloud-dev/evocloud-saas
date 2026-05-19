package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"
	"strings"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: string

	// Component names
	_name: "superset"

	// Secret names
	secretEnv: name: *"env" | string
	secretConfig: name: *"config" | string
	secretWsConfig: name: *"ws-config" | string

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

	metadata: labels: {
		chart:    *"superset-\(moduleVersion)" | string
		release:  metadata.name
		heritage: *"timoni" | string
	}

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	name: {
		if nameOverride != "" {nameOverride}
		if nameOverride == "" {"superset"}
	}
	fullname: {
		if fullnameOverride != "" {fullnameOverride}
		if fullnameOverride == "" {metadata.name}
	}

	#redisHost: {
		if redis.enabled {
			"\(fullname)-redis-headless"
		}
		if !redis.enabled {
			supersetNode.connections.redis_host
		}
	}

	#dbHost: {
		if postgresql.enabled {
			"\(fullname)-postgresql"
		}
		if !postgresql.enabled {
			supersetNode.connections.db_host
		}
	}

	configFromSecret: *null | string
	envFromSecret:    *null | string
	envFromSecrets:   [...] | *[]

	extraLabels:       {...} | *{}
	extraConfigs:      {...} | *{}
	extraSecrets:      {...} | *{}
	extraSecretEnv:    {...} | *{}
	extraVolumes:      [...] | *[]
	extraVolumeMounts: [...] | *[]
	extraEnv:          {...} | *{}
	extraEnvRaw:       [...] | *[]
	configOverrides:   {...} | *{}
	configOverridesFiles: {...} | *{}
	bootstrapScript:   string
	configMountPath:   string
	extraConfigMountPath: string
	runAsUser:         int
	secretEnv: {
		create: bool
		name:   *"env" | string
	}
	serviceAccountName: *null | string
	serviceAccount: {
		create: bool
		annotations: {...} | *{}
	}
	service: {
		type: string
		port: int
		annotations: {...} | *{}
		loadBalancerIP: *null | string
		nodePort: {
			http: *null | int
		}
	}
	image: {
		repository: string
		tag:        string
		pullPolicy: string
	}
	imagePullSecrets: [...] | *[]
	initImage: {
		repository: string
		tag:        string
		pullPolicy: string
	}
	ingress: {
		enabled:          bool
		ingressClassName: *null | string
		annotations:      {...} | *{}
		path:             string
		pathType:         string
		hosts:            [...]
		tls:              [...]
		extraHostsRaw:    [...] | *[]
	}
	resources: timoniv1.#ResourceRequirements | *{}
	hostAliases: [...] | *[]
	nodeSelector: {...} | *{}
	affinity: {...} | *{}
	tolerations: [...] | *[]
	topologySpreadConstraints: [...] | *[]
	priorityClassName: *null | string

	supersetNode: {
		replicas: {
			enabled:      bool
			replicaCount: int
		}
		autoscaling: {
			enabled:                        bool
			minReplicas:                    int
			maxReplicas:                    int
			targetCPUUtilizationPercentage: *null | int
			targetMemoryUtilizationPercentage: *null | int
		}
		podDisruptionBudget: {
			enabled:        bool
			minAvailable:   *null | int
			maxUnavailable: *null | int
		}
		command: [...]
		connections: {
			redis_host:      *null | string
			redis_port:      string
			redis_user:      string
			redis_password:  *null | string
			redis_cache_db:  string
			redis_celery_db: string
			redis_ssl: {
				enabled:       bool
				ssl_cert_reqs: string
			}
			db_type: string
			db_host: *null | string
			db_port: string
			db_user: string
			db_pass: string
			db_name: string
		}
		env: {...} | *{}
		forceReload: bool
		initContainers: [...] | *[{
			name:            *"wait-for-postgres-redis" | string
			image:           *"apache/superset:dockerize" | string
			imagePullPolicy: *"IfNotPresent" | string
			command: [
				"/bin/sh",
				"-c",
				"dockerize -wait \"tcp://$DB_HOST:$DB_PORT\" -wait \"tcp://$REDIS_HOST:$REDIS_PORT\" -timeout 120s",
			]
			envFrom: [{
				secretRef: {
					name: *"\(fullname)-\(secretEnv.name)" | string
				}
			}]
			resources: {
				limits: memory:  *"256Mi" | string
				requests: cpu:    *"250m" | string
				requests: memory: *"128Mi" | string
			}
		}]
		extraContainers: [...] | *[]
		deploymentAnnotations: {...} | *{}
		deploymentLabels: {...} | *{}
		affinity: {...} | *{}
		topologySpreadConstraints: [...] | *[]
		podAnnotations: {...} | *{}
		podLabels: {...} | *{}
		startupProbe: {...} | *{}
		livenessProbe: {...} | *{}
		readinessProbe: {...} | *{}
		resources: timoniv1.#ResourceRequirements | *{}
		podSecurityContext: {...} | *{}
		containerSecurityContext: {...} | *{}
		strategy: {...} | *{}
		podLabels: {...} | *{}
	}

	init: {
		enabled: bool
		command: [...]
		jobAnnotations: {...} | *{}
		podAnnotations: {...} | *{}
		podLabels: {...} | *{}
		createAdmin: bool
		adminUser: {
			username:  string
			firstname: string
			lastname:  string
			email:     string
			password:  string
		}
		loadExamples: bool
		initContainers: [...] | *[{
			name:            *"wait-for-postgres-redis" | string
			image:           *"apache/superset:dockerize" | string
			imagePullPolicy: *"IfNotPresent" | string
			command: [
				"/bin/sh",
				"-c",
				"dockerize -wait \"tcp://$DB_HOST:$DB_PORT\" -wait \"tcp://$REDIS_HOST:$REDIS_PORT\" -timeout 120s",
			]
			envFrom: [{
				secretRef: {
					name: string
				}
			}]
			resources: {
				limits: memory:   "256Mi" | string
				requests: cpu:    "250m" | string
				requests: memory: "128Mi" | string
			}
		}]
		initscript: string
		extraContainers: [...] | *[]
		resources: timoniv1.#ResourceRequirements | *{}
		podSecurityContext: {...} | *{}
		containerSecurityContext: {...} | *{}
		priorityClassName: *null | string
		affinity: {...} | *{}
		tolerations: [...] | *[]
		topologySpreadConstraints: [...] | *[]
	}

	postgresql: {
		enabled: bool
		auth: {
			existingSecret: *null | string
			username:       string
			password:       string
			database:       string
		}
		image: {
			registry:   string
			repository: string
			tag:        string
		}
		primary: {
			persistence: {
				enabled: bool
				accessModes: [...string]
			}
			service: {
				ports: {
					postgresql: string
				}
			}
		}
	}

	redis: {
		enabled:      bool
		architecture: string
		auth: {
			enabled:           bool
			existingSecret:    string
			existingSecretKey: string
			password:          string
		}
		master: {
			persistence: {
				enabled: bool
				accessModes: [...string]
			}
		}
		image: {
			registry:   string
			repository: string
			tag:        string
		}
	}

	supersetConfig: string

	supersetWorker: {
		replicas: {
			enabled:      bool
			replicaCount: int
		}
		autoscaling: {
			enabled:                        bool
			minReplicas:                    int
			maxReplicas:                    int
			targetCPUUtilizationPercentage: *null | int
			targetMemoryUtilizationPercentage: *null | int
		}
		podDisruptionBudget: {
			enabled:        bool
			minAvailable:   *null | int
			maxUnavailable: *null | int
		}
		command: [...]
		strategy: {...} | *{}
		initContainers: [...] | *[{
			name:            *"wait-for-postgres-redis" | string
			image:           *"apache/superset:dockerize" | string
			imagePullPolicy: *"IfNotPresent" | string
			command: [
				"/bin/sh",
				"-c",
				"dockerize -wait \"tcp://$DB_HOST:$DB_PORT\" -wait \"tcp://$REDIS_HOST:$REDIS_PORT\" -timeout 120s",
			]
			envFrom: [{
				secretRef: {
					name: string
				}
			}]
			resources: {
				limits: memory:   "256Mi"
				requests: cpu:    "250m"
				requests: memory: "128Mi"
			}
		}]
		extraContainers: [...] | *[]
		deploymentAnnotations: {...} | *{}
		deploymentLabels: {...} | *{}
		podAnnotations: {...} | *{}
		podLabels: {...} | *{}
		resources: timoniv1.#ResourceRequirements | *{}
		startupProbe: {...} | *{}
		livenessProbe: {...} | *{}
		readinessProbe: {...} | *{}
		podSecurityContext: {...} | *{}
		containerSecurityContext: {...} | *{}
		priorityClassName: *null | string
		affinity: {...} | *{}
		forceReload: bool
		topologySpreadConstraints?: [...] | *[]
	}

	supersetCeleryBeat: {
		enabled: bool
		podDisruptionBudget: {
			enabled:        bool
			minAvailable:   *null | int
			maxUnavailable: *null | int
		}
		command: [...]
		initContainers: [...] | *[{
			name:            *"wait-for-postgres-redis" | string
			image:           *"apache/superset:dockerize" | string
			imagePullPolicy: *"IfNotPresent" | string
			command: [
				"/bin/sh",
				"-c",
				"dockerize -wait \"tcp://$DB_HOST:$DB_PORT\" -wait \"tcp://$REDIS_HOST:$REDIS_PORT\" -timeout 120s",
			]
			envFrom: [{
				secretRef: {
					name: string
				}
			}]
			resources: {
				limits: memory:   "256Mi"
				requests: cpu:    "250m"
				requests: memory: "128Mi"
			}
		}]
		deploymentAnnotations: {...} | *{}
		podAnnotations: {...} | *{}
		podLabels: {...} | *{}
		resources: timoniv1.#ResourceRequirements | *{}
		podSecurityContext: {...} | *{}
		containerSecurityContext: {...} | *{}
		priorityClassName: *null | string
		affinity: {...} | *{}
		forceReload?: bool
		extraContainers?: [...] | *[]
		topologySpreadConstraints?: [...] | *[]
	}

	supersetCeleryFlower: {
		enabled:      bool
		replicaCount: int
		podDisruptionBudget: {
			enabled:        bool
			minAvailable:   *null | int
			maxUnavailable: *null | int
		}
		command: [...]
		service: {
			type: string
			port: int
			annotations: {...} | *{}
			loadBalancerIP: *null | string
			nodePort: {
				http: *null | int
			}
		}
		initContainers: [...] | *[{
			name:            *"wait-for-postgres-redis" | string
			image:           *"apache/superset:dockerize" | string
			imagePullPolicy: *"IfNotPresent" | string
			command: [
				"/bin/sh",
				"-c",
				"dockerize -wait \"tcp://$DB_HOST:$DB_PORT\" -wait \"tcp://$REDIS_HOST:$REDIS_PORT\" -timeout 120s",
			]
			envFrom: [{
				secretRef: {
					name: string
				}
			}]
			resources: {
				limits: memory:   "256Mi"
				requests: cpu:    "250m"
				requests: memory: "128Mi"
			}
		}]
		deploymentAnnotations: {...} | *{}
		podAnnotations: {...} | *{}
		podLabels: {...} | *{}
		resources: timoniv1.#ResourceRequirements | *{}
		startupProbe: {...} | *{}
		livenessProbe: {...} | *{}
		readinessProbe: {...} | *{}
		podSecurityContext: {...} | *{}
		containerSecurityContext: {...} | *{}
		priorityClassName: *null | string
		affinity: {...} | *{}
		extraContainers?: [...] | *[]
		topologySpreadConstraints?: [...] | *[]
	}

	supersetWebsockets: {
		enabled:      bool
		replicaCount: int
		podDisruptionBudget: {
			enabled:        bool
			minAvailable:   *null | int
			maxUnavailable: *null | int
		}
		image: {
			repository: string
			tag:        string
			pullPolicy: string
		}
		config: {
			port:        int
			logLevel:    *"debug" | string
			logToFile:   *false | bool
			logFilename: *"app.log" | string
			statsd: {
				host:       *"127.0.0.1" | string
				port:       *8125 | int
				globalTags: [...] | *[]
			}
			redis: {
				port:     *6379 | int
				host:     string | *#redisHost
				password: *"" | string
				db:       *0 | int
				ssl:      *false | bool
			}
			redisStreamPrefix: *"async-events-" | string
			jwtSecret:         string
			jwtCookieName:     *"async-token" | string
		}
		ingress: {
			path:     string
			pathType: string
		}
		service: {
			type: string
			port: int
			annotations: {...} | *{}
			loadBalancerIP: *null | string
			nodePort: {
				http: *null | int
			}
		}
		command: [...]
		deploymentAnnotations: {...} | *{}
		podAnnotations: {...} | *{}
		podLabels: {...} | *{}
		resources: timoniv1.#ResourceRequirements | *{}
		startupProbe: {...} | *{}
		livenessProbe: {...} | *{}
		readinessProbe: {...} | *{}
		podSecurityContext: {...} | *{}
		containerSecurityContext: {...} | *{}
		strategy: {...} | *{}
		priorityClassName: *null | string
		affinity: {...} | *{}
		extraContainers: [...] | *[]
		topologySpreadConstraints: [...] | *[]
	}

	test: {
		enabled: *false | bool
	}


	supersetConfig: *#"""
		import os
		from flask_caching.backends.rediscache import RedisCache

		def env(key, default=None):
		    return os.getenv(key, default)

		# Redis Base URL
		REDIS_PROTO = env('REDIS_PROTO', 'redis')
		REDIS_USER = env('REDIS_USER', '')
		REDIS_PASSWORD = env('REDIS_PASSWORD', '')
		REDIS_HOST = env('REDIS_HOST')
		REDIS_PORT = env('REDIS_PORT')

		if REDIS_PASSWORD:
		    REDIS_BASE_URL = f"{REDIS_PROTO}://{REDIS_USER}:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}"
		else:
		    REDIS_BASE_URL = f"{REDIS_PROTO}://{REDIS_HOST}:{REDIS_PORT}"

		# Redis URL Params
		if env('REDIS_SSL_ENABLED') == 'True':
		    REDIS_URL_PARAMS = f"?ssl_cert_reqs={env('REDIS_SSL_CERT_REQS', 'CERT_NONE')}"
		else:
		    REDIS_URL_PARAMS = ""

		# Build Redis URLs
		CACHE_REDIS_URL = f"{REDIS_BASE_URL}/{env('REDIS_DB', 1)}{REDIS_URL_PARAMS}"
		CELERY_REDIS_URL = f"{REDIS_BASE_URL}/{env('REDIS_CELERY_DB', 0)}{REDIS_URL_PARAMS}"

		MAPBOX_API_KEY = env('MAPBOX_API_KEY', '')
		CACHE_CONFIG = {
		      'CACHE_TYPE': 'RedisCache',
		      'CACHE_DEFAULT_TIMEOUT': 300,
		      'CACHE_KEY_PREFIX': 'superset_',
		      'CACHE_REDIS_URL': CACHE_REDIS_URL,
		}
		DATA_CACHE_CONFIG = CACHE_CONFIG

		try:
		    import psycopg2
		    if os.getenv("SQLALCHEMY_DATABASE_URI"):
		        SQLALCHEMY_DATABASE_URI = os.getenv("SQLALCHEMY_DATABASE_URI")
		    else:
		        SQLALCHEMY_DATABASE_URI = f"postgresql+psycopg2://{os.getenv('DB_USER')}:{os.getenv('DB_PASS')}@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
		except ImportError:
		    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"

		SQLALCHEMY_TRACK_MODIFICATIONS = True

		class CeleryConfig:
		  imports  = ("superset.sql_lab", )
		  broker_url = CELERY_REDIS_URL
		  result_backend = CELERY_REDIS_URL

		CELERY_CONFIG = CeleryConfig
		RESULTS_BACKEND = RedisCache(
		      host=env('REDIS_HOST'),
		      port=env('REDIS_PORT'),
		      key_prefix='superset_results',
		)

		# Overrides
		\#(strings.Join([for k, v in configOverrides { "# \(k)\n\(v)\n" }], "\n"))

		# Overrides from files
		\#(strings.Join([for k, v in configOverridesFiles { "# \(k)\n\(v)\n" }], "\n"))
		"""# | string
	}

#Instance: {
	config: #Config

	objects: {
		"secret-superset-config": #SecretSupersetConfig & {#config: config}
		"service":                 #Service & {#config: config}
		"deployment":              #Deployment & {#config: config}
		"configmap-superset":      #ConfigMapSuperset & {#config: config}

		if config.secretEnv.create {
			"secret-env": #SecretEnv & {#config: config}
		}

		if config.serviceAccount.create {
			"serviceaccount": #ServiceAccount & {#config: config}
		}

		if config.supersetWorker.replicas.enabled {
			"worker-deployment": #DeploymentWorker & {#config: config}
			if config.supersetWorker.autoscaling.enabled {
				"worker-hpa": #HpaWorker & {#config: config}
			}
			if config.supersetWorker.podDisruptionBudget.enabled {
				"worker-pdb": #PdbWorker & {#config: config}
			}
		}

		if config.supersetCeleryBeat.enabled {
			"beat-deployment": #DeploymentBeat & {#config: config}
			if config.supersetCeleryBeat.podDisruptionBudget.enabled {
				"beat-pdb": #PdbBeat & {#config: config}
			}
		}

		if config.supersetCeleryFlower.enabled {
			"flower-deployment": #DeploymentFlower & {#config: config}
			"flower-service":    #ServiceFlower & {#config: config}
			if config.supersetCeleryFlower.podDisruptionBudget.enabled {
				"flower-pdb": #PdbFlower & {#config: config}
			}
		}

		if config.supersetWebsockets.enabled {
			"ws-deployment": #DeploymentWs & {#config: config}
			"ws-service":    #ServiceWs & {#config: config}
			"ws-secret":     #SecretWs & {#config: config}
			if config.supersetWebsockets.podDisruptionBudget.enabled {
				"ws-pdb": #PdbWs & {#config: config}
			}
		}

		if config.init.enabled {
			"init-job": #InitJob & {#config: config}
		}

		if config.ingress.enabled {
			"ingress": #Ingress & {#config: config}
		}

		if config.supersetNode.autoscaling.enabled {
			"node-hpa": #HpaNode & {#config: config}
		}

		if config.supersetNode.podDisruptionBudget.enabled {
			"node-pdb": #Pdb & {#config: config}
		}

		if config.postgresql.enabled {
			"postgresql-secret":   #PostgresqlSecret          & {#config: config}
			"postgresql-service":  #PostgresqlService         & {#config: config}
			"postgresql-hl":       #PostgresqlHeadlessService & {#config: config}
			"postgresql-ss":       #PostgresqlStatefulSet     & {#config: config}
		}

		if config.redis.enabled {
			"redis-master":   #RedisService         & {#config: config}
			"redis-headless": #RedisHeadlessService & {#config: config}
			"redis-ss":       #RedisStatefulSet     & {#config: config}
		}
	}

	tests: {}
}
