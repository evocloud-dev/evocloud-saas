package templates

import (
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// The kubeVersion is set at apply-time via timoni.cue.
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.30.0"}

	// The moduleVersion is set from the module version.
	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// Values shared with HelmForge dependency charts.
	global: *{} | {...}

	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	commonLabels:      *{} | timoniv1.#Labels
	commonAnnotations: *{} | timoniv1.#Annotations

	replicaCount: *1 | int & >=1

	autoscaling: {
		enabled:                        *false | bool
		minReplicas:                    *2 | int & >=2
		maxReplicas:                    *5 | int & >=2
		targetCPUUtilizationPercentage: *70 | int & >0 & <=100
	}

	podDisruptionBudget: {
		enabled:      *true | bool
		minAvailable: *1 | int | string
	}

	image: timoniv1.#Image & {
		repository: *"ghcr.io/documenso/documenso" | string
		tag:        *"v2.21.0" | string
		digest:     *"sha256:d9985f66c19c59128f64b1439f057683da0110deb0e518655b97f06e3141f173" | string
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
	}

	imagePullSecrets: *[] | [...corev1.#LocalObjectReference]

	documenso: {
		publicUrl:                 *"" | string
		mailFromAddress:           *"noreply@example.com" | string
		mailFromName:              *"Documenso" | string
		jobsProvider:              *"bullmq" | "local" | "inngest"
		existingSecret:            *"" | string
		nextAuthSecretKey:         *"nextauth-secret" | string
		encryptionKeyKey:          *"encryption-key" | string
		encryptionSecondaryKeyKey: *"encryption-secondary-key" | string
		secrets: {
			nextAuthSecret:         *"dGhpcy1pcy1hLWRlZmF1bHQtc2VjcmV0LWZvci1kb2N1bWVuc28tYXV0aC0zMmNoYXJzIQ==" | string
			encryptionKey:          *"dGhpcy1pcy1hLWRlZmF1bHQtZW5jcnlwdGlvbi1rZXktZm9yLWRvY3VtZW5zby0zMmNoYXI=" | string
			encryptionSecondaryKey: *"dGhpcy1pcy1hLXNlY29uZGFyeS1lbmNyeXB0aW9uLWtleS1mb3ItZG9jdW1lbnNvMzI=" | string
		}
		extraEnv:     *[] | [...corev1.#EnvVar]
		extraEnvFrom: *[] | [...corev1.#EnvFromSource]
	}

	database: {
		external: {
			enabled:            *false | bool
			existingSecret:     *"" | string
			urlKey:             *"database-url" | string
			directUrlKey:       *"direct-database-url" | string
			directUrlEnabled:   *false | bool
			host:               *"" | string
			port:               *5432 | int & >0 & <=65535
			networkPolicyPeers: *[] | [...networkingv1.#NetworkPolicyPeer]
		}
	}

	postgresql: {
		enabled:          *true | bool
		nameOverride:     *"postgresql" | string
		fullnameOverride: *"" | string
		architecture:     *"standalone" | string
		image: timoniv1.#Image & {
			repository: *"docker.io/library/postgres" | string
			tag:        *"18.6-trixie" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		auth: {
			database:                      *"documenso" | string
			username:                      *"documenso" | string
			password:                      *"" | string
			postgresPassword:              *"" | string
			existingSecret:                *"" | string
			existingSecretUserPasswordKey: *"" | string
		}
		resources: corev1.#ResourceRequirements & {
			requests: {
				cpu:    *"100m" | string
				memory: *"256Mi" | string
			}
			limits: {
				cpu:    *"1" | string
				memory: *"1Gi" | string
			}
		}
		podSecurityContext: corev1.#PodSecurityContext & {
			fsGroup:             *999 | int
			fsGroupChangePolicy: *"OnRootMismatch" | string
			seccompProfile: {
				type: *"RuntimeDefault" | string
			}
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *999 | int
			runAsGroup:               *999 | int
			capabilities: {
				drop: *["ALL"] | [...string]
			}
		}
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"8Gi" | string
			}
			resources: corev1.#ResourceRequirements & {
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
	}

	redis: {
		enabled:          *false | bool
		nameOverride:     *"redis" | string
		fullnameOverride: *"" | string
		architecture:     *"standalone" | string
		image: timoniv1.#Image & {
			repository: *"docker.io/valkey/valkey" | string
			tag:        *"9.2" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		auth: {
			enabled:                   *true | bool
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"" | string
		}
		resources: corev1.#ResourceRequirements & {
			requests: {
				cpu:    *"50m" | string
				memory: *"128Mi" | string
			}
			limits: {
				cpu:    *"500m" | string
				memory: *"512Mi" | string
			}
		}
		podSecurityContext: corev1.#PodSecurityContext & {
			fsGroup:             *999 | int
			fsGroupChangePolicy: *"OnRootMismatch" | string
			seccompProfile: {
				type: *"RuntimeDefault" | string
			}
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *999 | int
			runAsGroup:               *999 | int
			capabilities: {
				drop: *["ALL"] | [...string]
			}
		}
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"1Gi" | string
			}
			resources: corev1.#ResourceRequirements & {
				requests: {
					cpu:    *"50m" | string
					memory: *"128Mi" | string
				}
				limits: {
					cpu:    *"500m" | string
					memory: *"512Mi" | string
				}
			}
		}
		external: {
			enabled:            *false | bool
			host:               *"" | string
			port:               *6379 | int & >0 & <=65535
			database:           *0 | int & >=0
			existingSecret:     *"" | string
			passwordKey:        *"redis-password" | string
			networkPolicyPeers: *[] | [...networkingv1.#NetworkPolicyPeer]
		}
	}

	smtp: {
		enabled:        *false | bool
		host:           *"" | string
		port:           *587 | int & >0 & <=65535
		secure:         *false | bool
		existingSecret: *"" | string
		usernameKey:    *"username" | string
		passwordKey:    *"password" | string
	}

	inbucket: {
		enabled: *false | bool
		image: timoniv1.#Image & {
			repository: *"docker.io/inbucket/inbucket" | string
			tag:        *"main" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		service: {
			type:     *"ClusterIP" | "NodePort" | "LoadBalancer"
			smtpPort: *2500 | int & >0 & <=65535
			webPort:  *9000 | int & >0 & <=65535
			pop3Port: *1100 | int & >0 & <=65535
		}
	}

	objectStorage: {
		provider: *"database" | "s3"
		s3: {
			bucket:         *"" | string
			region:         *"us-east-1" | string
			endpoint:       *"" | string
			forcePathStyle: *false | bool
			existingSecret: *"" | string
			accessKeyKey:   *"access-key" | string
			secretKeyKey:   *"secret-key" | string
		}
	}

	certificate: {
		enabled:        *false | bool
		existingSecret: *"" | string
		fileKey:        *"signing-certificate.p12" | string
		passphraseKey:  *"passphrase" | string
		mountPath:      *"/var/run/documenso/certificate/signing-certificate.p12" | string
	}

	gotenberg: {
		enabled:        *false | bool
		url:            *"" | string
		existingSecret: *"" | string
		usernameKey:    *"username" | string
		passwordKey:    *"password" | string
	}

	externalSecrets: {
		enabled:         *false | bool
		refreshInterval: *"1h" | string
		items:           *[] | [...#ExternalSecretItem]
	}

	serviceAccount: {
		create:                       *true | bool
		name:                         *"" | string
		annotations:                  *{} | timoniv1.#Annotations
		automountServiceAccountToken: *false | bool
	}

	service: {
		type:           *"ClusterIP" | "NodePort" | "LoadBalancer"
		port:           *3000 | int & >0 & <=65535
		annotations:    *{} | timoniv1.#Annotations
		ipFamilyPolicy: *"" | "SingleStack" | "PreferDualStack" | "RequireDualStack"
		ipFamilies:     *[] | [...corev1.#IPFamily]
	}

	gatewayAPI: {
		enabled:         *false | bool
		publicUrlScheme: *"https" | "http"
		annotations:     *{} | timoniv1.#Annotations
		labels:          *{} | timoniv1.#Labels
		parentRefs:      *[] | [...#HTTPRouteParentRef]
		hostnames:       *[] | [...string]
		rules:           *[] | [...#HTTPRouteRule]
		httpRoutes:      *[] | [...#HTTPRouteItem]
	}

	probes: {
		startup: {
			enabled:             *true | bool
			initialDelaySeconds: *5 | int & >=0
			periodSeconds:       *5 | int & >0
			timeoutSeconds:      *5 | int & >0
			failureThreshold:    *60 | int & >0
		}
		liveness: {
			enabled:             *true | bool
			initialDelaySeconds: *0 | int & >=0
			periodSeconds:       *20 | int & >0
			timeoutSeconds:      *5 | int & >0
			failureThreshold:    *3 | int & >0
		}
		readiness: {
			enabled:             *true | bool
			initialDelaySeconds: *0 | int & >=0
			periodSeconds:       *10 | int & >0
			timeoutSeconds:      *5 | int & >0
			failureThreshold:    *3 | int & >0
		}
	}

	waitForServices: {
		image: timoniv1.#Image & {
			repository: *"docker.io/library/busybox" | string
			tag:        *"1.37.0" | string
			digest:     *"sha256:bdf57e528e45e4433820e045b29b4597825a1c9e38353532d90a01445013f82e" | string
			pullPolicy: *"IfNotPresent" | "Always" | "Never"
		}
		timeoutSeconds: *180 | int & >0
		resources:      corev1.#ResourceRequirements & {
			requests: {
				cpu:    *"10m" | string
				memory: *"16Mi" | string
			}
			limits: {
				cpu:    *"100m" | string
				memory: *"64Mi" | string
			}
		}
	}

	resources: corev1.#ResourceRequirements & {
		requests: {
			cpu:    *"250m" | string
			memory: *"512Mi" | string
		}
		limits: {
			cpu:    *"1" | string
			memory: *"1Gi" | string
		}
	}

	podSecurityContext: corev1.#PodSecurityContext & {
		runAsNonRoot:        *true | bool
		runAsUser:           *1001 | int
		runAsGroup:          *1001 | int
		fsGroup:              *1001 | int
		fsGroupChangePolicy: *"OnRootMismatch" | "Always"
		seccompProfile: {
			type: *"RuntimeDefault" | "Localhost" | "Unconfined"
		}
	}

	securityContext: corev1.#SecurityContext & {
		allowPrivilegeEscalation: *false | bool
		readOnlyRootFilesystem:   *true | bool
		capabilities: {
			drop: *["ALL"] | [...string]
		}
	}

	runtimeStorage: {
		sizeLimit: *"512Mi" | timoniv1.#MemoryQuantity
	}

	terminationGracePeriodSeconds: *60 | int & >=0

	podLabels:                 *{} | timoniv1.#Labels
	podAnnotations:            *{} | timoniv1.#Annotations
	nodeSelector:              *{} | {[string]: string}
	tolerations:               *[] | [...corev1.#Toleration]
	affinity:                  *{} | corev1.#Affinity
	topologySpreadConstraints: *[] | [...corev1.#TopologySpreadConstraint]
	priorityClassName:         *"" | string
	extraVolumes:              *[] | [...corev1.#Volume]
	extraVolumeMounts:         *[] | [...corev1.#VolumeMount]

	// Derived helper fields
	#fullname: [
		if fullnameOverride != "" { fullnameOverride },
		metadata.name,
	][0]
	#name: [
		if nameOverride != "" { nameOverride },
		#fullname,
	][0]
	let uncreatedSA = [
		if serviceAccount.name != "" { serviceAccount.name },
		"default",
	][0]
	#serviceAccountName: [
		if !serviceAccount.create { uncreatedSA },
		if serviceAccount.name != "" { serviceAccount.name },
		#fullname,
	][0]
	#applicationSecretName: [
		if documenso.existingSecret != "" { documenso.existingSecret },
		"\(#fullname)-application",
	][0]
	#databaseFullname: [
		if postgresql.fullnameOverride != "" { postgresql.fullnameOverride },
		"\(metadata.name)-\(postgresql.nameOverride)",
	][0]
	#databaseHost: [
		if database.external.enabled { database.external.host },
		#databaseFullname,
	][0]
	#databasePort: [
		if database.external.enabled { database.external.port },
		5432,
	][0]
	#databaseSecretName: [
		if database.external.enabled { database.external.existingSecret },
		if postgresql.auth.existingSecret != "" { postgresql.auth.existingSecret },
		"\(#databaseFullname)-auth",
	][0]
	#databaseSecretKey: [
		if postgresql.auth.existingSecretUserPasswordKey != "" { postgresql.auth.existingSecretUserPasswordKey },
		"user-password",
	][0]
	#redisFullname: [
		if redis.fullnameOverride != "" { redis.fullnameOverride },
		"\(metadata.name)-\(redis.nameOverride)",
	][0]
	#redisHost: [
		if redis.external.enabled { redis.external.host },
		"\(#redisFullname)-client",
	][0]
	#redisPort: [
		if redis.external.enabled { redis.external.port },
		6379,
	][0]
	#redisSecretName: [
		if redis.external.enabled { redis.external.existingSecret },
		if redis.auth.existingSecret != "" { redis.auth.existingSecret },
		"\(#redisFullname)-auth",
	][0]
	#redisSecretKey: [
		if redis.external.enabled { redis.external.passwordKey },
		if redis.auth.existingSecretPasswordKey != "" { redis.auth.existingSecretPasswordKey },
		"redis-password",
	][0]

	#labels: {
		"app.kubernetes.io/name":       #name
		"app.kubernetes.io/instance":   metadata.name
		"app.kubernetes.io/version":    moduleVersion
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/part-of":    "helmforge"
		for k, v in commonLabels {
			"\(k)": v
		}
	}
	#selector: {
		"app.kubernetes.io/name":     #name
		"app.kubernetes.io/instance": metadata.name
	}

	let _routeUrl = [
		if gatewayAPI.enabled && len(gatewayAPI.hostnames) > 0 {
			"\(gatewayAPI.publicUrlScheme)://\(gatewayAPI.hostnames[0])"
		},
		if gatewayAPI.enabled && len(gatewayAPI.httpRoutes) > 0 {
			let r0 = gatewayAPI.httpRoutes[0]
			if len(r0.hostnames) > 0 {
				"\(gatewayAPI.publicUrlScheme)://\(r0.hostnames[0])"
			}
			if len(r0.hostnames) == 0 {
				""
			}
		},
		"",
	][0]

	#publicUrl: [
		if documenso.publicUrl != "" { documenso.publicUrl },
		if _routeUrl != "" { _routeUrl },
		"http://\(#fullname).\(metadata.namespace).svc:\(service.port)",
	][0]

	// Images
	#documensoImage: [
		if image.digest != "" { "\(image.repository)@\(image.digest)" },
		"\(image.repository):\(image.tag)",
	][0]
	#inbucketImage: [
		if inbucket.image.digest != "" { "\(inbucket.image.repository)@\(inbucket.image.digest)" },
		"\(inbucket.image.repository):\(inbucket.image.tag)",
	][0]
	#waitImage: waitForServices.image.reference

	// Annotations
	#serviceAccountAnnotations: {
		for k, v in commonAnnotations { "\(k)": v }
		for k, v in serviceAccount.annotations { "\(k)": v }
	}
	#applicationSecretAnnotations: {
		"helm.sh/resource-policy": "keep"
		for k, v in commonAnnotations { "\(k)": v }
	}
	#serviceAnnotations: {
		for k, v in commonAnnotations { "\(k)": v }
		for k, v in service.annotations { "\(k)": v }
	}
	#deploymentAnnotations: {
		for k, v in commonAnnotations { "\(k)": v }
	}
	#pdbAnnotations: {
		for k, v in commonAnnotations { "\(k)": v }
	}
	#hpaAnnotations: {
		for k, v in commonAnnotations { "\(k)": v }
	}

	// Validation rules
	if database.external.enabled {
		postgresql: enabled: false
		database: external: {
			host:           string & !=""
			existingSecret: string & !=""
		}
	}
	if !database.external.enabled {
		postgresql: enabled: true
	}

	if documenso.jobsProvider == "bullmq" {
		if redis.external.enabled {
			redis: enabled: false
			redis: external: {
				host:           string & !=""
				existingSecret: string & !=""
			}
		}
		if !redis.external.enabled {
			redis: enabled: true
		}
	}

	if replicaCount > 1 {
		documenso: jobsProvider: "bullmq"
		objectStorage: provider: "s3"
	}

	if autoscaling.enabled {
		documenso: jobsProvider: "bullmq"
		objectStorage: provider: "s3"
		autoscaling: maxReplicas: >=autoscaling.minReplicas
	}

	if objectStorage.provider == "s3" {
		objectStorage: s3: {
			bucket:         string & !=""
			existingSecret: string & !=""
		}
	}

	if smtp.enabled {
		smtp: {
			host:           string & !=""
			existingSecret: string & !=""
		}
	}

	if certificate.enabled {
		certificate: {
			existingSecret: string & !=""
		}
	}

	if gotenberg.enabled {
		gotenberg: {
			url: string & !=""
		}
	}
}

// Auxiliary types and helper schemas for HTTPRoute, ExternalSecrets, and Annotations
#HTTPRouteParentRef: {
	group?:       *"gateway.networking.k8s.io" | string
	kind?:        *"Gateway" | string
	name!:        string
	namespace?:   string
	sectionName?: string
	port?:        int
}

#HTTPRouteRule: {
	matches?: [...]
	filters?: [...]
	backendRefs?: [...]
	omitDefaultBackend: *false | bool
}

#HTTPRouteItem: {
	name:             *"" | string
	fullnameOverride: *"" | string
	labels:            *{} | timoniv1.#Labels
	annotations:       *{} | timoniv1.#Annotations
	parentRefs!:       [...#HTTPRouteParentRef] & [_, ...]
	hostnames:         *[] | [...string]
	rules:             *[] | [...#HTTPRouteRule]
}

#ExternalSecretItem: {
	name:             *"" | string
	fullnameOverride: *"" | string
	labels:            *{} | timoniv1.#Labels
	annotations:       *{} | timoniv1.#Annotations
	spec!: {
		refreshInterval: *"" | string
		secretStoreRef?: {
			name!: string
			kind?: *"ClusterSecretStore" | "SecretStore"
		}
		target: {
			name:            *"" | string
			creationPolicy?: string
			deletionPolicy?: string
			[string]:        _
		}
		data?:     [...]
		dataFrom?: [...]
		[string]:  _
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		if config.documenso.existingSecret == "" {
			secret: #Secret & {#config: config}
		}
		svc: #Service & {#config: config}
		deploy: #Deployment & {#config: config}
		if config.podDisruptionBudget.enabled {
			pdb: #PodDisruptionBudget & {#config: config}
		}
		if config.autoscaling.enabled {
			hpa: #HorizontalPodAutoscaler & {#config: config}
		}
		if config.gatewayAPI.enabled {
			if len(config.gatewayAPI.parentRefs) > 0 {
				httproute: #HTTPRoute & {#config: config}
			}
			for i, r in config.gatewayAPI.httpRoutes {
				"httproute_\(i)": #HTTPRouteItemResource & {#config: config, #route: r, #index: i}
			}
		}
		if config.externalSecrets.enabled {
			for i, item in config.externalSecrets.items {
				"externalsecret_\(i)": #ExternalSecret & {#config: config, #item: item}
			}
		}
		if config.postgresql.enabled && !config.database.external.enabled {
			if config.postgresql.auth.existingSecret == "" {
				postgresql_auth: #PostgreSQLAuthSecret & {#config: config}
			}
			postgresql_config: #PostgreSQLConfigMap & {#config: config}
			postgresql_initdb: #PostgreSQLInitDBConfigMap & {#config: config}
			postgresql_headless_svc: #PostgreSQLHeadlessService & {#config: config}
			postgresql_svc: #PostgreSQLService & {#config: config}
			postgresql_sts: #PostgreSQLStatefulSet & {#config: config}
		}
		if config.redis.enabled && !config.redis.external.enabled {
			if config.redis.auth.enabled && config.redis.auth.existingSecret == "" {
				redis_auth: #RedisAuthSecret & {#config: config}
			}
			redis_config: #RedisConfigMap & {#config: config}
			redis_headless_svc: #RedisHeadlessService & {#config: config}
			redis_svc: #RedisService & {#config: config}
			redis_sts: #RedisStatefulSet & {#config: config}
		}
		if config.inbucket.enabled && !config.smtp.enabled {
			inbucket_svc:    #InbucketService & {#config: config}
			inbucket_deploy: #InbucketDeployment & {#config: config}
		}
	}
}
