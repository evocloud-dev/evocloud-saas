package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Autoscaling: {
	enabled:                            *false | bool
	minReplicas:                        *1 | int & >0
	maxReplicas:                        *5 | int & >0
	targetCPUUtilizationPercentage:     *80 | int & >0 & <=100
	targetMemoryUtilizationPercentage?: int & >0 & <=100
}

#GatewayAPI: {
	enabled:          *false | bool
	gatewayClassName: *"" | string
	httpRoutes:       *[...] | [...#HTTPRouteConfig]
}

#HTTPRouteConfig: {
	name:         *"" | string
	labels:       *{[string]: string} | {[string]: string}
	annotations:  *{[string]: string} | {[string]: string}
	parentRefs?: [...{
		name:         string
		namespace?:   string
		group?:       string
		kind?:        string
		sectionName?: string
		port?:        int & >0 & <=65535
	}]
	hostnames: *[] | [...string]
	rules:     *[...] | [...]
}

#ServiceConfig: {
	type: *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
	port: int & >0 & <=65535
}

#ServiceAccountConfig: {
	create:      *true | bool
	annotations: *{[string]: string} | {[string]: string}
	name:        *"" | string
}

#Config: {
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}
	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion, name: *"fleetbase" | string}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	serviceAccount: #ServiceAccountConfig
	serviceAccountName: [
		if serviceAccount.name != "" {serviceAccount.name},
		if serviceAccount.create {metadata.name},
		"default",
	][0]

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	let _app = app
	let _httpd = httpd
	let _console = console
	let _socket = socket
	let _database = database
	let _cache = cache

	images: {
		api:      _app.image
		httpd:    _httpd.image
		console:  _console.image
		socket:   _socket.image
		database: _database.image
		cache:    _cache.image
	}

	// Deployment environment (development, staging, production)
	environment: *"development" | string

	app: {
		image:    timoniv1.#Image
		replicas: *1 | int & >0
		port:     *8000 | int & >0 & <=65535
		autoscaling: #Autoscaling
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"100m" | timoniv1.#CPUQuantity
				memory: *"256Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"1000m" | timoniv1.#CPUQuantity
				memory: *"1Gi" | timoniv1.#MemoryQuantity
			}
		}
		persistence: {
			enabled:       *false | bool
			size:          *"10Gi" | string
			storageClass?: string
			accessModes:   *["ReadWriteOnce"] | [...string]
		}
		key:              *"base64:hyts2W3knDncDxQ0gRgf8cCGHRTgGyZh0RoAEhCr1kQ=" | string
		consoleHost:      *"http://localhost:4200" | string
		frontendHosts:    *"http://localhost,http://127.0.0.1,http://localhost:4200,http://127.0.0.1:4200,http://localhost:8080,http://127.0.0.1:8080" | string
		environment:      *"development" | string
		envFileSecretRef?: string
		extraEnv?:  [...corev1.#EnvVar]
		secretRef?: string
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
		service?:            #ServiceConfig
	}

	httpd: {
		image:    timoniv1.#Image
		replicas: *1 | int & >0
		port:     *80 | int & >0 & <=65535
		autoscaling: #Autoscaling
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"20m" | timoniv1.#CPUQuantity
				memory: *"64Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"200m" | timoniv1.#CPUQuantity
				memory: *"256Mi" | timoniv1.#MemoryQuantity
			}
		}
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
		service?:            #ServiceConfig
	}

	console: {
		image:       timoniv1.#Image
		enabled:     *true | bool
		replicas:    *1 | int & >0
		port:        *4200 | int & >0 & <=65535
		apiHost:     *"http://localhost:8000" | string
		socketHost?: string
		socketPort?: int & >0 & <=65535
		autoscaling: #Autoscaling
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"20m" | timoniv1.#CPUQuantity
				memory: *"64Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"200m" | timoniv1.#CPUQuantity
				memory: *"128Mi" | timoniv1.#MemoryQuantity
			}
		}
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
		service?:            #ServiceConfig
	}

	queue: {
		enabled:     *true | bool
		replicas:    *1 | int & >0
		autoscaling: #Autoscaling
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"100m" | timoniv1.#CPUQuantity
				memory: *"256Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"500m" | timoniv1.#CPUQuantity
				memory: *"512Mi" | timoniv1.#MemoryQuantity
			}
		}
		extraEnv?:  [...corev1.#EnvVar]
		secretRef?: string
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
	}

	scheduler: {
		enabled:  *true | bool
		replicas: *1 | int & >0
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"50m" | timoniv1.#CPUQuantity
				memory: *"128Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"200m" | timoniv1.#CPUQuantity
				memory: *"256Mi" | timoniv1.#MemoryQuantity
			}
		}
		extraEnv?:  [...corev1.#EnvVar]
		secretRef?: string
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
	}

	socket: {
		image:       timoniv1.#Image
		enabled:     *true | bool
		replicas:    *1 | int & >0
		port:        *8000 | int & >0 & <=65535
		workers:     *10 | int & >0
		brokers:     *10 | int & >0
		options:     *"{\"origins\":\"http://localhost:*,https://localhost:*,ws://localhost:*,wss://localhost:*\"}" | string
		autoscaling: #Autoscaling
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"50m" | timoniv1.#CPUQuantity
				memory: *"128Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"500m" | timoniv1.#CPUQuantity
				memory: *"512Mi" | timoniv1.#MemoryQuantity
			}
		}
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
		service?:            #ServiceConfig
	}

	database: {
		image:               timoniv1.#Image
		enabled:             *true | bool
		name:                *"fleetbase" | string
		user:                *"root" | string
		password:            *"fleetbase" | string
		allowEmptyPassword:  *true | bool
		port:                *3306 | int & >0 & <=65535
		persistence: {
			enabled:       *false | bool
			size:          *"10Gi" | string
			storageClass?: string
		}
		url?: string
		urlSecretRef?: {
			name: string
			key:  string
		}
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"100m" | timoniv1.#CPUQuantity
				memory: *"512Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"1000m" | timoniv1.#CPUQuantity
				memory: *"1Gi" | timoniv1.#MemoryQuantity
			}
		}
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
		service?:            #ServiceConfig
	}

	cache: {
		image:   timoniv1.#Image
		enabled: *true | bool
		port:    *6379 | int & >0 & <=65535
		persistence: {
			enabled:       *false | bool
			size:          *"10Gi" | string
			storageClass?: string
		}
		url?: string
		urlSecretRef?: {
			name: string
			key:  string
		}
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"20m" | timoniv1.#CPUQuantity
				memory: *"64Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"200m" | timoniv1.#CPUQuantity
				memory: *"256Mi" | timoniv1.#MemoryQuantity
			}
		}
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
		service?:            #ServiceConfig
	}

	migration: {
		enabled: *true | bool
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"100m" | timoniv1.#CPUQuantity
				memory: *"256Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"1000m" | timoniv1.#CPUQuantity
				memory: *"1Gi" | timoniv1.#MemoryQuantity
			}
		}
		extraEnv?:  [...corev1.#EnvVar]
		secretRef?: string
		securityContext?: corev1.#SecurityContext
	}

	gatewayAPI: #GatewayAPI

	automountServiceAccountToken: *false | bool

	podAnnotations?: {[string]: string}
	podSecurityContext?: corev1.#PodSecurityContext
	imagePullSecrets?: [...timoniv1.#ObjectReference]
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]

	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}

	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}

	test: {
		enabled: *false | bool
	}
}

#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}

		if config.app.persistence.enabled {
			appStoragePvc: #ApplicationStoragePVC & {#config: config}
		}
		appDeploy: #ApplicationDeployment & {#config: config}
		appSvc:    #ApplicationService & {#config: config}

		httpdCm:     #HttpdConfigMap & {#config: config}
		httpdDeploy: #HttpdDeployment & {#config: config}
		httpdSvc:    #HttpdService & {#config: config}

		if config.queue.enabled {
			queueDeploy: #QueueDeployment & {#config: config}
		}

		if config.scheduler.enabled {
			schedulerDeploy: #SchedulerDeployment & {#config: config}
		}

		if config.console.enabled {
			consoleCm:     #ConsoleConfigMap & {#config: config}
			consoleDeploy: #ConsoleDeployment & {#config: config}
			consoleSvc:    #ConsoleService & {#config: config}
		}

		if config.socket.enabled {
			socketDeploy: #SocketDeployment & {#config: config}
			socketSvc:    #SocketService & {#config: config}
		}

		if config.database.enabled {
			mysqlStatefulSet: #MysqlStatefulSet & {#config: config}
			mysqlSvc:         #MysqlService & {#config: config}
		}

		if config.cache.enabled {
			redisStatefulSet: #RedisStatefulSet & {#config: config}
			redisSvc:         #RedisService & {#config: config}
		}

		if config.migration.enabled {
			migrationJob: #MigrationJob & {#config: config}
		}

		if config.app.autoscaling.enabled {
			appHpa: #HorizontalPodAutoscaler & {
				#config:      config
				#component:   "application"
				#targetName:  objects.appDeploy.metadata.name
				#autoscaling: config.app.autoscaling
			}
		}

		if config.httpd.autoscaling.enabled {
			httpdHpa: #HorizontalPodAutoscaler & {
				#config:      config
				#component:   "httpd"
				#targetName:  objects.httpdDeploy.metadata.name
				#autoscaling: config.httpd.autoscaling
			}
		}

		if config.queue.enabled && config.queue.autoscaling.enabled {
			queueHpa: #HorizontalPodAutoscaler & {
				#config:      config
				#component:   "queue"
				#targetName:  objects.queueDeploy.metadata.name
				#autoscaling: config.queue.autoscaling
			}
		}

		if config.console.enabled && config.console.autoscaling.enabled {
			consoleHpa: #HorizontalPodAutoscaler & {
				#config:      config
				#component:   "console"
				#targetName:  objects.consoleDeploy.metadata.name
				#autoscaling: config.console.autoscaling
			}
		}

		if config.socket.enabled && config.socket.autoscaling.enabled {
			socketHpa: #HorizontalPodAutoscaler & {
				#config:      config
				#component:   "socket"
				#targetName:  objects.socketDeploy.metadata.name
				#autoscaling: config.socket.autoscaling
			}
		}

		if config.gatewayAPI.enabled {
			for i, r in config.gatewayAPI.httpRoutes {
				let routeKey = [
					if r.name != "" {r.name},
					if i > 0 {"httpRoute-\(i)"},
					"httpRoute",
				][0]
				"\(routeKey)": #HTTPRoute & {
					#config: config
					#route:  r
					#index:  i
				}
			}
		}
	}

	tests: {}
}
