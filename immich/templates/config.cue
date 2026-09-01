package templates

import (
	"strings"

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

	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels:     {[string]: string}

	image: timoniv1.#Image & {
		repository: *"ghcr.io/immich-app/immich-server" | string
		tag:        *"v2.7.5" | string
		pullPolicy: *"IfNotPresent" | string
	}

	machineLearning: {
		enabled:      *true | bool
		replicaCount: *1 | int
		strategy: {
			type: *"" | string
		}
		image: timoniv1.#Image & {
			repository: *"ghcr.io/immich-app/immich-machine-learning" | string
			tag:        *"v2.7.5" | string
			pullPolicy: *"IfNotPresent" | string
		}
		service: {
			port: *3003 | int
		}
		probes: {
			readiness: {
				enabled:             *true | bool
				path:                *"/ping" | string
				initialDelaySeconds: *20 | int
				periodSeconds:       *10 | int
				timeoutSeconds:      *5 | int
				failureThreshold:    *12 | int
			}
			liveness: {
				enabled:             *true | bool
				path:                *"/ping" | string
				initialDelaySeconds: *60 | int
				periodSeconds:       *20 | int
				timeoutSeconds:      *5 | int
				failureThreshold:    *6 | int
			}
		}
		persistence: {
			enabled:     *true | bool
			accessModes: *["ReadWriteOnce"] | [...string]
			storageClass: *"" | string
			size:         *"10Gi" | string
		}
		resources: corev1.#ResourceRequirements | *{
			requests: {
				cpu:    "100m"
				memory: "512Mi"
			}
			limits: {
				cpu:    "1"
				memory: "2Gi"
			}
		}
		securityContext: corev1.#SecurityContext | *{
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   false
			capabilities: drop: ["ALL"]
		}
		extraEnv: *[] | [...corev1.#EnvVar]
	}

	server: {
		replicaCount:         *1 | int
		revisionHistoryLimit: *3 | int
		strategy: {
			type: *"" | string
		}
		logLevel: *"" | string
		logLevel: *"log" | string
		logFormat: *"json" | string
		timezone:  *"Etc/UTC" | string
		extraEnv:  *[] | [...corev1.#EnvVar]
		persistence: {
			enabled:     *true | bool
			accessModes: *["ReadWriteOnce"] | [...string]
			storageClass: *"" | string
			size:         *"50Gi" | string
		}
	}

	database: {
		external: {
			host:                      *"" | string
			port:                      *5432 | int
			database:                  *"immich" | string
			username:                  *"postgres" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"database-password" | string
		}
	}

	postgresql: {
		enabled:          *true | bool
		nameOverride:     *"" | string
		fullnameOverride: *"" | string
		image: timoniv1.#Image & {
			repository: *"ghcr.io/immich-app/postgres" | string
			tag:        *"14-vectorchord0.4.3-pgvectors0.2.0" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			database:                          *"immich" | string
			username:                          *"postgres" | string
			postgresPassword:                  *"" | string
			password:                          *"" | string
			existingSecret:                    *"" | string
			existingSecretPostgresPasswordKey: *"postgres-password" | string
			existingSecretUserPasswordKey:     *"user-password" | string
		}
		service: {
			port: *5432 | int
		}
		config: {
			postgresql: *"""
				shared_preload_libraries = 'vchord.so, vectors.so'
				max_wal_size = 2GB
				shared_buffers = 512MB
				wal_compression = on
				""" | string
		}
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"20Gi" | string
			}
			resources: corev1.#ResourceRequirements | *{
				requests: {
					cpu:    "100m"
					memory: "256Mi"
				}
				limits: {
					cpu:    "1"
					memory: "1Gi"
				}
			}
		}
		securityContext: corev1.#SecurityContext | *{
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   false
		}
		extraEnv: *[{
			name:  "POSTGRES_INITDB_ARGS"
			value: "--data-checksums --auth-local=scram-sha-256 --auth-host=scram-sha-256"
		}] | [...corev1.#EnvVar]
		extraVolumes:      *[] | [...corev1.#Volume]
		extraVolumeMounts: *[] | [...corev1.#VolumeMount]
		externalSecrets: {
			enabled: *false | bool
			auth: {
				enabled:    *false | bool
				targetName: *"" | string
			}
		}
	}

	valkey: {
		nameOverride:     *"" | string
		fullnameOverride: *"" | string
		architecture:     *"standalone" | string
		image: timoniv1.#Image & {
			repository: *"docker.io/valkey/valkey" | string
			tag:        *"8.1.9" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			enabled:                   *true | bool
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"valkey-password" | string
		}
		service: {
			ports: {
				redis: *6379 | int
			}
		}
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"5Gi" | string
			}
			resources: corev1.#ResourceRequirements | *{
				requests: {
					cpu:    "50m"
					memory: "128Mi"
				}
				limits: {
					cpu:    "500m"
					memory: "512Mi"
				}
			}
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *65510 | int
			runAsGroup:               *65510 | int
			capabilities: drop: *["ALL"] | [...string]
		}
		internal: {
			enabled: *true | bool
		}
		external: {
			host:                      *"" | string
			port:                      *6379 | int
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"redis-password" | string
		}
	}

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
		database: {
			enabled:  *false | bool
			data:     *[] | [..._]
			dataFrom: *[] | [..._]
		}
		redis: {
			enabled:  *false | bool
			data:     *[] | [..._]
			dataFrom: *[] | [..._]
		}
	}

	imagePullSecrets: *[] | [...corev1.#LocalObjectReference]

	serviceAccount: {
		create:                       *true | bool
		name:                         *"" | string
		annotations:                  {[string]: string}
		automountServiceAccountToken: *false | bool
	}

	service: {
		type:           *"ClusterIP" | string
		port:           *80 | int
		targetPort:     *2283 | int
		annotations:    {[string]: string}
		ipFamilyPolicy: *"" | string
		ipFamilies:     *[] | [...string]
	}

	ingress: {
		enabled:          *false | bool
		ingressClassName: *"" | string
		annotations:      {[string]: string}
		hosts: *[{
			host: "immich.local"
			paths: [{path: "/", pathType: "Prefix"}]
		}] | [...{
			host: string
			paths: [...{
				path:     string
				pathType: *"Prefix" | string
			}]
		}]
		tls: *[] | [...{
			secretName: string
			hosts: [...string]
		}]
	}

	gateway: {
		enabled:     *false | bool
		annotations: {[string]: string}
		parentRefs:  *[] | [...{name: string, namespace?: string}]
		hostnames:   *[] | [...string]
		path:        *"/" | string
		pathType:    *"PathPrefix" | string
	}

	networkPolicy: {
		enabled:     *false | bool
		ingress:     *[] | [..._]
		egress:      *[] | [..._]
		extraEgress: *[] | [..._]
	}

	autoscaling: {
		enabled:                            *false | bool
		minReplicas:                         *1 | int
		maxReplicas:                         *4 | int
		targetCPUUtilizationPercentage:    *70 | int
		targetMemoryUtilizationPercentage: *80 | int
	}

	pdb: {
		enabled:      *false | bool
		minAvailable: *1 | int
	}

	probes: {
		path:                         *"/api/server/ping" | string
		livenessInitialDelaySeconds:  *60 | int
		readinessInitialDelaySeconds: *20 | int
	}

	wait: {
		image: timoniv1.#Image & {
			repository: *"docker.io/library/busybox" | string
			tag:        *"1.37.0" | string
			pullPolicy: *"IfNotPresent" | string
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *true | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *65534 | int
			runAsGroup:               *65534 | int
			capabilities: drop: *["ALL"] | [...string]
		}
	}

	resources: corev1.#ResourceRequirements | *{
		requests: {
			cpu:    "100m"
			memory: "512Mi"
		}
		limits: {
			cpu:    "1"
			memory: "2Gi"
		}
	}

	podSecurityContext: corev1.#PodSecurityContext | *{
		seccompProfile: type: "RuntimeDefault"
	}

	securityContext: corev1.#SecurityContext | *{
		allowPrivilegeEscalation: false
		capabilities: drop: ["ALL"]
	}

	podAnnotations:                 {[string]: string}
	podLabels:                      {[string]: string}
	priorityClassName:              *"" | string
	terminationGracePeriodSeconds: *30 | int
	nodeSelector:                   {[string]: string}
	tolerations:                    *[] | [...corev1.#Toleration]
	affinity:                       corev1.#Affinity | *{}
	topologySpreadConstraints:      *[] | [...corev1.#TopologySpreadConstraint]

	test: {
		image: timoniv1.#Image & {
			repository: *"docker.io/library/busybox" | string
			tag:        *"1.37.0" | string
			pullPolicy: *"IfNotPresent" | string
		}
	}

	extraObjects:          *[] | [..._]
	extraVolumes:          *[] | [...corev1.#Volume]
	extraVolumeMounts:     *[] | [...corev1.#VolumeMount]
	name:                  string
	fullname:              string
	namespace:             string
	serviceAccountName:    string
	dbInternalEnabled:     bool
	dbHost:                string
	dbPort:                int
	dbName:                string
	dbUser:                string
	dbSecretName:          string
	dbSecretKey:           string
	valkeyInternalEnabled: bool
	valkeyHost:            string
	valkeyPort:            int
	valkeyName:            string
	redisSecretName:       string
	redisSecretKey:        string
	hasRedisPassword:      bool
	mlUrl:                 string
	uploadsPvcName:        string
	mlCachePvcName:        string
}

#Instance: {
	config: #Config

	config: {
		name:     string | *config.metadata.name
		fullname: string | *{
			if config.fullnameOverride != "" {
				config.fullnameOverride
			}
			if config.fullnameOverride == "" {
				if config.nameOverride != "" {
					"\(config.metadata.name)-\(config.nameOverride)"
				}
				if config.nameOverride == "" {
					config.metadata.name
				}
			}
		}
		namespace: string | *config.metadata.namespace

		serviceAccountName: string | *{
			if config.serviceAccount.create {
				if config.serviceAccount.name != "" {
					config.serviceAccount.name
				}
				if config.serviceAccount.name == "" {
					fullname
				}
			}
			if !config.serviceAccount.create {
				if config.serviceAccount.name != "" {
					config.serviceAccount.name
				}
				if config.serviceAccount.name == "" {
					"default"
				}
			}
		}

		dbInternalEnabled: config.postgresql.enabled
		dbHost: {
			if dbInternalEnabled {
				"\(fullname)-postgresql"
			}
			if !dbInternalEnabled {
				config.database.external.host
			}
		}
		dbPort: {
			if dbInternalEnabled {
				config.postgresql.service.port
			}
			if !dbInternalEnabled {
				config.database.external.port
			}
		}
		dbName: {
			if dbInternalEnabled {
				config.postgresql.auth.database
			}
			if !dbInternalEnabled {
				config.database.external.database
			}
		}
		dbUser: {
			if dbInternalEnabled {
				config.postgresql.auth.username
			}
			if !dbInternalEnabled {
				config.database.external.username
			}
		}
		dbSecretName: {
			if dbInternalEnabled {
				if config.postgresql.auth.existingSecret != "" {
					config.postgresql.auth.existingSecret
				}
				if config.postgresql.auth.existingSecret == "" {
					"\(fullname)-postgresql-auth"
				}
			}
			if !dbInternalEnabled {
				if config.database.external.existingSecret != "" {
					config.database.external.existingSecret
				}
				if config.database.external.existingSecret == "" {
					"\(fullname)-database"
				}
			}
		}
		dbSecretKey: {
			if dbInternalEnabled {
				if config.postgresql.auth.username == "postgres" {
					config.postgresql.auth.existingSecretPostgresPasswordKey
				}
				if config.postgresql.auth.username != "postgres" {
					config.postgresql.auth.existingSecretUserPasswordKey
				}
			}
			if !dbInternalEnabled {
				if config.database.external.existingSecret != "" {
					config.database.external.existingSecretPasswordKey
				}
				if config.database.external.existingSecret == "" {
					"database-password"
				}
			}
		}

		valkeyInternalEnabled: config.valkey.internal.enabled
		valkeyHost: {
			if valkeyInternalEnabled {
				"\(fullname)-valkey-client"
			}
			if !valkeyInternalEnabled {
				config.valkey.external.host
			}
		}
		valkeyPort: {
			if valkeyInternalEnabled {
				config.valkey.service.ports.redis
			}
			if !valkeyInternalEnabled {
				config.valkey.external.port
			}
		}
		valkeyName: {
			if config.valkey.nameOverride != "" {
				config.valkey.nameOverride
			}
			if config.valkey.nameOverride == "" {
				if strings.Contains(config.valkey.image.repository, "redis") {
					"redis"
				}
				if !strings.Contains(config.valkey.image.repository, "redis") {
					"valkey"
				}
			}
		}
		redisSecretName: {
			if valkeyInternalEnabled {
				if config.valkey.auth.existingSecret != "" {
					config.valkey.auth.existingSecret
				}
				if config.valkey.auth.existingSecret == "" {
					"\(fullname)-valkey-auth"
				}
			}
			if !valkeyInternalEnabled {
				if config.valkey.external.existingSecret != "" {
					config.valkey.external.existingSecret
				}
				if config.valkey.external.existingSecret == "" {
					"\(fullname)-redis"
				}
			}
		}
		redisSecretKey: {
			if valkeyInternalEnabled {
				config.valkey.auth.existingSecretPasswordKey
			}
			if !valkeyInternalEnabled {
				if config.valkey.external.existingSecret != "" {
					config.valkey.external.existingSecretPasswordKey
				}
				if config.valkey.external.existingSecret == "" {
					"redis-password"
				}
			}
		}
		hasRedisPassword: (valkeyInternalEnabled && config.valkey.auth.enabled) || config.valkey.external.password != "" || config.valkey.external.existingSecret != ""
		mlUrl:            "http://\(fullname)-machine-learning:\(config.machineLearning.service.port)"

		uploadsPvcName: "\(fullname)-uploads"
		mlCachePvcName: "\(fullname)-ml-cache"
	}

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccountBuilder & {_config: config}
		}
		serverDeployment: #ServerDeploymentBuilder & {_config: config}
		service:          #ServiceBuilder & {_config: config}

		if config.server.persistence.enabled {
			uploadsPVC: #UploadsPVCBuilder & {_config: config}
		}
		if config.machineLearning.enabled {
			mlService:    #MLServiceBuilder & {_config: config}
			mlDeployment: #MLDeploymentBuilder & {_config: config}
			if config.machineLearning.persistence.enabled {
				mlCachePVC: #MLCachePVCBuilder & {_config: config}
			}
		}
		if config.dbInternalEnabled {
			if config.postgresql.auth.existingSecret == "" {
				pgAuthSecret: #PostgreSQLAuthSecretBuilder & {_config: config}
			}
			pgStatefulSet:     #PostgreSQLStatefulSetBuilder & {_config: config}
			pgService:         #PostgreSQLServiceBuilder & {_config: config}
			pgHeadlessService: #PostgreSQLHeadlessServiceBuilder & {_config: config}
		}
		if config.valkeyInternalEnabled {
			if config.valkey.auth.enabled && config.valkey.auth.existingSecret == "" {
				valkeyAuthSecret: #ValkeyAuthSecretBuilder & {_config: config}
			}
			valkeyStatefulSet:     #ValkeyStatefulSetBuilder & {_config: config}
			valkeyClientService:   #ValkeyClientServiceBuilder & {_config: config}
			valkeyHeadlessService: #ValkeyHeadlessServiceBuilder & {_config: config}
		}
		if config.externalSecrets.enabled {
			if config.externalSecrets.database.enabled {
				dbExternalSecret: #DBExternalSecretBuilder & {_config: config}
			}
			if config.externalSecrets.redis.enabled {
				redisExternalSecret: #RedisExternalSecretBuilder & {_config: config}
			}
		}
		if config.ingress.enabled {
			ingress: #IngressBuilder & {_config: config}
		}
		if config.gateway.enabled {
			httpRoute: #HTTPRouteBuilder & {_config: config}
		}
		if config.networkPolicy.enabled {
			networkPolicy: #NetworkPolicyBuilder & {_config: config}
		}
		if config.autoscaling.enabled {
			hpa: #HPABuilder & {_config: config}
		}
		if config.pdb.enabled {
			pdb: #PDBBuilder & {_config: config}
		}
		for idx, m in config.extraObjects {
			"extra-object-\(idx)": m
		}
	}

	tests: {}
}
