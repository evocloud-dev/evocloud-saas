package templates

import (
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.26.0"}

	// The moduleVersion is set from the user-supplied module version.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	// The selector for Deployments and Services.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// Chart naming and common labels
	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels:     *{} | {[string]: string}

	// Workload settings
	replicaCount: *1 | 1

	// Images
	image!: timoniv1.#Image
	proxy: {
		image!: timoniv1.#Image
		resources: corev1.#ResourceRequirements & {
			requests: {
				(corev1.#ResourceCPU):    *"50m" | string
				(corev1.#ResourceMemory): *"32Mi" | string
			}
			limits: {
				(corev1.#ResourceCPU):    *"500m" | string
				(corev1.#ResourceMemory): *"128Mi" | string
			}
		}
		bodySize: *"20m" | string
	}
	admission: {
		key:            *"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef" | string
		existingSecret: *"" | string
		image!:         timoniv1.#Image
		resources: corev1.#ResourceRequirements & {
			requests: {
				(corev1.#ResourceCPU):    *"25m" | string
				(corev1.#ResourceMemory): *"32Mi" | string
			}
			limits: {
				(corev1.#ResourceCPU):    *"200m" | string
				(corev1.#ResourceMemory): *"128Mi" | string
			}
		}
	}

	// Compute resources
	resources: corev1.#ResourceRequirements & {
		requests: {
			(corev1.#ResourceCPU):    *"250m" | string
			(corev1.#ResourceMemory): *"512Mi" | string
		}
		limits: {
			(corev1.#ResourceCPU):    *"2" | string
			(corev1.#ResourceMemory): *"2Gi" | string
		}
	}

	// Security contexts
	podSecurityContext: corev1.#PodSecurityContext & {
		runAsNonRoot:        *true | bool
		runAsUser:           *1000 | int
		runAsGroup:          *1000 | int
		fsGroup:             *1000 | int
		fsGroupChangePolicy: *"OnRootMismatch" | string
		seccompProfile: {
			type: corev1.#SeccompProfileTypeRuntimeDefault
		}
	}

	securityContext: corev1.#SecurityContext & {
		allowPrivilegeEscalation: *false | bool
		readOnlyRootFilesystem:   *true | bool
		capabilities: {
			drop: *[corev1.#Capability("ALL")] | [...corev1.#Capability]
		}
	}

	// Server settings
	server: {
		port:      *3000 | 3000
		publicUrl: *"" | string
	}

	// Private enrollment
	bootstrap: {
		name:           *"Initial Owner" | string
		email:          *"owner@example.test" | string
		username:       *"owner" | string
		password:       *"" | string
		existingSecret: *"" | string
		passwordKey:    *"user-password" | string
	}

	// Retained credentials
	identity: {
		existingSecret:   *"" | string
		authSecret:       *"" | string
		encryptionSecret: *"" | string
	}

	// Storage
	storage: {
		driver: *"local" | "s3"
		s3: {
			bucket:             *"" | string
			region:             *"us-east-1" | string
			endpoint:           *"" | string
			forcePathStyle:     *false | bool
			existingSecret:     *"" | string
			accessKeyIdKey:     *"access-key-id" | string
			secretAccessKeyKey: *"secret-access-key" | string
			caSecret:           *"" | string
			caKey:              *"ca.crt" | string
		}
	}

	// OAuth
	oauth: {
		enabled:          *false | bool
		name:             *"Single sign-on" | string
		clientId:         *"" | string
		existingSecret:   *"" | string
		clientSecretKey:  *"client-secret" | string
		authorizationUrl: *"" | string
		tokenUrl:         *"" | string
		userInfoUrl:      *"" | string
		scopes:           *"profile email" | string
		caSecret:         *"" | string
		caKey:            *"ca.crt" | string
	}

	// SMTP
	smtp: {
		enabled:        *false | bool
		host:           *"" | string
		port:           *465 | int
		from:           *"" | string
		username:       *"" | string
		existingSecret: *"" | string
		passwordKey:    *"password" | string
		tls: {
			caSecret: *"" | string
			caKey:    *"ca.crt" | string
		}
	}

	// External database
	database: {
		host:           *"" | string
		port:           *5432 | int
		name:           *"reactive_resume" | string
		username:       *"reactive_resume" | string
		passwordSecret: *"" | string
		passwordKey:    *"password" | string
		tls: {
			enabled:  *true | bool
			caSecret: *"" | string
			caKey:    *"ca.crt" | string
		}
	}

	// Bundled PostgreSQL
	postgresql: {
		initdb?: scripts?: {[string]: string}
		securityContext?:   corev1.#SecurityContext
		extraVolumes?:      [...corev1.#Volume]
		extraVolumeMounts?: [...corev1.#VolumeMount]
		networkPolicy?: {
			enabled: *true | bool
			egress?: {
				enabled:                      *true | bool
				allowDNS:                     *true | bool
				allowSameNamespacePostgreSQL: *false | bool
				allowHTTPS:                   *false | bool
			}
		}
		enabled:      *true | bool
		architecture: *"standalone" | string
		auth: {
			database:                      *"reactive_resume" | string
			username:                      *"reactive_resume" | string
			existingSecret:                *"" | string
			existingSecretUserPasswordKey: *"user-password" | string
			password:                      *"" | string
		}
		service: {
			port: *5432 | int
		}
		image!: timoniv1.#Image
	}

	// Persistence
	persistence: {
		enabled:       *true | true
		existingClaim: *"" | string
		storageClass:  *"" | string
		size:          *"10Gi" | string
		accessModes:   *["ReadWriteOnce"] | [...string]
		retain:        *true | bool
		annotations?:  {[string]: string}
	}

	// Runtime Config
	runtime: {
		temporarySize: *"256Mi" | string
	}

	// Service
	service: {
		type:           *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
		port:           *3000 | int & >0 & <=65535
		annotations?:   timoniv1.#Annotations
		ipFamilyPolicy: *"" | string
		ipFamilies:     *[] | [...string]
	}

	// ServiceAccount
	serviceAccount: {
		create:                       *true | bool
		name:                         *"" | string
		annotations?:                 timoniv1.#Annotations
		automountServiceAccountToken: *false | bool
	}


	// Gateway API
	gatewayAPI: {
		enabled:          *false | bool
		gatewayClassName: *"" | string
		httpRoutes:       *[] | [...{
			name?:        string
			labels?:      {[string]: string}
			annotations?: {[string]: string}
			parentRefs:   [...{
				name:         string
				namespace?:   string
				group?:       string
				kind?:        string
				sectionName?: string
				port?:        int
			}]
			hostnames?:   [...string]
			rules?:       [...{
				matches?: [...{
					path?: {
						type?:  *"PathPrefix" | "Exact" | "RegularExpression" | string
						value?: string
					}
					headers?: [...{
						type?:  *"Exact" | "RegularExpression" | string
						name:   string
						value:  string
					}]
					queryParams?: [...{
						type?:  *"Exact" | "RegularExpression" | string
						name:   string
						value:  string
					}]
					method?: string
				}]
				filters?: [..._]
				backendRefs?: [...{
					name:       string
					namespace?: string
					port?:      int
					group?:     string
					kind?:      string
					weight?:    int
				}]
				omitDefaultBackend?: bool
			}]
		}]
	}

	// External Secrets
	externalSecrets: {
		enabled:         *false | bool
		refreshInterval: *"1h" | string
		items:           *[] | [...{
			name?:             string
			fullnameOverride?: string
			labels?:           {[string]: string}
			annotations?:      {[string]: string}
			spec:              _
		}]
	}

	// NetworkPolicy
	networkPolicy: {
		enabled:          *true | bool
		egressIsolation:  *true | bool
		allowPublicHttps: *true | bool
		ingressFrom:      *[] | [...netv1.#NetworkPolicyPeer]
		dnsEgress:        *[
			{
				namespaceSelector: matchLabels: {"kubernetes.io/metadata.name": "kube-system"}
				podSelector:       matchLabels: {"k8s-app": "kube-dns"}
			},
		] | [...netv1.#NetworkPolicyPeer]
		extraEgress: *[] | [...netv1.#NetworkPolicyEgressRule]
	}

	// Probes
	probes: {
		startup: {
			failureThreshold: *60 | int & >0
			periodSeconds:    *5 | int & >0
			timeoutSeconds:   *5 | int & >0
		}
		readiness: {
			failureThreshold: *3 | int & >0
			periodSeconds:    *10 | int & >0
			timeoutSeconds:   *5 | int & >0
		}
		liveness: {
			failureThreshold: *3 | int & >0
			periodSeconds:    *20 | int & >0
			timeoutSeconds:   *5 | int & >0
		}
	}

	// Pod scheduling
	podAnnotations:                *{} | {[string]: string}
	podLabels:                     *{} | {[string]: string}
	nodeSelector:                  *{} | {[string]: string}
	tolerations:                  *[] | [...corev1.#Toleration]
	affinity:                     *{} | corev1.#Affinity
	topologySpreadConstraints:    *[] | [...corev1.#TopologySpreadConstraint]
	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *60 | int & >0
	imagePullSecrets:             *[] | [...timoniv1.#ObjectReference]
	extraEnv:                      *[] | [...corev1.#EnvVar]

	// Validation constraints
	if oauth.enabled {
		oauth: {
			clientId:         string & !=""
			existingSecret:   string & !=""
			authorizationUrl: string & !=""
			tokenUrl:         string & !=""
			userInfoUrl:      string & !=""
		}
		server: publicUrl: string & =~"^https://"
	}
	if storage.driver == "s3" {
		storage: s3: {
			bucket:         string & !=""
			existingSecret: string & !=""
		}
	}
	if smtp.enabled {
		smtp: {
			host:           string & !=""
			from:           string & !=""
			username:       string & !=""
			existingSecret: string & !=""
		}
	}
	if !postgresql.enabled {
		database: {
			host:           string & !=""
			passwordSecret: string & !=""
		}
	}
	if bootstrap.password != "" {
		bootstrap: password: string & =~"^.{16,64}$"
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	_saName: [
		if !config.serviceAccount.create && config.serviceAccount.name != "" {config.serviceAccount.name},
		if !config.serviceAccount.create && config.serviceAccount.name == "" {"default"},
		if config.serviceAccount.create && config.serviceAccount.name != "" {config.serviceAccount.name},
		config.metadata.name,
	][0]

	_pvcName: [
		if config.persistence.existingClaim != "" {config.persistence.existingClaim},
		config.metadata.name,
	][0]

	_bootstrapSecretName: [
		if config.bootstrap.existingSecret != "" {config.bootstrap.existingSecret},
		"\(config.metadata.name)-bootstrap",
	][0]

	_identitySecretName: [
		if config.identity.existingSecret != "" {config.identity.existingSecret},
		"\(config.metadata.name)-identity",
	][0]

	_dbHost: [
		if config.postgresql.enabled {"\(config.metadata.name)-postgresql"},
		config.database.host,
	][0]

	_dbSecretName: [
		if config.postgresql.enabled {"\(config.metadata.name)-postgresql-auth"},
		config.database.passwordSecret,
	][0]

	_dbSecretKey: [
		if config.postgresql.enabled {config.postgresql.auth.existingSecretUserPasswordKey},
		config.database.passwordKey,
	][0]

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		svc:     #Service & {#config: config}
		runtime: #Runtime & {#config: config}
		deploy:  #Deployment & {
			#config:          config
			#saName:          _saName
			#pvcName:         _pvcName
			#bootstrapSecret: _bootstrapSecretName
			#identitySecret:  _identitySecretName
			#dbHost:          _dbHost
			#dbSecret:        _dbSecretName
			#dbKey:           _dbSecretKey
		}
		admissionSvc: #AdmissionService & {#config: config}
		admissionDeploy: #AdmissionDeployment & {
			#config: config
			#saName: _saName
		}
		if config.admission.existingSecret == "" {
			admissionSecret: #AdmissionSecret & {#config: config}
		}
		if config.bootstrap.existingSecret == "" {
			bootstrapSecret: #BootstrapSecret & {#config: config}
		}
		if config.identity.existingSecret == "" {
			identitySecret: #IdentitySecret & {#config: config}
		}
		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PersistentVolumeClaim & {#config: config}
		}
		if config.networkPolicy.enabled {
			netpol:          #NetworkPolicy & {#config: config}
			admissionNetpol: #AdmissionNetworkPolicy & {#config: config}
		}
		if config.gatewayAPI.enabled {
			for i, route in config.gatewayAPI.httpRoutes {
				"httproute-\(i)": #HTTPRoute & {#config: config, #route: route, #index: i}
			}
		}
		if config.externalSecrets.enabled {
			for i, item in config.externalSecrets.items {
				"externalsecret-\(i)": #ExternalSecret & {#config: config, #item: item}
			}
		}
		if config.postgresql.enabled {
			pgAuthSecret:      #PostgresAuthSecret & {#config: config}
			pgNetpol:          #PostgresNetworkPolicy & {#config: config}
			pgConfigMap:       #PostgresConfigMap & {#config: config}
			pgInitdbConfigMap: #PostgresInitdbConfigMap & {#config: config}
			pgHeadlessSvc:     #PostgresHeadlessService & {#config: config}
			pgSvc:             #PostgresService & {#config: config}
			pgStatefulSet:     #PostgresStatefulSet & {#config: config}
		}
	}
}
