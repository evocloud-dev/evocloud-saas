package templates

import (
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
	metadata:      timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: {
		name:      string
		namespace: string
	}

	// Secret references - derived from metadata.name
	ncSecretRef: metadata.name
	if nextcloud.existingSecret.secretName != "" {
		ncSecretRef: nextcloud.existingSecret.secretName
	}

	dbSecretRef: metadata.name + "-db"
	if database.externalDatabase.existingSecret.secretName != "" {
		dbSecretRef: database.externalDatabase.existingSecret.secretName
	}

	// Helm metadata overrides
	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	// The labels allows adding `metadata.labels` to all resources.
	// The `app.kubernetes.io/name` and `app.kubernetes.io/version` labels
	// are automatically generated and can't be overwritten.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	// The default image repository and tag is set in `values.cue`.
	image!: timoniv1.#Image

	deploymentAnnotations: *{} | {[string]: string}
	deploymentLabels:    *{} | {[string]: string}

	nextcloud: {
		containerPort: *80 | int & >0 & <=65535
		host:          *"nextcloud.kube.home" | string
		datadir:       *"/var/www/html/data" | string
		trustedDomains: [...string] | *[]
		trustedProxies: [...string] | *[]
		maintenanceWindowStart: *1 | int
		forceSTSSet:            *false | bool
		bruteForceProtection:   *true | bool
		bruteForceWhitelistedIps: [...string] | *[]
		update: *0 | int

		phpConfigs: {[string]: string} | *{}
		defaultConfigs: {
			[string]: bool
			"maintenance.config.php": *true | bool
		} | *{}
		configs: {[string]: string} | *{}

		// The Hooks Contract
		hooks: {[string]: string} | *{}

		// Admin credentials — required when existingSecret.enabled == false
		username: *"admin" | string
		password: *"changeme" | string

		// Reuse a pre-existing Secret instead of creating one
		existingSecret: {
			enabled:        *false | bool
			secretName:     *"" | string
			usernameKey:    *"nextcloud-username" | string
			passwordKey:    *"nextcloud-password" | string
			tokenKey:       *"" | string
			smtpUsernameKey: *"smtp-username" | string
			smtpPasswordKey: *"smtp-password" | string
			smtpHostKey:    *"smtp-host" | string
		}

		// SMTP mail configuration
		mail: {
			enabled:     *false | bool
			fromAddress: *"user" | string
			domain:      *"domain.com" | string
			smtp: {
				host:     *"domain.com" | string
				secure:   *"ssl" | string
				port:     *465 | int
				authtype: *"LOGIN" | string
				name:     *"user" | string
				password: *"pass" | string
			}
		}

		// Primary ObjectStore options
		objectStore: {
			s3: {
				enabled:        *false | bool
				accessKey:      *"" | string
				secretKey:      *"" | string
				legacyAuth:     *false | bool
				host:           *"" | string
				ssl:            *true | bool
				port:           *"443" | string
				region:         *"eu-west-1" | string
				bucket:         *"" | string
				prefix:         *"" | string
				usePathStyle:   *false | bool
				autoCreate:     *false | bool
				storageClass:   *"STANDARD" | string
				sse_c_key:      *"" | string
				existingSecret: *"" | string
				secretKeys: {
					host:      *"" | string
					accessKey: *"" | string
					secretKey: *"" | string
					bucket:    *"" | string
					sse_c_key: *"" | string
				}
			}
			swift: {
				enabled:    *false | bool
				autoCreate: *false | bool
				user: {
					name:     *"" | string
					password: *"" | string
					domain:   *"" | string
				}
				project: {
					name:   *"" | string
					domain: *"" | string
				}
				service:   *"" | string
				region:    *"" | string
				url:       *"" | string
				container: *"" | string
			}
		}

		phpClientHttpsFix: {
			enabled:  *false | bool
			protocol: *"https" | string
		}

		extraEnv: [...corev1.#EnvVar] | *[]
	}

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
	securityContext?: corev1.#SecurityContext

	// The podSecurityContext allows setting the pod security context.
	podSecurityContext?: corev1.#PodSecurityContext

	// The service allows setting the Kubernetes Service annotations and port.
	// By default, the HTTP port is 80.
	service: {
		type: *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
		port: *80 | int & >0 & <=65535

		annotations?: timoniv1.#Annotations
		nodePort?: int & >0 & <=65535

		loadBalancerIP: *"" | string
		ipFamilies:     *[...string] | [...string]
		ipFamilyPolicy: *"" | corev1.#IPFamilyPolicy

		sessionAffinity:       *"" | corev1.#ServiceAffinity
		sessionAffinityConfig: *null | corev1.#SessionAffinityConfig
	}

	// Pod optional settings.
	podAnnotations?: {[string]: string}
	podSecurityContext?: corev1.#PodSecurityContext
	imagePullSecrets?: [...timoniv1.#ObjectReference]
	tolerations?: [...corev1.#Toleration]
	affinity?: corev1.#Affinity
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	lifecycle?: corev1.#Lifecycle

	// Test Job disabled by default.
	test: {
		enabled: *false | bool
		image!:  timoniv1.#Image
	}

	metrics: {
		enabled:      *false | bool
		replicaCount: *1 | int & >0
		image: timoniv1.#Image & {
			reference:  *"docker.io/xperimental/nextcloud-exporter:0.8.0" | string
			repository: *"xperimental/nextcloud-exporter" | string
			tag:        *"0.8.0" | string
			digest:     *"" | string
		}
		server:       *"" | string
		timeout:      *"5s" | string
		tlsSkipVerify: *false | bool
		https:        *false | bool
		token:        *"" | string
		info: {
			apps:   *false | bool
			update: *false | bool
		}
		service: {
			type:           *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
			loadBalancerIP: *"" | string
			annotations?:   timoniv1.#Annotations
			labels?:        {[string]: string}
		}
		// Prometheus Operator ServiceMonitor configuration
		serviceMonitor: {
			enabled:         *false | bool
			namespace:       *"" | string
			jobLabel:        *"" | string
			interval:        *"30s" | string
			scrapeTimeout:   *"" | string
			labels?:         {[string]: string}
			namespaceSelector?: _
		}
		// Prometheus alerting rules configuration
		rules: {
			enabled: *false | bool
			labels?: {[string]: string}
			defaults: {
				enabled: *true | bool
				filter:  *"" | string
				labels?: {[string]: string}
			}
			additionalRules?: [..._]
		}
	}

	// Imaginary sub-component for faster image processing
	imaginary: {
		enabled:      *false | bool
		replicaCount: *1 | int & >0
		image: timoniv1.#Image & {
			reference:  *"docker.io/nextcloud/aio-imaginary:latest" | string
			repository: *"nextcloud/aio-imaginary" | string
			tag:        *"latest" | string
			digest:     *"" | string
		}
		service: {
			type:           *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
			nodePort?:      int & >0 & <=65535
			loadBalancerIP: *"" | string
			annotations?:   timoniv1.#Annotations
			labels?:        {[string]: string}
		}
		readinessProbe: {
			enabled:          *true | bool
			failureThreshold: *3 | int
			successThreshold: *1 | int
			periodSeconds:    *10 | int
			timeoutSeconds:   *5 | int
		}
		livenessProbe: {
			enabled:          *true | bool
			failureThreshold: *3 | int
			successThreshold: *1 | int
			periodSeconds:    *10 | int
			timeoutSeconds:   *5 | int
		}
		primaryHost: string | *(metadata.name + "-imaginary")
	}

	// Database settings — mirrors Helm mariadb/postgresql/externalDatabase.
	// Exactly one engine should be enabled at a time.
	database: {
		// Internal SQLite database (development only)
		internalDatabase: {
			enabled: bool | *true
			name:    *"nextcloud" | string
		}
		mariadb: {
			enabled:     *false | bool
			image:       *"docker.io/bitnami/mariadb:latest" | string
			primaryHost: string | *(metadata.name + "-mariadb")
			auth: {
				username:     *"nextcloud" | string
				password:     *"changeme" | string
				rootPassword: *"changeme" | string
				database:     *"nextcloud" | string
			}
			persistence: {
				enabled:      *false | bool
				storageClass: *"" | string
				accessMode:   *"ReadWriteOnce" | corev1.#PersistentVolumeAccessMode
				size:         *"8Gi" | timoniv1.#MemoryQuantity
			}
		}
		postgresql: {
			enabled:     *false | bool
			image:       *"docker.io/bitnami/postgresql:latest" | string
			primaryHost: string | *(metadata.name + "-postgresql")
			auth: {
				username:     *"nextcloud" | string
				password:     *"changeme" | string
				// Bitnami Postgres uses POSTGRESQL_POSTGRES_PASSWORD for the 'postgres' user
				rootPassword: *"changeme" | string
				database:     *"nextcloud" | string
			}
			persistence: {
				enabled:      *false | bool
				storageClass: *"" | string
				accessMode:   *"ReadWriteOnce" | corev1.#PersistentVolumeAccessMode
				size:         *"8Gi" | timoniv1.#MemoryQuantity
			}
		}
		if database.mariadb.enabled || database.postgresql.enabled || database.externalDatabase.enabled {
			internalDatabase: enabled: false
		}

		externalDatabase: {
			enabled:  *false | bool
			type:     *"mysql" | "mysql" | "postgresql"
			host:     *"" | string
			user:     *"nextcloud" | string
			password: *"" | string
			database: *"nextcloud" | string
			existingSecret: {
				enabled:     *false | bool
				secretName:  *"" | string
				usernameKey: *"db-username" | string
				passwordKey: *"db-password" | string
				hostKey:     *"" | string
				databaseKey: *"" | string
			}
		}
	}

	// Redis settings — for Nextcloud session/cache
	redis: {
		enabled: bool | *false
		image: {
			registry:   string | *"docker.io"
			repository: string | *"bitnamilegacy/redis"
			tag:        string | *"latest"
		}
		auth: {
			enabled:                   bool | *true
			password:                  string | *"changeme"
			existingSecret:            string | *""
			existingSecretPasswordKey: string | *""
		}
		global: storageClass: string | *""
		master: persistence: {
			enabled:      bool | *true
			size:         string | *"1Gi"
			storageClass: string | *""
			accessMode:   corev1.#PersistentVolumeAccessMode | *"ReadWriteOnce"
		}
		port: *6379 | int
		_name: metadata.name + "-redis"
		primaryHost: string | *(_name + "-master")
	}

	// External Redis — use when Redis is not deployed via sub-chart
	externalRedis: {
		enabled:  *false | bool
		host:     *"" | string
		port:     *"6379" | string
		password: *"" | string
	}

	// App settings.
	// RBAC settings
	rbac: {
		enabled: *false | bool
		serviceAccount: {
			create: *true | bool
			name:   *"" | string
			annotations?: timoniv1.#Annotations
		}
	}

	// Persistence settings – literal mirror of Helm persistence values.
	persistence: {
		enabled: *false | bool

		// storageClass: "-" disables dynamic provisioning, "" uses cluster default
		storageClass: *"" | string

		// Reuse a pre-existing PVC; when set no new PVC is created
		existingClaim: *"" | string

		accessMode: *"ReadWriteOnce" | corev1.#PersistentVolumeAccessMode
		size:       *"8Gi" | timoniv1.#MemoryQuantity

		annotations: *{} | {[string]: string}
		labels:      *{} | {[string]: string}

		// When non-empty a hostPath volume is used instead of a PVC
		hostPath: *"" | string
		subPath:  *"" | string

		// Separate PVC for user-uploaded data (/var/www/html/data)
		nextcloudData: {
			enabled: *false | bool

			storageClass:  *"" | string
			existingClaim: *"" | string
			accessMode:    *"ReadWriteOnce" | corev1.#PersistentVolumeAccessMode
			size:          *"8Gi" | timoniv1.#MemoryQuantity

			annotations: *{} | {[string]: string}
			labels:      *{} | {[string]: string}

			hostPath: *"" | string
			subPath:  *"" | string
		}
	}

	// HPA settings — when enabled, replicas is not set in the Deployment spec.
	hpa: {
		enabled:         *false | bool
		minPods:         *1 | int
		maxPods:         *10 | int
		cputhreshold:    *60 | int
	}

	cronjob: {
		enabled:   *false | bool
		type:      *"cronjob" | "sidecar"
		schedule:  *"*/5 * * * *" | string
		successfulJobsHistoryLimit: *3 | int
		failedJobsHistoryLimit:     *5 | int
		concurrencyPolicy:          *"Forbid" | string
		backoffLimit:               *1 | int
	}

	ingress: {
		enabled:   *false | bool
		className: *"" | string
		path:      *"/" | string
		pathType:  *"ImplementationSpecific" | string
		tls:       *[...] | [...]
		annotations: {[string]: string} | *{}
		labels:      {[string]: string} | *{}
	}

	httpRoute: {
		enabled:   *false | bool
		apiVersion: *"gateway.networking.k8s.io/v1beta1" | string
		kind:       *"HTTPRoute" | string
		parentRefs: *[...] | [...]
		hostnames:  *[...] | [...]
		rules:      *[...] | [...]
		annotations: {[string]: string} | *{}
	}

	// Nginx sidecar — when enabled Nextcloud runs as FPM and nginx serves HTTP.
	nginx: {
		enabled:         *false | bool
		image:           *"docker.io/library/nginx:alpine" | string
		imagePullPolicy: *"IfNotPresent" | corev1.#PullPolicy

		containerPort: *80 | int
		ipFamilies:    *["IPv4"] | [...string]

		config: {
			default:           *true | bool
			serverBlockCustom: *"""
				# set max upload size
				client_max_body_size 10G;
				client_body_timeout 300s;
				fastcgi_buffers 64 4K;
				fastcgi_read_timeout 3600s;
				""" | string
			custom?:           string
			headers:           {[string]: string} | *{
				"Strict-Transport-Security": ""
				"Referrer-Policy":           "no-referrer"
				"X-Content-Type-Options":    "nosniff"
				"X-Frame-Options":           "SAMEORIGIN"
				"X-Permitted-Cross-Domain-Policies": "none"
				"X-Robots-Tag":              "noindex, nofollow"
				"X-XSS-Protection":          "1; mode=block"
			}
		}

		resources:       corev1.#ResourceRequirements | *{}
		securityContext: corev1.#SecurityContext | *{}

		extraEnv: [...corev1.#EnvVar] | *[]
	}

	// Health probe settings — mirroring Helm's livenessProbe/readinessProbe/startupProbe blocks.
	livenessProbe: {
		enabled:             *true | bool
		initialDelaySeconds: *10 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		successThreshold:    *1 | int
		failureThreshold:    *3 | int
	}
	readinessProbe: {
		enabled:             *true | bool
		initialDelaySeconds: *10 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		successThreshold:    *1 | int
		failureThreshold:    *30 | int
	}
	startupProbe: {
		enabled:             *false | bool
		initialDelaySeconds: *30 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		successThreshold:    *1 | int
		failureThreshold:    *30 | int
	}

	priorityClassName: *"" | string
}

#Instance: {
	config: #Config

	objects: {
		if config.rbac.enabled && config.rbac.serviceAccount.create {
			sa: #ServiceAccount & {#in: config}
		}
		svc: #Service & {#in: config}
		cm:  #ConfigMap & {#in: config}

		// php-config.yaml — only when phpConfigs are provided
		if len([for k, v in config.nextcloud.phpConfigs {k}]) > 0 {
			phpCm: #PhpConfigMap & {#in: config}
		}
		if len([for k, v in config.nextcloud.hooks {k}]) > 0 {
			hooks: #Hooks & {#in: config}
		}

		if config.rbac.enabled {
			privilegedRole:        #Role & {#in: config}
			privilegedRoleBinding: #RoleBinding & {#in: config}
		}

		// nextcloud-pvc.yaml – only when enabled, no hostPath, no existingClaim
		if config.persistence.enabled &&
			config.persistence.hostPath == "" &&
			config.persistence.existingClaim == "" {
			nextcloudPVC: #NextcloudPVC & {#in: config}
		}

		// nextcloud-data-pvc.yaml – only when both persistence and nextcloudData are enabled
		if config.persistence.enabled &&
			config.persistence.nextcloudData.enabled &&
			config.persistence.nextcloudData.hostPath == "" &&
			config.persistence.nextcloudData.existingClaim == "" {
			nextcloudDataPVC: #NextcloudDataPVC & {#in: config}
		}

		deploy: #Deployment & {
			#in:      config
			#ncSecretRef: config.ncSecretRef
			#dbSecretRef: config.dbSecretRef
			if objects.cm != _|_ {
				#cmName: objects.cm.metadata.name
			}
		}

		if config.nginx.enabled {
			nginxConfigMap: #NginxConfigMap & {#in: config}
		}

		// secrets.yaml – only when not using a pre-existing secret
		if !config.nextcloud.existingSecret.enabled {
			secret: #NextcloudSecret & {#in: config}
		}

		// db-secret.yaml – only when a DB engine is enabled AND no existingSecret
		if (config.database.mariadb.enabled ||
			config.database.postgresql.enabled ||
			config.database.externalDatabase.enabled) &&
			!config.database.externalDatabase.existingSecret.enabled {
			dbSecret: #DbSecret & {#in: config}
		}

		// Advanced Capabilities (Phase 6)
		if config.cronjob.enabled {
			cronjob: #CronJob & {
				#in:      config
				#ncSecretRef: config.ncSecretRef
				#dbSecretRef: config.dbSecretRef
			}
		}

		if config.database.postgresql.enabled && config.database.postgresql.primaryHost == config.metadata.name + "-postgresql" {
			dbDeploy: (#PostgreSQL & {#in: config}).deployment
			dbSvc:    (#PostgreSQL & {#in: config}).service
			if config.database.postgresql.persistence.enabled {
				dbPVC: #DatabasePVC & {
					#in:          config
					#persistence: config.database.postgresql.persistence
					#name:        config.database.postgresql.primaryHost
				}
			}
		}

		if config.database.mariadb.enabled && config.database.mariadb.primaryHost == config.metadata.name + "-mariadb" {
			dbDeploy: (#MariaDB & {#in: config}).deployment
			dbSvc:    (#MariaDB & {#in: config}).service
			if config.database.mariadb.persistence.enabled {
				dbPVC: #DatabasePVC & {
					#in:          config
					#persistence: config.database.mariadb.persistence
					#name:        config.database.mariadb.primaryHost
				}
			}
		}

		if config.redis.enabled {
			redisDeploy: (#Redis & {#in: config}).deployment
			redisSvc:    (#Redis & {#in: config}).service
			if config.redis.master.persistence.enabled {
				redisPVC: #DatabasePVC & {
					#in:          config
					#persistence: config.redis.master.persistence
					#name:        config.metadata.name + "-redis"
				}
			}
		}


		if config.ingress.enabled {
			ingress: #Ingress & {#in: config}
		}
		if config.httpRoute.enabled {
			httpRoute: #HTTPRoute & {#in: config}
		}
		if config.hpa.enabled {
			hpa: #HorizontalPodAutoscaler & {#in: config}
		}

		// Phase 6 Extensions
		if config.imaginary.enabled {
			imaginaryDeploy: #ImaginaryDeployment & {#in: config}
			imaginarySvc:    #ImaginaryService & {#in: config}
		}
		if config.metrics.enabled {
			metricsDeploy: #MetricsDeployment & {#in: config}
			metricsSvc:    #MetricsService & {#in: config}
		}
		if config.metrics.enabled && config.metrics.serviceMonitor.enabled {
			serviceMonitor: #ServiceMonitor & {#in: config}
		}
		if config.metrics.rules.enabled {
			prometheusRules: #PrometheusRule & {#in: config}
		}
	}

	tests: {
		"test-svc": #TestJob & {#in: config}
	}
}