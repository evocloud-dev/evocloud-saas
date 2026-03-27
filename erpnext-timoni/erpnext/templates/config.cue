package templates

import (
	"list"
	"strings"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: _config={
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: string
	// Using the kubeVersion you can enforce a minimum Kubernetes minor version.
	// By default, the minimum Kubernetes version is set to 1.20.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	// The moduleVersion is set from the user-supplied module version.
	// This field is used for the `app.kubernetes.io/version` label.
	moduleVersion!: string
	
    metadata: timoniv1.#Metadata & {
	#Version: moduleVersion
	name:      *"default" | string
	namespace: *"default" | string
	}
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

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	// The default image repository and tag is set in `values.cue`.

	// The resources allows setting the container resource requirements.
	// By default, the container requests 10m CPU and 32Mi memory.
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"10m" | timoniv1.#CPUQuantity
			memory: *"32Mi" | timoniv1.#MemoryQuantity
		}
	}

	// The number of pods replicas.
	// By default, the number of replicas is 1.
	replicas: *1 | int & >0

	// The securityContext allows setting the container security context.
	// By default, the container is denined privilege escalation.
	securityContext: corev1.#SecurityContext & {
		allowPrivilegeEscalation: *false | true
		privileged:               *false | true
		capabilities:
		{
			drop: *["ALL"] | [string]
			add: *["CHOWN", "NET_BIND_SERVICE", "SETGID", "SETUID"] | [string]
		}
	}

	// The service allows setting the Kubernetes Service annotations and port.
	// By default, the HTTP port is 80.
	service: {
		annotations?: timoniv1.#Annotations

		port: *80 | int & >0 & <=65535
	}

	// Pod optional settings.
	podAnnotations?: {[string]: string}
	podSecurityContext?: corev1.#PodSecurityContext
	imagePullSecrets?: [...corev1.#LocalObjectReference]
	tolerations?: [...corev1.#Toleration]
	affinity?: corev1.#Affinity
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]


	// Configure external database host
	dbHost:                       *"" | string
	dbPort:                       *3306 | int
	dbRootUser:                   *"" | string
	dbRootPassword:               *"" | string
	dbRds:                        *false | bool
	dbExistingSecret:             *"" | string
	dbExistingSecretPasswordKey:  *"db-root-password" | string
	_socketioPort:               *9000 | int


	// Configure external redis host
	externalRedis: {
		cache: *"" | string
		queue: *"" | string
	}

	_dbHost: *dbHost | string
	if dbHost == "" {
		if (_config.mariadb.enabled || _config["mariadb-subchart"].enabled) {
			_dbHost: "\(_config.metadata.name)-mariadb"
		}
		if !(_config.mariadb.enabled || _config["mariadb-subchart"].enabled) && (_config.postgresql.enabled || _config["postgresql-subchart"].enabled) {
			_dbHost: "\(_config.metadata.name)-postgresql"
		}
		if !(_config.mariadb.enabled || _config["mariadb-subchart"].enabled) && !(_config.postgresql.enabled || _config["postgresql-subchart"].enabled) && _config["mariadb-sts"].enabled {
			_dbHost: "\(_config.metadata.name)-mariadb-sts"
		}
		if !(_config.mariadb.enabled || _config["mariadb-subchart"].enabled) && !(_config.postgresql.enabled || _config["postgresql-subchart"].enabled) && _config["postgresql-sts"].enabled {
			_dbHost: "\(_config.metadata.name)-postgresql-sts"
		}
	}

	_dbPort: *dbPort | int
	if dbPort == 3306 {
		if (_config.mariadb.enabled || _config["mariadb-subchart"].enabled || _config["mariadb-sts"].enabled) {
			_dbPort: 3306
		}
		if !(_config.mariadb.enabled || _config["mariadb-subchart"].enabled || _config["mariadb-sts"].enabled) && (_config.postgresql.enabled || _config["postgresql-subchart"].enabled || _config["postgresql-sts"].enabled) {
			_dbPort: 5432
		}
	}

	_globalEnv: [
		{
			name:  "DB_HOST"
			value: _dbHost
		},
		{
			name:  "DB_PORT"
			value: "\(_dbPort)"
		},
		{
			name:  "REDIS_CACHE"
			value: _redisCache
		},
		{
			name:  "REDIS_QUEUE"
			value: _redisQueue
		},
		{
			name:  "REDIS_SOCKETIO"
			value: _redisQueue
		},
		{
			name:  "SOCKETIO_PORT"
			value: "\(_socketioPort)"
		},
	]

	_dbRootUser: *dbRootUser | string

	if dbRootUser == "" {
		if (_config.mariadb.enabled || _config["mariadb-subchart"].enabled || _config["mariadb-sts"].enabled) {
			_dbRootUser: "root"
		}
		if !(_config.mariadb.enabled || _config["mariadb-subchart"].enabled || _config["mariadb-sts"].enabled) && (_config.postgresql.enabled || _config["postgresql-subchart"].enabled || _config["postgresql-sts"].enabled) {
			_dbRootUser: "postgres"
		}
	}



	_redisCache: *externalRedis.cache | string
	if externalRedis.cache == "" {
		if _config["valkey-cache"].enabled {
			_redisCache: "redis://\(_config.metadata.name)-valkey-cache:6379"
		}
		if !_config["valkey-cache"].enabled && _config["dragonfly-cache"].enabled {
			_redisCache: "redis://\(_config.metadata.name)-dragonfly-cache:6379"
		}
		if !_config["valkey-cache"].enabled && !_config["dragonfly-cache"].enabled && _config["redis-cache"].enabled {
			_redisCache: "redis://\(_config.metadata.name)-redis-cache-master:6379"
		}
	}
	_redisQueue: *externalRedis.queue | string
	if externalRedis.queue == "" {
		if _config["valkey-queue"].enabled {
			_redisQueue: "redis://\(_config.metadata.name)-valkey-queue:6379"
		}
		if !_config["valkey-queue"].enabled && _config["dragonfly-queue"].enabled {
			_redisQueue: "redis://\(_config.metadata.name)-dragonfly-queue:6379"
		}
		if !_config["valkey-queue"].enabled && !_config["dragonfly-queue"].enabled && _config["redis-queue"].enabled {
			_redisQueue: "redis://\(_config.metadata.name)-redis-queue-master:6379"
		}
	}


	image: {
		repository:  *"frappe/erpnext" | string
		tag:         *"v16.10.1" | string
		digest:      *"" | string
		pullPolicy:  *"IfNotPresent" | string
		reference:   *"\(repository):\(tag)" | string
	}

	nginx: {
		replicaCount: *1 | int & >0
		autoscaling: {
			enabled:     *false | bool
			minReplicas: *1 | int & >0
			maxReplicas: *3 | int & >minReplicas
			targetCPU:   *75 | int & >0
			targetMemory: *75 | int & >0
		}
		config: *"" | string
		environment: {
			upstreamRealIPAddress:   *"127.0.0.1" | string
			upstreamRealIPRecursive: *"off" | string
			upstreamRealIPHeader:    *"X-Forwarded-For" | string
			frappeSiteNameHeader:    *"$host" | string
			proxyReadTimeout:        *"120" | string
			clientMaxBodySize:       *"50m" | string
		}
		livenessProbe:  corev1.#Probe & { tcpSocket: port: *8080 | int | string, initialDelaySeconds: *5 | int, periodSeconds: *10 | int }
		readinessProbe: corev1.#Probe & { tcpSocket: port: *8080 | int | string, initialDelaySeconds: *5 | int, periodSeconds: *10 | int }
		service: {
			type: *"ClusterIP" | string
			port: *8080 | int & >0 & <=65535
		}
		resources:       corev1.#ResourceRequirements
		nodeSelector:    {[string]: string}
		tolerations:     [...corev1.#Toleration]
		affinity:        corev1.#Affinity
		defaultTopologySpread: {
			maxSkew:           *1 | int & >0
			topologyKey:       *"kubernetes.io/hostname" | string
			whenUnsatisfiable: *"DoNotSchedule" | string
		}
		envVars:        *[] | [...corev1.#EnvVar]
		initContainers: *[] | [...corev1.#Container]
		sidecars:       *[] | [...corev1.#Container]
	}

	worker: {
		gunicorn:  #WorkerConfig & { service: port: *8000 | int }
		default:   #WorkerConfig
		short:     #WorkerConfig
		long:      #WorkerConfig
		scheduler: #WorkerConfig & { 
			livenessProbe: override:  *false | bool, 
			readinessProbe: override: *false | bool 
		}

		defaultTopologySpread: {
			maxSkew:           *1 | int & >0
			topologyKey:       *"kubernetes.io/hostname" | string
			whenUnsatisfiable: *"DoNotSchedule" | string
		}

		healthProbe: *"" | string
	}

	#WorkerConfig: {
		replicaCount: *1 | int & >0
		queue:        *"" | string
		autoscaling: {
			enabled:     *false | bool
			minReplicas: *1 | int & >0
			maxReplicas: *3 | int & >minReplicas
			targetCPU:   *75 | int & >0
			targetMemory: *75 | int & >0
		}
		livenessProbe: {
			override: *false | bool
			probe:    corev1.#Probe & { tcpSocket: port: *8000 | int | string, initialDelaySeconds: *5 | int, periodSeconds: *10 | int }
		}
		readinessProbe: {
			override: *false | bool
			probe:    corev1.#Probe & { tcpSocket: port: *8000 | int | string, initialDelaySeconds: *5 | int, periodSeconds: *10 | int }
		}
		_resolvedLivenessProbe: {
			if livenessProbe.override {
				livenessProbe.probe
			}
			if !livenessProbe.override {
				_healthProbe
			}
		}
		_resolvedReadinessProbe: {
			if readinessProbe.override {
				readinessProbe.probe
			}
			if !readinessProbe.override {
				_healthProbe
			}
		}
		service?: {
			type: *"ClusterIP" | string
			port: int & >0 & <=65535
		}
		resources:       corev1.#ResourceRequirements
		nodeSelector:    {[string]: string}
		tolerations:     [...corev1.#Toleration]
		affinity:        corev1.#Affinity
		args:            [...string]
		envVars:         [...corev1.#EnvVar]
		initContainers:  [...corev1.#Container]
		sidecars:        [...corev1.#Container]
	}

	socketio: {
		replicaCount: *1 | int & >0
		autoscaling: {
			enabled:     *false | bool
			minReplicas: *1 | int & >0
			maxReplicas: *3 | int & >minReplicas
			targetCPU:   *75 | int & >0
			targetMemory: *75 | int & >0
		}
		livenessProbe:  corev1.#Probe & { tcpSocket: port: *9000 | int | string, initialDelaySeconds: *5 | int, periodSeconds: *10 | int }
		readinessProbe: corev1.#Probe & { tcpSocket: port: *9000 | int | string, initialDelaySeconds: *5 | int, periodSeconds: *10 | int }
		resources:       corev1.#ResourceRequirements
		nodeSelector:    {[string]: string}
		tolerations:     [...corev1.#Toleration]
		affinity:        corev1.#Affinity
		service: {
			type: *"ClusterIP" | string
			port: *9000 | int & >0 & <=65535
		}
		envVars:         [...corev1.#EnvVar]
		initContainers:  [...corev1.#Container]
		sidecars:        [...corev1.#Container]
	}

	persistence: {
		worker: {
			enabled:       *true | bool
			existingClaim: *"" | string
			size:          *"8Gi" | string
			storageClass:  *"" | string
			accessModes:   *["ReadWriteOnce"] | [...string]
		}
		logs: {
			enabled:       *false | bool
			existingClaim: *"" | string
			size:          *"8Gi" | string
			storageClass:  *"" | string
			accessModes:   *["ReadWriteOnce"] | [...string]
		}
	}

	ingress: {
		enabled:      *false | bool
		ingressName?: string
		className?:   string
		annotations:  {[string]: string}
		hosts: [...{
			host: string
			paths: [...{
				path:     string
				pathType: *"ImplementationSpecific" | string
			}]
		}]
		tls: [...{
			hosts: [...string]
			secretName: string
		}]
	}

	httproute: {
		enabled:     *false | bool
		name:         *"" | string
		annotations:  {[string]: string}
		parentRefs: [...{
			gatewayName:        string
			gatewayNamespace:   *_config.metadata.namespace | string
			gatewayKind?:       string
			gatewaySectionName?: string
		}]
		hostnames: [...string]
		rules: [...{
			matches: [...{
				path:     *"/" | string
				pathType: *"PathPrefix" | string
			}]
		}]
	}

	jobs: {
		volumePermissions: {
			enabled:      *false | bool
			jobName?:     string
			backoffLimit: *0 | int
			resources:    corev1.#ResourceRequirements
			nodeSelector: {[string]: string}
			tolerations:  [...corev1.#Toleration]
			affinity:     corev1.#Affinity
		}
		configure: {
			enabled:      *true | bool
			jobName?:     string
			fixVolume:    *true | bool
			backoffLimit: *0 | int
			resources:    corev1.#ResourceRequirements
			nodeSelector: {[string]: string}
			tolerations:  [...corev1.#Toleration]
			affinity:     corev1.#Affinity
			envVars:         *[] | [...corev1.#EnvVar]
			initContainers:  *[] | [...corev1.#Container]
			command:    [...string] | *["bash", "-c"]
			args:       [...string] | *[
				"""
				ls -1 apps > sites/apps.txt;
				[[ -f sites/common_site_config.json ]] || echo \"{}\" > sites/common_site_config.json;
				bench set-config -gp db_port $DB_PORT;
				bench set-config -g db_host $DB_HOST;
				bench set-config -g redis_cache $REDIS_CACHE;
				bench set-config -g redis_queue $REDIS_QUEUE;
				bench set-config -g redis_socketio $REDIS_QUEUE;
				bench set-config -gp socketio_port $SOCKETIO_PORT;
				""",
			]

		}
		createSite: {
			enabled:                *false | bool
			jobName?:               string
			forceCreate:            *false | bool
			siteName:               *"erp.cluster.local" | string
			adminPassword:          *"changeit" | string
			adminExistingSecret:    *"" | string
			adminExistingSecretKey: *"password" | string
			installApps:            *["erpnext"] | [...string]
			dbType:                 *"mariadb" | string
			backoffLimit:           *0 | int
			resources:              corev1.#ResourceRequirements
			nodeSelector:           {[string]: string}
			tolerations:            [...corev1.#Toleration]
			affinity:               corev1.#Affinity
		}
		createMultipleSites: {
			enabled:                *false | bool
			jobName?:               string
			forceCreate:            *false | bool
			sites: [...{
				name: string
				installApps: [...string]
			}]
			adminPassword:          *"changeit" | string
			adminExistingSecret:    *"" | string
			adminExistingSecretKey: *"password" | string
			dbType:                 *"mariadb" | string
			backoffLimit:           *0 | int
			resources:              corev1.#ResourceRequirements
			nodeSelector:           {[string]: string}
			tolerations:            [...corev1.#Toleration]
			affinity:               corev1.#Affinity
		}
		dropSite: {
			enabled:      *false | bool
			jobName?:     string
			forced:       *false | bool
			siteName:     *"erp.cluster.local" | string
			backoffLimit: *0 | int
			resources:    corev1.#ResourceRequirements
			nodeSelector: {[string]: string}
			tolerations:  [...corev1.#Toleration]
			affinity:     corev1.#Affinity
		}
		dropMultipleSites: {
			enabled:      *false | bool
			jobName?:     string
			forced:       *false | bool
			sites: [...{ name: string }]
			backoffLimit: *0 | int
			resources:    corev1.#ResourceRequirements
			nodeSelector: {[string]: string}
			tolerations:  [...corev1.#Toleration]
			affinity:     corev1.#Affinity
		}
		backup: {
			enabled:      *false | bool
			jobName?:     string
			siteName:     *"erp.cluster.local" | string
			withFiles:    *true | bool
			backoffLimit: *0 | int
			resources:    corev1.#ResourceRequirements
			nodeSelector: {[string]: string}
			tolerations:  [...corev1.#Toleration]
			affinity:     corev1.#Affinity
		}
		backupMultipleSites: {
			enabled:      *false | bool
			jobName?:     string
			withFiles:    *true | bool
			sites: [...{ name: string }]
			backoffLimit: *0 | int
			resources:    corev1.#ResourceRequirements
			nodeSelector: {[string]: string}
			tolerations:  [...corev1.#Toleration]
			affinity:     corev1.#Affinity
		}
		migrate: {
			enabled:      *false | bool
			jobName?:     string
			siteName:     *"erp.cluster.local" | string
			skipFailing:  *false | bool
			backoffLimit: *0 | int
			resources:    corev1.#ResourceRequirements
			nodeSelector: {[string]: string}
			tolerations:  [...corev1.#Toleration]
			affinity:     corev1.#Affinity
		}
		migrateMultipleSites: {
			enabled:      *false | bool
			jobName?:     string
			skipFailing:  *false | bool
			sites: [...{ name: string }]
			backoffLimit: *0 | int
			resources:    corev1.#ResourceRequirements
			nodeSelector: {[string]: string}
			tolerations:  [...corev1.#Toleration]
			affinity:     corev1.#Affinity
		}
		custom: {
			enabled:        *false | bool
			jobName:        *"" | string
			labels:         {[string]: string}
			backoffLimit:   *0 | int
			initContainers: [...corev1.#Container]
			containers:     [...corev1.#Container]
			restartPolicy:  *"Never" | string
			volumes:        [...corev1.#Volume]
			nodeSelector:   {[string]: string}
			affinity:       corev1.#Affinity
			tolerations:    [...corev1.#Toleration]
		}
	}

	imagePullSecrets: [...corev1.#LocalObjectReference]
	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	serviceAccount: {
		create: *true | bool
	}

	podSecurityContext: corev1.#PodSecurityContext
	securityContext:    corev1.#SecurityContext

	"mariadb-sts": {
		enabled: *false | bool
		image: {
			repository: *"mariadb" | string
			tag:        *"10.6" | string
			digest?:    string
			pullPolicy: *"IfNotPresent" | string
		}
		rootPassword: *"changeit" | string
		persistence: {
			size:         *"8Gi" | string
			storageClass: *"" | string
		}
		resources: corev1.#ResourceRequirements
		myCnf:     *"" | string
	}

	"mariadb-subchart": {
		enabled: *true | bool
		rootPassword?: string
		password?: string
		image: {
			repository: *"bitnamilegacy/mariadb" | string
			tag:        *"10.6.17-debian-11-r10" | string
		}
	}

	mariadb: {
		enabled: *false | bool
	}

	"dragonfly-cache": {
		enabled: *false | bool
		image: {
			repository: *"docker.io/dragonflydb/dragonfly" | string
			tag:        *"latest" | string
			pullPolicy: *"IfNotPresent" | string
		}
		args?: [...string]
	}

	"dragonfly-queue": {
		enabled: *false | bool
		storage: {
			enabled: *false | bool
			size:    *"8Gi" | string
		}
		image: {
			repository: *"docker.io/dragonflydb/dragonfly" | string
			tag:        *"latest" | string
			pullPolicy: *"IfNotPresent" | string
		}
		args?: [...string]
	}

	postgresql: {
		enabled: *false | bool
	}

	"postgresql-subchart": {
		enabled: *false | bool
		image: {
			repository: *"bitnamilegacy/postgresql" | string
			tag:        *"14" | string
		}
	}

	"postgresql-sts": {
		enabled: *false | bool
		image: {
			repository: *"postgres" | string
			tag:        *"15" | string
			digest?:    string
			pullPolicy: *"IfNotPresent" | string
		}
		postgresUser:     *"postgres" | string
		postgresPassword: *"changeit" | string
		persistence: {
			size:         *"8Gi" | string
			storageClass: *"" | string
		}
		resources: corev1.#ResourceRequirements
	}

	"redis-cache": {
		enabled: *false | bool
		image: {
			repository: *"bitnamilegacy/redis" | string
			tag:        *"7.0" | string
			digest?:    string
		}
	}

	"redis-queue": {
		enabled: *false | bool
		image: {
			repository: *"bitnamilegacy/redis" | string
			tag:        *"7.0" | string
			digest?:    string
		}
	}

	"valkey-cache": {
		enabled: *true | bool
		image: {
			repository: *"valkey/valkey" | string
			tag:        *"7.2" | string
			digest?:    string
		}
	}

	"valkey-queue": {
		enabled: *true | bool
		image: {
			repository: *"valkey/valkey" | string
			tag:        *"7.2" | string
			digest?:    string
		}
	}

	test: {
		enabled: *false | bool
	}

	_healthProbe: corev1.#Probe & {
		_dbPart: [
			if _config["mariadb-sts"].enabled {
				"wait-for-it \(_config.metadata.name)-mariadb-sts:3306 -t 5;"
			},
			if !_config["mariadb-sts"].enabled && _config["postgresql-sts"].enabled {
				"wait-for-it \(_config.metadata.name)-postgresql-sts:5432 -t 5;"
			},
			if !_config["mariadb-sts"].enabled && !_config["postgresql-sts"].enabled && (_config.mariadb.enabled || _config["mariadb-subchart"].enabled) {
				"( wait-for-it \(_config.metadata.name)-mariadb-subchart:3306 -t 0 || wait-for-it \(_config.metadata.name)-mariadb:3306 -t 0 || wait-for-it \(_config.metadata.name)-mariadb-subchart-primary:3306 -t 0 || wait-for-it \(_config.metadata.name)-mariadb-primary:3306 -t 5 )"
			},
			if !_config["mariadb-sts"].enabled && !_config["postgresql-sts"].enabled && !(_config.mariadb.enabled || _config["mariadb-subchart"].enabled) && (_config.postgresql.enabled || _config["postgresql-subchart"].enabled) {
				"( wait-for-it \(_config.metadata.name)-postgresql-subchart:5432 -t 0 || wait-for-it \(_config.metadata.name)-postgresql:5432 -t 5 )"
			},
			if !_config["mariadb-sts"].enabled && !_config["postgresql-sts"].enabled && !(_config.mariadb.enabled || _config["mariadb-subchart"].enabled) && !(_config.postgresql.enabled || _config["postgresql-subchart"].enabled) && _config.dbHost != _|_ && _config.dbHost != "" {
				"wait-for-it \(_config.dbHost):\(_config.dbPort) -t 5;"
			},
		]
		_redisCachePart: [
			if _config.externalRedis.cache != "" {
				"wait-for-it $(echo \(_config.externalRedis.cache) | sed 's,redis://,,') -t 5;"
			},
			if _config.externalRedis.cache == "" && _config["valkey-cache"].enabled {
				"wait-for-it \(_config.metadata.name)-valkey-cache:6379 -t 5;"
			},
			if _config.externalRedis.cache == "" && !_config["valkey-cache"].enabled && _config["dragonfly-cache"].enabled {
				"wait-for-it \(_config.metadata.name)-dragonfly-cache:6379 -t 5;"
			},
			if _config.externalRedis.cache == "" && !_config["valkey-cache"].enabled && !_config["dragonfly-cache"].enabled && _config["redis-cache"].enabled {
				"wait-for-it \(_config.metadata.name)-redis-cache-master:6379 -t 5;"
			},
		]
		_redisQueuePart: [
			if _config.externalRedis.queue != "" {
				"wait-for-it $(echo \(_config.externalRedis.queue) | sed 's,redis://,,') -t 5;"
			},
			if _config.externalRedis.queue == "" && _config["valkey-queue"].enabled {
				"wait-for-it \(_config.metadata.name)-valkey-queue:6379 -t 5;"
			},
			if _config.externalRedis.queue == "" && !_config["valkey-queue"].enabled && _config["dragonfly-queue"].enabled {
				"wait-for-it \(_config.metadata.name)-dragonfly-queue:6379 -t 5;"
			},
			if _config.externalRedis.queue == "" && !_config["valkey-queue"].enabled && !_config["dragonfly-queue"].enabled && _config["redis-queue"].enabled {
				"wait-for-it \(_config.metadata.name)-redis-queue-master:6379 -t 5;"
			},
		]

		exec: command: [
			"bash",
			"-c",
			strings.Join(list.Concat([["echo \"Pinging backing services\";"], _dbPart, _redisCachePart, _redisQueuePart]), "\n"),
		]
		initialDelaySeconds: 15
		periodSeconds:       5
		timeoutSeconds:      5
	}

	#_defaultProbe: corev1.#Probe & {
		tcpSocket: port: int | string
		initialDelaySeconds: 5
		periodSeconds:       10
	}
}


// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		[string]: metadata: namespace: config.metadata.namespace
		"sa-erpnext": #ServiceAccount & {#config: config}

		if config.nginx.config != _|_ && config.nginx.config != "" {
			"cm-nginx": #NginxConfigMap & {#config: config}
		}

		"deploy-nginx": #NginxDeployment & {#config: config}
		"svc-nginx":    #NginxService & {#config: config}

		"deploy-gunicorn": #GunicornDeployment & {#config: config}
		"svc-gunicorn":    #GunicornService & {#config: config}

		"deploy-socketio": #SocketioDeployment & {#config: config}
		"svc-socketio":    #SocketioService & {#config: config}

		"deploy-worker-default": #WorkerDefaultDeployment & {#config: config}
		"deploy-worker-short":   #WorkerShortDeployment & {#config: config}
		"deploy-worker-long":    #WorkerLongDeployment & {#config: config}
		"deploy-scheduler":      #SchedulerDeployment & {#config: config}

		if config.nginx.autoscaling.enabled {
			"hpa-nginx": #NginxHPA & {#config: config}
		}

		if config.worker.gunicorn.autoscaling.enabled {
			"hpa-gunicorn": #GunicornHPA & {#config: config}
		}

		if config.socketio.autoscaling.enabled {
			"hpa-socketio": #SocketioHPA & {#config: config}
		}

		if config.worker.default.autoscaling.enabled {
			"hpa-worker-default": #WorkerDefaultHPA & {#config: config}
		}

		if config.worker.short.autoscaling.enabled {
			"hpa-worker-short": #WorkerShortHPA & {#config: config}
		}

		if config.worker.long.autoscaling.enabled {
			"hpa-worker-long": #WorkerLongHPA & {#config: config}
		}

		// Ensure all objects are part of the for-comprehension by being in this struct

		if config.jobs.createSite.enabled {
			"job-create-site": #CreateSiteJob & {#config: config}
		}

		if config.jobs.migrate.enabled {
			"job-migrate-site": #MigrateSiteJob & {#config: config}
		}

		if config.jobs.configure.enabled {
			"job-configure-bench": #ConfigureBenchJob & {#config: config}
		}

		if config.jobs.volumePermissions.enabled {
			"job-fix-volume-permission": #FixVolumeJob & {#config: config}
		}

		if config.jobs.custom.enabled {
			"job-custom": #CustomJob & {#config: config}
		}

		if config.jobs.backup.enabled {
			"job-backup": #BackupJob & {#config: config}
		}

		if config.jobs.backupMultipleSites.enabled {
			"job-backup-multiple-sites": #BackupMultipleSitesJob & {#config: config}
		}

		if config.jobs.migrateMultipleSites.enabled {
			"job-migrate-multiple-sites": #MigrateMultipleSitesJob & {#config: config}
		}

		if config.jobs.createMultipleSites.enabled {
			"job-create-multiple-sites": #CreateMultipleSitesJob & {#config: config}
		}

		if config.jobs.dropSite.enabled {
			"job-drop-site": #DropSiteJob & {#config: config}
		}

		if config.jobs.dropMultipleSites.enabled {
			"job-drop-multiple-sites": #DropMultipleSitesJob & {#config: config}
		}

		if config["mariadb-sts"].enabled {
			"statefulset-mariadb": #MariaDBStatefulSet & {#config: config}
			"service-mariadb":     #MariaDBService & {#config: config}
			if config["mariadb-sts"]["myCnf"] != _|_ {
				"configmap-mariadb": #MariaDBConfigMap & {#config: config}
			}

			if config["mariadb-subchart"].enabled {
			"mariadb-subchart":     #MariaDBSubchart & {#config: config}
			"mariadb-subchart-svc": #MariaDBSubchartSVC & {#config: config}
		}

		}

		if config["postgresql-sts"].enabled {
			"statefulset-postgresql": #PostgreSQLStatefulSet & {#config: config}
			"service-postgresql":     #PostgreSQLService & {#config: config}
		}

		if config["postgresql-subchart"].enabled {
			"postgresql-subchart":     #PostgreSQLSubchart & {#config: config}
			"postgresql-subchart-svc": #PostgreSQLSubchartSVC & {#config: config}
		}

		if config["valkey-cache"].enabled {
			"deploy-valkey-cache": #ValkeyCacheDeployment & {#config: config}
			"svc-valkey-cache":    #ValkeyCacheService & {#config: config}
		}

		if config["valkey-queue"].enabled {
			"deploy-valkey-queue": #ValkeyQueueDeployment & {#config: config}
			"svc-valkey-queue":    #ValkeyQueueService & {#config: config}
		}

		if config["dragonfly-cache"].enabled {
			"deploy-dragonfly-cache": #DragonflyCacheDeployment & {#config: config}
			"svc-dragonfly-cache":    #DragonflyCacheService & {#config: config}
		}

		if config["dragonfly-queue"].enabled {
			"deploy-dragonfly-queue": #DragonflyQueueDeployment & {#config: config}
			"svc-dragonfly-queue":    #DragonflyQueueService & {#config: config}
		}

		if config["redis-cache"].enabled {
			"deploy-redis-cache": #RedisCacheDeployment & {#config: config}
			"svc-redis-cache":    #RedisCacheService & {#config: config}
		}

		if config["redis-queue"].enabled {
			"deploy-redis-queue": #RedisQueueDeployment & {#config: config}
			"svc-redis-queue":    #RedisQueueService & {#config: config}
		}

		if config.persistence.worker.enabled && config.persistence.worker.existingClaim == "" {
			"pvc-worker": #WorkerPVC & {#config: config}
		}

		if config.persistence.logs.enabled && config.persistence.logs.existingClaim == "" {
			"pvc-logs": #LogsPVC & {#config: config}
		}

		// Check if we need to create the Secret
		_createSecret: (config["postgresql-sts"].enabled && config["postgresql-sts"].postgresPassword != _|_) ||
			(config["postgresql-subchart"].enabled) ||
			(config["mariadb-sts"].enabled && config["mariadb-sts"].rootPassword != _|_) ||
			(config.dbRootPassword != _|_ && config.dbExistingSecret == "") || true // Always create merged secret

		if _createSecret {
			"secret": #Secret & {#config: config}
		}


		if config.ingress.enabled {
			"ingress": #Ingress & {#config: config}
		}

		if config.httproute.enabled {
			"httproute": #HTTPRoute & {#config: config}
		}
	}

	tests: {
		if config.test.enabled {
			"test-job": #TestJob & {#config: config}
		}
	}
}
