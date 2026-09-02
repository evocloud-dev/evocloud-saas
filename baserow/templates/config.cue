package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Config: {
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}
	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels:       timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations
	selector: timoniv1.#Selector & {#Name: metadata.name}

	global: #GlobalConfig

	#OtelEnv: [
		if backend.config.enableOtel {
			{
				name: "K8S_NODE_NAME"
				valueFrom: fieldRef: fieldPath: "spec.nodeName"
			}
		},
		if backend.config.enableOtel {
			{
				name: "K8S_POD_NAME"
				valueFrom: fieldRef: fieldPath: "metadata.name"
			}
		},
		if backend.config.enableOtel {
			{
				name: "K8S_POD_UID"
				valueFrom: fieldRef: fieldPath: "metadata.uid"
			}
		},
		if backend.config.enableOtel {
			{
				name: "K8S_POD_NAMESPACE"
				valueFrom: fieldRef: fieldPath: "metadata.namespace"
			}
		},
		if backend.config.enableOtel {
			{
				name: "HOST_IP"
				valueFrom: fieldRef: fieldPath: "status.hostIP"
			}
		},
		if backend.config.enableOtel {
			{
				name:  "OTEL_RESOURCE_ATTRIBUTES"
				value: "k8s.container.name=$(K8S_POD_NAME),k8s.node.name=$(K8S_NODE_NAME),k8s.pod.name=$(K8S_POD_NAME),k8s.pod.uid=$(K8S_POD_UID),k8s.namespace.name=$(K8S_POD_NAMESPACE),k8s.resource.type=container"
			}
		},
		if backend.config.enableOtel {
			{
				name:  "OTEL_EXPORTER_OTLP_ENDPOINT"
				value: "http://$(HOST_IP):4318"
			}
		},
	]

	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	frontend: #FrontendConfig
	backend:  #BackendConfig
	migration: #MigrationConfig
	config:   #GeneralConfig

	postgresql:         #PostgresqlConfig
	externalPostgresql: #ExternalPostgresqlConfig
	redis:              #RedisConfig
	externalRedis:      #ExternalRedisConfig
	minio:              #MinioConfig
	caddy:              #CaddyConfig
	embeddings:         #EmbeddingsConfig
}

#GlobalConfig: {
	baserow: {
		domain:        *"cluster.local" | string
		backendDomain: *"api.cluster.local" | string
		objectsDomain: *"objects.cluster.local" | string
		assistantLLMModel?: string
	}
}

#FrontendConfig: {
	image: {
		registry:   *"docker.io" | string
		repository: *"baserow/web-frontend" | string
		pullPolicy: *"Always" | "IfNotPresent" | "Never"
		tag:        *"2.2.2" | string
	}
	imagePullSecrets: [...timoniv1.#ObjectReference] | *[]
	podAnnotations: {[string]: string} | *{}
	podSecurityContext?:  corev1.#PodSecurityContext
	priorityClassName:    *"" | string
	replicaCount:         *1 | int & >=0
	revisionHistoryLimit: *10 | int & >=0
	resources?:           timoniv1.#ResourceRequirements
	securityContext?:     corev1.#SecurityContext
	serviceAccount: {
		create: *true | bool
		annotations: {[string]: string} | *{}
		name: *"" | string
	}
	service: {
		type: *"ClusterIP" | string
		port: *3000 | int & >0
	}
	route: {
		main: {
			enabled:    *false | bool
			apiVersion: *"gateway.networking.k8s.io/v1" | string
			kind:       *"HTTPRoute" | string
			annotations?: {[string]: string}
			labels?: {[string]: string}
			hostnames?: [...string]
			parentRefs?: [...{name: string, namespace?: string}] | *[]
			matches: [...{
				path?: {
					type?:  string
					value?: string
				}
			}] | *[{path: {type: "PathPrefix", value: "/"}}]
			filters?: [...]
			additionalRules?: [...]
			httpsRedirect: *false | bool
			timeouts?: {...}
		}
	}
	autoscaling: {
		enabled:                            *false | bool
		minReplicas:                        *1 | int & >=1
		maxReplicas:                        *100 | int & >=1
		targetCPUUtilizationPercentage?:    int & >=1
		targetMemoryUtilizationPercentage?: int & >=1
	}
	livenessProbe: {
		initialDelaySeconds: *5 | int & >=0
		periodSeconds:       *5 | int & >=1
		successThreshold:    *1 | int & >=1
		timeoutSeconds:      *1 | int & >=1
	}
	readinessProbe: {
		initialDelaySeconds: *5 | int & >=0
		periodSeconds:       *5 | int & >=1
		successThreshold:    *1 | int & >=1
		timeoutSeconds:      *1 | int & >=1
	}
	nodeSelector: {[string]: string} | *{}
	tolerations: [...corev1.#Toleration] | *[]
	affinity?: corev1.#Affinity
	selectorLabels: {[string]: string} | *{}
	extraEnv: [...corev1.#EnvVar] | *[]
	config: {
		additionalModules:            *"" | string
		disablePublicUrlCheck:        *"" | string
		disableGoogleDocsFilePreview: *"" | string
		downloadFileViaXhr:           *"0" | string
	}
}

#BackendComponent: {
	image: {
		registry:   *"docker.io" | string
		repository: *"baserow/backend" | string
		pullPolicy: *"Always" | "IfNotPresent" | "Never"
		tag:        *"2.2.2" | string
	}
	imagePullSecrets: [...timoniv1.#ObjectReference] | *[]
	podAnnotations: {[string]: string} | *{}
	podSecurityContext?:  corev1.#PodSecurityContext
	priorityClassName:    *"" | string
	replicaCount:         *1 | int & >=0
	revisionHistoryLimit: *10 | int & >=0
	resources?:           timoniv1.#ResourceRequirements
	securityContext?:     corev1.#SecurityContext
	serviceAccount: {
		create: *true | bool
		annotations: {[string]: string} | *{}
		name: *"" | string
	}
	service?: {
		type: *"ClusterIP" | string
		port: *8000 | int & >0
	}
	route?: [string]: {
		enabled:    *false | bool
		apiVersion: *"gateway.networking.k8s.io/v1" | string
		kind:       *"HTTPRoute" | string
		annotations?: {[string]: string}
		labels?: {[string]: string}
		hostnames?: [...string]
		parentRefs?: [...{name: string, namespace?: string}] | *[]
		matches: [...{
			path?: {
				type?:  string
				value?: string
			}
		}] | *[{path: {type: "PathPrefix", value: "/"}}]
		filters?: [...]
		additionalRules?: [...]
		httpsRedirect: *false | bool
		timeouts?: {...}
	}
	autoscaling: {
		enabled:                            *false | bool
		minReplicas:                        *1 | int & >=1
		maxReplicas:                        *100 | int & >=1
		targetCPUUtilizationPercentage?:    int & >=1
		targetMemoryUtilizationPercentage?: int & >=1
	}
	livenessProbe?: {
		failureThreshold?:    int
		initialDelaySeconds?: int
		periodSeconds?:       int
		successThreshold?:    int
		timeoutSeconds?:      int
	}
	readinessProbe?: {
		failureThreshold?:    int
		initialDelaySeconds?: int
		periodSeconds?:       int
		successThreshold?:    int
		timeoutSeconds?:      int
	}
	nodeSelector: {[string]: string} | *{}
	tolerations: [...corev1.#Toleration] | *[]
	affinity?: corev1.#Affinity
	selectorLabels: {[string]: string} | *{}
	extraEnv: [...corev1.#EnvVar] | *[]
	config?: {[string]: string}
}

#CeleryFlowerConfig: {
	enabled: *false | bool
	image: {
		registry:   *"docker.io" | string
		repository: *"baserow/backend" | string
		pullPolicy: *"Always" | "IfNotPresent" | "Never"
		tag:        *"2.2.2" | string
	}
	imagePullSecrets: [...timoniv1.#ObjectReference] | *[]
	podAnnotations: {[string]: string} | *{}
	podSecurityContext?:  corev1.#PodSecurityContext
	priorityClassName:    *"" | string
	replicaCount:         *1 | int & >=0
	revisionHistoryLimit: *10 | int & >=0
	resources?:           timoniv1.#ResourceRequirements
	securityContext?:     corev1.#SecurityContext
	serviceAccount: {
		create: *true | bool
		annotations: {[string]: string} | *{}
		name: *"" | string
	}
	service: {
		type:       *"ClusterIP" | string
		port:       *5555 | int & >0
		targetPort: *5555 | int & >0
	}
	nodeSelector: {[string]: string} | *{}
	tolerations: [...corev1.#Toleration] | *[]
	affinity?: corev1.#Affinity
	selectorLabels: {[string]: string} | *{}
	extraEnv: [...corev1.#EnvVar] | *[]
}

#BackendConfig: {
	asgi:   #BackendComponent
	celery: {
		worker:       #BackendComponent
		exportWorker: #BackendComponent
		beatWorker:   #BackendComponent
		flower:       #CeleryFlowerConfig
	}
	wsgi:   #BackendComponent
	config?: {[string]: _}
	persistence: {
		enabled: *false | bool
		accessModes: [...string] | *["ReadWriteOnce"]
		annotations: {[string]: string} | *{}
		existingClaim:    *"" | string
		storageClassName: *"" | string
		resources?:       corev1.#VolumeResourceRequirements | *{
			requests: {
				storage: *"8Gi" | string
			}
		}
	}
}

#MigrationConfig: {
	enabled: *true | bool
	image: {
		registry:   *"docker.io" | string
		repository: *"baserow/backend" | string
		pullPolicy: *"Always" | "IfNotPresent" | "Never"
		tag:        *"2.3.3" | string
	}
	imagePullSecrets: [...timoniv1.#ObjectReference] | *[]
	priorityClassName:    *"" | string
	nodeSelector: {[string]: string} | *{}
	tolerations: [...corev1.#Toleration] | *[]
	affinity?: corev1.#Affinity
	extraEnv: [...corev1.#EnvVar] | *[]
	envFrom: [...corev1.#EnvFromSource] | *[]
	volumes: [...corev1.#Volume] | *[]
	volumeMounts: [...corev1.#VolumeMount] | *[]
	securityContext: {
		enabled: *false | bool
		fsGroupChangePolicy: *"" | string
		sysctls: *"" | string
		supplementalGroups: *"" | string
		fsGroup: *"" | string | int
	}
	containerSecurityContext: {
		enabled: *false | bool
		seLinuxOptions: {[string]: string} | *{}
		runAsUser: *"" | string | int
		runAsGroup: *"" | string | int
		runAsNonRoot: *"" | string | bool
		privileged: *false | bool
		readOnlyRootFilesystem: *false | bool
		allowPrivilegeEscalation: *false | bool
		capabilities: {
			add: [...string] | *[]
			drop: [...string] | *[]
		}
		seccompProfile: {
			type: *"" | string
		}
	}
}

#GeneralConfig: {
	maxImportFileSizeMb:  *"512" | string
	maxSnapshotsPerGroup: *"-1" | string
}

#PostgresqlConfig: {
	enabled: *true | bool
	image: {
		registry:   *"docker.io" | string
		repository: *"postgres" | string
		tag:        *"18.6" | string
	}
	auth: {
		database:       *"baserow" | string
		existingSecret: *"" | string
		password:       *"baserow" | string
		username:       *"baserow" | string
	}
	resources?: corev1.#ResourceRequirements
	podSecurityContext?:  corev1.#PodSecurityContext
	securityContext?:     corev1.#SecurityContext
	persistence: {
		enabled: *false | bool
		accessModes: [...string] | *["ReadWriteOnce"]
		annotations: {[string]: string} | *{}
		existingClaim:    *"" | string
		storageClassName: *"" | string
		resources?:       corev1.#VolumeResourceRequirements | *{
			requests: {
				storage: *"8Gi" | string
			}
		}
	}
}

#ExternalPostgresqlConfig: {
	auth: {
		database:        *"baserow" | string
		existingSecret:  *"" | string
		password:        *"baserow" | string
		username:        *"baserow" | string
		userPasswordKey: *"" | string
		userUsernameKey: *"" | string
	}
	hostname: *"" | string
	port:     *5432 | int
}

#RedisConfig: {
	enabled:      *true | bool
	architecture: *"standalone" | string
	image: {
		registry:   *"docker.io" | string
		repository: *"redis" | string
		tag:        *"8.8" | string
	}
	auth: {
		enabled:  *true | bool
		password: *"baserow" | string
	}
	resources?: corev1.#ResourceRequirements
	podSecurityContext?:  corev1.#PodSecurityContext
	securityContext?:     corev1.#SecurityContext
	persistence: {
		enabled: *false | bool
		accessModes: [...string] | *["ReadWriteOnce"]
		annotations: {[string]: string} | *{}
		existingClaim:    *"" | string
		storageClassName: *"" | string
		resources?:       corev1.#VolumeResourceRequirements | *{
			requests: {
				storage: *"8Gi" | string
			}
		}
	}
}

#ExternalRedisConfig: {
	auth: {
		enabled:         *true | bool
		existingSecret:  *"" | string
		password:        *"" | string
		userPasswordKey: *"" | string
	}
	hostname: *"" | string
	port:     *6379 | int
}

#MinioConfig: {
	enabled:      *true | bool
	image: {
		registry:   *"docker.io" | string
		repository: *"minio/minio" | string
		tag:        *"latest" | string
	}
	auth: {
		rootUser: *"minioadmin" | string
		rootPassword: *"minioadmin" | string
	}
	service: {
		type: *"ClusterIP" | string
		port: *9000 | int
		consolePort: *9001 | int
		nodePort?: int
		consoleNodePort?: int
		clusterIP?: string
		externalTrafficPolicy?: string
		loadBalancerIP?: string
		loadBalancerSourceRanges?: [...string]
	}
	resources?: corev1.#ResourceRequirements
	podSecurityContext?:  corev1.#PodSecurityContext
	securityContext?:     corev1.#SecurityContext
	persistence: {
		enabled: *false | bool
		accessModes: [...string] | *["ReadWriteOnce"]
		annotations: {[string]: string} | *{}
		existingClaim:    *"" | string
		storageClassName: *"" | string
		resources?:       corev1.#VolumeResourceRequirements | *{
			requests: {
				storage: *"8Gi" | string
			}
		}
	}
}



#CaddyConfig: {
	enabled: *true | bool
	image: {
		registry:   *"docker.io" | string
		repository: *"caddy" | string
		tag:        *"2.8" | string
	}
	resources?: corev1.#ResourceRequirements
}

#EmbeddingsConfig: {
	enabled: *false | bool
	image: {
		registry:   *"docker.io" | string
		repository: *"baserow/embeddings" | string
		pullPolicy: *"Always" | "IfNotPresent" | "Never"
		tag:        *"2.3.3" | string
	}
	imagePullSecrets: [...timoniv1.#ObjectReference] | *[]
	podAnnotations: {[string]: string} | *{}
	podSecurityContext?:  corev1.#PodSecurityContext
	priorityClassName:    *"" | string
	replicaCount:         *1 | int & >=0
	revisionHistoryLimit: *10 | int & >=0
	resources:            corev1.#ResourceRequirements | *{
		requests: {
			cpu:    "800m"
			memory: "1536Mi"
		}
		limits: {
			cpu:    "1000m"
			memory: "1536Mi"
		}
	}
	securityContext?:     corev1.#SecurityContext
	nodeSelector: {[string]: string} | *{}
	tolerations: [...corev1.#Toleration] | *[]
	affinity?: corev1.#Affinity
	extraEnv: [...corev1.#EnvVar] | *[]
	service: {
		type:       *"ClusterIP" | "NodePort" | "LoadBalancer"
		port:       *80 | int
		targetPort: *80 | int
	}
	serviceAccount: {
		create: *true | bool
		name:   *"" | string
		annotations: {[string]: string} | *{}
	}
	livenessProbe?: {
		initialDelaySeconds: *10 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		successThreshold:    *1 | int
		failureThreshold:    *3 | int
	}
	readinessProbe?: {
		initialDelaySeconds: *10 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		successThreshold:    *1 | int
		failureThreshold:    *3 | int
	}
	autoscaling: {
		enabled:                            *false | bool
		minReplicas:                        *1 | int & >=1
		maxReplicas:                        *3 | int & >=1
		targetCPUUtilizationPercentage?:    int & >=1
		targetMemoryUtilizationPercentage?: int & >=1
	}
}

#Instance: {
	config: #Config

	objects: {
		cmGeneral: #ConfigMapGeneral & {#config: config}

		// Frontend Components
		if config.frontend.serviceAccount.create {
			saFrontend: #ServiceAccountFrontend & {#config: config}
		}
		svcFrontend: #ServiceFrontend & {#config: config}
		deployFrontend: #DeploymentFrontend & {#config: config}
		if config.frontend.route != _|_ {
			for routeName, routeConfig in config.frontend.route {
				if routeConfig.enabled {
					"routeFrontend-\(routeName)": #RouteFrontend & {
						#config:      config
						#routeName:   routeName
						#routeConfig: routeConfig
					}
				}
			}
		}
		if config.frontend.autoscaling.enabled {
			hpaFrontend: #HpaFrontend & {#config: config}
		}

		// Backend WSGI Components
		if config.backend.wsgi.serviceAccount.create {
			saWsgi: #ServiceAccountWsgi & {#config: config}
		}
		svcWsgi: #ServiceWsgi & {#config: config}
		deployWsgi: #DeploymentWsgi & {#config: config}
		if config.backend.wsgi.route != _|_ {
			for routeName, routeConfig in config.backend.wsgi.route {
				if routeConfig.enabled {
					"routeWsgi-\(routeName)": #RouteWsgi & {
						#config:      config
						#routeName:   routeName
						#routeConfig: routeConfig
					}
				}
			}
		}
		if config.backend.wsgi.autoscaling.enabled {
			hpaWsgi: #HpaWsgi & {#config: config}
		}

		// Backend ASGI Components
		if config.backend.asgi.serviceAccount.create {
			saAsgi: #ServiceAccountAsgi & {#config: config}
		}
		svcAsgi: #ServiceAsgi & {#config: config}
		deployAsgi: #DeploymentAsgi & {#config: config}
		if config.backend.asgi.route != _|_ {
			for routeName, routeConfig in config.backend.asgi.route {
				if routeConfig.enabled {
					"routeAsgi-\(routeName)": #RouteAsgi & {
						#config:      config
						#routeName:   routeName
						#routeConfig: routeConfig
					}
				}
			}
		}
		if config.backend.asgi.autoscaling.enabled {
			hpaAsgi: #HpaAsgi & {#config: config}
		}

		// Celery Components
		if config.backend.celery.worker.serviceAccount.create {
			saCelery: #ServiceAccountCelery & {#config: config}
		}
		deployCeleryWorker: #DeploymentCeleryWorker & {#config: config}
		deployCeleryExportWorker: #DeploymentCeleryExportWorker & {#config: config}
		deployCeleryBeatWorker: #DeploymentCeleryBeatWorker & {#config: config}
		if config.backend.celery.flower.enabled {
			svcCeleryFlower: #ServiceCeleryFlower & {#config: config}
			deployCeleryFlower: #DeploymentCeleryFlower & {#config: config}
		}
		if config.backend.celery.worker.autoscaling.enabled {
			hpaCelery: #HpaCelery & {#config: config}
		}

		// Shared Configs and PVCs
		cmFrontend: #ConfigMapFrontend & {#config: config}
		cmBackend: #ConfigMapBackend & {#config: config}
		secretBackend: #SecretBackend & {#config: config}
		if config.backend.config.email.smtp != _|_ {
			secretEmail: #SecretEmail & {#config: config}
		}
		if config.backend.config.aws.accessKeyId != _|_ || config.backend.config.aws.existingSecret != _|_ {
			secretAws: #SecretAwsBackend & {#config: config}
		}
		if config.backend.persistence.enabled {
			pvcBackend: #PvcBackend & {#config: config}
		}

		// Database Components
		if config.postgresql.enabled {
			postgresqlSa:     #PostgresqlServiceAccount & {#config: config}
			postgresqlSecret: #PostgresqlSecret & {#config: config}
			postgresqlSvc:    #PostgresqlService & {#config: config}
			postgresqlHlSvc:  #PostgresqlHeadlessService & {#config: config}
			postgresqlSts:    #PostgresqlStatefulSet & {#config: config}
		}
		if config.redis.enabled {
			redisSa:          #RedisServiceAccount & {#config: config}
			redisSecret:      #RedisSecret & {#config: config}
			redisSvc:         #RedisService & {#config: config}
			redisHeadlessSvc: #RedisHeadlessService & {#config: config}
			redisSts:         #RedisStatefulSet & {#config: config}
		}
		if config.minio.enabled {
			minioSa:      #MinioServiceAccount & {#config: config}
			minioSecret:  #MinioSecret & {#config: config}
			minioSvc:     #MinioService & {#config: config}
			minioSts:     #MinioStatefulSet & {#config: config}
			minioProvJob: #MinioProvisioningJob & {#config: config}
		}
		if config.caddy.enabled {
			caddySa:     #CaddyServiceAccount & {#config: config}
			caddyCm:     #CaddyConfigMap & {#config: config}
			caddySvc:    #CaddyService & {#config: config}
			caddyDeploy: #CaddyDeployment & {#config: config}
		}
		if config.embeddings.enabled {
			if config.embeddings.serviceAccount.create {
				saEmbeddings: #ServiceAccountEmbeddings & {#config: config}
			}
			svcEmbeddings: #ServiceEmbeddings & {#config: config}
			deployEmbeddings: #DeploymentEmbeddings & {#config: config}
		}
		migrationJob: #BackendMigrationJob & {#config: config}

	}
}
