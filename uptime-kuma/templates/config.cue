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
	// By default, the minimum Kubernetes version is set to 1.26.0 (matching Chart.yaml).
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.26.0"}

	// The moduleVersion is set from the user-supplied module version.
	// This field is used for the `app.kubernetes.io/version` label.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// Name overrides
	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	_name: string
	if fullnameOverride != "" {
		_name: fullnameOverride
	}
	if fullnameOverride == "" {
		_name: metadata.name
	}

	// Common labels for all resources
	commonLabels: *{} | {[string]: string}
	metadata: labels: commonLabels
	metadata: labels: {
		"app.kubernetes.io/part-of": *"helmforge" | string
	}

	// The selector allows adding label selectors to Deployments and Services.
	selector: timoniv1.#Selector & {#Name: _name}

	// Container image configuration
	image!: timoniv1.#Image & {
		tag: !~"^(latest|stable|main|master|edge)$"
	}

	// Image pull secrets
	imagePullSecrets: *[] | [...timoniv1.#ObjectReference]

	// Uptime Kuma application configuration
	uptimeKuma: {
		port:                   *3001 | int & >0 & <=65535
		disableFrameSameOrigin: *false | bool
		extraEnv: *[] | [...corev1.#EnvVar]
	}

	// Database configuration
	database: {
		type: *"sqlite" | "mariadb"
		external: {
			host:                      *"" | string
			port:                      *3306 | int | string
			name:                      *"uptime_kuma" | string
			username:                  *"uptime_kuma" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"password" | string
		}
	}

	// MySQL subchart / compatibility configuration
	mysql: {
		enabled:      *false | bool
		architecture: *"standalone" | string
		image: {
			repository: *"docker.io/library/mysql" | string
			tag:        *"9.7.2" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | string
			reference:  string
			if digest != "" && tag != "" {
				reference: "\(repository):\(tag)@\(digest)"
			}
			if digest != "" && tag == "" {
				reference: "\(repository)@\(digest)"
			}
			if digest == "" && tag != "" {
				reference: "\(repository):\(tag)"
			}
			if digest == "" && tag == "" {
				reference: "\(repository):latest"
			}
		}
		auth: {
			database:            *"uptime_kuma" | string
			username:            *"uptime_kuma" | string
			password:            *"" | string
			rootPassword:        *"" | string
			replicationPassword: *"" | string
		}
		persistence: {
			enabled:      *true | bool
			size:         *"8Gi" | string
			storageClass: *"" | string
			accessModes: *[corev1.#ReadWriteOnce] | [...corev1.#PersistentVolumeAccessMode]
		}
		resources: *{
			requests: {
				cpu:    "250m"
				memory: "512Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "1Gi"
			}
		} | timoniv1.#ResourceRequirements | {}
	}

	_dbType: database.type
	_dbHost: string
	if mysql.enabled {
		_dbHost: "\(_name)-mysql"
	}
	if !mysql.enabled {
		_dbHost: database.external.host
	}

	_dbPort: string
	if mysql.enabled {
		_dbPort: "3306"
	}
	if !mysql.enabled {
		_dbPort: "\(database.external.port)"
	}

	_dbName: string
	if mysql.enabled {
		if mysql.auth.database != "" {
			_dbName: mysql.auth.database
		}
		if mysql.auth.database == "" {
			_dbName: "uptime_kuma"
		}
	}
	if !mysql.enabled {
		if database.external.name != "" {
			_dbName: database.external.name
		}
		if database.external.name == "" {
			_dbName: "uptime_kuma"
		}
	}

	_dbUsername: string
	if mysql.enabled {
		if mysql.auth.username != "" {
			_dbUsername: mysql.auth.username
		}
		if mysql.auth.username == "" {
			_dbUsername: "uptime_kuma"
		}
	}
	if !mysql.enabled {
		if database.external.username != "" {
			_dbUsername: database.external.username
		}
		if database.external.username == "" {
			_dbUsername: "uptime_kuma"
		}
	}

	_dbSecretName: string
	if mysql.enabled {
		_dbSecretName: "\(_name)-mysql-auth"
	}
	if !mysql.enabled {
		if database.external.existingSecret != "" {
			_dbSecretName: database.external.existingSecret
		}
		if database.external.existingSecret == "" {
			_dbSecretName: "\(_name)-db"
		}
	}

	_dbSecretPasswordKey: string
	if mysql.enabled {
		_dbSecretPasswordKey: "mysql-user-password"
	}
	if !mysql.enabled {
		if database.external.existingSecret != "" {
			_dbSecretPasswordKey: database.external.existingSecretPasswordKey
		}
		if database.external.existingSecret == "" {
			_dbSecretPasswordKey: "password"
		}
	}

	// Persistence configuration
	persistence: {
		enabled:      *true | bool
		size:         *"2Gi" | string
		storageClass: *"" | string
		accessModes: *[corev1.#ReadWriteOnce] | [...corev1.#PersistentVolumeAccessMode]
		existingClaim: *"" | string
	}

	_dataClaimName: string
	if persistence.existingClaim != "" {
		_dataClaimName: persistence.existingClaim
	}
	if persistence.existingClaim == "" {
		_dataClaimName: "\(_name)-data"
	}

	// ServiceAccount configuration
	serviceAccount: {
		create:                        *false | bool
		name:                          *"" | string
		annotations?:                  timoniv1.#Annotations
		automountServiceAccountToken?: bool
	}

	_serviceAccountName: string
	if serviceAccount.create {
		if serviceAccount.name != "" {
			_serviceAccountName: serviceAccount.name
		}
		if serviceAccount.name == "" {
			_serviceAccountName: _name
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

	// Service configuration
	service: {
		type:            *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
		port:            *80 | int & >0 & <=65535
		annotations?:    timoniv1.#Annotations
		ipFamilyPolicy?: *"SingleStack" | "PreferDualStack" | "RequireDualStack" | string
		ipFamilies?: [...string]
	}


	// Probes configuration
	probes: {
		startup: {
			enabled:             *true | bool
			path:                *"/" | string
			initialDelaySeconds: *10 | int
			periodSeconds:       *5 | int
			timeoutSeconds:      *3 | int
			failureThreshold:    *30 | int
		}
		liveness: {
			enabled:             *true | bool
			path:                *"/" | string
			initialDelaySeconds: *0 | int
			periodSeconds:       *15 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *3 | int
		}
		readiness: {
			enabled:             *true | bool
			path:                *"/" | string
			initialDelaySeconds: *0 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *3 | int
		}
	}

	// Resources and Security
	resources: *{
		requests: {
			cpu:    "100m"
			memory: "128Mi"
		}
		limits: {
			cpu:    "500m"
			memory: "512Mi"
		}
	} | timoniv1.#ResourceRequirements | {}
	podSecurityContext?: corev1.#PodSecurityContext
	securityContext?:    corev1.#SecurityContext

	lifecycle: *{
		preStop: {
			exec: {
				command: ["sh", "-c", "sleep 5"]
			}
		}
	} | corev1.#Lifecycle

	// Scheduling & Pod settings
	nodeSelector: *{} | {[string]: string}
	tolerations: *[] | [...corev1.#Toleration]
	affinity: *{} | timoniv1.#AffinityValues | corev1.#Affinity
	topologySpreadConstraints: *[] | [...corev1.#TopologySpreadConstraint]
	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *30 | int
	podLabels?: {[string]: string}
	podAnnotations?: {[string]: string}

	// Backup configuration
	backup: {
		enabled:                    *false | bool
		schedule:                   *"0 2 * * *" | string
		suspend:                    *false | bool
		concurrencyPolicy:          *"Forbid" | "Allow" | "Replace"
		successfulJobsHistoryLimit: *3 | int
		failedJobsHistoryLimit:     *3 | int
		backoffLimit:               *1 | int
		archivePrefix:              *"uptime-kuma" | string
		resources: *{} | timoniv1.#ResourceRequirements
		images: {
			uploader!: timoniv1.#Image
			mysql!:    timoniv1.#Image
		}
		s3: {
			endpoint:                   *"" | string
			bucket:                     *"" | string
			prefix:                     *"uptime-kuma" | string
			createBucketIfNotExists:    *true | bool
			existingSecret:             *"" | string
			existingSecretAccessKeyKey: *"access-key" | string
			existingSecretSecretKeyKey: *"secret-key" | string
			accessKey:                  *"" | string
			secretKey:                  *"" | string
		}
	}

	_backupSecretName: string
	if backup.s3.existingSecret != "" {
		_backupSecretName: backup.s3.existingSecret
	}
	if backup.s3.existingSecret == "" {
		_backupSecretName: "\(_name)-backup-s3"
	}

	// Volumes & Mounts
	extraVolumes: *[] | [...corev1.#Volume]
	extraVolumeMounts: *[] | [...corev1.#VolumeMount]

	// Extra manifests
	extraManifests: *[] | [...{...}]

	// Gateway API
	gatewayAPI: {
		enabled:          *false | bool
		gatewayClassName: *"" | string
		httpRoutes: *[] | [...{...}]
	}

	// External Secrets
	externalSecrets: {
		enabled:         *false | bool
		apiVersion:      *"external-secrets.io/v1" | string
		refreshInterval: *"1h" | string
		items: *[] | [...{...}]
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		deploy: #Deployment & {#config: config}
		svc: #Service & {#config: config}

		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PersistentVolumeClaim & {#config: config}
		}

		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}


		if config.database.type == "mariadb" && !config.mysql.enabled && config.database.external.existingSecret == "" && config.database.external.password != "" {
			secretDB: #DBSecret & {#config: config}
		}

		if config.mysql.enabled {
			mysqlAuth: #MySQLAuthSecret & {#config: config}
			mysqlConfig: #MySQLConfigMap & {#config: config}
			mysqlInitDB: #MySQLInitDBConfigMap & {#config: config}
			mysqlHeadlessSvc: #MySQLHeadlessService & {#config: config}
			mysqlSvc: #MySQLService & {#config: config}
			mysqlStatefulSet: #MySQLStatefulSet & {#config: config}
		}

		if config.backup.enabled && config.backup.s3.existingSecret == "" && (config.backup.s3.accessKey != "" || config.backup.s3.secretKey != "") {
			secretBackup: #BackupSecret & {#config: config}
		}

		if config.backup.enabled {
			cmBackup: #BackupConfigMap & {#config: config}
			cronBackup: #BackupCronJob & {#config: config}
		}

		if config.gatewayAPI.enabled {
			for i, r in config.gatewayAPI.httpRoutes {
				"httproute-\(i)": #HTTPRoute & {#config: config, #route: r, #index: i}
			}
		}

		if config.externalSecrets.enabled {
			for i, it in config.externalSecrets.items {
				"externalsecret-\(i)": #ExternalSecret & {#config: config, #item: it, #index: i}
			}
		}

		for i, m in config.extraManifests {
			"extra-\(i)": m
		}
	}
}
