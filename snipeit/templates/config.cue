package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
	networkingv1 "k8s.io/api/networking/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"crypto/sha256"
	"encoding/hex"
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

	fullname:   metadata.name
	chart:      *"snipeit-3.4.1" | string
	appVersion: *"v6.0.14" | string

	// The number of pods replicas.
	// By default, the number of replicas is 1.
	replicaCount: *1 | int

	// Revision history limit.
	revisionHistoryLimit: *0 | int

	// Deployment strategy.
	deploymentStrategy?: appsv1.#DeploymentStrategy


	// PodDisruptionBudget settings
	pdb: {
		enabled: *true | bool
		maxUnavailable?: int | string
	}

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	// The default image repository and tag is set in `values.cue`.
	image: timoniv1.#Image & {
		repository: *"snipe/snipe-it" | string
		tag:        *"" | string
		digest:     *"" | string
	}

	// The resources allows setting the container resource requirements.
	resources: *{} | corev1.#ResourceRequirements

	// Service settings.
	service: {
		type: *"ClusterIP" | "NodePort" | "LoadBalancer" | "ExternalName"
		annotations: *{} | {[string]: string}
		port:            *80 | int & >0 & <=65535
		clusterIP?:      string
		loadBalancerIP?: string
		loadBalancerSourceRanges?: [...string]
		externalIPs?: [...string]
	}

	config: {
		mysql: externalDatabase: {
			user: *"snipeit" | string
			pass: *"" | string
			name: *"db-snipeit" | string
			host: *"mysql" | string
			port: *3306 | int | string
		}
		snipeit: {
			env:      *"production" | string
			debug:    *false | bool | string
			url:      *"http://example.local" | string
			key:      *"" | string
			timezone: *"Europe/Berlin" | string
			locale:   *"en" | string
			envConfig: *{} | {[string]: _}
		}
		externalSecrets: *"" | string
	}

	mysql: {
		enabled:                 *false | bool
		image:                   *"mysql" | string
		imageTag:                *"9.7.0" | string
		imagePullPolicy:         *"IfNotPresent" | string
		mysqlRootPassword:       *mysqlPassword | string
		mysqlUser:               *"snipeit" | string
		mysqlPassword:           *"snipeit" | string
		mysqlAllowEmptyPassword: *false | bool
		allowEmptyRootPassword:  *false | bool
		mysqlDatabase:           *"db-snipeit" | string
		existingSecret:          *"" | string
		args: *[] | [...string]
		extraVolumes: *[] | [...corev1.#Volume]
		extraVolumeMounts: *[] | [...corev1.#VolumeMount]
		extraInitContainers: *[] | [...corev1.#Container]
		extraEnvVars: *[] | [...corev1.#EnvVar]
		imagePullSecrets: *[] | [...corev1.#LocalObjectReference]
		nodeSelector: *{} | {[string]: string}
		affinity: *{} | corev1.#Affinity
		tolerations: *[] | [...corev1.#Toleration]
		schedulerName?:     string
		priorityClassName?: string
		deploymentAnnotations: *{} | {[string]: string}
		podAnnotations: *{} | {[string]: string}
		podLabels: *{} | {[string]: string}
		strategy: *{type: "Recreate"} | _
		busybox: {
			image: *"busybox" | string
			tag:   *"1.32" | string
		}
		testFramework: {
			enabled:         *true | bool
			image:           *"bats/bats" | string
			tag:             *"1.2.1" | string
			imagePullPolicy: *"IfNotPresent" | string
			securityContext: *{} | corev1.#SecurityContext
		}
		livenessProbe: {
			initialDelaySeconds: *30 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
			successThreshold:    *1 | int
			failureThreshold:    *3 | int
		}
		readinessProbe: {
			initialDelaySeconds: *5 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *1 | int
			successThreshold:    *1 | int
			failureThreshold:    *3 | int
		}
		persistence: {
			enabled:    *true | bool
			accessMode: *"ReadWriteOnce" | string
			size:       *"8Gi" | string
			annotations: *{} | {[string]: string}
			storageClass?: string
			existingClaim: *"" | string
			subPath?:      string
		}
		securityContext: {
			enabled:                  *false | bool
			runAsUser:                *999 | int
			fsGroup:                  *999 | int
			allowPrivilegeEscalation: *false | bool
			capabilities:             *{drop: ["ALL"]} | corev1.#Capabilities
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
			seccompProfile:           *{type: "RuntimeDefault"} | corev1.#SeccompProfile
		}
		resources: *{requests: {memory: "256Mi", cpu: "100m"}} | corev1.#ResourceRequirements
		configurationFilesPath: *"/etc/mysql/conf.d/" | string
		configurationFiles: *{} | {[string]: string}
		initializationFiles: *{} | {[string]: string}
		metrics: {
			enabled:         *false | bool
			image:           *"prom/mysqld-exporter" | string
			imageTag:        *"v0.10.0" | string
			imagePullPolicy: *"IfNotPresent" | string
			resources: *{} | corev1.#ResourceRequirements
			annotations: *{} | {[string]: string}
			livenessProbe: {
				initialDelaySeconds: *15 | int
				timeoutSeconds:      *5 | int
			}
			readinessProbe: {
				initialDelaySeconds: *5 | int
				timeoutSeconds:      *1 | int
			}
			flags: *[] | [...string]
			serviceMonitor: {
				enabled: *false | bool
				additionalLabels: *{} | {[string]: string}
			}
		}
		service: {
			annotations: *{} | {[string]: string}
			type:            *"ClusterIP" | string
			port:            *3306 | int
			nodePort?:       int
			loadBalancerIP?: string
		}
		serviceAccount: {
			create: *false | bool
			name:   *"" | string
		}
		ssl: {
			enabled: *false | bool
			secret:  *"mysql-ssl-certs" | string
			certificates: *[] | [...{name: string, ca: string, cert: string, key: string}]
		}
		timezone?: string
		initContainer: resources: *{requests: {memory: "10Mi", cpu: "10m"}} | corev1.#ResourceRequirements
		chart: *"mysql-1.0.0" | string
		labels: {
			"app.kubernetes.io/name":     "mysql"
			"app.kubernetes.io/instance": metadata.name
			"helm.sh/chart":              chart
		}
		selector: {
			"app.kubernetes.io/name":     "mysql"
			"app.kubernetes.io/instance": metadata.name
		}
		secretName: string
		if existingSecret != "" {
			secretName: existingSecret
		}
		if existingSecret == "" {
			secretName: "\(metadata.name)-mysql"
		}
		serviceAccountName: string
		if serviceAccount.create {
			if serviceAccount.name != "" {
				serviceAccountName: serviceAccount.name
			}
			if serviceAccount.name == "" {
				serviceAccountName: "\(metadata.name)-mysql"
			}
		}
		if !serviceAccount.create {
			if serviceAccount.name != "" {
				serviceAccountName: serviceAccount.name
			}
			if serviceAccount.name == "" {
				serviceAccountName: "default"
			}
		}
	}

	"mysql-backup": {
		enabled: *false | bool
		image: {
			name:       *"quay.io/yeebase/mysql-client" | string
			tag:        *"gcloud-sdk" | string
			pullPolicy: *"Always" | string
			pullSecrets: *[] | [...string]
		}
		tasks: {
			backup: {
				cron:   *false | bool
				manual: *false | bool
			}
			restore: {
				cron:   *false | bool
				manual: *false | bool
			}
		}
		schedule: *"0 3 * * *" | string
		gcs: {
			serviceAccountKey: *"" | string
			bucket: {
				name: *"" | string
				path: *"" | string
			}
		}
		database: {
			host:    *"mariadb" | string
			user:    *"admin" | string
			pass:    *"dummy" | string
			name:    *"--all-databases" | string
			charset: *"utf8" | string
		}
		filename: *"" | string
		resources: *{} | corev1.#ResourceRequirements
		sanitize: {
			enabled: *false | bool
			sql: *[] | [...string]
		}
		chart: *"mysql-backup-1.0.1" | string
		_backupFilename: string
		if filename != "" {
			_backupFilename: filename
		}
		if filename == "" {
			if database.name == "--all-databases" {
				_backupFilename: "all"
			}
			if database.name != "--all-databases" {
				_backupFilename: database.name
			}
		}
	}

	persistence: {
		enabled: *true | bool
		annotations: *{} | {[string]: string}
		accessMode:    *"ReadWriteOnce" | string
		existingClaim: *"" | string
		storageClass?: string
		size:          *"2Gi" | string
		www: {
			mountPath: *"/var/lib/snipeit" | string
			subPath:   *"www" | string
		}
		sessions: {
			mountPath: *"/var/www/html/storage/framework/sessions" | string
			subPath:   *"sessions" | string
		}
	}

	ingress: {
		enabled:   *true | bool
		className: *"" | string
		annotations: *{} | {[string]: string}
		path:     *"/" | string
		pathType: *"ImplementationSpecific" | networkingv1.#PathType
		hosts: *["example.local"] | [...string]
		tls: *[] | [...{secretName?: string, hosts: [...string]}]
	}

	podSecurityContext?:  corev1.#PodSecurityContext
	securityContext?:     corev1.#SecurityContext
	podAnnotations?:      {[string]: string}
	nodeSelector: *{} | {[string]: string}
	initContainer: resources: *{requests: {memory: "10Mi", cpu: "10m"}} | corev1.#ResourceRequirements
	tolerations?: [...corev1.#Toleration]
	affinity?: corev1.#Affinity
	extraAnnotations: *{} | {[string]: string}
	extraVolumeMounts: *[] | [...corev1.#VolumeMount]
	extraVolumes: *[] | [...corev1.#Volume]
	extraManifests: *[] | [...]

	_labels: {
		"app.kubernetes.io/name":     "snipeit"
		"app.kubernetes.io/instance": metadata.name
		"helm.sh/chart":              chart
	}
	_selector: {
		"app.kubernetes.io/name":     "snipeit"
		"app.kubernetes.io/instance": metadata.name
	}
	_pdbSelector: {
		app:     _chartName
		release: metadata.name
	}
	_chartName: string
	_chartName: "snipeit"
	_claimName: string
	if persistence.existingClaim != "" {
		_claimName: persistence.existingClaim
	}
	if persistence.existingClaim == "" {
		_claimName: fullname
	}
	_imageTag: string
	if image.tag != "" {
		_imageTag: image.tag
	}
	if image.tag == "" {
		_imageTag: appVersion
	}
	_imageRef:       "\(image.repository):\(_imageTag)"
	_secretChecksum: hex.Encode(sha256.Sum256("\(config.externalSecrets)|\(mysql.enabled)|\(mysql.mysqlUser)|\(mysql.mysqlPassword)|\(mysql.mysqlDatabase)|\(config.mysql.externalDatabase.user)|\(config.mysql.externalDatabase.pass)|\(config.mysql.externalDatabase.name)|\(config.mysql.externalDatabase.host)|\(config.mysql.externalDatabase.port)|\(config.snipeit.key)|\(len(config.snipeit.envConfig))"))

	test: {
		enabled: bool | *false
	}
}

#Instance: {
	config: #Config

	objects: {
		svc: #Service & {#config: config}

		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PersistentVolumeClaim & {#config: config}
		}

		if config.config.externalSecrets == "" {
			secret: #Secret & {#config: config}
		}

		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}


		if config.pdb.enabled {
			pdb: #PodDisruptionBudget & {#config: config}
		}


		if config.mysql.enabled {
			if len([for key, _ in config.mysql.configurationFiles {key}]) > 0 {
				"mysql-configmap": #MysqlConfigMap & {#config: config}
			}
			if len([for key, _ in config.mysql.initializationFiles {key}]) > 0 {
				mysqlInitialization: #MysqlInitializationConfigMap & {#config: config}
			}
			if config.mysql.existingSecret == "" && (!config.mysql.allowEmptyRootPassword || config.mysql.mysqlRootPassword != "" || config.mysql.mysqlPassword != "") {
				"mysql-secret": #mysqlSecret & {#config: config}
			}
			if config.mysql.serviceAccount.create {
				mysqlServiceAccount: #MysqlServiceAccount & {#config: config}
			}
			"mysql-deployment": #MysqlDeployment & {#config: config}
			"mysql-service": #MysqlService & {#config: config}
			if config.mysql.persistence.enabled && config.mysql.persistence.existingClaim == "" {
				"mysql-pvc": #MysqlPersistentVolumeClaim & {#config: config}
			}
			if config.mysql.metrics.enabled && config.mysql.metrics.serviceMonitor.enabled {
				mysqlServiceMonitor: #MysqlServiceMonitor & {#config: config}
			}
			if config.mysql.testFramework.enabled {
				"mysql-test-configmap": #MysqlTestConfigMap & {#config: config}
			}
		}

		if config["mysql-backup"].enabled {
			"mysql-backup-configmap":    #MysqlBackupScriptConfigMap & {#config: config}
			"mysql-backup-gcs-secret":   #MysqlBackupGCSSecret & {#config: config}
			"mysql-backup-mysql-secret": #MysqlBackupMysqlSecret & {#config: config}
			if config["mysql-backup"].sanitize.enabled {
				"mysql-backup-sanitize-configmap": #MysqlBackupSanitizeConfigMap & {#config: config}
			}
			if config["mysql-backup"].tasks.backup.cron {
				"mysql-backup-cronjob": #MysqlBackupCronJob & {#config: config}
			}
			if config["mysql-backup"].tasks.restore.cron {
				"mysql-restore-cronjob": #MysqlRestoreCronJob & {#config: config}
			}
			if config["mysql-backup"].tasks.backup.manual {
				"mysql-backup-job": #MysqlBackupJob & {#config: config}
			}
			if config["mysql-backup"].tasks.restore.manual {
				"mysql-restore-job": #MysqlRestoreJob & {#config: config}
			}
		}

		deploy: #Deployment & {
			#config: config
		}
	}

	tests: {}
}