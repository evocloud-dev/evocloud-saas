package templates

import (
	"strconv"
	"strings"

	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	kubeVersion!: string
	// Using the kubeVersion you can enforce a minimum Kubernetes minor version.
	// By default, the minimum Kubernetes version is set to 1.20.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels:       timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	selector: timoniv1.#Selector & {#Name: metadata.name}

	global: *{} | {...}
	global: *{} | {...}
	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels: *{} | timoniv1.#Labels
	commonAnnotations: *{} | timoniv1.#Annotations

	metadata: labels: commonLabels

	image!: timoniv1.#Image
	imagePullSecrets: *[] | [...timoniv1.#ObjectReference]

	containerPorts: {
		http: *2586 | int & >=1024 & <=65535
	}

	ntfy: {
		baseUrl:           *"" | string
		authDefaultAccess: *"read-write" | "read-only" | "write-only" | "deny-all"
		admin: {
			enabled:                   *false | bool
			username:                  *"admin" | string
			password:                  *"" | string
			role:                      *"admin" | "user"
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"password" | string
			existingSecretUsernameKey: *"" | string
			annotations: *{} | timoniv1.#Annotations
		}
		behindProxy:              *true | bool
		enableMetrics:            *false | bool
		metricsListenHttp:        *"" | string
		attachmentTotalSizeLimit: *"" | string
		attachmentFileSizeLimit:  *"" | string
		attachmentExpiryDuration: *"" | string
		banFeed: {
			enabled:   *false | bool
			file:      *"/var/cache/ntfy/ban.log" | string
			window:    *"10m" | string & !=""
			threshold: *100 | int & >=1
			weights: *["42909:10"] | [...string & =~"^(?:\\*|[0-9]+\\*?):[0-9]+$"]
			if enabled {
				file: !="" & =~"^/"
			}
		}
		extraConfig: *"" | string & !~"(?m)^[ \\t]*['\"]?listen[-_]http['\"]?[ \\t]*:"
		extraEnv: *[] | [...corev1.#EnvVar]
		database: {
			mode:              *"sqlite" | "postgresql"
			enabled:           *false | bool
			existingSecret:    *"" | string
			existingSecretKey: *"database-url" | string
			external: {
				host:                      *"" | string
				port:                      *"5432" | string | int
				name:                      *"ntfy" | string
				username:                  *"ntfy" | string
				password:                  *"" | string
				existingSecret:            *"" | string
				existingSecretPasswordKey: *"password" | string
				existingSecretUrlKey:      *"database-url" | string
			}
			waitImage!: timoniv1.#Image
		}
	}

	postgresql: {
		enabled:      *false | bool
		architecture: *"standalone" | string
		host:         *"" | string
		image: timoniv1.#Image & {
			repository: *"docker.io/library/postgres" | string
			tag:        *"18.6-trixie" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		auth: {
			database:                      *"ntfy" | string
			username:                      *"ntfy" | string
			password:                      *"" | string
			existingSecret:                *"" | string
			existingSecretUserPasswordKey: *"user-password" | string
		}
		resources: corev1.#ResourceRequirements & {
			requests: {
				cpu:    *"250m" | string
				memory: *"512Mi" | string
			}
			limits: {
				cpu:    *"500m" | string
				memory: *"1Gi" | string
			}
		}
		persistence: {
			enabled:      *true | bool
			size:         *"8Gi" | string
			storageClass: *"" | string
		}
		podSecurityContext: corev1.#PodSecurityContext & {
			runAsNonRoot:        *true | bool
			runAsUser:           *999 | int & >=1
			runAsGroup:          *999 | int & >=1
			fsGroup:             *999 | int & >=1
			fsGroupChangePolicy: *"OnRootMismatch" | "Always"
			seccompProfile: type: *"RuntimeDefault" | "Localhost" | "Unconfined"
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			privileged:               *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *999 | int & >=1
			runAsGroup:               *999 | int & >=1
			capabilities: drop: *["ALL"] | [...string]
		}
	}

	#ExternalSecretItem: {
		name:             *"" | string
		fullnameOverride: *"" | string
		labels: *{} | timoniv1.#Labels
		annotations: *{} | timoniv1.#Annotations
		spec!: {
			refreshInterval?: string
			secretStoreRef?: {name!: string, kind?: string, ...}
			target?: {name?: string, creationPolicy?: string, ...}
			data: *[] | [...{
				secretKey!: string
				remoteRef?: {...}
				sourceRef?: {
					storeRef?: {name!: string, ...}
					generatorRef?: {name!: string, ...}
					...
				}
				...
			}]
			dataFrom: *[] | [...{
				sourceRef?: {
					storeRef?: {name!: string, ...}
					generatorRef?: {name!: string, ...}
					...
				}
				...
			}]
			...
		}
	}

	externalSecrets: {
		enabled:         *false | bool
		refreshInterval: *"1h" | string & !=""
		items: *[] | [...#ExternalSecretItem]
	}

	persistence: {
		enabled:      *true | bool
		size:         *"2Gi" | string
		storageClass: *"" | string
		accessModes: *["ReadWriteOnce"] | [...corev1.#PersistentVolumeAccessMode]
		existingClaim:     *"" | string
		emptyDirSizeLimit: *"1Gi" | string & !=""
	}

	serviceAccount: {
		create: *false | bool
		name:   *"" | string
		annotations: *{} | timoniv1.#Annotations
		automountServiceAccountToken: *false | bool
	}

	service: {
		type: *"ClusterIP" | "NodePort" | "LoadBalancer"
		port: *80 | int & >0 & <=65535
		annotations: *{} | timoniv1.#Annotations
		ipFamilyPolicy: *null | null | "SingleStack" | "PreferDualStack" | "RequireDualStack"
		ipFamilies: *[] | [...("IPv4" | "IPv6")]
		if len(ipFamilies) > 2 {
			_ipFamiliesTooMany: true & false
		}
	}

	gateway: {
		enabled: *false | bool
		annotations: *{} | timoniv1.#Annotations
		parentRefs: *[] | [...{
			name!:        string & !=""
			namespace?:   string
			group?:       string
			kind?:        string
			sectionName?: string
			port?:        int & >=1 & <=65535
		}]
		hostnames: *[] | [...string]
		path:     *"/" | string
		pathType: *"PathPrefix" | "Exact" | "RegularExpression"
	}

	probes: {
		startup: {
			enabled:             *true | bool
			path:                *"/v1/health" | string & =~"^/"
			initialDelaySeconds: *5 | int & >=0
			periodSeconds:       *5 | int & >=1
			timeoutSeconds:      *3 | int & >=1
			failureThreshold:    *30 | int & >=1
		}
		liveness: {
			enabled:             *true | bool
			path:                *"/v1/health" | string & =~"^/"
			initialDelaySeconds: *0 | int & >=0
			periodSeconds:       *15 | int & >=1
			timeoutSeconds:      *5 | int & >=1
			failureThreshold:    *3 | int & >=1
		}
		readiness: {
			enabled:             *true | bool
			path:                *"/v1/health" | string & =~"^/"
			initialDelaySeconds: *0 | int & >=0
			periodSeconds:       *10 | int & >=1
			timeoutSeconds:      *5 | int & >=1
			failureThreshold:    *3 | int & >=1
		}
	}

	metrics: serviceMonitor: {
		enabled:  *false | bool
		interval: *"30s" | timoniv1.#PromDuration
		labels: *{} | timoniv1.#Labels
	}

	resources: corev1.#ResourceRequirements & {
		requests: {
			cpu:    *"50m" | string
			memory: *"64Mi" | string
		}
		limits: {
			cpu:    *"500m" | string
			memory: *"256Mi" | string
		}
	}

	podSecurityContext: corev1.#PodSecurityContext & {
		runAsNonRoot:        *true | bool
		runAsUser:           *1000 | int & >=1
		runAsGroup:          *1000 | int & >=1
		fsGroup:             *1000 | int & >=1
		fsGroupChangePolicy: *"OnRootMismatch" | "Always"
		seccompProfile: type: *"RuntimeDefault" | "Localhost" | "Unconfined"
	}

	securityContext: corev1.#SecurityContext & {
		allowPrivilegeEscalation: *false | bool
		privileged:               *false | bool
		readOnlyRootFilesystem:   *true | bool
		capabilities: drop: *["ALL"] | [...string]
	}

	runtimeStorage: {
		tmpSizeLimit: *"128Mi" | string & !=""
	}

	nodeSelector: *{} | {[string]: string}
	tolerations: *[] | [...corev1.#Toleration]
	affinity: *{} | corev1.#Affinity
	topologySpreadConstraints: *[] | [...corev1.#TopologySpreadConstraint]
	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *30 | int & >=0

	podLabels: *{} | timoniv1.#Labels
	podAnnotations: *{} | timoniv1.#Annotations

	podDisruptionBudget: {
		enabled:        *false | bool
		minAvailable:   *1 | int | string | null
		maxUnavailable: *null | int | string | null
	}

	extraVolumes: *[] | [...corev1.#Volume]
	extraVolumeMounts: *[] | [...corev1.#VolumeMount]
	extraManifests: *[] | [...{
		apiVersion!: string
		kind!:       string
		metadata!: {name!: string, namespace?: string, ...}
		...
	}]

	backup: {
		enabled:                    *false | bool
		schedule:                   *"0 3 * * *" | string
		suspend:                    *false | bool
		concurrencyPolicy:          *"Forbid" | "Allow" | "Replace"
		successfulJobsHistoryLimit: *3 | int & >=0
		failedJobsHistoryLimit:     *3 | int & >=0
		backoffLimit:               *1 | int & >=0
		archivePrefix:              *"ntfy" | string
		images: {
			archiver: *"docker.io/library/alpine:3.22" | string
			uploader: *"docker.io/helmforge/mc:1.0.0" | string
		}
		resources: *{} | corev1.#ResourceRequirements
		scratchSizeLimit: *"3Gi" | string & !=""
		tmpSizeLimit:     *"64Mi" | string & !=""
		serviceAccount: {
			create: *true | bool
			name:   *"" | string
			annotations: *{} | timoniv1.#Annotations
			automountServiceAccountToken: *false | bool
		}
		s3: {
			endpoint:                   *"" | string
			bucket:                     *"" | string
			prefix:                     *"ntfy" | string
			createBucketIfNotExists:    *false | bool
			existingSecret:             *"" | string
			existingSecretAccessKeyKey: *"access-key" | string
			existingSecretSecretKeyKey: *"secret-key" | string
			accessKey:                  *"" | string
			secretKey:                  *"" | string
			region:                     *"" | string
			credentialsFromPodIdentity: *false | bool
		}
	}

	oidc: {
		enabled:           *false | bool
		issuerUrl:         *"" | string
		clientId:          *"" | string
		clientSecret:      *"" | string
		existingSecret:    *"" | string
		existingSecretKey: *"client-secret" | string
		redirectUrl:       *"" | string
		logoutRedirectUrl: *"" | string
		defaultAccess:     *"read-write" | "read-only" | "deny-all"
	}

	smtp: {
		enabled:                   *false | bool
		senderAddr:                *"" | string
		senderFrom:                *"" | string
		senderUser:                *"" | string
		senderPass:                *"" | string
		existingSecret:            *"" | string
		existingSecretPasswordKey: *"smtp-password" | string
		senderVerify:              *false | bool
	}

	// Derived wiring values used across resource templates.
	_dbEnabled: postgresql.enabled || ntfy.database.mode == "postgresql" || ntfy.database.enabled

	_saName: [
		if serviceAccount.create && serviceAccount.name != "" {serviceAccount.name},
		if serviceAccount.create {metadata.name},
		if serviceAccount.name != "" {serviceAccount.name},
		"default",
	][0]

	_backupSaName: [
		if backup.serviceAccount.create && backup.serviceAccount.name != "" {backup.serviceAccount.name},
		if backup.serviceAccount.create {"\(metadata.name)-backup"},
		if backup.serviceAccount.name != "" {backup.serviceAccount.name},
		"default",
	][0]

	_pvcName: [
		if persistence.existingClaim != "" {persistence.existingClaim},
		"\(metadata.name)-data",
	][0]

	_dbHost: [
		if postgresql.enabled && postgresql.host != "" {postgresql.host},
		if postgresql.enabled {"\(metadata.name)-postgresql"},
		ntfy.database.external.host,
	][0]

	_dbPort: [
		if postgresql.enabled {"5432"},
		"\(ntfy.database.external.port)",
	][0]

	_dbName: [
		if postgresql.enabled {postgresql.auth.database},
		ntfy.database.external.name,
	][0]

	_dbUser: [
		if postgresql.enabled {postgresql.auth.username},
		ntfy.database.external.username,
	][0]

	_dbPass: [
		if postgresql.enabled {postgresql.auth.password},
		ntfy.database.external.password,
	][0]

	_dbUseExtSecretUrl: ntfy.database.existingSecret == "" && !postgresql.enabled && ntfy.database.external.password == "" && ntfy.database.external.existingSecret != ""
	_dbCreateSecret:    _dbEnabled && ntfy.database.existingSecret == "" && !_dbUseExtSecretUrl

	_dbSecretName: [
		if ntfy.database.existingSecret != "" {ntfy.database.existingSecret},
		if _dbUseExtSecretUrl {ntfy.database.external.existingSecret},
		"\(metadata.name)-db",
	][0]

	_dbSecretKey: [
		if ntfy.database.existingSecret != "" {ntfy.database.existingSecretKey},
		if _dbUseExtSecretUrl {ntfy.database.external.existingSecretUrlKey},
		"database-url",
	][0]

	_adminSecretName: [
		if ntfy.admin.existingSecret != "" {ntfy.admin.existingSecret},
		"\(metadata.name)-admin",
	][0]

	_adminPassKey: [
		if ntfy.admin.existingSecret != "" {ntfy.admin.existingSecretPasswordKey},
		"password",
	][0]

	_oidcSecretName: [
		if oidc.existingSecret != "" {oidc.existingSecret},
		"\(metadata.name)-oidc",
	][0]

	_smtpSecretName: [
		if smtp.existingSecret != "" {smtp.existingSecret},
		"\(metadata.name)-smtp",
	][0]

	_backupSecretName: [
		if backup.s3.existingSecret != "" {backup.s3.existingSecret},
		"\(metadata.name)-backup-s3",
	][0]

	// Cross-field validations matching templates/_helpers.tpl (ntfy.validate).
	if oidc.enabled && oidc.existingSecret == "" && oidc.clientSecret == "" {
		_oidcSecretRequired: "ntfy: oidc.clientSecret or oidc.existingSecret must be provided when oidc.enabled is true" & false
	}
	if smtp.enabled {
		if smtp.senderAddr == "" {
			_smtpAddrRequired: "ntfy: smtp.senderAddr is required when smtp.enabled is true" & false
		}
		if smtp.senderFrom == "" {
			_smtpFromRequired: "ntfy: smtp.senderFrom is required when smtp.enabled is true" & false
		}
		if ntfy.baseUrl == "" {
			_smtpBaseUrlRequired: "ntfy: ntfy.baseUrl is required when smtp.enabled is true" & false
		}
	}
	if _dbEnabled {
		if !postgresql.enabled && ntfy.database.existingSecret == "" && ntfy.database.external.host == "" {
			_dbConfigRequired: "PostgreSQL is enabled but neither postgresql.enabled, ntfy.database.existingSecret, nor ntfy.database.external.host is configured" & false
		}
		if postgresql.enabled && postgresql.auth.password == "" && postgresql.auth.existingSecret == "" {
			_pgPasswordRequired: "postgresql.enabled=true requires postgresql.auth.password or postgresql.auth.existingSecret" & false
		}
		if ntfy.database.mode == "postgresql" && !postgresql.enabled && ntfy.database.existingSecret == "" && ntfy.database.external.password == "" && ntfy.database.external.existingSecret == "" {
			_extDbPasswordRequired: "External PostgreSQL requires ntfy.database.external.password or ntfy.database.external.existingSecret" & false
		}
	}
	if externalSecrets.enabled {
		if len(externalSecrets.items) == 0 {
			_extSecretsItemsRequired: "externalSecrets.items must contain at least one item when externalSecrets.enabled=true" & false
		}
		let _esNames = [
			for idx, item in externalSecrets.items {
				[
					if item.fullnameOverride != "" {item.fullnameOverride},
					if item.name != "" {"\(metadata.name)-\(item.name)"},
					"\(metadata.name)-external-secret-\(idx)",
				][0]
			},
		]
		for i, ni in _esNames {
			for j, nj in _esNames if i < j && ni == nj {
				_duplicateEsNameErr: "externalSecrets.items resolve to duplicate name \(ni)" & false
			}
		}
	}
	if ntfy.admin.enabled {
		if ntfy.admin.existingSecret != "" && ntfy.admin.existingSecretPasswordKey == "" {
			_adminKeyRequired: "ntfy.admin.existingSecretPasswordKey must not be empty when ntfy.admin.existingSecret is configured" & false
		}
		if ntfy.admin.existingSecret == "" && ntfy.admin.password == "" {
			_adminPassRequired: "ntfy.admin.password or ntfy.admin.existingSecret must be provided when ntfy.admin.enabled is true" & false
		}
	}
	if ntfy.metricsListenHttp != "" {
		if (ntfy.metricsListenHttp & =~":[0-9]+$") == _|_ {
			_metricsPortFormatErr: "ntfy.metricsListenHttp must end with :PORT (1-65535)" & false
		}
		let _mParts = strings.Split(ntfy.metricsListenHttp, ":")
		let _mPort = strconv.Atoi(_mParts[len(_mParts)-1])
		if _mPort < 1 || _mPort > 65535 {
			_metricsPortRangeErr: "ntfy.metricsListenHttp port must be between 1 and 65535" & false
		}
	}
	for _, e in ntfy.extraEnv {
		if strings.ToUpper(e.name) == "NTFY_LISTEN_HTTP" {
			_extraEnvListenHttpErr: "ntfy: ntfy.extraEnv must not override NTFY_LISTEN_HTTP; use containerPorts.http" & false
		}
	}
	for k, _ in podLabels {
		if k == "app.kubernetes.io/name" || k == "app.kubernetes.io/instance" || k == "app.kubernetes.io/component" {
			_reservedPodLabelErr: "ntfy: podLabels must not override reserved selector label" & false
		}
	}
	if podDisruptionBudget.enabled {
		if podDisruptionBudget.minAvailable != null && podDisruptionBudget.maxUnavailable != null {
			_pdbMutualExclusionErr: "ntfy: podDisruptionBudget.minAvailable and maxUnavailable are mutually exclusive" & false
		}
		if podDisruptionBudget.minAvailable == null && podDisruptionBudget.maxUnavailable == null {
			_pdbAtLeastOneErr: "ntfy: podDisruptionBudget requires either minAvailable or maxUnavailable when enabled" & false
		}
	}
	if backup.enabled {
		if !persistence.enabled {
			_backupPersistenceErr: "ntfy: backup.enabled requires persistence.enabled=true" & false
		}
		if backup.s3.credentialsFromPodIdentity {
			if backup.s3.region == "" {
				_backupRegionErr: "ntfy: backup.s3.region is required when backup.s3.credentialsFromPodIdentity is true" & false
			}
			if !backup.serviceAccount.create && backup.serviceAccount.name == "" {
				_backupSaErr: "ntfy: backup.serviceAccount.name is required when workload identity is enabled and backup.serviceAccount.create is false" & false
			}
		}
	}
	if gateway.enabled && len(gateway.parentRefs) == 0 {
		_gatewayParentRefsErr: "gateway.parentRefs is required when gateway.enabled=true" & false
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.externalSecrets.enabled {
			for idx, item in config.externalSecrets.items {
				"externalsecret_\(idx)": #ExternalSecret & {#config: config, #index: idx, #item: item}
			}
		}

		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}

		if config.backup.enabled && config.backup.s3.credentialsFromPodIdentity && config.backup.serviceAccount.create {
			"backup-sa": #BackupServiceAccount & {#config: config}
		}

		cm: #ConfigMap & {#config: config}

		if config._dbCreateSecret {
			"db-secret": #DbSecret & {#config: config}
		}

		if config.ntfy.admin.enabled && config.ntfy.admin.existingSecret == "" {
			"admin-secret": #AdminSecret & {#config: config}
		}

		if config.oidc.enabled && config.oidc.clientSecret != "" && config.oidc.existingSecret == "" {
			"oidc-secret": #OidcSecret & {#config: config}
		}

		if config.smtp.enabled && config.smtp.senderPass != "" && config.smtp.existingSecret == "" {
			"smtp-secret": #SmtpSecret & {#config: config}
		}

		if config.backup.enabled && !config.backup.s3.credentialsFromPodIdentity && config.backup.s3.existingSecret == "" {
			"backup-s3-secret": #BackupS3Secret & {#config: config}
		}

		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PVC & {#config: config}
		}

		svc: #Service & {#config: config}

		deploy: #Deployment & {
			#config: config
			#cmData: objects.cm.data
		}

		if config.podDisruptionBudget.enabled {
			pdb: #PodDisruptionBudget & {#config: config}
		}

		if config.gateway.enabled {
			httproute: #HTTPRoute & {#config: config}
		}

		if config.ntfy.enableMetrics && config.metrics.serviceMonitor.enabled {
			servicemonitor: #ServiceMonitor & {#config: config}
		}

		if config.backup.enabled {
			"backup-cronjob": #BackupCronJob & {#config: config}
		}

		if config.postgresql.enabled {
			if config.postgresql.auth.existingSecret == "" {
				"postgresql-auth": #PostgresqlSecret & {#config: config}
			}
			"postgresql-config": #PostgresqlConfigMap & {#config: config}
			"postgresql-initdb": #PostgresqlInitDbConfigMap & {#config: config}
			"postgresql-primary-headless": #PostgresqlHeadlessService & {#config: config}
			"postgresql": #PostgresqlService & {#config: config}
			"postgresql-statefulset": #PostgresqlStatefulSet & {#config: config}
		}

		if config.postgresql.enabled {
			if config.postgresql.auth.existingSecret == "" {
				"postgresql-auth": #PostgresqlSecret & {#config: config}
			}
			"postgresql-config": #PostgresqlConfigMap & {#config: config}
			"postgresql-initdb": #PostgresqlInitDbConfigMap & {#config: config}
			"postgresql-primary-headless": #PostgresqlHeadlessService & {#config: config}
			"postgresql": #PostgresqlService & {#config: config}
			"postgresql-statefulset": #PostgresqlStatefulSet & {#config: config}
		}

		for idx, m in config.extraManifests {
			"extra-manifest-\(idx)": m
		}
	}
}
