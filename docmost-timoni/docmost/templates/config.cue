package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// Required fields injected at runtime
	kubeVersion!: string
	moduleVersion!: string

	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}
	metadata:       timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations
	selector:       timoniv1.#Selector & {#Name: metadata.name}

	nameOverride?:     string
	fullnameOverride?: string
	commonLabels: {[string]: string}
	replicaCount: *1 | int & >0

	image: timoniv1.#Image & {
		repository: *"docker.io/docmost/docmost" | string
		tag:        *"0.80.2" | string
		digest:     *"" | string
	}

	imagePullSecrets?: [...timoniv1.#ObjectReference]

	docmost: {
		appUrl:            *"" | string
		appSecret:         *"" | string
		jwtTokenExpiresIn: *"30d" | string
		extraEnv: [...corev1.#EnvVar]
	}

	database: {
		mode: *"auto" | "external" | "postgresql"
		external: {
			host:                      *"" | string
			port:                      *5432 | int & >0 & <=65535
			name:                      *"docmost" | string
			username:                  *"docmost" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"database-password" | string
		}
	}

	postgresql: {
		enabled:      *true | bool
		architecture: *"standalone" | "replication"
		image: {
			repository: *"docker.io/library/postgres" | string
			tag:        *"18.3-trixie" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			database:         *"docmost" | string
			username:         *"docmost" | string
			password:         *"" | string
			postgresPassword: *"" | string
		}
		initdb: {
			scripts: {[string]: string}
		}
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"8Gi" | string
			}
		}
	}

	redis: {
		enabled:      *true | bool
		architecture: *"standalone" | "replication"
		image: {
			repository: *"docker.io/library/redis" | string
			tag:        *"8.6.2" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			enabled:  *true | bool
			password: *"" | string
		}
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"1Gi" | string
			}
		}
		external: {
			host:                      *"" | string
			port:                      *6379 | int & >0 & <=65535
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"redis-password" | string
		}
	}

	storage: {
		mode: *"local" | "s3"
		local: {
			enabled:      *true | bool
			storageClass: *"" | string
			accessMode:   *"ReadWriteOnce" | string
			size:         *"10Gi" | string
			existingClaim: *"" | string
			annotations: {[string]: string}
		}
		s3: {
			region:                     *"us-east-1" | string
			bucket:                     *"" | string
			endpoint:                   *"" | string
			forcePathStyle:             *true | bool
			accessKey:                  *"" | string
			secretKey:                  *"" | string
			existingSecret:             *"" | string
			existingSecretAccessKeyKey: *"access-key" | string
			existingSecretSecretKeyKey: *"secret-key" | string
		}
	}

	backup: {
		enabled:                    *false | bool
		schedule:                   *"0 3 * * *" | string
		suspend:                    *false | bool
		concurrencyPolicy:          *"Forbid" | "Allow" | "Replace"
		successfulJobsHistoryLimit: *3 | int & >=0
		failedJobsHistoryLimit:     *3 | int & >=0
		backoffLimit:               *1 | int & >=0
		archivePrefix:              *"docmost" | string
		images: {
			postgresql: *"docker.io/library/postgres:18.3-trixie" | string
			uploader:   *"docker.io/helmforge/mc:1.0.0" | string
		}
		resources: {
			requests: {
				cpu: *"500m" | string
			    memory: *"512Mi" | string
		    }
		    limits: {
				cpu: *"1000m" | string
			    memory: *"1Gi" | string
		    }
	    }
		database: {
			pgDumpArgs: *"" | string
		}
		s3: {
			endpoint:                   *"" | string
			bucket:                     *"" | string
			prefix:                     *"docmost" | string
			createBucketIfNotExists:    *true | bool
			existingSecret:             *"" | string
			existingSecretAccessKeyKey: *"access-key" | string
			existingSecretSecretKeyKey: *"secret-key" | string
			accessKey:                  *"" | string
			secretKey:                  *"" | string
		}
	}

	service: {
		type: *"ClusterIP" | "NodePort" | "LoadBalancer"
		port: *80 | int & >0 & <=65535
		annotations: {[string]: string}
		ipFamilyPolicy: *"" | "SingleStack" | "PreferDualStack" | "RequireDualStack"
		ipFamilies: [...string]
	}

	ingress: {
		enabled:          *false | bool
		ingressClassName: *"" | string
		annotations: {[string]: string}
		hosts: [...{
			host: string
			paths: [...{
				path:     string
				pathType: string
			}]
		}]
		tls: [...{
			hosts?: [...string]
			secretName?: string
		}]
	}

	gateway: {
		enabled:     *false | bool
		annotations: {[string]: string}
		parentRefs: [...{
			name:       string
			namespace?: string
			kind?:      string
			group?:     string
		}]
		hostnames: [...string]
		path:     *"/" | string
		pathType: *"PathPrefix" | "Exact" | "Exact"
	}

	startupProbe: {
		enabled:             *true | bool
		path:                *"/api/health" | string
		initialDelaySeconds: *10 | int & >=0
		periodSeconds:       *10 | int & >=0
		timeoutSeconds:      *5 | int & >=0
		failureThreshold:    *30 | int & >=0
	}

	livenessProbe: {
		enabled:             *true | bool
		path:                *"/api/health" | string
		initialDelaySeconds: *0 | int & >=0
		periodSeconds:       *20 | int & >=0
		timeoutSeconds:      *5 | int & >=0
		failureThreshold:    *3 | int & >=0
	}

	readinessProbe: {
		enabled:             *true | bool
		path:                *"/api/health" | string
		initialDelaySeconds: *0 | int & >=0
		periodSeconds:       *10 | int & >=0
		timeoutSeconds:      *5 | int & >=0
		failureThreshold:    *3 | int & >=0
	}

	resources: {
		requests: {
			cpu: *"500m" | string
			memory: *"512Mi" | string
		}
		limits: {
			cpu: *"1000m" | string
			memory: *"1Gi" | string
		}
	}
	

	podSecurityContext: corev1.#PodSecurityContext

	securityContext: corev1.#SecurityContext

	serviceAccount: {
		create:      *false | bool
		name:        *"" | string
		annotations: {[string]: string}
	}

	nodeSelector: {[string]: string}
	tolerations: [...corev1.#Toleration]
	affinity: corev1.#Affinity
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]

	priorityClassName: *"" | string
	terminationGracePeriodSeconds: *30 | int & >=0

	podLabels: {[string]: string}
	podAnnotations: {[string]: string}

	extraVolumeMounts: [...corev1.#VolumeMount]
	extraVolumes: [...corev1.#Volume]

	extraManifests: [...]

	externalSecrets: {
		enabled:         *false | bool
		apiVersion:      *"external-secrets.io/v1" | string
		refreshInterval: *"0" | string
		secretStoreRef: {
			name: *"" | string
			kind: *"SecretStore" | string
		}
		target: {
			creationPolicy: *"Owner" | string
		}
		data: [...]
	}

	test: {
		enabled: *false | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/curlimages/curl" | string
			tag:        *"8.6.0" | string
			digest:     *"" | string
		}
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		let _dbMode = {
			if config.database.mode == "external" { "external" }
			if config.database.mode == "postgresql" { "postgresql" }
			if config.database.mode == "auto" {
				if config.database.external.host != "" || config.database.external.existingSecret != "" { "external" }
				if config.database.external.host == "" && config.database.external.existingSecret == "" { "postgresql" }
			}
		}
		let _redisMode = {
			if config.redis.external.host != "" || config.redis.external.existingSecret != "" { "external" }
			if config.redis.external.host == "" && config.redis.external.existingSecret == "" { "internal" }
		}

		sa: #ServiceAccount & {#config: config}
		svc: #Service & {#config: config}
		deploy: #Deployment & {#config: config}

		// Unconditional App Secret
		sec_app: #AppSecret & {#config: config}

		// Conditional Database Secret
		if _dbMode == "external" && config.database.external.existingSecret == "" {
			sec_db: #DatabaseSecret & {#config: config}
		}

		// Conditional Redis Secret
		if _redisMode == "external" && config.redis.external.existingSecret == "" {
			sec_redis: #RedisSecret & {#config: config}
		}

		// Conditional S3 Storage Secret
		if config.storage.mode == "s3" && config.storage.s3.existingSecret == "" {
			sec_storage: #StorageSecret & {#config: config}
		}

		// Conditional Backup S3 Secret
		if config.backup.enabled && config.backup.s3.existingSecret == "" {
			sec_backup: #BackupSecret & {#config: config}
		}

		// Conditional Local Persistent Volume Claim
		let _isLocalPvc = {
			if config.storage.mode == "local" && config.storage.local.enabled && config.storage.local.existingClaim == "" { true }
			if !(config.storage.mode == "local" && config.storage.local.enabled && config.storage.local.existingClaim == "") { false }
		}
		if _isLocalPvc {
			pvc: #StoragePVC & {#config: config}
		}

		// Conditional PostgreSQL StatefulSet and Service
		let _isPgEnabled = {
			if config.postgresql.enabled && _dbMode == "postgresql" { true }
			if !(config.postgresql.enabled && _dbMode == "postgresql") { false }
		}
		if _isPgEnabled {
			pg_cm: #PostgresConfigMap & {#config: config}
			pg_sts: #PostgresStatefulSet & {#config: config, #initdbCmName: pg_cm.metadata.name}
			pg_svc: #PostgresService & {#config: config}
			pg_headless_svc: #PostgresHeadlessService & {#config: config}
		}

		// Conditional Redis Deployment and Service
		let _isRedisEnabled = {
			if config.redis.enabled && _redisMode == "internal" { true }
			if !(config.redis.enabled && _redisMode == "internal") { false }
		}
		if _isRedisEnabled {
			redis_deploy: #RedisDeployment & {#config: config}
			redis_svc: #RedisService & {#config: config}
			redis_headless_svc: #RedisHeadlessService & {#config: config}
		}

		// Conditional standard Ingress
		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}

		// Conditional Gateway API HTTPRoute
		if config.gateway.enabled {
			gateway: #HTTPRoute & {#config: config}
		}

		// Conditional Backup CronJob
		if config.backup.enabled {
			backup_cm: #BackupConfigMap & {#config: config}
			backup_cron: #BackupCronJob & {#config: config, #backupCmName: backup_cm.metadata.name}
		}

		// Conditional ExternalSecret
		if config.externalSecrets.enabled {
			ext_sec: #ExternalSecret & {#config: config}
		}

		// Conditional Extra Manifests
		for i, manifest in config.extraManifests {
			"extra-\(i)": manifest
		}
	}

	tests: {
		if config.test.enabled {
			"test-svc": #TestJob & {#config: config}
		}
	}
}
