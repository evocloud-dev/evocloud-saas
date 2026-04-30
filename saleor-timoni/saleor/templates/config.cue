package templates

import (
	corev1 "k8s.io/api/core/v1"
	"list"
	"strings"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}
	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations
	test: {
		enabled: bool | *false
	}
	tests: {
		// Placeholder for tests
	}

	selector: timoniv1.#Selector & {#Name: metadata.name}

	global: {
		imagePullSecrets: [...timoniv1.#ObjectReference] | *[]
		storageClass:     string | *""
		databaseUrl:      string | *""
		secretKey:        string | *""
		redisUrl:         string | *""
		celeryRedisUrl:   string | *""
		jwtRsaPrivateKey?: string
		jwtRsaPublicKey?:  string
		extraSecrets: {[string]: string} | *{}
		image: {
			repository: string | *"ghcr.io/saleor/saleor"
			tag:        string | *"3.23.3"
			pullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
		}
		database: {
			primaryUrl:        string | *""
			replicaUrl:        string | *""
			maxConnections:    int | *150
			connectionTimeout: int | *5
			connMaxAge:        int | *0
		}
		tls: {
			enabled:    bool | *false
			secretName: string | *""
		}
	}

	serviceMesh: {
		enabled: bool | *false
		istio: {
			enabled: bool | *false
			api: {
				circuitBreaker: {
					enabled:        bool | *false
					maxConnections: int | *100
				}
				timeout: {
					enabled: bool | *false
					http:    string | *"10s"
				}
				connectionPool: {
					enabled:                  bool | *false
					http1MaxPendingRequests:  int | *1024
					maxRequestsPerConnection: int | *100
				}
				outlierDetection: {
					enabled:              bool | *false
					consecutiveErrors:    int | *5
					interval:             string | *"10s"
					baseEjectionTime:     string | *"30s"
					maxEjectionPercent:   int | *10
				}
				loadBalancer: {
					enabled: bool | *false
				}
			}
		}
	}

	commonLabels: {[string]:      string} | *{}
	commonAnnotations: {[string]: string} | *{}

	api: {
		enabled:      bool | *true
		replicaCount: int & >0 | *2
		extraEnv: [...corev1.#EnvVar] | *[
			{name: "ALLOWED_HOSTS", value:        "*"},
			{name: "ALLOWED_CLIENT_HOSTS", value: "*"},
		]
		service: {
			type: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
			port: int & >0 & <=65535 | *8000
		}
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    string | *"1000m"
				memory: string | *"512Mi"
			}
			limits: memory: string | *"1Gi"
		}
		autoscaling: {
			enabled:                        bool | *true
			minReplicas:                    int | *2
			maxReplicas:                    int | *4
			targetCPUUtilizationPercentage: int | *80
		}
		securityContext?:    corev1.#SecurityContext
		podAnnotations?:     {[string]: string}
		imagePullSecrets?:   [...timoniv1.#ObjectReference]
		nodeSelector?:       {[string]: string}
		tolerations?:        [...corev1.#Toleration]
		affinity?:           corev1.#Affinity
		podSecurityContext?: corev1.#PodSecurityContext
	}

	dashboard: {
		enabled:      bool | *true
		replicaCount: int & >0 | *1
		image: {
			repository: string | *"ghcr.io/saleor/saleor-dashboard"
			tag:        string | *"3.23.3"
			pullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
		}
		appsMarketplaceApiUrl: string | *"https://apps.saleor.io/api/v2/saleor-apps"
		appsExtensionsApiUrl:  string | *"https://apps.saleor.io/api/v2/saleor-apps"
		isCloudInstance:       bool | *false
		extraEnv: [...corev1.#EnvVar] | *[]
		service: {
			type: "ClusterIP" | "NodePort" | "LoadBalancer" | *"ClusterIP"
			port: int & >0 & <=65535 | *80
		}
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    string | *"100m"
				memory: string | *"128Mi"
			}
			limits: {
				cpu:    string | *"500m"
				memory: string | *"256Mi"
			}
		}
		autoscaling: {
			enabled:                           bool | *false
			minReplicas:                       int | *1
			maxReplicas:                       int | *3
			targetCPUUtilizationPercentage:    int | *80
			targetMemoryUtilizationPercentage: int | *80
		}
		securityContext: corev1.#SecurityContext & {
			runAsUser:  int | *0
			runAsGroup: int | *0
		}
		podAnnotations?:     {[string]: string}
		imagePullSecrets?:   [...timoniv1.#ObjectReference]
		volumeMounts:        [...corev1.#VolumeMount] | *[]
		volumes:             [...corev1.#Volume] | *[]
		nodeSelector?:       {[string]: string}
		tolerations?:        [...corev1.#Toleration]
		affinity?:           corev1.#Affinity
		podSecurityContext?: corev1.#PodSecurityContext
	}

	worker: {
		enabled:      bool | *true
		replicaCount: int | *1
		extraEnv: [...corev1.#EnvVar] | *[]
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    string | *"100m"
				memory: string | *"128Mi"
			}
			limits: cpu: string | *"500m"
		}
		autoscaling: {
			enabled:                           bool | *false
			minReplicas:                       int | *1
			maxReplicas:                       int | *3
			targetCPUUtilizationPercentage:    int | *80
			targetMemoryUtilizationPercentage: int | *80
		}
		scheduler: {
			resources: timoniv1.#ResourceRequirements & {
				requests: {
					cpu:    string | *"100m"
					memory: string | *"200Mi"
				}
				limits: {
					cpu:    string | *"300m"
					memory: string | *"400Mi"
				}
			}
		}
		nodeSelector?:       {[string]: string}
		tolerations?:        [...corev1.#Toleration]
		affinity?:           corev1.#Affinity
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
	}

	migrations: {
		enabled:  bool | *false
		extraEnv: [...corev1.#EnvVar] | *[]
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    string | *"100m"
				memory: string | *"256Mi"
			}
			limits: {
				cpu:    string | *"200m"
				memory: string | *"512Mi"
			}
		}
		nodeSelector: {[string]: string} | *{}
		affinity:     corev1.#Affinity | *{}
		tolerations: [...corev1.#Toleration] | *[]
	}

	storage: {
		s3: {
			enabled: bool | *false
			credentials: {
				accessKeyId:     string | *""
				secretAccessKey: string | *""
			}
			config: {
				region:                 string | *"us-east-1"
				staticBucketName:       string | *""
				customDomain:           string | *""
				mediaBucketName:        string | *""
				mediaCustomDomain:      string | *""
				mediaPrivateBucketName: string | *""
				defaultAcl:             string | *""
				queryStringAuth:        bool | *false
				queryStringExpire:      int | *3600
				endpointUrl:            string | *""
			}
		}
		gcs: {
			enabled: bool | *false
			credentials: {
				jsonKey: string | *""
			}
			config: {
				staticBucketName:       string | *""
				customEndpoint:         string | *""
				mediaBucketName:        string | *""
				mediaCustomEndpoint:    string | *""
				mediaPrivateBucketName: string | *""
				defaultAcl:             string | *""
				queryStringAuth:        bool | *false
				queryStringExpire?:     int
			}
		}
	}

	postgresql: {
		enabled:      bool | *true
		architecture: "standalone" | "replication" | *"standalone"
		image: {
			repository: string | *"postgres"
			tag:        string | *"15-alpine"
			pullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
			command: [...string] | *[]
			args: [...string] | *[]
		}
		persistence: mountPath: string | *"/var/lib/postgresql/data"
		auth: {
			database:            string | *"postgres"
			postgresPassword:    string | *""
			replicationPassword: string | *""
			existingSecret:      string | *"postgresql-credentials"
			secretKeys: {
				adminPasswordKey:       string | *"postgresql-password"
				userPasswordKey:        string | *"user-password"
				replicationPasswordKey: string | *"replication-password"
			}
		}
		primary: {
			persistence: size: string | *"8Gi"
			resources: timoniv1.#ResourceRequirements & {
				requests: {
					cpu:    string | *"500m"
					memory: string | *"2Gi"
				}
			}
			extendedConfiguration: string | *""
		}
		readReplicas: {
			replicaCount: int | *1
			persistence: size: string | *"8Gi"
			resources: timoniv1.#ResourceRequirements & {
				requests: {
					cpu:    string | *"500m"
					memory: string | *"1Gi"
				}
			}
			extendedConfiguration: string | *""
		}
	}

	redis: {
		enabled:      bool | *true
		architecture: "standalone" | "replication" | *"standalone"
		image: {
			repository: string | *"valkey/valkey"
			tag:        string | *"8.1-alpine"
			pullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
			command: [...string] | *["valkey-server"]
			args: [...string] | *["--requirepass", "$(REDIS_PASSWORD)"]
		}
		persistence: mountPath: string | *"/data"
		auth: {
			enabled:                   bool | *true
			password:                  string | *""
			existingSecret:            string | *""
			existingSecretPasswordKey: string | *""
		}
		master: {
			persistence: size: string | *"8Gi"
			resources: timoniv1.#ResourceRequirements & {
				requests: {
					cpu:    string | *"100m"
					memory: string | *"128Mi"
				}
			}
		}
		external: {
			host:           string | *""
			port:           int | *6379
			database:       int | *0
			celeryDatabase: int | *1
			username:       string | *""
			password:       string | *""
			tls: enabled: bool | *false
		}
	}

	ingress: {
		enabled:   bool | *true
		className: string | *""
		annotations: {[string]: string} | *{}
		api: {
			enabled: bool | *true
			annotations: {[string]: string} | *{
				"nginx.ingress.kubernetes.io/proxy-body-size": "20m"
			}
			hosts: [...{
				host: string
				paths: [...{
					path:     string
					pathType: string
				}]
			}] | *[
				{
					host: "chart-example.local"
					paths: [
						{path: "/graphql/", pathType:    "Prefix"},
						{path: "/thumbnail/", pathType:  "Prefix"},
						{path: "/.well-known/jwks.json", pathType: "ImplementationSpecific"},
					]
				},
			]
			tls: [...{
				secretName: string
				hosts: [...string]
			}] | *[]
		}
	}

	imageCredentials: {
		enabled:  bool | *false
		registry: string | *""
		username: string | *""
		password: string | *""
	}

	serviceAccount: {
		create:      bool | *true
		annotations: {[string]: string} | *{}
		name:        string | *""
	}

	podSecurityContext:  corev1.#PodSecurityContext | *{}
	securityContext:     corev1.#SecurityContext | *{}
	nodeSelector:        {[string]: string} | *{}
	tolerations:         [...corev1.#Toleration] | *[]
	affinity:            corev1.#Affinity | *{}
	imagePullSecrets:    [...timoniv1.#ObjectReference] | *[]
	topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]

	// Internal Logic for Helpers (simulating saleor.redisUrl etc in CUE)
	#internal: {
		_redisProtocol: string
		if redis.external.tls.enabled {
			_redisProtocol: "rediss"
		}
		if !redis.external.tls.enabled {
			_redisProtocol: "redis"
		}

		redisUrl: string
		if global.redisUrl != "" {
			redisUrl: global.redisUrl
		}
		if global.redisUrl == "" && !redis.enabled {
			if redis.external.username != "" && redis.external.password != "" {
				redisUrl: "\(_redisProtocol)://\(redis.external.username):\(redis.external.password)@\(redis.external.host):\(redis.external.port)/\(redis.external.database)"
			}
			if redis.external.username == "" && redis.external.password != "" {
				redisUrl: "\(_redisProtocol)://:\(redis.external.password)@\(redis.external.host):\(redis.external.port)/\(redis.external.database)"
			}
			if redis.external.username == "" && redis.external.password == "" {
				redisUrl: "\(_redisProtocol)://\(redis.external.host):\(redis.external.port)/\(redis.external.database)"
			}
		}
		if global.redisUrl == "" && redis.enabled {
			redisUrl: "redis://:\(redis.auth.password)@\(metadata.name)-redis-master:6379/0"
		}

		celeryRedisUrl: string
		if global.celeryRedisUrl != "" {
			celeryRedisUrl: global.celeryRedisUrl
		}
		if global.celeryRedisUrl == "" && !redis.enabled {
			if redis.external.username != "" && redis.external.password != "" {
				celeryRedisUrl: "\(_redisProtocol)://\(redis.external.username):\(redis.external.password)@\(redis.external.host):\(redis.external.port)/\(redis.external.celeryDatabase)"
			}
			if redis.external.username == "" && redis.external.password != "" {
				celeryRedisUrl: "\(_redisProtocol)://:\(redis.external.password)@\(redis.external.host):\(redis.external.port)/\(redis.external.celeryDatabase)"
			}
			if redis.external.username == "" && redis.external.password == "" {
				celeryRedisUrl: "\(_redisProtocol)://\(redis.external.host):\(redis.external.port)/\(redis.external.celeryDatabase)"
			}
		}
		if global.celeryRedisUrl == "" && redis.enabled {
			celeryRedisUrl: "redis://:\(redis.auth.password)@\(metadata.name)-redis-master:6379/1"
		}

		databaseUrl: string
		if global.database.primaryUrl != "" {
			databaseUrl: global.database.primaryUrl
		}
		if global.database.primaryUrl == "" && postgresql.enabled {
			databaseUrl: "postgresql://postgres:\(postgresql.auth.postgresPassword)@\(metadata.name)-postgresql:5432/postgres"
		}

		databaseReplicaUrl: string
		if global.database.replicaUrl != "" {
			databaseReplicaUrl: global.database.replicaUrl
		}
		if global.database.replicaUrl == "" && postgresql.enabled {
			if postgresql.architecture == "replication" {
				databaseReplicaUrl: "postgresql://postgres:\(postgresql.auth.postgresPassword)@\(metadata.name)-postgresql-read:5432/postgres"
			}
			if postgresql.architecture == "standalone" {
				databaseReplicaUrl: databaseUrl
			}
		}
		if global.database.replicaUrl == "" && !postgresql.enabled {
			databaseReplicaUrl: databaseUrl
		}

		readReplicaEnabled: bool
		if (global.database.replicaUrl != "") || (postgresql.enabled && postgresql.architecture == "replication") {
			readReplicaEnabled: true
		}
		if !((global.database.replicaUrl != "") || (postgresql.enabled && postgresql.architecture == "replication")) {
			readReplicaEnabled: false
		}

		s3Env: [
			if storage.s3.enabled && storage.s3.credentials.accessKeyId != "" {
				{name: "AWS_ACCESS_KEY_ID", value: storage.s3.credentials.accessKeyId}
			},
			if storage.s3.enabled && storage.s3.credentials.secretAccessKey != "" {
				{name: "AWS_SECRET_ACCESS_KEY", value: storage.s3.credentials.secretAccessKey}
			},
			if storage.s3.enabled && storage.s3.config.staticBucketName != "" {
				{name: "AWS_STATIC_BUCKET_NAME", value: storage.s3.config.staticBucketName}
			},
			if storage.s3.enabled && storage.s3.config.mediaBucketName != "" {
				{name: "AWS_MEDIA_BUCKET_NAME", value: storage.s3.config.mediaBucketName}
			},
			if storage.s3.enabled && storage.s3.config.mediaPrivateBucketName != "" {
				{name: "AWS_MEDIA_PRIVATE_BUCKET_NAME", value: storage.s3.config.mediaPrivateBucketName}
			},
			if storage.s3.enabled && storage.s3.config.customDomain != "" {
				{name: "AWS_STATIC_CUSTOM_DOMAIN", value: storage.s3.config.customDomain}
			},
			if storage.s3.enabled && storage.s3.config.mediaCustomDomain != "" {
				{name: "AWS_MEDIA_CUSTOM_DOMAIN", value: storage.s3.config.mediaCustomDomain}
			},
			if storage.s3.enabled && storage.s3.config.defaultAcl != "" {
				{name: "AWS_DEFAULT_ACL", value: storage.s3.config.defaultAcl}
			},
			if storage.s3.enabled {
				{name: "AWS_QUERYSTRING_AUTH", value: "\(storage.s3.config.queryStringAuth)"}
			},
			if storage.s3.enabled {
				{name: "AWS_QUERYSTRING_EXPIRE", value: "\(storage.s3.config.queryStringExpire)"}
			},
			if storage.s3.enabled && storage.s3.config.endpointUrl != "" {
				{name: "AWS_S3_ENDPOINT_URL", value: storage.s3.config.endpointUrl}
			},
		]

		gcsEnv: [
			if storage.gcs.enabled && storage.gcs.config.staticBucketName != "" {
				{name: "GS_BUCKET_NAME", value: storage.gcs.config.staticBucketName}
			},
			if storage.gcs.enabled && storage.gcs.config.mediaBucketName != "" {
				{name: "GS_MEDIA_BUCKET_NAME", value: storage.gcs.config.mediaBucketName}
			},
			if storage.gcs.enabled && storage.gcs.config.mediaPrivateBucketName != "" {
				{name: "GS_MEDIA_PRIVATE_BUCKET_NAME", value: storage.gcs.config.mediaPrivateBucketName}
			},
			if storage.gcs.enabled && storage.gcs.config.customEndpoint != "" {
				{name: "GS_CUSTOM_ENDPOINT", value: storage.gcs.config.customEndpoint}
			},
			if storage.gcs.enabled && storage.gcs.config.mediaCustomEndpoint != "" {
				{name: "GS_MEDIA_CUSTOM_ENDPOINT", value: storage.gcs.config.mediaCustomEndpoint}
			},
			if storage.gcs.enabled && storage.gcs.config.defaultAcl != "" {
				{name: "GS_DEFAULT_ACL", value: storage.gcs.config.defaultAcl}
			},
			if storage.gcs.enabled {
				{name: "GS_QUERYSTRING_AUTH", value: "\(storage.gcs.config.queryStringAuth)"}
			},
			if storage.gcs.enabled && storage.gcs.config.queryStringExpire != _|_ {
				{name: "GS_EXPIRATION", value: "\(storage.gcs.config.queryStringExpire)"}
			},
			if storage.gcs.enabled && storage.gcs.credentials.jsonKey != "" {
				{name: "GOOGLE_APPLICATION_CREDENTIALS", value: "/var/secrets/google/credentials.json"}
			},
		]

		isCloudInstance: bool
		if dashboard.appsMarketplaceApiUrl != "" && !strings.Contains(dashboard.appsMarketplaceApiUrl, "apps.saleor.io/") {
			isCloudInstance: true
		}
		if !(dashboard.appsMarketplaceApiUrl != "" && !strings.Contains(dashboard.appsMarketplaceApiUrl, "apps.saleor.io/")) {
			isCloudInstance: false
		}

		_publicUrlProtocol: string | *"http"
		if ingress.api.tls != [] {
			_publicUrlProtocol: "https"
		}
		celeryEnv: list.Concat([
			[
				if ingress.api.enabled && ingress.api.hosts != [] {
					{
						name:  "PUBLIC_URL"
						value: "\(_publicUrlProtocol)://\(ingress.api.hosts[0].host)"
					}
				},
				{
					name: "DATABASE_URL"
					valueFrom: secretKeyRef: {
						name: "\(metadata.name)-secrets"
						key:  "database-url"
					}
				},
				if readReplicaEnabled {
					{
						name: "DATABASE_URL_REPLICA"
						if global.database.replicaUrl != "" {
							value: global.database.replicaUrl
						}
						if global.database.replicaUrl == "" {
							valueFrom: secretKeyRef: {
								name: "\(metadata.name)-secrets"
								key:  "database-url-replica"
							}
						}
					}
				},
				if readReplicaEnabled {
					{
						name:  "DB_CONN_MAX_AGE"
						value: "\(global.database.connMaxAge)"
					}
				},
				if global.jwtRsaPrivateKey != _|_ {
					{
						name: "RSA_PRIVATE_KEY"
						valueFrom: secretKeyRef: {
							name: "\(metadata.name)-secrets"
							key:  "jwt-private-key"
						}
					}
				},
				{
					name:  "DATABASE_CONNECTION_TIMEOUT"
					value: "\(global.database.connectionTimeout)"
				},
				{
					name:  "DATABASE_MAX_CONNECTIONS"
					value: "\(global.database.maxConnections)"
				},
				{
					name: "REDIS_URL"
					valueFrom: secretKeyRef: {
						name: "\(metadata.name)-secrets"
						key:  "redis-url"
					}
				},
				{
					name: "CELERY_BROKER_URL"
					valueFrom: secretKeyRef: {
						name: "\(metadata.name)-secrets"
						key:  "celery-redis-url"
					}
				},
				{
					name: "SECRET_KEY"
					valueFrom: secretKeyRef: {
						name: "\(metadata.name)-secrets"
						key:  "secret-key"
					}
				},
			],
			worker.extraEnv,
			s3Env,
			gcsEnv,
		])
	}
}


// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		secret: #Secret & {#config: config}
		if config.storage.s3.enabled {
			"s3-secret": #S3Secret & {#config: config}
		}
		if config.storage.gcs.enabled {
			"gcs-secret": #GCSSecret & {#config: config}
		}
		settings: #SettingsConfigMap & {#config: config}
		
		if config.api.enabled {
			"api-svc": #APIService & {#config: config}
			"api-deploy": #APIDeployment & {#config: config}
			if config.api.autoscaling.enabled {
				"api-hpa": #APIHPA & {#config: config}
			}
		}

		if config.dashboard.enabled {
			"dashboard-svc": #DashboardService & {#config: config}
			"dashboard-deploy": #DashboardDeployment & {#config: config}
			if config.dashboard.autoscaling.enabled {
				"dashboard-hpa": #DashboardHPA & {#config: config}
			}
		}

		if config.worker.enabled {
			"worker-deploy": #WorkerDeployment & {#config: config}
			if config.worker.autoscaling.enabled {
				"worker-hpa": #WorkerHPA & {#config: config}
			}
			"celery-beat": #BeatStatefulSet & {#config: config}
		}

		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}

		if config.serviceMesh.enabled && config.serviceMesh.istio.enabled {
			"istio-dr": #IstioDestinationRule & {#config: config}
			"istio-vs": #IstioVirtualService & {#config: config}
		}

		if config.postgresql.enabled {
			"pg-secret": #PostgresqlSecret & {#config:    config}
			"pg-svc":    #PostgresqlService & {#config:   config}
			"pg-hl-svc": #PostgresqlHeadlessService & {#config: config}
			"pg-sts":    #PostgresqlStatefulSet & {#config: config}
		}

		if config.redis.enabled {
			"redis-secret": #RedisSecret & {#config:      config}
			"redis-svc":    #RedisService & {#config:     config}
			"redis-hl-svc": #RedisHeadlessService & {#config: config}
			"redis-sts":    #RedisStatefulSet & {#config: config}
		}

		if config.migrations.enabled {
			"migration-job": #MigrationJob & {#config: config}
		}
	}

	tests: {
		// tests can be added here
	}
}
