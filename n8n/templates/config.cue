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
	// Enforce a minimum Kubernetes minor version.
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

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	// The default image repository, tag and digest are set in `images.cue`.
	image!:           timoniv1.#Image
	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels: {[string]: string}

	// Image configuration
	image: timoniv1.#Image & {
		repository: *"docker.io/n8nio/n8n" | string
		tag:        *"2.37.11" | string
		pullPolicy: *"IfNotPresent" | string
		digest:     *"" | string
	}
	imagePullSecrets: *[] | [...timoniv1.#ObjectReference]

	// n8n Application configuration
	n8n: {
		encryptionKey:           *"" | string
		webhookUrl:              *"" | string
		editorBaseUrl:           *"" | string
		logLevel:                *"info" | string
		logOutput:               *"console" | string
		diagnosticsEnabled:      *false | bool
		gracefulShutdownTimeout: *60 | int
		extraEnv: *[] | [...corev1.#EnvVar]
	}

	// Task runners sidecar configuration
	taskRunners: {
		mode: *"external" | "internal"
		image: timoniv1.#Image & {
			repository: *"docker.io/n8nio/runners" | string
			tag:        *"2.37.11" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		autoShutdownTimeout: *15 | int
		resources: corev1.#ResourceRequirements | *{
			requests: {
				cpu:    "100m"
				memory: "128Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "512Mi"
			}
		}
		authToken:         *"" | string
		existingSecret:    *"" | string
		existingSecretKey: *"auth-token" | string
		nativePython: {
			enabled: *false | bool
		}
	}

	// The number of pods replicas.
	// By default, the number of replicas is 1.
	replicas: *1 | int & >0
	// Queue mode (horizontal worker scaling with Redis)
	queue: {
		enabled:     *false | bool
		workers:     *1 | int & >0
		concurrency: *10 | int & >0
		persistence: {
			shareMainVolume: *true | bool
		}
		resources: corev1.#ResourceRequirements | *{
			requests: {
				cpu:    "250m"
				memory: "512Mi"
			}
			limits: {
				cpu:    "1"
				memory: "1Gi"
			}
		}
		external: {
			host:                      *"" | string
			port:                      *6379 | int
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"redis-password" | string
		}
	}
	// Dedicated encryption key secret overrides
	encryptionKey: {
		existingSecret:    *"" | string
		existingSecretKey: *"encryption-key" | string
	}

	// Database selection & configuration
	database: {
		mode: *"auto" | "sqlite" | "external" | "postgresql" | "mysql"
		sqlite: {
			file: *"/home/node/.n8n/database.sqlite" | string
		}
		external: {
			vendor:                    *"postgres" | "mysql"
			host:                      *"" | string
			port:                      *"" | string
			name:                      *"n8n" | string
			username:                  *"n8n" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"database-password" | string
		}
	}

	// The service allows setting the Kubernetes Service annotations and port.
	// By default, the HTTP port is 80.
	// Subchart: PostgreSQL
	postgresql: {
		enabled:      *true | bool
		architecture: *"standalone" | string
		auth: {
			database: *"n8n" | string
			username: *"n8n" | string
			password: *"" | string
		}
		image: timoniv1.#Image & {
			repository: *"docker.io/library/postgres" | string
			tag:        *"18.6-alpine" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		service: {
			port: *5432 | int
		}
		standalone: {
			persistence: {
				enabled:      *true | bool
				size:         *"8Gi" | string
				storageClass: *"" | string
			}
			resources: corev1.#ResourceRequirements | *{
				requests: {
					cpu:    *"100m" | string
					memory: *"256Mi" | string
				}
				limits: {
					cpu:    *"1" | string
					memory: *"1Gi" | string
				}
			}
		}
		initdb: {
			scripts: {[string]: string}
		}
		securityContext: corev1.#SecurityContext | *{
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   false
			runAsUser:                70
			runAsGroup:               70
			runAsNonRoot:             true
			capabilities: drop: ["ALL"]
		}
		podSecurityContext: corev1.#PodSecurityContext | *{
			runAsUser:    70
			runAsGroup:   70
			runAsNonRoot: true
			fsGroup:      70
			seccompProfile: type: "RuntimeDefault"
		}
	}

	// Subchart: MySQL
	mysql: {
		enabled:      *false | bool
		architecture: *"standalone" | string
		auth: {
			database:     *"n8n" | string
			username:     *"n8n" | string
			password:     *"" | string
			rootPassword: *"" | string
		}
		image: timoniv1.#Image & {
			repository: *"docker.io/library/mysql" | string
			tag:        *"9.7" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		service: {
			port: *3306 | int
		}
		standalone: {
			persistence: {
				enabled:      *true | bool
				size:         *"8Gi" | string
				storageClass: *"" | string
			}
			resources: corev1.#ResourceRequirements | *{
				requests: {
					cpu:    *"100m" | string
					memory: *"256Mi" | string
				}
				limits: {
					cpu:    *"1" | string
					memory: *"1Gi" | string
				}
			}
		}
		startupProbe: {
			initialDelaySeconds: *30 | int
		}
		securityContext: corev1.#SecurityContext | *{
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   false
			runAsUser:                999
			runAsGroup:               999
			runAsNonRoot:             true
			capabilities: drop: ["ALL"]
		}
		podSecurityContext: corev1.#PodSecurityContext | *{
			runAsUser:    999
			runAsGroup:   999
			runAsNonRoot: true
			fsGroup:      999
			seccompProfile: type: "RuntimeDefault"
		}
	}

	// Subchart: Redis
	redis: {
		enabled:      *true | bool
		architecture: *"standalone" | string
		auth: {
			password: *"" | string
		}
		image: timoniv1.#Image & {
			repository: *"docker.io/library/redis" | string
			tag:        *"8.10.1" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		service: {
			port: *6379 | int
		}
		standalone: {
			persistence: {
				enabled:      *true | bool
				size:         *"1Gi" | string
				storageClass: *"" | string
			}
			resources: corev1.#ResourceRequirements | *{
				requests: {
					cpu:    *"50m" | string
					memory: *"64Mi" | string
				}
				limits: {
					cpu:    *"500m" | string
					memory: *"256Mi" | string
				}
			}
		}
		securityContext: corev1.#SecurityContext | *{
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   false
			runAsUser:                999
			runAsGroup:               999
			runAsNonRoot:             true
			capabilities: drop: ["ALL"]
		}
		podSecurityContext: corev1.#PodSecurityContext | *{
			runAsUser:    999 | int
			runAsGroup:   999 | int
			runAsNonRoot: true | bool
			fsGroup:      999 | int
			seccompProfile: type: "RuntimeDefault"
		}
	}

	// Persistence for n8n data
	persistence: {
		enabled:       *true | bool
		storageClass:  *"" | string
		accessMode:    *"ReadWriteOnce" | string
		size:          *"5Gi" | string
		existingClaim: *"" | string
		annotations: {[string]: string}
	}

	// Resources for main n8n container
	resources: corev1.#ResourceRequirements | *{
		requests: {
			cpu:    "250m"
			memory: "512Mi"
		}
		limits: {
			cpu:    "1"
			memory: "1Gi"
		}
	}

	// Security context
	podSecurityContext: corev1.#PodSecurityContext | *{
		fsGroup:             1000
		fsGroupChangePolicy: "OnRootMismatch"
		seccompProfile: type: "RuntimeDefault"
	}

	securityContext: corev1.#SecurityContext | *{
		runAsUser:                1000
		runAsGroup:               1000
		runAsNonRoot:             true
		allowPrivilegeEscalation: false
		capabilities: drop: ["ALL"]
	}

	// Probes
	startupProbe: {
		enabled:             *true | bool
		path:                *"/healthz" | string
		initialDelaySeconds: *10 | int
		periodSeconds:       *5 | int
		timeoutSeconds:      *3 | int
		failureThreshold:    *30 | int
	}

	livenessProbe: {
		enabled:             *true | bool
		path:                *"/healthz" | string
		initialDelaySeconds: *0 | int
		periodSeconds:       *15 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *3 | int
	}

	readinessProbe: {
		enabled:             *true | bool
		path:                *"/healthz/readiness" | string
		initialDelaySeconds: *30 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *3 | int
	}

	// Service
	service: {
		annotations?: timoniv1.#Annotations
		type:         *"ClusterIP" | string
		port:         *80 | int
		annotations: {[string]: string}
		ipFamilyPolicy: *"" | string
		ipFamilies: *[] | [...string]
	}

	port: *80 | int & >0 & <=65535
	// Ingress
	ingress: {
		enabled:          *false | bool
		ingressClassName: *"" | string
		annotations: {[string]: string}
		hosts: *[] | [...{
			host: string
			paths?: [...{
				path:     *"" | string
				pathType: *"" | string
			}]
		}]
		tls: *[] | [...{
			secretName: string
			hosts: [...string]
		}]
	}

	// Pod optional settings.
	podAnnotations?: {[string]: string}
	podSecurityContext?: corev1.#PodSecurityContext
	imagePullSecrets?: [...timoniv1.#ObjectReference]
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	// ServiceAccount
	serviceAccount: {
		create: *true | bool
		name:   *"" | string
		annotations: {[string]: string}
		automountServiceAccountToken: *false | bool
	}

	// Pods are scheduled on Linux nodes by default.
	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}
	// Scheduled Backup
	backup: {
		enabled:                    *false | bool
		schedule:                   *"0 3 * * *" | string
		suspend:                    *false | bool
		concurrencyPolicy:          *"Forbid" | string
		successfulJobsHistoryLimit: *3 | int
		failedJobsHistoryLimit:     *3 | int
		backoffLimit:               *1 | int
		archivePrefix:              *"n8n" | string
		images: {
			sqlite:     *"docker.io/library/alpine:3.22" | string
			postgresql: *"docker.io/library/postgres:18.4-alpine" | string
			mysql:      *"docker.io/library/mysql:8.4" | string
			uploader:   *"docker.io/helmforge/mc:1.0.0" | string
		}
		resources?: corev1.#ResourceRequirements
		s3: {
			endpoint:                   *"" | string
			bucket:                     *"" | string
			prefix:                     *"n8n" | string
			createBucketIfNotExists:    *true | bool
			existingSecret:             *"" | string
			existingSecretAccessKeyKey: *"access-key" | string
			existingSecretSecretKeyKey: *"secret-key" | string
			accessKey:                  *"" | string
			secretKey:                  *"" | string
		}
		database: {
			host:                      *"" | string
			port:                      *"" | string
			name:                      *"" | string
			username:                  *"" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"database-password" | string
			postgresDumpArgs:          *"" | string
			mysqlDumpArgs:             *"--single-transaction --quick --skip-lock-tables --no-tablespaces" | string
		}
	}
	// Scheduling & Pod-level metadata
	nodeSelector: {[string]: string}
	tolerations: *[] | [...corev1.#Toleration]
	affinity?: corev1.#Affinity
	topologySpreadConstraints: *[] | [...corev1.#TopologySpreadConstraint]
	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *75 | int
	podLabels: {[string]: string}
	podAnnotations: {[string]: string}
	extraVolumeMounts: *[] | [...corev1.#VolumeMount]
	extraVolumes: *[] | [...corev1.#Volume]
	extraManifests: *[] | [...{...}]

	// Gateway API
	gateway: {
		enabled: *false | bool
		annotations: {[string]: string}
		parentRefs: *[] | [...{
			name:         string
			namespace?:   string
			group?:       string
			kind?:        string
			sectionName?: string
			port?:        int
		}]
		hostnames: *[] | [...string]
		path:     *"/" | string
		pathType: *"PathPrefix" | string
	}

	// Test Job disabled by default.
	// The test image defaults are set in `images.cue`.
	// External Secrets Operator
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
		data: *[] | [...{
			secretKey: string
			remoteRef: {
				key:       string
				property?: string
			}
		}]
	}

	// Testing hook
	test: {
		enabled: *false | bool
	}
	// ---------------------------------------------------------------------------
	// Computed helper fields (mirroring Helm template helpers)
	// ---------------------------------------------------------------------------

	fullname: [
		if fullnameOverride != "" {fullnameOverride},
		if nameOverride != "" {"\(metadata.name)-\(nameOverride)"},
		"\(metadata.name)-n8n",
	][0]

	namespace: metadata.namespace

	serviceAccountName: [
		if serviceAccount.name != "" {serviceAccount.name},
		if serviceAccount.create {fullname},
		"default",
	][0]

	_hasExternalDb: (database.external.host != "") || (database.external.existingSecret != "")

	dbMode: [
		if database.mode != "auto" {database.mode},
		if _hasExternalDb {"external"},
		if postgresql.enabled {"postgresql"},
		if mysql.enabled {"mysql"},
		"sqlite",
	][0]

	dbVendor: [
		if dbMode == "external" {database.external.vendor},
		if dbMode == "postgresql" {"postgres"},
		if dbMode == "mysql" {"mysql"},
		"sqlite",
	][0]

	dbType: [
		if dbVendor == "sqlite" {"sqlite"},
		if dbVendor == "postgres" {"postgresdb"},
		"mysqldb",
	][0]

	dbHost: [
		if dbMode == "external" {database.external.host},
		if dbMode == "postgresql" {"\(fullname)-postgresql"},
		if dbMode == "mysql" {"\(fullname)-mysql"},
		"",
	][0]

	dbPort: [
		if dbMode == "external" {
			[
				if database.external.port != "" {database.external.port},
				if database.external.vendor == "mysql" {"3306"},
				"5432",
			][0]
		},
		if dbMode == "postgresql" {"5432"},
		if dbMode == "mysql" {"3306"},
		"",
	][0]

	dbName: [
		if dbMode == "external" {database.external.name},
		if dbMode == "postgresql" {postgresql.auth.database},
		if dbMode == "mysql" {mysql.auth.database},
		"",
	][0]

	dbUsername: [
		if dbMode == "external" {database.external.username},
		if dbMode == "postgresql" {postgresql.auth.username},
		if dbMode == "mysql" {mysql.auth.username},
		"",
	][0]

	dbPasswordValue: [
		if dbMode == "external" {database.external.password},
		if dbMode == "postgresql" {postgresql.auth.password},
		if dbMode == "mysql" {mysql.auth.password},
		if dbMode == "postgresql" {
			[
				if postgresql.auth.password != "" {postgresql.auth.password},
				"CHANGE_ME_POSTGRESQL_PASSWORD",
			][0]
		},
		if dbMode == "mysql" {
			[
				if mysql.auth.password != "" {mysql.auth.password},
				"CHANGE_ME_MYSQL_PASSWORD",
			][0]
		},
		"",
	][0]

	encryptionKeySecretName: [
		if encryptionKey.existingSecret != "" {encryptionKey.existingSecret},
		"\(fullname)-encryption",
	][0]

	encryptionKeySecretKey: [
		if encryptionKey.existingSecret != "" {encryptionKey.existingSecretKey},
		"encryption-key",
	][0]

	taskRunnerSecretName: [
		if taskRunners.existingSecret != "" {taskRunners.existingSecret},
		"\(fullname)-task-runners",
	][0]

	taskRunnerSecretKey: [
		if taskRunners.existingSecret != "" {taskRunners.existingSecretKey},
		"auth-token",
	][0]

	dbSecretName: [
		if dbMode == "external" && database.external.existingSecret != "" {
			database.external.existingSecret
		},
		"\(fullname)-database",
	][0]

	dbSecretKey: [
		if dbMode == "external" && database.external.existingSecret != "" {
			database.external.existingSecretPasswordKey
		},
		"database-password",
	][0]

	redisHost: [
		if queue.external.host != "" {queue.external.host},
		if redis.enabled {"\(fullname)-redis-client"},
		"",
	][0]

	redisPort: [
		if queue.external.host != "" {"\(queue.external.port)"},
		"6379",
	][0]

	redisSecretName: [
		if queue.external.existingSecret != "" {queue.external.existingSecret},
		if redis.enabled {"\(fullname)-redis-auth"},
		"\(fullname)-redis-queue",
	][0]

	redisSecretKey: [
		if queue.external.existingSecret != "" {queue.external.existingSecretPasswordKey},
		"redis-password",
	][0]

	hasRedisPassword: (queue.external.password != "") || (queue.external.existingSecret != "") || (redis.enabled && redis.auth.password != "")

	backupSecretName: [
		if backup.s3.existingSecret != "" {backup.s3.existingSecret},
		"\(fullname)-backup",
	][0]

	backupDatabaseHost: [
		if backup.database.host != "" {backup.database.host},
		dbHost,
	][0]

	backupDatabasePort: [
		if backup.database.port != "" {backup.database.port},
		dbPort,
	][0]

	backupDatabaseName: [
		if backup.database.name != "" {backup.database.name},
		dbName,
	][0]

	backupDatabaseUsername: [
		if backup.database.username != "" {backup.database.username},
		dbUsername,
	][0]

	backupDatabasePasswordSecretName: [
		if backup.database.existingSecret != "" {backup.database.existingSecret},
		dbSecretName,
	][0]

	backupDatabasePasswordSecretKey: [
		if backup.database.existingSecret != "" {backup.database.existingSecretPasswordKey},
		dbSecretKey,
	][0]

	runnerImageTag: [
		if taskRunners.image.tag != "" {taskRunners.image.tag},
		image.tag,
	][0]

	webhookUrl: [
		if n8n.webhookUrl != "" {n8n.webhookUrl},
		if ingress.enabled && len(ingress.hosts) > 0 {"https://\(ingress.hosts[0].host)/"},
		"",
	][0]

	editorBaseUrl: [
		if n8n.editorBaseUrl != "" {n8n.editorBaseUrl},
		if ingress.enabled && len(ingress.hosts) > 0 {"https://\(ingress.hosts[0].host)/"},
		"",
	][0]
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccountBuilder & {_config: config}
		}

		if config.encryptionKey.existingSecret == "" {
			secretEncryption: #EncryptionSecretBuilder & {_config: config}
		}

		if config.taskRunners.mode == "external" && config.taskRunners.existingSecret == "" {
			secretTaskRunners: #TaskRunnersSecretBuilder & {_config: config}
		}

		if config.dbMode != "sqlite" && !(config.dbMode == "external" && config.database.external.existingSecret != "") {
			secretDb: #DatabaseSecretBuilder & {_config: config}
		}

		if !config.redis.enabled && config.queue.enabled && config.queue.external.existingSecret == "" && config.hasRedisPassword {
			secretRedisQueue: #RedisQueueSecretBuilder & {_config: config}
		}

		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PVCBuilder & {_config: config}
		}

		svc: #ServiceBuilder & {_config: config}

		deploy: #DeploymentBuilder & {_config: config}

		if config.queue.enabled {
			deployWorker: #WorkerDeploymentBuilder & {_config: config}
		}

		if config.ingress.enabled {
			ingress: #IngressBuilder & {_config: config}
		}

		if config.gateway.enabled {
			httpRoute: #HTTPRouteBuilder & {_config: config}
		}

		if config.externalSecrets.enabled {
			externalSecret: #ExternalSecretBuilder & {_config: config}
		}

		if config.backup.enabled {
			backupConfigMap: #BackupConfigMapBuilder & {_config: config}
			backupCronJob: #BackupCronJobBuilder & {_config: config}
			if config.backup.s3.existingSecret == "" {
				secretBackup: #BackupSecretBuilder & {_config: config}
			}
		}

		if config.postgresql.enabled {
			pgSecret: #PostgreSQLSecret & {#config: config}
			pgSVC: #PostgreSQLService & {#config: config}
			pgHeadlessSVC: #PostgreSQLHeadlessService & {#config: config}
			pgDeploy: #PostgreSQLStatefulSet & {#config: config}
			if len(config.postgresql.initdb.scripts) > 0 {
				pgInitConfigMap: #PostgreSQLInitConfigMap & {#config: config}
			}
		}

		if config.mysql.enabled {
			mysqlSecret: #MySQLSecret & {#config: config}
			mysqlSVC: #MySQLService & {#config: config}
			mysqlHeadlessSVC: #MySQLHeadlessService & {#config: config}
			mysqlDeploy: #MySQLStatefulSet & {#config: config}
		}

		if config.redis.enabled {
			if config.hasRedisPassword {
				redisSecret: #RedisSecret & {#config: config}
			}
			redisSVC: #RedisService & {#config: config}
			redisHeadlessSVC: #RedisHeadlessService & {#config: config}
			redisDeploy: #RedisStatefulSet & {#config: config}
		}

		for idx, m in config.extraManifests {
			"extra-manifest-\(idx)": m
		}
	}

	tests: {}
}
