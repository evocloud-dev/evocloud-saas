package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Config: {
	// Cluster and Module info
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}
	moduleVersion!: string

	// Metadata
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	// Replicas & runtimeClass
	replicas: *1 | int & >0
	runtimeClassName?: string

	// Image mirroring values.yaml
	image: timoniv1.#Image & {
		repository: *"docker.io/nocodb/nocodb" | string
		tag:        *"0.301.5" | string
		digest:     *"sha256:d9516f0bf546fd6c78a382ab0657626c683fca7aaafdbbe53c66baf15df7fc0d" | string
		pullPolicy: *"IfNotPresent" | string
	}

	// Security context mirroring values.yaml
	securityContext: {
		container: corev1.#SecurityContext & {
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *false | bool
			runAsUser:                *0 | int
			runAsGroup:               *0 | int
			allowPrivilegeEscalation: *false | bool
			privileged:               *false | bool
			seccompProfile: {
				type: *"RuntimeDefault" | string
			}
			capabilities: {
				add:  *["CHOWN", "SETUID", "SETGID", "FOWNER", "DAC_OVERRIDE"] | [...string]
				drop: *["ALL"] | [...string]
			}
		}
		pod: corev1.#PodSecurityContext & {
			fsGroup:             *568 | int
			fsGroupChangePolicy: *"OnRootMismatch" | string
			supplementalGroups:  *[568] | [...int]
			sysctls:             *[] | [...corev1.#Sysctl]
		}
	}

	// Workload mirroring values.yaml
	workload: main: podSpec: containers: main: {
		probes: {
			liveness: path: *"/dashboard" | string
			readiness: path: *"/dashboard" | string
			startup: path: *"/dashboard" | string
		}
		env: {
			PORT:                  *service.main.ports.main.port | int
			NC_PUBLIC_URL:         *"http://localhost:10226" | string
			NC_DISABLE_TELE:       *true | bool
			DISABLE_SPLASH_SCREEN: *false | bool
			NC_JWT_EXPIRES_IN:     *"10h" | string
			NC_INVITE_ONLY_SIGNUP: *false | bool
			NC_DISABLE_CACHE:      *false | bool
			NC_DISABLE_ERR_REPORT: *true | bool
			NC_REQUEST_BODY_SIZE:  *"1MB" | string
			NC_EXPORT_MAX_TIMEOUT: *5000 | int
			NC_SENTRY_DSN:         *"" | string
			NC_AUTH_JWT_SECRET:    *"cDmjQ89jBhdccMGjDqMegQvl4BbsZ7v9" | string
			AWS_ACCESS_KEY_ID:     *"" | string
			AWS_SECRET_ACCESS_KEY: *"" | string
			AWS_BUCKET:            *"" | string
			AWS_BUCKET_PATH:       *"" | string
		}
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"75m" | timoniv1.#CPUQuantity
				memory: *"200Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"1500m" | timoniv1.#CPUQuantity
				memory: *"2400Mi" | timoniv1.#MemoryQuantity
			}
		}
	}

	// Service mirroring values.yaml
	service: main: ports: main: {
		port: *10226 | int & >0 & <=65535
	}

	// Persistence mirroring values.yaml
	persistence: data: {
		enabled:     *true | bool
		mountPath:   *"/usr/app/data" | string
		storage:     *"100Gi" | string
		accessModes: *["ReadWriteOnce"] | [...string]
	}

	// CloudNative-PG 
	cnpg: main: {
		enabled:     *true | bool
		user:        *"nocodb" | string
		database:    *"nocodb" | string
		password:    *"PLACEHOLDERPASSWORD" | string
		instances:   *2 | int & >0
		storage:     *"100Gi" | string
		image: timoniv1.#Image & {
			repository: *"ghcr.io/cloudnative-pg/postgresql" | string
			tag:        *"16.15" | string
			digest:     *"sha256:34cd4159d07b3410a1b29da35072e2e927a0905e717a61afa3814624a2e8859a" | string
		}
		securityContext: {
			container: {
				runAsUser:  *26 | int
				runAsGroup: *26 | int
			}
		}
		postgresUID: *securityContext.container.runAsUser | int
		postgresGID: *securityContext.container.runAsGroup | int
		clientImage: *"oci.trueforge.org/containerforge/postgresql-client:9.6.24@sha256:d40ff61568601b7032a7e6892ca08e55f772d24b32a053d1c0c6b45a2c01ae93" | string
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"75m" | timoniv1.#CPUQuantity
				memory: *"200Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"1500m" | timoniv1.#CPUQuantity
				memory: *"2400Mi" | timoniv1.#MemoryQuantity
			}
		}
	}

	// Redis mirroring values.yaml
	redis: {
		enabled:       *true | bool
		redisUsername: *"default" | string
		password:      *"PLACEHOLDERPASSWORD" | string
		port:          *6379 | int & >0 & <=65535
		image:         timoniv1.#Image & {
			repository: *"docker.io/bitnamisecure/valkey" | string
			tag:        *"latest" | string
			digest:     *"sha256:a442c1984446caac0a8df531272bf05d64517d855eb0738df67fedb8e9be6371" | string
			pullPolicy: *"IfNotPresent" | string
		}
		toolsImage:    *"oci.trueforge.org/containerforge/valkey-tools:1.1.0@sha256:cd85086b5d1faccfff68407791efeee843d4ea5ae4538e0a73cd68d607558d8a" | string
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"75m" | timoniv1.#CPUQuantity
				memory: *"200Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"1500m" | timoniv1.#CPUQuantity
				memory: *"2400Mi" | timoniv1.#MemoryQuantity
			}
		}
		securityContext: {
			container: corev1.#SecurityContext & {
				readOnlyRootFilesystem:   *false | bool
				runAsNonRoot:             *false | bool
				runAsUser:                *568 | int
				runAsGroup:               *0 | int
				allowPrivilegeEscalation: *false | bool
				privileged:               *false | bool
				seccompProfile: {
					type: *"RuntimeDefault" | string
				}
				capabilities: {
					add:  *[] | [...string]
					drop: *["ALL"] | [...string]
				}
			}
		}
	}

	// Init containers configuration
	initResources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"10m" | timoniv1.#CPUQuantity
			memory: *"50Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			cpu:    *"500m" | timoniv1.#CPUQuantity
			memory: *"512Mi" | timoniv1.#MemoryQuantity
		}
	}

	initSecurityContext: corev1.#SecurityContext & {
		runAsNonRoot:             *true | bool
		runAsUser:                *568 | int
		runAsGroup:               *568 | int
		readOnlyRootFilesystem:   *true | bool
		allowPrivilegeEscalation: *false | bool
		privileged:               *false | bool
		seccompProfile: {
			type: *"RuntimeDefault" | string
		}
		capabilities: {
			add:  *[] | [...string]
			drop: *["ALL"] | [...string]
		}
	}
	// Gateway API settings
	#HTTPRouteParentRef: {
		name!:       string
		group:       *"" | string
		kind:        *"" | string
		namespace:   *"" | string
		sectionName: *"" | string
		port:        *0 | int
	}

	#HTTPRouteRule: {
		matches?: [...]
		filters?: [...]
		backendRefs?: [...]
		omitDefaultBackend: *false | bool
	}

	#HTTPRouteItem: {
		name: *"" | string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		parentRefs!: [...#HTTPRouteParentRef] & [_, ...]
		hostnames: *[] | [...string]
		rules: *[] | [...#HTTPRouteRule]
	}

	gatewayAPI: {
		enabled:          *false | bool
		gatewayClassName: *"" | string
		httpRoutes: *[] | [...#HTTPRouteItem]
	}
}

#Instance: {
	config: #Config

	objects: {
		cnpgUrlsSecret:   #CnpgUrlsSecret & {#config: config}
		cnpgUserSecret:   #CnpgUserSecret & {#config: config}
		redisCredsSecret: #RedisCredsSecret & {#config: config}
		nocodbSecrets:    #NocodbSecrets & {#config: config}
		redisHealthCm:    #RedisHealthConfigMap & {#config: config}
		nocodbCm:         #NocodbConfigMap & {#config: config}
		if config.persistence.data.enabled {
			dataPvc: #DataPVC & {#config: config}
		}
		redisSvc:         #RedisService & {#config: config}
		nocodbSvc:        #NocodbService & {#config: config}
		if config.gatewayAPI.enabled {
			for i, r in config.gatewayAPI.httpRoutes {
				"httproute-\(i)": #HTTPRoute & {
					#config: config
					#route:  r
					#index:  i
				}
			}
		}
		nocodbDeploy:     #NocodbDeployment & {#config: config}
		redisStatefulSet: #RedisStatefulSet & {#config: config}
		cnpgCluster:      #CnpgCluster & {#config: config}
	}
}
