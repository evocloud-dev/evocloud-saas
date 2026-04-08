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


	fullnameOverride: *"" | string
	nameOverride:     *"" | string

	_image: image
	image: {
		repository: *"twentycrm/twenty" | string
		tag:        *"v1.19.1" | string
		pullPolicy: *"IfNotPresent" | string
	}

	// Global security context
	securityContext: {
		runAsUser: *1000 | int
		fsGroup:   *1000 | int
	}

	// Storage configuration
	storage: {
		type: *"local" | "s3"
		s3?: {
			bucket:          string
			region:          string
			endpoint:        string
			accessKeyId:     string
			secretAccessKey: string
		}
	}

	// Authentication secrets
	secrets: {
		tokens: {
			create:      *true | bool
			name:        *"tokens" | string
			accessToken: *"" | string
		}
	}

	// Utility images
	utilityImages: {
		postgres: *"postgres:16-alpine" | string
	}

	// Strategy schema
	#Strategy: {
		type: string
		rollingUpdate?: {
			maxSurge:       *1 | int | string
			maxUnavailable: *1 | int | string
		}
	}
	server: {
		enabled:      *true | bool
		replicaCount: *1 | int & >0
		image: {
			repository: *_image.repository | string
			tag:        *_image.tag | string
			pullPolicy: *_image.pullPolicy | string
			reference:  *"\(repository):\(tag)" | string
		}
		strategy: #Strategy & {
			type: *"RollingUpdate" | string
		}
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"250m" | timoniv1.#CPUQuantity
				memory: *"256Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"1000m" | timoniv1.#CPUQuantity
				memory: *"1Gi" | timoniv1.#MemoryQuantity
			}
		}
		env: {
			SERVER_URL:                                     *"http://localhost:8080" | string
			FRONTEND_URL:                                   *"http://localhost:8080" | string
			SIGN_IN_PREFILLED:                              *"false" | string
			ACCESS_TOKEN_EXPIRES_IN:                        *"7d" | string
			LOGIN_TOKEN_EXPIRES_IN:                         *"1h" | string
			API_RATE_LIMITING_SHORT_LIMIT:                  *100 | int
			API_RATE_LIMITING_SHORT_TTL_IN_MS:              *1000 | int
			IS_MULTIWORKSPACE_ENABLED:                      *"false" | string
			DEFAULT_SUBDOMAIN:                              *"app" | string
			IS_WORKSPACE_CREATION_LIMITED_TO_SERVER_ADMINS: *"true" | string
		}
		service: {
			type: *"ClusterIP" | "NodePort" | "LoadBalancer"
			port: *3000 | int & >0 & <=65535
		}
		ingress: {
			enabled:   *false | bool
			className: *"nginx" | string
			acme:      *false | bool
			annotations: timoniv1.#Annotations | *{}
			hosts: [...{
				host: string
				paths: [...{
					path:     *"/" | string
					pathType: *"Prefix" | string
				}]
			}]
			tls: [...{
				secretName: string
				hosts: [...string]
			}]
		}
		persistence: {
			enabled:      *true | bool
			size:         *"10Gi" | timoniv1.#Capacity
			storageClass: *"" | string
			accessModes:  *["ReadWriteOnce"] | [...string]
			existingClaim: *"" | string
		}
		dockerDataPersistence: {
			enabled:      *true | bool
			size:         *"100Mi" | timoniv1.#Capacity
			storageClass: *"" | string
			accessModes:  *["ReadWriteOnce"] | [...string]
			existingClaim: *"" | string
		}
		stdin:        *true | bool
		tty:          *true | bool
		extraVolumeMounts: [...corev1.#VolumeMount]
	}

	// Worker component
	worker: {
		enabled:      *true | bool
		replicaCount: *1 | int & >0
		image: {
			repository: *_image.repository | string
			tag:        *_image.tag | string
			pullPolicy: *_image.pullPolicy | string
			reference:  *"\(repository):\(tag)" | string
		}
		strategy: #Strategy & {
			type: *"RollingUpdate" | string
		}
		command:  *["yarn", "worker:prod"] | [...string]
		stdin:    *true | bool
		tty:      *true | bool
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"250m" | timoniv1.#CPUQuantity
				memory: *"1Gi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"1000m" | timoniv1.#CPUQuantity
				memory: *"2Gi" | timoniv1.#MemoryQuantity
			}
		}
	}

	// Database configuration
	db: {
		enabled: *true | bool
		internal: {
			enabled:  *true | bool
			database: *"twenty" | string
			appUser:  *"twenty_app_user" | string
			appPassword: *"twenty" | string
			strategy: #Strategy & {
				type: *"Recreate" | string
			}
			image: {
				repository: *"ghcr.io/zalando/spilo-16" | string
				tag:        *"3.3-p2" | string
				pullPolicy: *"IfNotPresent" | string
				reference:  *"\(repository):\(tag)" | string
			}
			resources: timoniv1.#ResourceRequirements & {
				requests: {
					cpu:    *"250m" | timoniv1.#CPUQuantity
					memory: *"256Mi" | timoniv1.#MemoryQuantity
				}
				limits: {
					cpu:    *"1000m" | timoniv1.#CPUQuantity
					memory: *"1Gi" | timoniv1.#MemoryQuantity
				}
			}
			persistence: {
				enabled:      *true | bool
				size:         *"10Gi" | timoniv1.#Capacity
				storageClass: *"" | string
				accessModes:  *["ReadWriteOnce"] | [...string]
				existingClaim: *"" | string
			}
			env: {
				PGUSER_SUPERUSER:     *"postgres" | string
				PGPASSWORD_SUPERUSER: *"postgres" | string
				SPILO_PROVIDER:       *"local" | string
				ALLOW_NOSSL:           *"true" | string
			}
		}
		external?: {
			host:        string
			port:        *5432 | int
			user:        string
			password:    string
			database:    "twenty"
			ssl:         *false | bool
			secretName:  string
			passwordKey: string
		}
	}

	// Redis configuration
	redis: {
		internal: {
			enabled: *true | bool
			strategy: #Strategy & {
				type: *"Recreate" | "RollingUpdate"
			}
			image: {
				repository: *"redis/redis-stack-server" | string
				tag:        *"7.2.0-v10" | string
				pullPolicy: *"IfNotPresent" | string
				reference:  *"\(repository):\(tag)" | string
			}
			resources: timoniv1.#ResourceRequirements & {
				requests: {
					cpu:    *"250m" | timoniv1.#CPUQuantity
					memory: *"1Gi" | timoniv1.#MemoryQuantity
				}
				limits: {
					cpu:    *"500m" | timoniv1.#CPUQuantity
					memory: *"2Gi" | timoniv1.#MemoryQuantity
				}
			}
			service: {
				port: *6379 | int & >0 & <=65535
			}
			persistence: {
				enabled:      *false | bool
				size:         *"1Gi" | timoniv1.#Capacity
				storageClass: *"" | string
				accessModes:  *["ReadWriteOnce"] | [...string]
				existingClaim: *"" | string
			}
		}
		external?: {
			host:     string
			port:     *6379 | int
			password: *"" | string
		}
	}
	// Test configuration
	test: {
		enabled: *false | bool
	}
}



// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		[string]: metadata: namespace: config.metadata.namespace

		if config.server.enabled {
			"server-deploy": #ServerDeployment & {#config: config}
			"server-svc":    #ServerService & {#config: config}
			if config.server.persistence.enabled && config.server.persistence.existingClaim == "" {
				"server-pvc": #ServerPVC & {#config: config}
			}
			if config.server.dockerDataPersistence.enabled && config.server.dockerDataPersistence.existingClaim == "" {
				"server-docker-pvc": #ServerDockerPVC & {#config: config}
			}
			if config.server.ingress.enabled {
				"server-ingress": #ServerIngress & {#config: config}
			}
		}

		if config.worker.enabled {
			"worker-deploy": #WorkerDeployment & {#config: config}
		}

		if config.db.enabled && config.db.internal.enabled {
			"db-deploy": #DatabaseDeployment & {#config: config}
			"db-svc":    #DatabaseService & {#config: config}
			if config.db.internal.persistence.enabled && config.db.internal.persistence.existingClaim == "" {
				"db-pvc": #DatabasePVC & {#config: config}
			}
			"db-url-secret": #DbUrlSecret & {#config: config}
			"db-superuser-secret": #DbSuperuserSecret & {#config: config}
		}

		if config.redis.internal.enabled {
			"redis-deploy": #RedisDeployment & {#config: config}
			"redis-svc":    #RedisService & {#config: config}
			if config.redis.internal.persistence.enabled && config.redis.internal.persistence.existingClaim == "" {
				"redis-pvc": #RedisPVC & {#config: config}
			}
		}

		if config.secrets.tokens.create {
			"tokens-secret": #TokensSecret & {#config: config}
		}
	}
}