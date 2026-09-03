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

	replicaCount: *1 | int & >0

	nameOverride: *"" | string
	fullnameOverride: *"" | string

	pimcore: {
		tag: *"main" | string
		appEnv: *"prod" | string
		appSecret: *"ChangeMe123!" | string
		instanceIdentifier: *"pimcore-evocms-0.1" | string
		productKey: *"" | string
		encryptionSecret: *"def00000acb380da2a08598936351dd70af63d1b6867b5eb6edbe955a9ff0a5e2189265b8c0a1efa056abffa277b50fe02977c7e49ef9942b17df2ee2ab0abb66ca7f469" | string
		databaseURL: *"mysql://pimcore:ChangeMe123!@mysql-mariadb.pimcore.svc.cluster.local:3306/pimcore?serverVersion=mariadb-11.4" | string
		redisServer: *"redis-master.pimcore.svc.cluster.local" | string
		redisPassword: *"ChangeMe123!" | string
		createProject: *"pimcore/skeleton" | string
		installProfile: *"App\\Installer\\SkeletonProfile" | string
		username: *"admin" | string
		password: *"ChangeMe123!" | string
		db: {
			name: *"pimcore" | string
			root_password: *"root" | string
			host: *"mysql-mariadb.pimcore.svc.cluster.local" | string
			port: *3306 | int
			username: *"pimcore" | string
			password: *"ChangeMe123!" | string
		}
		customConfigFiles: {
			[string]: {
				enabled: *false | bool
				localPath: string
				containerPath: string
				productKey: *"" | string
			}
		}
		mountedConfigDirs: {
			[string]: {
				enabled: *false | bool
				containerPath: string
				data: [string]: string
			}
		}
		customEnvVars: *[] | [...corev1.#EnvVar]
		redisAuthCheck: {
			enabled: *true | bool
			maxAttempts: *24 | int
			retryDelaySeconds: *5 | int
		}
	}

	php: {
		imagePullSecrets: *[] | [...timoniv1.#ObjectReference]
		image: #Image & {
			registry: *"pimcore/pimcore" | string
			tag: *"php8.2-latest" | string
			digest: *"" | string
			pullPolicy: *"Always" | string
		}
		replicas: *1 | int & >0
		pdb: {
			enabled: *true | bool
		}
		strategy: *{} | _
		topologySpreadConstraints: *[] | [...]
		podAnnotations: *{} | {[string]: string}
		service: {
			type: *"ClusterIP" | string
			port: *9000 | int
		}
		phpUser: {
			userName: *"www-data" | string
			uid: *33 | int
			groupName: *"www-data" | string
			gid: *33 | int
		}
		fpmPool: {
			pm: *"dynamic" | string
			pmMaxChildren: *100 | int
			pmStartServers: *3 | int
			pmMinSpareServers: *3 | int
			pmMaxSpareServers: *8 | int
			pmMaxRequests: *10000 | int
			pmProcessIdleTimeout: *"10s" | string
		}
		resources: #ResourceRequirements
		startupProbe: {
			enabled: *true | bool
			exec?: corev1.#ExecAction
			periodSeconds: *10 | int
			timeoutSeconds: *5 | int
			failureThreshold: *30 | int
		}
		livenessProbe: {
			enabled: *true | bool
			exec?: corev1.#ExecAction
			periodSeconds: *30 | int
			timeoutSeconds: *5 | int
			failureThreshold: *3 | int
		}
		readinessProbe: {
			enabled: *false | bool
			tcpSocket?: corev1.#TCPSocketAction
			initialDelaySeconds: *10 | int
			periodSeconds: *10 | int
			timeoutSeconds: *3 | int
			failureThreshold: *3 | int
		}
		ini: {
			pimcore: {
				phpMemoryLimit: *"512M" | string
				phpMaxExecutionTime: *300 | int
				phpErrorReporting: *"E_ALL" | string
				phpDisplayErrors: *"Off" | string
				phpDisplayStartupErrors: *1 | int
				phpPostMaxSize: *"100M" | string
				phpUploadMaxFilesize: *"100M" | string
				opcacheEnable: *1 | int
				opcacheEnableCli: *0 | int
				opcacheMemoryConsumption: *512 | int
				opcacheMaxAcceleratedFiles: *10000 | int
				opcacheValidateTimestamps: *1 | int
				opcacheConsistencyChecks: *0 | int
			}
			maintenance: {
				cronjob: {
					phpMemoryLimit: *"512M" | string
					phpMaxExecutionTime: *0 | int
				}
				worker: {
					phpMemoryLimit: *"512M" | string
					phpMaxExecutionTime: *0 | int
				}
				shell: {
					phpMemoryLimit: *"0" | string
					phpMaxExecutionTime: *0 | int
				}
			}
			installation: {
				phpMemoryLimit: *"512M" | string
				phpMaxExecutionTime: *0 | int
			}
		}
	}

	nginx: {
		imagePullSecrets: *[] | [...timoniv1.#ObjectReference]
		image: #Image & {
			registry: *"nginx" | string
			tag: *"stable-alpine" | string
			digest: *"" | string
			pullPolicy: *"Always" | string
		}
		config: *"" | string
		compression: {
			enabled: *true | bool
			gzip: {
				enabled: *true | bool
				min_length: *1000 | int
				comp_level: *1 | int
				types: *"text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript" | string
			}
			brotli: {
				enabled: *true | bool
				comp_level: *6 | int
				types: *"text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript" | string
			}
		}
		replicas: *1 | int & >0
		pdb: {
			enabled: *true | bool
		}
		strategy: *{} | _
		topologySpreadConstraints: *[] | [...]
		podAnnotations: *{} | {[string]: string}
		tag: *"master" | string
		service: {
			type: *"ClusterIP" | string
			port: *80 | int
		}
		annotations: *{} | {[string]: string}
		backendConfig: {
			enabled: *true | bool
			timeoutSec: *300 | int
			healthCheck: {
				checkIntervalSec: *30 | int
				timeoutSec: *30 | int
				healthyThreshold: *2 | int
				unhealthyThreshold: *2 | int
				requestPath: *"/livez" | string
				type: *"HTTP" | string
				port: *80 | int
			}
		}
		resources: #ResourceRequirements
		clientMaxBodySize: *"100m" | string
		cacheControl: {
			assets: *"public, max-age=300, must-revalidate" | string
			thumbnails: *"public, max-age=300, must-revalidate" | string
		}
		sharedFolders: *["public", "vendor"] | [...string]
		startupProbe: {
			enabled: *true | bool
			httpGet?: corev1.#HTTPGetAction
			periodSeconds: *5 | int
			timeoutSeconds: *3 | int
			failureThreshold: *60 | int
		}
		livenessProbe: {
			enabled: *true | bool
			httpGet?: corev1.#HTTPGetAction
			periodSeconds: *30 | int
			timeoutSeconds: *3 | int
			failureThreshold: *3 | int
		}
		readinessProbe: {
			enabled: *false | bool
			httpGet?: corev1.#HTTPGetAction
			initialDelaySeconds: *2 | int
			periodSeconds: *10 | int
			timeoutSeconds: *5 | int
			failureThreshold: *3 | int
		}
	}

	installation: {
		resources: #ResourceRequirements
	}

	maintenance: {
		cronjob: {
			resources: #ResourceRequirements
		}
		worker: {
			replicas: *1 | int & >=0
			extraTransports: *[] | [...string]
			messengerMemoryLimit: *"" | string
			customEnvVars: *[] | [...corev1.#EnvVar]
			resources: #ResourceRequirements
			livenessProbe: {
				enabled: *true | bool
				exec?: corev1.#ExecAction
				initialDelaySeconds: *60 | int
				periodSeconds: *60 | int
				timeoutSeconds: *5 | int
				failureThreshold: *3 | int
			}
		}
		shell: {
			replicas: *0 | int & >=0
			resources: #ResourceRequirements
			maintainer: {
				userName: *"maintainer" | string
				userId: *1000 | int
				groupName: *"developers" | string
				groupId: *1200 | int
			}
			installProfile: *"App\\Installer\\SkeletonProfile" | string
			installPackages: *"ranger vim procps" | string
			entrypointAdditionalCommands: *"" | string
			extraVolumeMounts: *[] | [...corev1.#VolumeMount]
		}
		consoleCronjobs: {
			[string]: {
				enabled: *true | bool
				schedule: string
				command: string
				resources?: #ResourceRequirements
				concurrencyPolicy: *"Forbid" | "Allow" | "Replace" | string
				restartPolicy: *"OnFailure" | "Never" | string
				ttlSecondsAfterFinished: *60 | int
				activeDeadlineSeconds?: int
				startingDeadlineSeconds?: int
				successfulJobsHistoryLimit: *3 | int
				failedJobsHistoryLimit: *1 | int
			}
		}
		mysqlBackup: {
			enabled: *false | bool
			imagePullSecrets: *[] | [...timoniv1.#ObjectReference]
			image: #Image & {
				registry: *"mariadb" | string
				tag: *"11.4" | string
				digest: *"" | string
				pullPolicy: *"Always" | string
			}
			compression: {
				tool: *"pigz" | string
			}
			replicas: *1 | int
			resources: #ResourceRequirements
		}
	}

	pvc: {
		data: {
			existingClaim: *"" | string
			subPath: *"pimcore" | string
			sharedSubPaths: {
				[string]: {
					mountPath: string
					subPath: string
				}
			}
			name: *"data" | string
			storage: *"10Gi" | string
			accessMode: *"ReadWriteMany" | string
			storageClass: *"" | string
			initFromRepo: {
				enabled: *false | bool
				gitRepositoryUrl: string
				gitUserName: *"git" | string
				gitPersonalAccessToken: *"" | string
			}
			composerAuth: *"" | string
			gitExtraHeader: {
				host: *"" | string
				value: *"" | string
			}
		}
		mysqlBackup: {
			existingClaim: *"" | string
			subPath: *"pimcore-mysql-backup" | string
			name: *"mysql-backup" | string
			storage: *"10Gi" | string
			accessMode: *"ReadWriteOnce" | string
			storageClass: *"" | string
		}
		mysql: {
			existingClaim: *"" | string
			subPath: *"mysql" | string
			name: *"mysql" | string
			storage: *"8Gi" | string
			accessMode: *"ReadWriteOnce" | string
			storageClass: *"" | string
		}
		redis: {
			existingClaim: *"" | string
			subPath: *"redis" | string
			name: *"redis" | string
			storage: *"8Gi" | string
			accessMode: *"ReadWriteOnce" | string
			storageClass: *"" | string
		}
		opensearch: {
			existingClaim: *"" | string
			subPath: *"opensearch" | string
			name: *"opensearch" | string
			storage: *"5Gi" | string
			accessMode: *"ReadWriteOnce" | string
			storageClass: *"" | string
		}
		rabbitmq: {
			existingClaim: *"" | string
			subPath: *"rabbitmq" | string
			name: *"rabbitmq" | string
			storage: *"5Gi" | string
			accessMode: *"ReadWriteOnce" | string
			storageClass: *"" | string
		}
	}

	mysql: {
		replicas: *1 | int
		image: #Image & {
			registry: *"mariadb" | string
			tag: *"11.4" | string
			digest: *"" | string
			pullPolicy: *"Always" | string
		}
		resources?: #ResourceRequirements
		pdb: {
			enabled: *true | bool
		}
		primary: {
			containerPorts: mysql: *3306 | int
			configuration: string
		}
		auth: {
			database:        *"pimcore" | string
			username:        *"pimcore" | string
			replicationUser: *"replicator" | string
		}
	}

	redis: {
		replicas: *1 | int
		image: #Image & {
			registry: *"redis" | string
			tag: *"8.8-alpine" | string
			digest: *"" | string
			pullPolicy: *"Always" | string
		}
		resources?: #ResourceRequirements
		pdb: {
			enabled: *true | bool
		}
		auth: {
			password: *"ChangeMe123!" | string
		}
		master: {
			extraFlags: [...string]
		}
		replica: {
			replicaCount: *1 | int
			extraFlags: [...string]
		}
	}

	opensearch: {
		image:                 *"opensearchproject/opensearch:2.19.6" | string
		initialAdminPassword:  *"ChangeMe123!" | string
		disableSecurityPlugin: *true | bool
	}
	rabbitmq: {
		image: *"rabbitmq:4-management" | string
		username: *"guest" | string
		password: *"guest" | string
	}

	supervisord: {
		enabled: *true | bool
		replicas: *1 | int
		image: #Image & {
			registry: *"pimcore/pimcore" | string
			tag: *"php8.5-supervisord-5.x" | string
			digest: *"" | string
			pullPolicy: *"IfNotPresent" | string
		}
		resources?: #ResourceRequirements
	}

	mercure: {
		enabled: *true | bool
		replicas: *1 | int
		image: #Image & {
			registry: *"dunglas/mercure" | string
			tag: *"latest" | string
			digest: *"" | string
			pullPolicy: *"IfNotPresent" | string
		}
		publisherJwtKey: *"!ChangeThisMercureHubJWTSecretKey!" | string
		subscriberJwtKey: *"!ChangeThisMercureHubJWTSecretKey!" | string
		extraDirectives: *"anonymous" | string
		resources?: #ResourceRequirements
	}

	s3: {
		enabled: *false | bool
		key: *"" | string
		secret: *"" | string
		publicBucket: *"" | string
		privateBucket: *"" | string
	}

	serviceAccount: {
		create: *true | bool
		annotations: *{} | {[string]: string}
		name: *"" | string
	}

	podAnnotations: *{} | {[string]: string}
	podSecurityContext: *{} | {[string]: _}
	securityContext: *{} | {[string]: _}

	autoscaling: {
		enabled: *false | bool
		minReplicas: *1 | int
		maxReplicas: *100 | int
		targetCPUUtilizationPercentage: *80 | int
	}

	nodeSelector: *{} | {[string]: string}
	tolerations: {
		nginx?: [...corev1.#Toleration]
		php?: [...corev1.#Toleration]
		maintenance?: [...corev1.#Toleration]
	}
	affinity: *{} | corev1.#Affinity
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		sa: #ServiceAccount & {#config: config}
		
		// Define core objects
		dotenv: #DotenvSecret & {#config: config}
		
		if config.pvc.data.existingClaim == "" {
			pvcData: #PVCData & {#config: config}
		}
		if config.maintenance.mysqlBackup.enabled && config.pvc.mysqlBackup.existingClaim == "" {
			pvcBackup: #PVCMysqlBackup & {#config: config}
		}

		// PHP & Nginx services
		svcPhp: #ServicePhp & {#config: config}
		svcNginx: #ServiceNginx & {#config: config}

		// Nginx ConfigMaps
		cmNginx: #ConfigMapNginx & {#config: config}
		cmNginxServer: #ConfigMapNginxServer & {#config: config}

		// Custom ConfigMap files
		for k, v in config.pimcore.customConfigFiles {
			if v.enabled {
				"cm-custom-\(k)": #CustomConfigMap & {#config: config, #name: k, #configVal: v}
			}
		}

		// Mounted Config Dirs
		for k, v in config.pimcore.mountedConfigDirs {
			if v.enabled {
				"cm-mounted-\(k)": #MountedConfigMap & {#config: config, #name: k, #configVal: v}
			}
		}

		// Deployments
		deployPhp: #DeploymentPhp & {#config: config}
		deployNginx: #DeploymentNginx & {#config: config}

		if config.maintenance.worker.replicas > 0 {
			deployWorker: #DeploymentWorker & {#config: config}
		}
		if config.supervisord.enabled {
			cmSupervisord:     #ConfigMapSupervisord & {#config: config}
			deploySupervisord: #SupervisordDeployment & {#config: config}
		}
		if config.mercure.enabled {
			deployMercure: #MercureDeployment & {#config: config}
			svcMercure: #MercureService & {#config: config}
			svcMercureAlias: #MercureServiceAlias & {#config: config}
		}
		if config.maintenance.shell.replicas > 0 {
			deployShell: #DeploymentShell & {#config: config}
		}

		// PodDisruptionBudgets
		if config.php.pdb.enabled {
			pdbPhp: #PDBPhp & {#config: config}
		}
		if config.nginx.pdb.enabled {
			pdbNginx: #PDBNginx & {#config: config}
		}
		if config.mysql.pdb.enabled {
			pdbMysql: #PDBMysql & {#config: config}
		}
		if config.redis.pdb.enabled {
			pdbRedis: #PDBRedis & {#config: config}
		}

		// Maintenance Scripts ConfigMap
		cmMaintShellInit: #ConfigMapMaintenanceShellInit & {#config: config}

		// Jobs
		if config.pimcore.redisAuthCheck.enabled {
			jobRedisCheck: #JobRedisAuthCheck & {#config: config}
		}
		jobInitialize: #JobInitialize & {#config: config}
		jobInstall: #JobInstall & {#config: config}
		jobMigrate: #JobMigrate & {#config: config}

		// CronJobs
		cronjobMaint: #CronJobMaintenance & {#config: config}
		if config.maintenance.mysqlBackup.enabled {
			cronjobBackup: #CronJobMysqlBackup & {#config: config}
		}
		for k, v in config.maintenance.consoleCronjobs {
			if v.enabled {
				"cronjob-console-\(k)": #CronJobConsole & {#config: config, #name: k, #cronVal: v}
			}
		}

		// PHP config maps
		cmPhpEnv:                 #ConfigMapPhpEnv & {#config: config}
		cmPhpConfD30PimcoreIni:   #ConfigMapPhpConfD30PimcoreIni & {#config: config}
		cmPhpFpmConf:             #ConfigMapPhpFpmConf & {#config: config}
		cmPhpFpmDzzzzWwwPoolConf: #ConfigMapPhpFpmDzzzzWwwPoolConf & {#config: config}
		cmPhpIni:                 #ConfigMapPhpIni & {#config: config}

		// Job environment and init dotenv
		cmInstallEnv:  #ConfigMapInstallationEnv & {#config: config}
		secInitDotenv: #SecretInitializeDotenv & {#config: config}

		// Cronjob environment
		cmMaintCronjobEnv: #ConfigMapMaintenanceCronjobEnv & {#config: config}

		// BackendConfig
		if config.nginx.backendConfig.enabled {
			"backendconfig-nginx": #BackendConfigNginx & {#config: config}
		}

		// Worker environment
		if config.maintenance.worker.replicas > 0 {
			cmMaintWorkerEnv: #ConfigMapMaintenanceWorkerEnv & {#config: config}
		}

		// Shell environment & dotenv
		if config.maintenance.shell.replicas > 0 {
			cmMaintShellEnv: #ConfigMapMaintenanceShellEnv & {#config: config}
			secMaintDotenv:  #SecretMaintenanceDotenv & {#config: config}
		}

		// HPA
		if config.autoscaling.enabled {
			hpa: #HorizontalPodAutoscaler & {#config: config}
		}

		// MySQL (MariaDB)
		mysqlSts:         #MySQLStatefulSet & {#config: config}
		mysqlHeadlessSvc: #MySQLHeadlessService & {#config: config}
		mysqlSvc:         #MySQLService & {#config: config}

		// Redis
		redisSts:         #RedisStatefulSet & {#config: config}
		redisHeadlessSvc: #RedisHeadlessService & {#config: config}
		redisSvc:         #RedisService & {#config: config}

		// OpenSearch
		opensearchSts:      #OpenSearchStatefulSet & {#config: config}
		opensearchSvc:      #OpenSearchService & {#config: config}
		opensearchSvcAlias: #OpenSearchServiceAlias & {#config: config}

		// RabbitMQ
		rabbitmqSts:       #RabbitMQStatefulSet & {#config: config}
		rabbitmqSvc:       #RabbitMQService & {#config: config}
		rabbitmqSvcAlias:  #RabbitMQServiceAlias & {#config: config}
	}
}

#ResourceRequirements: {
	requests?: {
		cpu?:    string
		memory?: string
		"ephemeral-storage"?: string
	}
	limits?: {
		cpu?:    string
		memory?: string
		"ephemeral-storage"?: string
	}
}

#Image: {
	registry:   string
	tag:        string
	digest:     *"" | string
	pullPolicy: *"Always" | "IfNotPresent" | "Never" | string
}
