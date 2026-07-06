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

	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	global: {
		security: {
			allowInsecureImages: *true | bool
		}
	}

	#appName: "shlink-backend"
	#serviceName: metadata.name


	image: {
		registry:   *"docker.io" | string
		repository: *"shlinkio/shlink" | string
		pullPolicy: *"Always" | string
		tag:        *"5.1.5" | string
		reference:  "\(registry)/\(repository):\(tag)"
	}
	imagePullSecrets: [...timoniv1.#ObjectReference] | *[]

	replicaCount:          *1 | int & >=0
	revisionHistoryLimit: *10 | int & >=0

	serviceAccount: {
		create:      *true | bool
		annotations: *{} | #StringMap
		name:        *"" | string
	}
	#serviceAccountName: metadata.name
	if serviceAccount.name != "" {
		#serviceAccountName: serviceAccount.name
	}
	if !serviceAccount.create && serviceAccount.name == "" {
		#serviceAccountName: "default"
	}

	podAnnotations:     *{} | #StringMap
	podLabels:          *{} | #StringMap
	podSecurityContext: *{} | corev1.#PodSecurityContext
	securityContext:    *{} | corev1.#SecurityContext
	resources:          *{} | corev1.#ResourceRequirements

	service: {
		type: *"ClusterIP" | string
		port: *8080 | int & >0 & <=65535
	}

	ingress: {
		enabled:     *false | bool
		className:   *"" | string
		annotations: *{} | #StringMap
		hosts: *[{
			host: "chart-example.local"
			paths: [{
				path:     "/"
				pathType: "ImplementationSpecific"
			}]
		}] | [...{
			host: string
			paths: [...{
				path:     string
				pathType: *"ImplementationSpecific" | string
			}]
		}]
		tls: *[] | [...{
			secretName: string
			hosts: [...string]
		}]
	}

	route: [string]: {
		enabled:         *false | bool
		apiVersion:      *"gateway.networking.k8s.io/v1" | string
		kind:            *"HTTPRoute" | string
		annotations:     *{} | #StringMap
		labels:          *{} | #StringMap
		hostnames:       *[] | [...string]
		parentRefs:      *[] | [...#AnyMap]
		matches:         *[{path: {type: "PathPrefix", value: "/"}}] | [...#AnyMap]
		filters:         *[] | [...#AnyMap]
		additionalRules: *[] | [...#AnyMap]
		httpsRedirect:   *false | bool
		timeouts:        *{} | #AnyMap
	}
	route: main: {}

	autoscaling: {
		enabled: *false | bool
		minReplicas: *1 | int & >0
		maxReplicas: *100 | int & >0
		targetCPUUtilizationPercentage?: int & >0 & <=100
		targetMemoryUtilizationPercentage?: int & >0 & <=100
	}
	autoscaling: targetCPUUtilizationPercentage: *80 | int

	deploymentStrategy: *{} | #AnyMap
	nodeSelector:       *{} | #StringMap
	tolerations:        *[] | [...corev1.#Toleration]
	affinity:           *{} | corev1.#Affinity

	extraEnv: *[] | [...corev1.#EnvVar]

	config: {
		database: {
			auth: {
				database:       *"" | string
				existingSecret: *"" | string
				password:       *"" | string
				username:       *"" | string
			}
			driver:        *"sqlite" | "sqlite" | "mysql" | "maria" | "postgres" | string
			host:          *"" | string
			port:          *0 | int & >=0 & <=65535
			useEncryption: *false | bool
		}
		general: {
			basePath:        *"" | string
			cacheNamespace:  *"" | string
			defaultDomain:   *"" | string
			initialApiKey:   *"" | string
			isHttpsEnabled:  *false | bool
			memoryLimit:     *"" | string
			timezone:        *"" | string
		}
		geolite: {
			licenseKey:          *"" | string
			skipInitialDownload: *false | bool
		}
		matomo: {
			enabled: *false | bool
			auth: {
				apiToken:       *"" | string
				existingSecret: *"" | string
			}
			baseUrl: *"" | string
			siteId:  *"" | string
		}
		mercure: {
			enabled: *false | bool
			auth: {
				jwtSecret:      *"" | string
				existingSecret: *"" | string
			}
			publicHubUrl:   *"" | string
			internalHubUrl: *"" | string
		}
		qrCodes: {
			codeForDisabledShortUrls: *true | bool
			defaultColors: {
				background: *"#FFFFFF" | string
				foreground: *"#000000" | string
			}
			defaultErrorCorrection: *"l" | string
			defaultFormat:          *"png" | string
			defaultLogoUrl:         *"" | string
			defaultMargin:          *0 | int & >=0
			defaultRoundBlockSize:  *true | bool
			defaultSize:            *300 | int & >=0
		}
		rabbitmq: {
			enabled: *false | bool
			auth: {
				existingSecret: *"" | string
				password:       *"" | string
				username:       *"" | string
			}
			host:   *"" | string
			port:   *0 | int & >=0 & <=65535
			useSsl: *false | bool
			vhost:  *"/" | string
		}
		redirects: {
			cacheLifetime:                  *30 | int & >=0
			defaultBaseUrlRedirect:         *"" | string
			defaultInvalidShortUrlRedirect: *"" | string
			defaultRegular404Redirect:      *"" | string
			extraPathMode:                  *"default" | string
			statusCode:                     *302 | int
		}
		redis: {
			enabled:       *false | bool
			pubSubEnabled: *false | bool
			sentinal: {
				enabled: *false | bool
				service: *"" | string
			}
			servers: *"" | string
		}
		robots: {
			allowAllShortUrls: *false | bool
			userAgents:        *"*" | string
		}
		trackingVisits: {
			anonymizeRemoteAddr:      *true | bool
			disable:                  *false | bool
			disableIpTracking:        *false | bool
			disableReferrerTracking:  *false | bool
			disableTrackingParam:     *"" | string
			disableTrackingFrom:      *"" | string
			disableUaTracking:        *false | bool
			trackOrphanVisits:        *true | bool
		}
		urlShortening: {
			autoResolveTitles:        *true | bool
			defaultShortCodesLength:  *5 | int & >=0
			deleteShortUrlThreshold:  *"" | string
			multiSegmentSlugsEnabled: *false | bool
			shortUrlMode:             *"strict" | string
			shortUrlTrailingSlash:    *false | bool
		}
	}

	mariadb: {
		enabled: *false | bool
		auth: {
			database: *"shlink" | string
			password: *"shlink" | string
			username: *"shlink" | string
		}
		image: {
			repository: *"bitnamilegacy/mariadb" | string
			tag:        *"12.0.2-debian-12-r0" | string
		}
		persistence: #Persistence & {
			enabled: *true | bool
		}
	}
	mysql: {
		enabled: *false | bool
		auth: {
			database: *"shlink" | string
			password: *"shlink" | string
			username: *"shlink" | string
		}
		image: {
			repository: *"bitnamilegacy/mysql" | string
			tag:        *"9.4.0-debian-12-r1" | string
		}
		persistence: #Persistence & {
			enabled: *true | bool
		}
	}
	postgresql: {
		enabled: *false | bool
		auth: {
			database: *"shlink" | string
			password: *"shlink" | string
			username: *"shlink" | string
		}
		image: {
			repository: *"bitnamilegacy/postgresql" | string
			tag:        *"17.6.0-debian-12-r4" | string
		}
		persistence: #Persistence & {
			enabled: *true | bool
		}
	}
	rabbitmq: {
		enabled: *false | bool
		image: {
			repository: *"bitnamilegacy/rabbitmq" | string
			tag:        *"4.1.3-debian-12-r1" | string
		}
		persistence: #Persistence & {
			enabled: *true | bool
		}
	}
	redis: {
		enabled:      *false | bool
		architecture: *"standalone" | string
		auth: {
			enabled:  *false | bool
			sentinel: *false | bool
		}
		sentinel: {
			enabled: *false | bool
		}
		image: {
			repository: *"bitnamilegacy/redis" | string
			tag:        *"8.2.1-debian-12-r0" | string
		}
		persistence: #Persistence & {
			enabled: *true | bool
		}
	}
	web: {
		enabled: *false | bool
		image: {
			registry:   *"docker.io" | string
			repository: *"shlinkio/shlink-web-client" | string
			pullPolicy: *"Always" | string
			tag:        *"4.8.0" | string
		}
		imagePullSecrets: [...timoniv1.#ObjectReference] | *[]
		serviceAccount: {
			create:      *true | bool
			annotations: *{} | #StringMap
			name:        *"" | string
		}
		#serviceAccountName: metadata.name + "-web"
		if serviceAccount.name != "" {
			#serviceAccountName: serviceAccount.name
		}
		if !serviceAccount.create && serviceAccount.name == "" {
			#serviceAccountName: "default"
		}
		replicaCount: *1 | int & >0
		revisionHistoryLimit: *10 | int & >0
		podAnnotations: *{} | #StringMap
		podLabels:      *{} | #StringMap
		podSecurityContext: *{} | #AnyMap
		securityContext:    *{} | #AnyMap
		service: {
			type: *"ClusterIP" | string
			port: *80 | int & >0 & <=65535
		}
		ingress: {
			enabled:     *false | bool
			className:   *"" | string
			annotations: *{} | #StringMap
			hosts: *[] | [...{
				host: string
				paths: [...{
					path:     string
					pathType: *"ImplementationSpecific" | string
				}]
			}]
			tls: *[] | [...{
				secretName: string
				hosts: [...string]
			}]
		}
		route: [string]: {
			enabled:         *false | bool
			apiVersion:      *"gateway.networking.k8s.io/v1" | string
			kind:            *"HTTPRoute" | string
			annotations:     *{} | #StringMap
			labels:          *{} | #StringMap
			hostnames:       *[] | [...string]
			parentRefs:      *[] | [...#AnyMap]
			matches:         *[{path: {type: "PathPrefix", value: "/"}}] | [...#AnyMap]
			filters:         *[] | [...#AnyMap]
			additionalRules: *[] | [...#AnyMap]
			httpsRedirect:   *false | bool
			timeouts:        *{} | #AnyMap
		}
		route: main: {}
		resources:          *{} | #AnyMap
		autoscaling: {
			enabled: *false | bool
			minReplicas: *1 | int & >0
			maxReplicas: *100 | int & >0
			targetCPUUtilizationPercentage?: int & >0 & <=100
			targetMemoryUtilizationPercentage?: int & >0 & <=100
		}
		autoscaling: targetCPUUtilizationPercentage: *80 | int
		deploymentStrategy: *{} | #AnyMap
		nodeSelector:       *{} | #StringMap
		tolerations:        *[] | [...corev1.#Toleration]
		affinity:           *{} | corev1.#Affinity
		configuration: *[] | [...#AnyMap]
		extraEnv: *[] | [...corev1.#EnvVar]
	}

	#databaseDriver: string
	if !mariadb.enabled && !mysql.enabled && !postgresql.enabled {
		#databaseDriver: config.database.driver
	}
	if mariadb.enabled {
		#databaseDriver: "maria"
	}
	if mysql.enabled {
		#databaseDriver: "mysql"
	}
	if postgresql.enabled {
		#databaseDriver: "postgres"
	}

	#databasePort: int
	if !mariadb.enabled && !mysql.enabled && !postgresql.enabled {
		#databasePort: config.database.port
	}
	if config.database.port == 0 && #databaseDriver == "maria" {
		#databasePort: 3306
	}
	if config.database.port == 0 && #databaseDriver == "mysql" {
		#databasePort: 3306
	}
	if config.database.port == 0 && #databaseDriver == "postgres" {
		#databasePort: 5432
	}
	if config.database.port == 0 && #databaseDriver == "sqlite" {
		#databasePort: 0
	}

	#databaseHost: string
	if !mariadb.enabled && !mysql.enabled && !postgresql.enabled {
		#databaseHost: config.database.host
	}
	if mariadb.enabled {
		#databaseHost: "\(metadata.name)-mariadb"
	}
	if mysql.enabled {
		#databaseHost: "\(metadata.name)-mysql"
	}
	if postgresql.enabled {
		#databaseHost: "\(metadata.name)-postgresql"
	}

	#databaseName: string
	if !mariadb.enabled && !mysql.enabled && !postgresql.enabled {
		#databaseName: config.database.auth.database
	}
	if mariadb.enabled {
		#databaseName: mariadb.auth.database
	}
	if mysql.enabled {
		#databaseName: mysql.auth.database
	}
	if postgresql.enabled {
		#databaseName: postgresql.auth.database
	}

	#databaseUsername: string
	if !mariadb.enabled && !mysql.enabled && !postgresql.enabled {
		#databaseUsername: config.database.auth.username
	}
	if mariadb.enabled {
		#databaseUsername: mariadb.auth.username
	}
	if mysql.enabled {
		#databaseUsername: mysql.auth.username
	}
	if postgresql.enabled {
		#databaseUsername: postgresql.auth.username
	}

	#databaseSecretName: string
	if !mariadb.enabled && !mysql.enabled && !postgresql.enabled {
		#databaseSecretName: "\(metadata.name)-database"
	}
	if mariadb.enabled {
		#databaseSecretName: "\(metadata.name)-mariadb"
	}
	if mysql.enabled {
		#databaseSecretName: "\(metadata.name)-mysql"
	}
	if postgresql.enabled {
		#databaseSecretName: "\(metadata.name)-postgresql"
	}
	if config.database.auth.existingSecret != "" {
		#databaseSecretName: config.database.auth.existingSecret
	}

	#databasePasswordKey: string
	if !mariadb.enabled && !mysql.enabled && !postgresql.enabled {
		#databasePasswordKey: "database-password"
	}
	if mariadb.enabled {
		#databasePasswordKey: "mariadb-password"
	}
	if mysql.enabled {
		#databasePasswordKey: "mysql-password"
	}
	if postgresql.enabled {
		#databasePasswordKey: "password"
	}

	#matomoSecretName: string
	if config.matomo.auth.existingSecret == "" {
		#matomoSecretName: "\(metadata.name)-matomo"
	}
	if config.matomo.auth.existingSecret != "" {
		#matomoSecretName: config.matomo.auth.existingSecret
	}

	#mercureSecretName: string
	if config.mercure.auth.existingSecret == "" {
		#mercureSecretName: "\(metadata.name)-mercure"
	}
	if config.mercure.auth.existingSecret != "" {
		#mercureSecretName: config.mercure.auth.existingSecret
	}

	#rabbitmqEnabled: config.rabbitmq.enabled || rabbitmq.enabled

	#rabbitmqHost: string
	if !rabbitmq.enabled {
		#rabbitmqHost: config.rabbitmq.host
	}
	if rabbitmq.enabled {
		#rabbitmqHost: "\(metadata.name)-rabbitmq"
	}

	#rabbitmqPort: int
	if !rabbitmq.enabled {
		#rabbitmqPort: config.rabbitmq.port
	}
	if rabbitmq.enabled {
		if config.rabbitmq.port == 0 {
			#rabbitmqPort: 5672
		}
		if config.rabbitmq.port != 0 {
			#rabbitmqPort: config.rabbitmq.port
		}
	}

	#rabbitmqUsername: string
	if !rabbitmq.enabled {
		#rabbitmqUsername: config.rabbitmq.auth.username
	}
	if rabbitmq.enabled {
		if config.rabbitmq.auth.username == "" {
			#rabbitmqUsername: "user"
		}
		if config.rabbitmq.auth.username != "" {
			#rabbitmqUsername: config.rabbitmq.auth.username
		}
	}

	#rabbitmqSecretName: string
	if config.rabbitmq.auth.existingSecret == "" {
		#rabbitmqSecretName: "\(metadata.name)-rabbitmq"
	}
	if config.rabbitmq.auth.existingSecret != "" {
		#rabbitmqSecretName: config.rabbitmq.auth.existingSecret
	}

	#redisEnabled: config.redis.enabled || redis.enabled

	#redisServers: string
	if !redis.enabled {
		#redisServers: config.redis.servers
	}
	if redis.enabled {
		if config.redis.servers == "" {
			#redisServers: "\(metadata.name)-redis-master:6379"
		}
		if config.redis.servers != "" {
			#redisServers: config.redis.servers
		}
	}

	#redisSentinelService: string
	if !redis.enabled {
		#redisSentinelService: config.redis.sentinal.service
	}
	if redis.enabled {
		if config.redis.sentinal.service == "" {
			#redisSentinelService: "\(metadata.name)-redis:26379"
		}
		if config.redis.sentinal.service != "" {
			#redisSentinelService: config.redis.sentinal.service
		}
	}
	test: {
		enabled:  *false | bool
	}
}

#StringMap: {[string]: string}
#AnyMap: {[string]: _}

#Persistence: {
	enabled:          bool
	accessModes:      *["ReadWriteOnce"] | [...string]
	storageClassName: *"" | string
	resources:         corev1.#ResourceRequirements & {
		requests: {
			storage: *"8Gi" | string
		}
	}
}

#Instance: {
	config: #Config

	objects: [
		if config.serviceAccount.create {#ServiceAccount & {#config: config}},
		#Service & {#config: config},
		#Deployment & {#config: config},
		if config.autoscaling.enabled {#HorizontalPodAutoscaler & {#config: config}},
		if config.ingress.enabled {#Ingress & {#config: config}},
		if config.#databaseDriver != "sqlite" && config.config.database.auth.existingSecret == "" && !config.mariadb.enabled && !config.mysql.enabled && !config.postgresql.enabled {
			#DatabaseSecret & {#config: config}
		},
		if config.config.matomo.enabled && config.config.matomo.auth.existingSecret == "" {
			#MatomoSecret & {#config: config}
		},
		if config.config.mercure.enabled && config.config.mercure.auth.existingSecret == "" {
			#MercureSecret & {#config: config}
		},
		if config.config.rabbitmq.enabled && config.config.rabbitmq.auth.existingSecret == "" && !config.rabbitmq.enabled {
			#RabbitMQSecret & {#config: config}
		},
		for name, route in config.route if route.enabled {
			#HTTPRoute & {#config: config, #routeName: name, #route: route}
		},
		for obj in (#MariaDB & {#config: config}).objects if config.mariadb.enabled {
			obj
		},
		for obj in (#MySQL & {#config: config}).objects if config.mysql.enabled {
			obj
		},
		for obj in (#PostgreSQL & {#config: config}).objects if config.postgresql.enabled {
			obj
		},
		for obj in (#Redis & {#config: config}).objects if config.redis.enabled {
			obj
		},
		for obj in (#RabbitMQ & {#config: config}).objects if config.rabbitmq.enabled {
			obj
		},
		if config.web.enabled && config.web.serviceAccount.create {
			#WebServiceAccount & {#config: config}
		},
		if config.web.enabled {
			#WebDeployment & {#config: config}
		},
		if config.web.enabled {
			#WebService & {#config: config}
		},
		if config.web.enabled && len(config.web.configuration) > 0 {
			#WebConfigMap & {#config: config}
		},
		if config.web.enabled && config.web.autoscaling.enabled {
			#WebHorizontalPodAutoscaler & {#config: config}
		},
		if config.web.enabled && config.web.ingress.enabled {
			#WebIngress & {#config: config}
		},
		for name, route in config.web.route if config.web.enabled && route.enabled {
			#WebHTTPRoute & {#config: config, #routeName: name, #route: route}
		},
	]
}