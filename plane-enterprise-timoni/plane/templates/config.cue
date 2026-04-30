package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// The kubeVersion is a required field, set at apply-time.
	kubeVersion!: *"1.31.0" | string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	// The moduleVersion is used for the app.kubernetes.io/version label.
	moduleVersion!: *"v2.5.3" | string

	// Common metadata for all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion, #Name: "plane"}
	metadata: name: *"plane" | string
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	// Standard labels selector.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	#namespace: metadata.namespace

	planeVersion: string | *"v2.5.3"

	dockerRegistry: {
		enabled: bool | *false
		registry: string | *"index.docker.io/v1/"
		loginid: string | *""
		password: string | *""
		existingSecret: string | *""
	}

	license: {
		licenseServer: string | *"https://prime.plane.so"
		licenseDomain: string | *""
	}

	airgapped: {
		enabled: bool | *false
		s3Secrets: [...{
			name: string
			key: string
		}] | *[]
		s3SecretName: string | *""
		s3SecretKey: string | *""
	}

	ingress: {
		enabled: bool | *false
		minioHost: string | *""
		rabbitmqHost: string | *""
		ingressClass: string | *"traefik"
		traefik: {
			maxRequestBodyBytes: int | *20971520
		}
		annotations: *{} | {[string]: string}
	}

	ssl: {
		tls_secret_name: string | *"plane.local-cert"
		createIssuer: bool | *false
		issuer: "cloudflare" | "digitalocean" | "http" | *"http"
		token: string | *""
		server: string | *"https://acme-v02.api.letsencrypt.org/directory"
		email: string | *"plane@example.com"
		generateCerts: bool | *false
	}


	#ServiceConfig: {
		enabled:  bool | *true
		replicas: *1 | int
		image?:   string
		imagePullPolicy: *"Always" | "IfNotPresent" | "Never"
		memoryLimit?:    string
		cpuLimit?:       string
		memoryRequest?:  string
		cpuRequest?:     string
		assign_cluster_ip: bool | *false
		nodeSelector: *{} | {[string]: string}
		tolerations:  *[] | [...corev1.#Toleration]
		affinity:     *{} | corev1.#Affinity
		labels:       *{} | {[string]: string}
		annotations:  *{} | {[string]: string}
		smtp_domain?: string

		resources: {
			if cpuLimit != _|_ || memoryLimit != _|_ {
				limits: {
					if cpuLimit != _|_ {cpu: cpuLimit}
					if memoryLimit != _|_ {memory: memoryLimit}
				}
			}
			if cpuRequest != _|_ || memoryRequest != _|_ {
				requests: {
					if cpuRequest != _|_ {cpu: cpuRequest}
					if memoryRequest != _|_ {memory: memoryRequest}
				}
			}
		}

		...
	}

	// Microservices Configuration
	services: {
		redis: #ServiceConfig & {
			image:       *"valkey/valkey:7.2.11-alpine" | string
			servicePort: int | *6379
			volumeSize:  string | *"500Mi"
			local_setup: bool | *true
			pullPolicy: *"IfNotPresent" | string
			assign_cluster_ip: bool | *false
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		postgres: #ServiceConfig & {
			local_setup: bool | *true
			image:       *"postgres:15.7-alpine" | string
			servicePort: int | *5432
			volumeSize:  string | *"2Gi"
			pullPolicy: *"IfNotPresent" | string
			assign_cluster_ip: bool | *false
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		rabbitmq: #ServiceConfig & {
			local_setup: bool | *true
			image:       *"rabbitmq:3.13.6-management-alpine" | string
			servicePort: int | *5672
			managementPort: int | *15672
			volumeSize:  string | *"100Mi"
			default_user: string | *"plane"
			default_password: string | *"plane"
			external_rabbitmq_url: string | *""
			assign_cluster_ip: bool | *false
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		opensearch: #ServiceConfig & {
			local_setup: bool | *true
			image:       *"opensearchproject/opensearch:3.3.2" | string
			servicePort: int | *9200
			volumeSize:  string | *"5Gi"
			pullPolicy: *"IfNotPresent" | string
			username:    string | *"plane"
			password:    string | *"Secure@Pass#123!%^&*"
			memoryLimit: string | *"1.5Gi"
			cpuLimit: string | *"750m"
			memoryRequest: string | *"1Gi"
			cpuRequest: string | *"500m"
			assign_cluster_ip: bool | *false
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		minio: #ServiceConfig & {
			local_setup: bool | *true
			image:       *"minio/minio:latest" | string
			image_mc:    *"minio/mc:latest" | string
			volumeSize:  string | *"3Gi"
			pullPolicy: *"IfNotPresent" | string
			root_user:     string | *"admin"
			root_password: string | *"password"
			assign_cluster_ip: bool | *false
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
			env: {
				minio_endpoint_ssl: bool | *false
			}
		}
		iframely: #ServiceConfig & {
			enabled:   bool | *false
			image:     *"artifacts.plane.so/makeplane/iframely:v1.2.0" | string
			pullPolicy: *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		web: #ServiceConfig & {
			image:     *"artifacts.plane.so/makeplane/web-commercial" | string
			pullPolicy: *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		monitor: #ServiceConfig & {
			image:      *"artifacts.plane.so/makeplane/monitor-commercial" | string
			volumeSize: string | *"100Mi"
			pullPolicy: *"Always" | string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
		}
		space: #ServiceConfig & {
			image:     *"artifacts.plane.so/makeplane/space-commercial" | string
			pullPolicy: *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		admin: #ServiceConfig & {
			image:     *"artifacts.plane.so/makeplane/admin-commercial" | string
			pullPolicy: *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		live: #ServiceConfig & {
			image:     *"artifacts.plane.so/makeplane/live-commercial" | string
			pullPolicy: *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		api: #ServiceConfig & {
			image:     *"artifacts.plane.so/makeplane/backend-commercial" | string
			pullPolicy: *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		worker: #ServiceConfig & {
			pullPolicy:   *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		beatworker: #ServiceConfig & {
			pullPolicy:   *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		silo: #ServiceConfig & {
			enabled:     bool | *true
			image:       *"artifacts.plane.so/makeplane/silo-commercial" | string
			pullPolicy: *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
			connectors: {
				slack: {
					enabled:       bool | *false
					client_id:     string | *""
					client_secret: string | *""
				}
				github: {
					enabled:       bool | *false
					client_id:     string | *""
					client_secret: string | *""
					app_name:      string | *""
					app_id:        string | *""
					private_key:   string | *""
				}
				gitlab: {
					enabled:       bool | *false
					client_id:     string | *""
					client_secret: string | *""
				}
			}
		}
		email_service: #ServiceConfig & {
			enabled:        bool | *true
			generate_certs: bool | *false
			replicaCount:   int | *1
			image:          *"artifacts.plane.so/makeplane/email-commercial" | string
			pullPolicy:     *"Always" | string
			smtp_domain:    string | *""
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		outbox_poller: #ServiceConfig & {
			enabled:   bool | *true
			image:     *"artifacts.plane.so/makeplane/backend-commercial" | string
			pullPolicy: *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		automation_consumer: #ServiceConfig & {
			enabled:   bool | *true
			image:     *"artifacts.plane.so/makeplane/backend-commercial" | string
			pullPolicy: *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		pi: #ServiceConfig & {
			enabled:     bool | *true
			image:       *"artifacts.plane.so/makeplane/plane-pi-commercial" | string
			pullPolicy: *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
			ai_providers: {
				openai: {
					enabled:  bool | *false
					base_url: string | *""
					api_key:  string | *""
				}
				claude: {
					enabled:  bool | *false
					base_url: string | *""
					api_key:  string | *""
				}
				groq: {
					enabled:  bool | *false
					base_url: string | *""
					api_key:  string | *""
				}
				cohere: {
					enabled:  bool | *false
					base_url: string | *""
					api_key:  string | *""
				}
				custom_llm: {
					enabled:             bool | *false
					api_key:             string | *""
					base_url:            string | *""
					model_key:           string | *"gpt-oss-120b"
					name:                string | *"GPT-OSS-120B"
					max_tokens:          int | *128000
					provider:            string | *""
					aws_region:          string | *""
				}
				embedding_model: {
					enabled:             bool | *false
					name:                string | *"openai/text-embedding-3-small"
					model_id:            string | *"dummy-id"
					embedding_dimension: int | *1536
					aws_access_key:      string | *""
					aws_secret_access_key: string | *""
					aws_region:          string | *"us-east-1"
					aws_session_token:   string | *""
				}
			}
		}
		pi_beat_worker: #ServiceConfig & {
			pullPolicy:   *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
		pi_worker: #ServiceConfig & {
			pullPolicy:   *"Always" | string
			memoryLimit?:    string
			cpuLimit?:       string
			memoryRequest?:  string
			cpuRequest?:     string
			nodeSelector: *{} | {[string]: string}
			tolerations:  *[] | [...corev1.#Toleration]
			affinity:     *{} | corev1.#Affinity
			labels:       *{} | {[string]: string}
			annotations:  *{} | {[string]: string}
		}
	}

	external_secrets: {
		rabbitmq_existingSecret:  string | *""
		pgdb_existingSecret:      string | *""
		opensearch_existingSecret: string | *""
		doc_store_existingSecret:  string | *""
		app_env_existingSecret:    string | *""
		live_env_existingSecret:   string | *""
		silo_env_existingSecret:   string | *""
		pi_api_env_existingSecret: string | *""
	}

	env: {
		storageClass: string | *"standard"
		
		// REDIS
		remote_redis_url: string | *""

		// POSTGRES DB VALUES
		pgdb_username:       string | *"plane"
		pgdb_password:       string | *"plane"
		pgdb_name:           string | *"plane"
		pg_pi_db_name:       string | *"plane_pi"
		pgdb_remote_url:     string | *""
		pg_pi_db_remote_url: string | *""

		// DATA STORE
		docstore_bucket:       string | *"uploads"
		doc_upload_size_limit: string | *"5242880"

		// REQUIRED IF MINIO LOCAL SETUP IS FALSE
		aws_access_key:        string | *""
		aws_secret_access_key: string | *""
		aws_region:            string | *""
		aws_s3_endpoint_url:   string | *""

		use_storage_proxy:          bool | *false
		allow_all_attachment_types: bool | *false
		enable_drf_spectacular:     bool | *false

		// OPENSEARCH ENVS
		opensearch_remote_url:          string | *""
		opensearch_remote_username:     string | *""
		opensearch_remote_password:     string | *""
		opensearch_index_prefix:        string | *""
		opensearch_embedding_dimension: int | *1536

		// API KEYS
		secret_key:         string | *"60gp0byfz2dvffa45cxl20p1scy9xbpf6d8c5y0geejgkyp1b5"
		api_key_rate_limit: string | *"60/minute"

		sentry_dsn:         string | *""
		sentry_environment: string | *""

		cors_allowed_origins: string | *""
		instance_admin_email: string | *""
		web_url:              string | *""

		live_sentry_dsn:                string | *""
		live_sentry_environment:        string | *""
		live_sentry_traces_sample_rate: string | *""
		live_server_secret_key:         string | *"htbqvBJAgpm9bzvf3r4urJer0ENReatceh"
		external_iframely_url:          string | *""

		silo_envs: {
			sentry_dsn:                string | *""
			sentry_environment:        string | *""
			sentry_traces_sample_rate: string | *""
			batch_size:                int | *100
			mq_prefetch_count:         int | *1
			request_interval:          int | *400
			hmac_secret_key:           string | *"gzb7MRLr0FoN129NyWARZEs84P9LzQ"
			aes_secret_key:            string | *"dsOdt7YrvxsTIFJ37pOaEVvLxN8KGBCr"
			cors_allowed_origins:      string | *""
		}

		email_service_envs: {
			smtp_domain:         string | *""
			max_attachment_size: string | *"10485760"
		}

		outbox_poller_envs: {
			memory_limit_mb:       int | *400
			interval_min:          float | *0.25
			interval_max:          int | *2
			batch_size:            int | *250
			memory_check_interval: int | *30
			pool: {
				size:                  int | *4
				min_size:              int | *2
				max_size:              int | *10
				timeout:               float | *30.0
				max_idle:              float | *300.0
				max_lifetime:          int | *3600
				reconnect_timeout:     float | *5.0
				health_check_interval: int | *60
			}
		}

		automation_consumer_envs: {
			event_stream_queue_name: string | *"plane.event_stream.automations"
			event_stream_prefetch:  int | *10
			exchange_name:           string | *"plane.event_stream"
			event_types:             string | *"issue"
		}

		pi_envs: {
			plane_oauth: {
				state_expiry_seconds: int | *82800
			}
			plane_api_host:        string | *""
			follower_postgres_uri: string | *""
			cors_allowed_origins:  string | *""
			internal_secret:       string | *"tyfvfqvBJAgpm9bzvf3r4urJer0Ehfdubk"
			log_level:             string | *"DEBUG"
			celery: {
				vector_sync_enabled:           bool | *false
				vector_sync_interval:          int | *3
				workspace_plan_sync_enabled:   bool | *false
				workspace_plan_sync_interval:  int | *86400
				docs_sync_enabled:             bool | *false
				docs_sync_interval:            int | *86400
			}
		}
	}

	test: {
		enabled: *false | bool
	}

	extraEnv: [...{
		name:  string
		value: string
	}] | *[]
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		"app-env": #AppConfigMap & {#config: config}
		"app-secret": #AppSecret & {#config: config}
		if config.services.automation_consumer.enabled {
			"automation-consumer-vars": #AutomationConsumerConfigMap & {#config: config}
		}
		if config.dockerRegistry.enabled {
			"docker-registry-credentials": #DockerRegistrySecret & {#config: config}
		}
		"doc-store-secrets": #DocStoreSecret & {#config: config}
		if config.services.email_service.enabled {
			"email-vars": #EmailConfigMap & {#config: config}
		}
		"live-secrets": #LiveSecret & {#config: config}
		"live-vars":    #LiveConfigMap & {#config: config}
		"monitor-vars": #MonitorConfigMap & {#config: config}
		"opensearch-secrets": #OpenSearchSecret & {#config: config}
		if config.services.opensearch.local_setup {
			"opensearch-init": #OpenSearchConfigMap & {#config: config}
		}
		if config.services.outbox_poller.enabled {
			"outbox-poller-vars": #OutboxPollerConfigMap & {#config: config}
		}
		if config.services.postgres.local_setup {
			"pgdb-secrets": #PostgresSecret & {#config: config}
			"pgdb-vars":    #PostgresConfigMap & {#config: config}
		}
		if config.services.pi.enabled {
			"pi-api-secrets": #PIApiSecret & {#config: config}
			"pi-api-vars":    #PIApiConfigMap & {#config: config}
		}
		if config.services.rabbitmq.local_setup {
			"rabbitmq-secrets": #RabbitMQSecret & {#config: config}
		}
		if config.services.silo.enabled {
			"silo-secrets": #SiloSecret & {#config: config}
			"silo-vars":    #SiloConfigMap & {#config: config}
		}
		"admin-wl":      #AdminDeployment & {#config: config}
		"admin-service": #AdminService & {#config: config}
		"api-wl":        #ApiDeployment & {#config: config}
		"api-service":   #ApiService & {#config: config}
		if config.services.automation_consumer.enabled {
			"automation-consumer-wl": #AutomationConsumerDeployment & {#config: config}
		}
		"beat-worker-wl": #BeatWorkerDeployment & {#config: config}
		if config.services.email_service.enabled {
			"email-wl":      #EmailDeployment & {#config: config}
			"email-service": #EmailService & {#config: config}
		}
		"iframely-wl":      #IframelyDeployment & {#config: config}
		"iframely-service": #IframelyService & {#config: config}
		"live-wl":          #LiveDeployment & {#config: config}
		"live-service":     #LiveService & {#config: config}
		"api-migrate":      #MigratorJob & {#config: config}
		if config.services.minio.local_setup {
			"minio-service": #MinioService & {#config: config}
			"minio-wl":      #MinioStatefulSet & {#config: config}
			"minio-bucket":  #MinioBucketJob & {#config: config}
		}
		"monitor-service": #MonitorService & {#config: config}
		"monitor-wl":      #MonitorDeployment & {#config: config}
		if config.services.opensearch.local_setup {
			"opensearch-service": #OpensearchService & {#config: config}
			"opensearch-wl":      #OpensearchStatefulSet & {#config: config}
			"opensearch-secrets": #OpenSearchSecret & {#config: config}
			"opensearch-vars":    #OpenSearchConfigMap & {#config: config}
		}
		if config.services.postgres.local_setup {
			"postgres-service": #PostgresService & {#config: config}
			"postgres-wl":      #PostgresStatefulSet & {#config: config}
		}
		if config.services.rabbitmq.local_setup {
			"rabbitmq-service": #RabbitmqService & {#config: config}
			"rabbitmq-wl":      #RabbitmqStatefulSet & {#config: config}
		}
		if config.services.redis.assign_cluster_ip || !config.services.redis.assign_cluster_ip {
			"redis-service": #RedisService & {#config: config}
			"redis-wl":      #RedisDeployment & {#config: config}
		}
		if config.services.outbox_poller.enabled {
			"outbox-poller-wl": #OutboxPollerDeployment & {#config: config}
		}
		if config.services.pi.enabled {
			"pi-api-wl":      #PIAPIDeployment & {#config: config}
			"pi-api-service": #PIAPIService & {#config: config}
			"pi-beat-wl":     #PIBeatDeployment & {#config: config}
			"pi-api-migrate": #PIMigratorJob & {#config: config}
			"pi-worker-wl":    #PIWorkerDeployment & {#config: config}
		}
		if config.services.silo.enabled {
			"silo-wl":      #SiloDeployment & {#config: config}
			"silo-service": #SiloService & {#config: config}
		}
		if config.services.space.replicas > 0 {
			"space-wl":      #SpaceDeployment & {#config: config}
			"space-service": #SpaceService & {#config: config}
		}
		if config.services.web.replicas > 0 {
			"web-wl":      #WebDeployment & {#config: config}
			"web-service": #WebService & {#config: config}
		}
		"worker-wl": #WorkerDeployment & {#config: config}
		if config.ingress.enabled && config.license.licenseDomain != "" && config.ingress.ingressClass != "traefik" && config.ingress.ingressClass != "traefik-ingress" {
			"ingress": #PlaneIngress & {#config: config}
		}
		"srv-account": #PlaneServiceAccount & {#config: config}
		if config.ingress.enabled && config.ssl.createIssuer && config.ssl.tls_secret_name == "" {
			"cert-issuer-token": #PlaneIssuerTokenSecret & {#config: config}
			"cert-issuer":       #PlaneCertIssuer & {#config: config}
		}
		if config.ingress.enabled && config.ssl.createIssuer && config.ssl.generateCerts && config.ssl.tls_secret_name == "" {
			"certificates": #PlaneCertificates & {#config: config}
		}
		if config.services.email_service.enabled && config.services.email_service.smtp_domain != "" {
			"email-certs": #PlaneEmailCert & {#config: config}
		}
		if config.ingress.enabled && (config.ingress.ingressClass == "traefik" || config.ingress.ingressClass == "traefik-ingress") {
			"traefik-middleware": #TraefikMiddleware & {#config: config}
			"traefik-ingress":    #TraefikIngressRoute & {#config: config}
		}
	}
}
