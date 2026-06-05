package templates

import (
	"list"
	"strconv"
	"strings"
	timoniv1 "timoni.sh/core/v1alpha1"
)

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

	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	labels:            *{} | {[string]: string}
	podLabels:         *{} | {[string]: string}
	commonAnnotations: *{} | {[string]: string}
	podAnnotations:    *{} | {[string]: string}
	imagePullSecrets:  *[] | [..._]

	serviceAccount: {
		create:      *true | bool
		name:        *"" | string
		annotations: *{} | {[string]: string}
	}

	hieventsConfig: {
		app: {
			name:                         *"Hi.Events" | string
			env:                          *"production" | string
			debug:                        *"false" | string
			url:                          *"" | string
			frontendUrl:                  *"" | string
			cdnUrl:                       *"" | string
			sanctumStatefulDomains:       *"" | string
			sessionDomain:                *"" | string
			trustedProxies:               *"*" | string
			logQueries:                   *"false" | string
			homepageViewsUpdateBatchSize: *8 | int
			allowedInternalWebhookHosts:  *"" | string
			emailLogoUrl:                 *"" | string
			emailLogoLinkUrl:             *"" | string
			disableRegistration:          *"false" | string
			platformSupportEmail:         *"" | string
			saasModeEnabled:              *"false" | string
			saasStripeApplicationFeePercent: *"0" | string
			saasStripeApplicationFeeFixed:   *"0" | string
			stripeConnectAccountType:        *"express" | string
			timezone:                     *"UTC" | string
			locale:                       *"en" | string
			viteApiUrlClient:             *"" | string
			viteApiUrlServer:             *"" | string
			viteFrontendUrl:              *"" | string
			port:                         *8080 | int
		}
		mail: {
			mailer:      *"log" | string
			driver:      *"log" | string
			host:        *"" | string
			port:        *587 | int
			username:    *"" | string
			encryption:  *"tls" | string
			fromAddress: *"" | string
			fromName:    *"" | string
		}
		logging: {
			channel:             *"stderr" | string
			level:               *"info" | string
			deprecationsChannel: *"" | string
		}
		queue: {
			connection:       *"redis" | string
			webhookQueueName: *"webhook-queue" | string
		}
		cache: driver: *"redis" | string
		session: {
			driver:   *"redis" | string
			lifetime: *120 | int
		}
		broadcast: driver: *"log" | string
		jwt: algo: *"HS256" | string
		storage: {
			driver:           *"local" | string
			disk:             *"" | string
			filesystemDriver: *"" | string
			publicDisk:       *"" | string
			privateDisk:      *"" | string
		}
		postgresql: {
			port:        *5432 | int
			database:    *"hievents" | string
			username:    *"hievents" | string
			databaseUrl: *"" | string
		}
		redis: {
			client:        *"phpredis" | string
			port:          *6379 | int
			database:      *0 | int
			cacheDatabase: *1 | int
			username:      *"" | string
			url:           *"" | string
		}
		s3: {
			region:               *"us-east-1" | string
			publicBucket:         *"" | string
			privateBucket:        *"" | string
			endpoint:             *"" | string
			url:                  *"" | string
			usePathStyleEndpoint: *"true" | string
		}
	}
	secrets: {
		app: {
			useExisting:             *false | bool
			secretName:              *"app" | string
			appKeySecretKey:         *"app-key" | string
			appKeyKey:               *"app-key" | string
			appKey:                  *"" | string
			jwtSecretKey:            *"jwt-secret" | string
			jwtSecret:               *"" | string
			stripePublishableKeyKey: *"stripe-publishable-key" | string
			stripePublishableKey:    *"" | string
			stripeSecretKeyKey:      *"stripe-secret-key" | string
			stripeSecretKey:         *"" | string
			stripeWebhookSecretKey:  *"stripe-webhook-secret" | string
			stripeWebhookSecret:     *"" | string
		}
		postgresql: {
			useExisting: *false | bool
			secretName:  *"postgresql" | string
			passwordKey: *"postgres-password" | string
			password:    *"" | string
		}
		redis: {
			useExisting: *false | bool
			secretName:  *"redis" | string
			passwordKey: *"redis-password" | string
			password:    *"" | string
		}
		mail: {
			useExisting: *false | bool
			secretName:  *"mail" | string
			passwordKey: *"mail-password" | string
			password:    *"" | string
		}
		s3: {
			useExisting:        *false | bool
			secretName:         *"s3" | string
			accessKeyIdKey:     *"aws-access-key-id" | string
			secretAccessKeyKey: *"aws-secret-access-key" | string
			accessKeyId:        *"" | string
			secretAccessKey:    *"" | string
		}
	}
	backend: {
		enabled:      *true | bool
		replicaCount: *1 | int
		image: {registry: *"docker.io" | string, repository: *"daveearley/hi.events-backend" | string, tag: *"v1.9.0-beta" | string, digest: *"" | string, pullPolicy: *"IfNotPresent" | string}
		command: *[] | [...string]
		args:    *[] | [...string]
		service: {type: *"ClusterIP" | string, port: *80 | int, targetPort: *8080 | int}
		probes: {
			type: *"tcpSocket" | string
			startup:   {periodSeconds: *10 | int, timeoutSeconds: *5 | int, failureThreshold: *30 | int}
			liveness:  {initialDelaySeconds: *30 | int, periodSeconds: *10 | int, timeoutSeconds: *5 | int, failureThreshold: *3 | int}
			readiness: {initialDelaySeconds: *15 | int, periodSeconds: *10 | int, timeoutSeconds: *5 | int, failureThreshold: *10 | int}
		}
		resources:          *{} | {[string]: _}
		podSecurityContext: *{} | {[string]: _}
		securityContext:    *{} | {[string]: _}
		persistence: {
			enabled:       *true | bool
			existingClaim: *"" | string
			storageClass:  *"" | string
			accessModes:   *["ReadWriteOnce"] | [...string]
			size:          *"10Gi" | string
			mountPath:     *"/var/www/html/storage/app" | string
		}
		nodeSelector:              *{} | {[string]: string}
		tolerations:               *[] | [..._]
		affinity:                  *{} | {[string]: _}
		topologySpreadConstraints: *[] | [..._]
		autoscaling: {
			enabled:                        *false | bool
			minReplicas:                    *1 | int
			maxReplicas:                    *10 | int
			targetCPUUtilizationPercentage: *80 | int
		}
		pdb: {
			enabled:      *false | bool
			minAvailable: *1 | int
		}
	}
	frontend: {
		enabled:      *true | bool
		replicaCount: *1 | int
		image: {registry: *"docker.io" | string, repository: *"daveearley/hi.events-frontend" | string, tag: *"v1.9.0-beta" | string, digest: *"" | string, pullPolicy: *"IfNotPresent" | string}
		command: *[] | [...string]
		args:    *[] | [...string]
		env: viteApiUrlServer: *"" | string
		service: {type: *"ClusterIP" | string, port: *80 | int, targetPort: *5678 | int}
		probes: {
			type: *"tcpSocket" | string
			startup:   {periodSeconds: *10 | int, timeoutSeconds: *5 | int, failureThreshold: *30 | int}
			liveness:  {initialDelaySeconds: *30 | int, periodSeconds: *10 | int, timeoutSeconds: *5 | int, failureThreshold: *3 | int}
			readiness: {initialDelaySeconds: *15 | int, periodSeconds: *10 | int, timeoutSeconds: *5 | int, failureThreshold: *10 | int}
		}
		resources:                 *{} | {[string]: _}
		podSecurityContext:        *{} | {[string]: _}
		securityContext:           *{} | {[string]: _}
		nodeSelector:              *{} | {[string]: string}
		tolerations:               *[] | [..._]
		affinity:                  *{} | {[string]: _}
		topologySpreadConstraints: *[] | [..._]
		autoscaling: {
			enabled:                        *false | bool
			minReplicas:                    *1 | int
			maxReplicas:                    *10 | int
			targetCPUUtilizationPercentage: *80 | int
		}
		pdb: {
			enabled:      *false | bool
			minAvailable: *1 | int
		}
	}
	webProxy: {
		enabled:      *true | bool
		replicaCount: *1 | int
		image: {registry: *"docker.io" | string, repository: *"nginx" | string, tag: *"1.27-alpine" | string, digest: *"" | string, pullPolicy: *"IfNotPresent" | string}
		service: {type: *"ClusterIP" | string, port: *80 | int, targetPort: *8080 | int}
		probes: {
			startup:   {periodSeconds: *5 | int, timeoutSeconds: *3 | int, failureThreshold: *12 | int}
			liveness:  {initialDelaySeconds: *15 | int, periodSeconds: *10 | int, timeoutSeconds: *3 | int, failureThreshold: *3 | int}
			readiness: {initialDelaySeconds: *5 | int, periodSeconds: *10 | int, timeoutSeconds: *3 | int, failureThreshold: *3 | int}
		}
		resources:                 *{} | {[string]: _}
		podSecurityContext:        *{} | {[string]: _}
		securityContext:           *{} | {[string]: _}
		nodeSelector:              *{} | {[string]: string}
		tolerations:               *[] | [..._]
		affinity:                  *{} | {[string]: _}
		topologySpreadConstraints: *[] | [..._]
	}
	worker: {
		enabled:                       *true | bool
		replicaCount:                  *1 | int
		command:                       *["php", "artisan", "queue:work"] | [...string]
		args:                          *["--queue=default,webhook-queue", "--sleep=3", "--tries=3", "--timeout=60"] | [...string]
		terminationGracePeriodSeconds: *60 | int
		resources:                     *{} | {[string]: _}
		podSecurityContext:            *{} | {[string]: _}
		securityContext:               *{} | {[string]: _}
		nodeSelector:                  *{} | {[string]: string}
		tolerations:                   *[] | [..._]
		affinity:                      *{} | {[string]: _}
		topologySpreadConstraints:      *[] | [..._]
		autoscaling: {
			enabled:                        *false | bool
			minReplicas:                    *1 | int
			maxReplicas:                    *10 | int
			targetCPUUtilizationPercentage: *80 | int
		}
	}
	scheduler: {
		enabled:                    *true | bool
		schedule:                   *"* * * * *" | string
		concurrencyPolicy:          *"Forbid" | string
		successfulJobsHistoryLimit: *3 | int
		failedJobsHistoryLimit:     *3 | int
		command:                    *["php", "artisan", "schedule:run"] | [...string]
		args:                       *["--no-interaction"] | [...string]
		resources:                  *{} | {[string]: _}
		podSecurityContext:         *{} | {[string]: _}
		securityContext:            *{} | {[string]: _}
	}
	migration: {
		enabled:          *true | bool
		useHelmHooks:     *false | bool
		hookDeletePolicy: *"before-hook-creation,hook-succeeded" | string
		command:          *["sh", "-c"] | [...string]
		args:             *[
			"php artisan migrate --force\nphp artisan cache:clear\nphp artisan config:clear\nphp artisan route:clear\nphp artisan view:clear\nphp artisan storage:link\n",
		] | [...string]
		resources:          *{} | {[string]: _}
		podSecurityContext: *{} | {[string]: _}
		securityContext:    *{} | {[string]: _}
	}
	initContainers: {
		postgresql: {enabled: *true | bool, image: *"postgres:16-alpine" | string, imagePullPolicy: *"IfNotPresent" | string}
		redis:      {enabled: *true | bool, image: *"redis:7-alpine" | string, imagePullPolicy: *"IfNotPresent" | string}
	}
	postgresql: {
		enabled: *true | bool
		image: {repository: *"postgres" | string, tag: *"16-alpine" | string, pullPolicy: *"IfNotPresent" | string}
		persistence: {enabled: *true | bool, size: *"10Gi" | string, storageClass: *"" | string}
		service: port: *5432 | int
		resources: *{} | {[string]: _}
	}
	externalDatabase: host: *"" | string
	redis: {
		enabled: *true | bool
		image: {repository: *"redis" | string, tag: *"7-alpine" | string, pullPolicy: *"IfNotPresent" | string}
		persistence: {enabled: *true | bool, size: *"2Gi" | string, storageClass: *"" | string}
		service: port: *6379 | int
		resources: *{} | {[string]: _}
	}
	externalRedis: host: *"" | string
	httpRoute: {
		enabled:     *false | bool
		annotations: *{} | {[string]: string}
		parentRefs:  *[] | [..._]
		hostnames:   *[] | [...string]
		rules: apiPrefix: *"/api" | string
	}
	networkPolicy: enabled: *false | bool
	test: enabled:          *false | bool

	// --- Hidden computed variables ---
	_fullname:   metadata.name
	_appName:    "hievents"
	_appVersion: "1.9.0-beta"
	_chartLabel: "hievents-0.1.0"
	_serviceAccountRefName: string
	if serviceAccount.create && serviceAccount.name != "" {_serviceAccountRefName: serviceAccount.name}
	if serviceAccount.create && serviceAccount.name == "" {_serviceAccountRefName: _fullname}
	if !serviceAccount.create && serviceAccount.name != "" {_serviceAccountRefName: serviceAccount.name}
	if !serviceAccount.create && serviceAccount.name == "" {_serviceAccountRefName: "default"}
	_saName: _serviceAccountRefName
	_configMapName: _fullname + "-config"
	_appSecretRefName: string
	_postgresSecretRefName: string
	_redisSecretRefName: string
	_mailSecretRefName: string
	_s3SecretRefName: string
	if secrets.app.useExisting {_appSecretRefName: secrets.app.secretName}
	if !secrets.app.useExisting {_appSecretRefName: _fullname + "-" + secrets.app.secretName}
	if secrets.postgresql.useExisting {_postgresSecretRefName: secrets.postgresql.secretName}
	if !secrets.postgresql.useExisting {_postgresSecretRefName: _fullname + "-" + secrets.postgresql.secretName}
	if secrets.redis.useExisting {_redisSecretRefName: secrets.redis.secretName}
	if !secrets.redis.useExisting {_redisSecretRefName: _fullname + "-" + secrets.redis.secretName}
	if secrets.mail.useExisting {_mailSecretRefName: secrets.mail.secretName}
	if !secrets.mail.useExisting {_mailSecretRefName: _fullname + "-" + secrets.mail.secretName}
	if secrets.s3.useExisting {_s3SecretRefName: secrets.s3.secretName}
	if !secrets.s3.useExisting {_s3SecretRefName: _fullname + "-" + secrets.s3.secretName}
	_appSecretName: _appSecretRefName
	_postgresSecretName: _postgresSecretRefName
	_redisSecretName: _redisSecretRefName
	_mailSecretName: _mailSecretRefName
	_s3SecretName: _s3SecretRefName
	_backendName: _fullname + "-backend"
	_frontendName: _fullname + "-frontend"
	_workerName: _fullname + "-worker"
	_schedulerName: _fullname + "-scheduler"
	_migrationRefName: string
	if migration.useHelmHooks {_migrationRefName: _fullname + "-migration"}
	if !migration.useHelmHooks {_migrationRefName: _fullname + "-migration-1"}
	_migrationName: _migrationRefName
	_nginxConfigName: _fullname + "-configmap-nginx"
	_nginxDeploymentName: _fullname + "-deployment-nginx"
	_nginxServiceName: _fullname + "-service-nginx"
	_postgresName: _fullname + "-postgresql"
	_redisName: _fullname + "-redis"
	_storageClaimRefName: string
	_databaseHost: string
	_redisServiceHost: string
	_storageDiskName: string
	_publicDiskName: string
	_privateDiskName: string
	_filesystemDriverName: string
	_viteApiClientURL: string
	_viteFrontendURL: string
	_viteApiServerURL: string
	if backend.persistence.existingClaim != "" {_storageClaimRefName: backend.persistence.existingClaim}
	if backend.persistence.existingClaim == "" {_storageClaimRefName: _fullname + "-backend-storage"}
	if postgresql.enabled {_databaseHost: _postgresName}
	if !postgresql.enabled {_databaseHost: externalDatabase.host}
	if redis.enabled {_redisServiceHost: _redisName}
	if !redis.enabled {_redisServiceHost: externalRedis.host}
	if hieventsConfig.storage.disk != "" {_storageDiskName: hieventsConfig.storage.disk}
	if hieventsConfig.storage.disk == "" && hieventsConfig.storage.driver == "local" {_storageDiskName: "public"}
	if hieventsConfig.storage.disk == "" && hieventsConfig.storage.driver != "local" {_storageDiskName: "s3"}
	if hieventsConfig.storage.publicDisk != "" {_publicDiskName: hieventsConfig.storage.publicDisk}
	if hieventsConfig.storage.publicDisk == "" && hieventsConfig.storage.driver == "local" {_publicDiskName: "public"}
	if hieventsConfig.storage.publicDisk == "" && hieventsConfig.storage.driver != "local" {_publicDiskName: "s3-public"}
	if hieventsConfig.storage.privateDisk != "" {_privateDiskName: hieventsConfig.storage.privateDisk}
	if hieventsConfig.storage.privateDisk == "" && hieventsConfig.storage.driver == "local" {_privateDiskName: "local"}
	if hieventsConfig.storage.privateDisk == "" && hieventsConfig.storage.driver != "local" {_privateDiskName: "s3-private"}
	if hieventsConfig.storage.filesystemDriver != "" {_filesystemDriverName: hieventsConfig.storage.filesystemDriver}
	if hieventsConfig.storage.filesystemDriver == "" {_filesystemDriverName: _storageDiskName}
	if hieventsConfig.app.viteApiUrlClient != "" {_viteApiClientURL: hieventsConfig.app.viteApiUrlClient}
	if hieventsConfig.app.viteApiUrlClient == "" {_viteApiClientURL: hieventsConfig.app.url + "/api"}
	if hieventsConfig.app.viteFrontendUrl != "" {_viteFrontendURL: hieventsConfig.app.viteFrontendUrl}
	if hieventsConfig.app.viteFrontendUrl == "" {_viteFrontendURL: hieventsConfig.app.frontendUrl}
	if hieventsConfig.app.viteApiUrlServer != "" {_viteApiServerURL: hieventsConfig.app.viteApiUrlServer}
	if hieventsConfig.app.viteApiUrlServer == "" && frontend.env.viteApiUrlServer != "" {_viteApiServerURL: frontend.env.viteApiUrlServer + "/api"}
	if hieventsConfig.app.viteApiUrlServer == "" && frontend.env.viteApiUrlServer == "" && webProxy.enabled {_viteApiServerURL: "http://" + _nginxServiceName + "/api"}
	if hieventsConfig.app.viteApiUrlServer == "" && frontend.env.viteApiUrlServer == "" && !webProxy.enabled {_viteApiServerURL: "http://" + _backendName + "/api"}
	_storageClaimName: _storageClaimRefName
	_dbHost: _databaseHost
	_redisHost: _redisServiceHost
	_storageDisk: _storageDiskName
	_publicDisk: _publicDiskName
	_privateDisk: _privateDiskName
	_filesystemDriver: _filesystemDriverName
	_viteApiClient: _viteApiClientURL
	_viteFrontend: _viteFrontendURL
	_viteApiServer: _viteApiServerURL

	_baseLabels: {
		"helm.sh/chart":                _chartLabel
		"app.kubernetes.io/name":       _appName
		"app.kubernetes.io/instance":   metadata.name
		"app.kubernetes.io/version":    _appVersion
		"app.kubernetes.io/managed-by": "timoni"
		[string]:                       string
		for k, v in labels {(k): v}
	}
	_podAnnotations: {
		for k, v in commonAnnotations {(k): v}
		for k, v in podAnnotations {(k): v}
	}
	_appKeySecretKey: secrets.app.appKeySecretKey
	_sessionSecureCookieValue: string
	if hieventsConfig.app.env == "local" {_sessionSecureCookieValue: "false"}
	if hieventsConfig.app.env != "local" {_sessionSecureCookieValue: "true"}
	_nginxLocalCookieFlags: string
	if hieventsConfig.app.env == "local" {_nginxLocalCookieFlags: "proxy_cookie_flags ~.* nosecure samesite=lax;"}
	if hieventsConfig.app.env != "local" {_nginxLocalCookieFlags: ""}

	// Init containers
	_postgresInitContainer: {
		name: "wait-for-postgresql"
		image: initContainers.postgresql.image
		imagePullPolicy: initContainers.postgresql.imagePullPolicy
		env: [{
			name: "PGPASSWORD"
			valueFrom: secretKeyRef: {name: _postgresSecretName, key: secrets.postgresql.passwordKey}
		}]
		command: ["sh", "-c", strings.Join([
			"until pg_isready -h ", _dbHost, " -p ", strconv.FormatInt(hieventsConfig.postgresql.port, 10), " -U ", hieventsConfig.postgresql.username, " -d ", hieventsConfig.postgresql.database, "; do\n",
			"  echo \"waiting for postgresql\"\n",
			"  sleep 2\n",
			"done\n",
		], "")]
	}
	_redisInitContainer: {
		name: "wait-for-redis"
		image: initContainers.redis.image
		imagePullPolicy: initContainers.redis.imagePullPolicy
		env: [{
			name: "REDISCLI_AUTH"
			valueFrom: secretKeyRef: {name: _redisSecretName, key: secrets.redis.passwordKey}
		}]
		command: ["sh", "-c", strings.Join([
			"until redis-cli -h ", _redisHost, " -p ", strconv.FormatInt(hieventsConfig.redis.port, 10), " ping; do\n",
			"  echo \"waiting for redis\"\n",
			"  sleep 2\n",
			"done\n",
		], "")]
	}

	// Environments
	_laravelEnv: [
		{name: "APP_NAME", value: hieventsConfig.app.name},
		{name: "APP_ENV", value: hieventsConfig.app.env},
		{name: "APP_DEBUG", value: hieventsConfig.app.debug},
		{name: "APP_URL", value: hieventsConfig.app.url},
		{name: "APP_PORT", value: strconv.FormatInt(hieventsConfig.app.port, 10)},
		{name: "APP_FRONTEND_URL", value: hieventsConfig.app.frontendUrl},
		{name: "APP_TIMEZONE", value: hieventsConfig.app.timezone},
		{name: "APP_LOCALE", value: hieventsConfig.app.locale},
		{name: "VITE_API_URL", value: _viteApiClient},
		{name: "VITE_API_URL_CLIENT", value: _viteApiClient},
		{name: "VITE_FRONTEND_URL", value: _viteFrontend},
		{name: "SANCTUM_STATEFUL_DOMAINS", value: hieventsConfig.app.sanctumStatefulDomains},
		if hieventsConfig.app.sessionDomain != "" {
			{name: "SESSION_DOMAIN", value: hieventsConfig.app.sessionDomain}
		},
		{name: "CORS_ALLOWED_ORIGINS", value: hieventsConfig.app.url + "," + hieventsConfig.app.frontendUrl},
		{name: "TRUSTED_PROXIES", value: hieventsConfig.app.trustedProxies},
		{name: "SESSION_SECURE_COOKIE", value: _sessionSecureCookieValue},
		if hieventsConfig.app.cdnUrl != "" {
			{name: "APP_CDN_URL", value: hieventsConfig.app.cdnUrl}
		},
		{name: "APP_LOG_QUERIES", value: hieventsConfig.app.logQueries},
		{name: "APP_HOMEPAGE_VIEWS_UPDATE_BATCH_SIZE", value: strconv.FormatInt(hieventsConfig.app.homepageViewsUpdateBatchSize, 10)},
		{name: "APP_ALLOWED_INTERNAL_WEBHOOK_HOSTS", value: hieventsConfig.app.allowedInternalWebhookHosts},
		if hieventsConfig.app.emailLogoUrl != "" {
			{name: "APP_EMAIL_LOGO_URL", value: hieventsConfig.app.emailLogoUrl}
		},
		if hieventsConfig.app.emailLogoLinkUrl != "" {
			{name: "APP_EMAIL_LOGO_LINK_URL", value: hieventsConfig.app.emailLogoLinkUrl}
		},
		{name: "APP_DISABLE_REGISTRATION", value: hieventsConfig.app.disableRegistration},
		{name: "APP_PLATFORM_SUPPORT_EMAIL", value: hieventsConfig.app.platformSupportEmail},
		{name: "APP_SAAS_MODE_ENABLED", value: hieventsConfig.app.saasModeEnabled},
		{name: "APP_SAAS_STRIPE_APPLICATION_FEE_PERCENT", value: hieventsConfig.app.saasStripeApplicationFeePercent},
		{name: "APP_SAAS_STRIPE_APPLICATION_FEE_FIXED", value: hieventsConfig.app.saasStripeApplicationFeeFixed},
		{name: "APP_STRIPE_CONNECT_ACCOUNT_TYPE", value: hieventsConfig.app.stripeConnectAccountType},
		{name: "LOG_CHANNEL", value: hieventsConfig.logging.channel},
		{name: "LOG_LEVEL", value: hieventsConfig.logging.level},
		if hieventsConfig.logging.deprecationsChannel != "" {
			{name: "LOG_DEPRECATIONS_CHANNEL", value: hieventsConfig.logging.deprecationsChannel}
		},
		{name: "QUEUE_CONNECTION", value: hieventsConfig.queue.connection},
		{name: "WEBHOOK_QUEUE_NAME", value: hieventsConfig.queue.webhookQueueName},
		{name: "CACHE_DRIVER", value: hieventsConfig.cache.driver},
		{name: "SESSION_DRIVER", value: hieventsConfig.session.driver},
		{name: "SESSION_LIFETIME", value: strconv.FormatInt(hieventsConfig.session.lifetime, 10)},
		{name: "BROADCAST_DRIVER", value: hieventsConfig.broadcast.driver},
		{name: "FILESYSTEM_DISK", value: _storageDisk},
		{name: "FILESYSTEM_DRIVER", value: _filesystemDriver},
		{name: "FILESYSTEM_PUBLIC_DISK", value: _publicDisk},
		{name: "FILESYSTEM_PRIVATE_DISK", value: _privateDisk},
		{
			name: "APP_KEY"
			valueFrom: secretKeyRef: {name: _appSecretName, key: _appKeySecretKey}
		},
		{
			name: "JWT_SECRET"
			valueFrom: secretKeyRef: {name: _appSecretName, key: secrets.app.jwtSecretKey}
		},
		{name: "JWT_ALGO", value: hieventsConfig.jwt.algo},
		if secrets.app.stripePublishableKey != "" {
			{
				name: "STRIPE_PUBLIC_KEY"
				valueFrom: secretKeyRef: {name: _appSecretName, key: secrets.app.stripePublishableKeyKey}
			}
		},
		if secrets.app.stripePublishableKey != "" {
			{
				name: "STRIPE_KEY"
				valueFrom: secretKeyRef: {name: _appSecretName, key: secrets.app.stripePublishableKeyKey}
			}
		},
		if secrets.app.stripeSecretKey != "" {
			{
				name: "STRIPE_SECRET_KEY"
				valueFrom: secretKeyRef: {name: _appSecretName, key: secrets.app.stripeSecretKeyKey}
			}
		},
		if secrets.app.stripeSecretKey != "" {
			{
				name: "STRIPE_SECRET"
				valueFrom: secretKeyRef: {name: _appSecretName, key: secrets.app.stripeSecretKeyKey}
			}
		},
		if secrets.app.stripeWebhookSecret != "" {
			{
				name: "STRIPE_WEBHOOK_SECRET"
				valueFrom: secretKeyRef: {name: _appSecretName, key: secrets.app.stripeWebhookSecretKey}
			}
		},
		{name: "MAIL_MAILER", value: hieventsConfig.mail.mailer},
		{name: "MAIL_DRIVER", value: hieventsConfig.mail.driver},
		{name: "MAIL_HOST", value: hieventsConfig.mail.host},
		{name: "MAIL_PORT", value: strconv.FormatInt(hieventsConfig.mail.port, 10)},
		{name: "MAIL_USERNAME", value: hieventsConfig.mail.username},
		{name: "MAIL_ENCRYPTION", value: hieventsConfig.mail.encryption},
		{name: "MAIL_FROM_ADDRESS", value: hieventsConfig.mail.fromAddress},
		{name: "MAIL_FROM_NAME", value: hieventsConfig.mail.fromName},
		if secrets.mail.password != "" || secrets.mail.useExisting {
			{
				name: "MAIL_PASSWORD"
				valueFrom: secretKeyRef: {name: _mailSecretName, key: secrets.mail.passwordKey}
			}
		},
	]

	_dbEnv: [
		{name: "DB_CONNECTION", value: "pgsql"},
		{name: "DB_HOST", value: _dbHost},
		{name: "DB_PORT", value: strconv.FormatInt(hieventsConfig.postgresql.port, 10)},
		{name: "DB_DATABASE", value: hieventsConfig.postgresql.database},
		{name: "DB_USERNAME", value: hieventsConfig.postgresql.username},
		{
			name: "DB_PASSWORD"
			valueFrom: secretKeyRef: {name: _postgresSecretName, key: secrets.postgresql.passwordKey}
		},
		{name: "DATABASE_URL", value: hieventsConfig.postgresql.databaseUrl},
	]

	_redisEnv: [
		{name: "REDIS_HOST", value: _redisHost},
		{
			name: "REDIS_PASSWORD"
			valueFrom: secretKeyRef: {name: _redisSecretName, key: secrets.redis.passwordKey}
		},
		{name: "REDIS_PORT", value: strconv.FormatInt(hieventsConfig.redis.port, 10)},
		{name: "REDIS_CLIENT", value: hieventsConfig.redis.client},
		{name: "REDIS_DB", value: strconv.FormatInt(hieventsConfig.redis.database, 10)},
		{name: "REDIS_CACHE_DB", value: strconv.FormatInt(hieventsConfig.redis.cacheDatabase, 10)},
		if hieventsConfig.redis.username != "" {
			{name: "REDIS_USERNAME", value: hieventsConfig.redis.username}
		},
		if hieventsConfig.redis.username != "" {
			{name: "REDIS_USER", value: hieventsConfig.redis.username}
		},
		if hieventsConfig.redis.url != "" {
			{name: "REDIS_URL", value: hieventsConfig.redis.url}
		},
	]

	_s3Env: [
		if hieventsConfig.storage.driver == "s3" {
			{name: "AWS_DEFAULT_REGION", value: hieventsConfig.s3.region}
		},
		if hieventsConfig.storage.driver == "s3" {
			{name: "AWS_PUBLIC_BUCKET", value: hieventsConfig.s3.publicBucket}
		},
		if hieventsConfig.storage.driver == "s3" {
			{name: "AWS_PRIVATE_BUCKET", value: hieventsConfig.s3.privateBucket}
		},
		if hieventsConfig.storage.driver == "s3" && hieventsConfig.s3.endpoint != "" {
			{name: "AWS_ENDPOINT", value: hieventsConfig.s3.endpoint}
		},
		if hieventsConfig.storage.driver == "s3" && hieventsConfig.s3.url != "" {
			{name: "AWS_URL", value: hieventsConfig.s3.url}
		},
		if hieventsConfig.storage.driver == "s3" {
			{name: "AWS_USE_PATH_STYLE_ENDPOINT", value: hieventsConfig.s3.usePathStyleEndpoint}
		},
		if hieventsConfig.storage.driver == "s3" {
			{
				name: "AWS_ACCESS_KEY_ID"
				valueFrom: secretKeyRef: {name: _s3SecretName, key: secrets.s3.accessKeyIdKey}
			}
		},
		if hieventsConfig.storage.driver == "s3" {
			{
				name: "AWS_SECRET_ACCESS_KEY"
				valueFrom: secretKeyRef: {name: _s3SecretName, key: secrets.s3.secretAccessKeyKey}
			}
		},
	]

	_frontendEnv: [
		{name: "VITE_API_URL", value: _viteApiClient},
		{name: "VITE_API_URL_CLIENT", value: _viteApiClient},
		{name: "VITE_API_URL_SERVER", value: _viteApiServer},
		{name: "VITE_FRONTEND_URL", value: _viteFrontend},
		{name: "VITE_APP_NAME", value: hieventsConfig.app.name},
		{name: "NODE_PORT", value: strconv.FormatInt(frontend.service.targetPort, 10)},
		{
			name: "VITE_STRIPE_PUBLISHABLE_KEY"
			valueFrom: secretKeyRef: {name: _appSecretName, key: secrets.app.stripePublishableKeyKey}
		},
	]

	_appEnv: list.Concat([_laravelEnv, _dbEnv, _redisEnv, _s3Env])

	_backendImageRef: string
	if backend.image.digest == "" {
		_backendImageRef: backend.image.registry + "/" + backend.image.repository + ":" + backend.image.tag
	}
	if backend.image.digest != "" {
		_backendImageRef: backend.image.registry + "/" + backend.image.repository + "@" + backend.image.digest
	}

	_frontendImageRef: string
	if frontend.image.digest == "" {
		_frontendImageRef: frontend.image.registry + "/" + frontend.image.repository + ":" + frontend.image.tag
	}
	if frontend.image.digest != "" {
		_frontendImageRef: frontend.image.registry + "/" + frontend.image.repository + "@" + frontend.image.digest
	}

	_webProxyImageRef: string
	if webProxy.image.digest == "" {
		_webProxyImageRef: webProxy.image.registry + "/" + webProxy.image.repository + ":" + webProxy.image.tag
	}
	if webProxy.image.digest != "" {
		_webProxyImageRef: webProxy.image.registry + "/" + webProxy.image.repository + "@" + webProxy.image.digest
	}
}

#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		if config.backend.enabled && config.backend.persistence.enabled && config.hieventsConfig.storage.driver == "local" && config.backend.persistence.existingClaim == "" {
			backendPVC: #BackendPVC & {#config: config}
		}
		if !config.secrets.app.useExisting {
			appSecret: #AppSecret & {#config: config}
		}
		if !config.secrets.postgresql.useExisting && config.postgresql.enabled {
			postgresSecret: #PostgresqlSecret & {#config: config}
		}
		if !config.secrets.redis.useExisting && config.redis.enabled {
			redisSecret: #RedisSecret & {#config: config}
		}
		if !config.secrets.mail.useExisting && (config.secrets.mail.password != "" || config.secrets.mail.useExisting) {
			mailSecret: #MailSecret & {#config: config}
		}
		if !config.secrets.s3.useExisting && config.hieventsConfig.storage.driver == "s3" {
			s3Secret: #S3Secret & {#config: config}
		}
		if config.backend.enabled {
			configMap: #ConfigMap & {#config: config}
		}
		if config.webProxy.enabled && config.backend.enabled && config.frontend.enabled {
			configMapNginx: #ConfigMapNginx & {#config: config}
		}
		if config.backend.enabled {
			backendDeployment: #BackendDeployment & {#config: config}
			backendService: #BackendService & {#config: config}
		}
		if config.frontend.enabled {
			frontendDeployment: #FrontendDeployment & {#config: config}
			frontendService: #FrontendService & {#config: config}
		}
		if config.webProxy.enabled && config.backend.enabled && config.frontend.enabled {
			deploymentNginx: #DeploymentNginx & {#config: config}
			serviceNginx: #ServiceNginx & {#config: config}
		}
		if config.worker.enabled {
			workerDeployment: #WorkerDeployment & {#config: config}
		}
		if config.scheduler.enabled {
			schedulerCronJob: #SchedulerCronJob & {#config: config}
		}
		if config.migration.enabled && config.backend.enabled {
			migrationJob: #MigrationJob & {#config: config}
		}
		if config.backend.enabled && config.backend.autoscaling.enabled {
			backendHPA: #BackendHPA & {#config: config}
		}
		if config.frontend.enabled && config.frontend.autoscaling.enabled {
			frontendHPA: #FrontendHPA & {#config: config}
		}
		if config.backend.enabled && config.backend.pdb.enabled {
			backendPDB: #BackendPDB & {#config: config}
		}
		if config.frontend.enabled && config.frontend.pdb.enabled {
			frontendPDB: #FrontendPDB & {#config: config}
		}
		if config.httpRoute.enabled {
			httpRoute: #HTTPRoute & {#config: config}
		}
		if config.networkPolicy.enabled {
			networkPolicy: #NetworkPolicy & {#config: config}
		}
		if config.postgresql.enabled {
			postgresqlStatefulSet: #PostgresqlStatefulSet & {#config: config}
			postgresqlService: #PostgresqlService & {#config: config}
			postgresqlHeadlessService: #PostgresqlHeadlessService & {#config: config}
		}
		if config.redis.enabled {
			redisStatefulSet: #RedisStatefulSet & {#config: config}
			redisService: #RedisService & {#config: config}
			redisHeadlessService: #RedisHeadlessService & {#config: config}
		}
	}
}
