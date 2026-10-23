package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// PersistenceVolume defines the schema for a persistent volume mount.
#PersistenceVolume: {
	enabled:        *true | bool
	storageClass?:  string
	accessModes:    *["ReadWriteOnce"] | [...corev1.#PersistentVolumeAccessMode]
	size:           timoniv1.#MemoryQuantity
	existingClaim?: string
	annotations?:   timoniv1.#Annotations
}

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
	metadata: timoniv1.#Metadata & {
		#Version: moduleVersion
		labels: {
			"app.kubernetes.io/instance": metadata.name
		}
	}

	// The labels allows adding `metadata.labels` to all resources.
	// The `app.kubernetes.io/name` and `app.kubernetes.io/version` labels
	// are automatically generated and can't be overwritten.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	_fullname: metadata.name
	_labels:   metadata.labels

	// The selector allows adding label selectors to Deployments and Services.
	// The `app.kubernetes.io/name` label selector is automatically generated
	// from the instance name and can't be overwritten.
	selector: timoniv1.#Selector & {
		#Name: metadata.name
		labels: {
			"app.kubernetes.io/instance": metadata.name
			"pod.name":                   *"main" | string
		}
	}

	// The image allows setting the container image repository,
	// tag, digest and pull policy.
	// The default image repository, tag and digest are set in `images.cue`.
	image!: timoniv1.#Image

	// The resources allows setting the container resource requirements.
	// By default, the container requests 100m CPU and 256Mi memory, with limits of 1000m CPU and 512Mi memory.
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"100m" | timoniv1.#CPUQuantity
			memory: *"256Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			cpu:    *"1000m" | timoniv1.#CPUQuantity
			memory: *"512Mi" | timoniv1.#MemoryQuantity
		}
	}

	// The number of pods replicas.
	// By default, the number of replicas is 1.
	replicas: *1 | int & >0

	// Deployment rollout strategy. Defaults to Recreate for ReadWriteOnce SQLite storage.
	strategy: appsv1.#DeploymentStrategy & {
		type: *"Recreate" | "RollingUpdate"
	}

	// The securityContext allows setting the container security context.
	// By default, the container is denied privilege escalation.
	securityContext: corev1.#SecurityContext & {
		allowPrivilegeEscalation: *false | true
		privileged:               *false | true
		capabilities: {
			drop: *["ALL"] | [...string]
			add: *["CHOWN", "DAC_OVERRIDE", "FOWNER", "NET_BIND_SERVICE", "SETGID", "SETUID"] | [...string]
		}
	}

	// The service allows setting the Kubernetes Service type, annotations and port.
	// By default, the HTTP port is 3002 (matching docker-compose.yml).
	service: {
		annotations?: timoniv1.#Annotations
		type:         *corev1.#ServiceTypeClusterIP | corev1.#ServiceType
		port:         *3002 | int & >0 & <=65535
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

	// Optional bundled PostgreSQL service (matches docs/examples/docker-compose.postgres.yml).
	// When enabled, deploys PostgreSQL and sets DATABASE_URL automatically.
	postgres: {
		enabled:  *false | bool
		image!:   timoniv1.#Image
		port:     *5432 | int & >0 & <=65535
		database: *"tududi" | string
		user:     *"tududi" | string
		password: *"change-me-postgres-password" | string
		podSecurityContext: corev1.#PodSecurityContext & {
			runAsUser:  *999 | int
			runAsGroup: *999 | int
			fsGroup:    *999 | int
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | true
			privileged:               *false | true
			capabilities: {
				drop: *["ALL"] | [...string]
				add: *["CHOWN", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"] | [...string]
			}
		}
		persistence: {
			storageClass?: string
			accessModes:   *["ReadWriteOnce"] | [...corev1.#PersistentVolumeAccessMode]
			size:          *"5Gi" | timoniv1.#MemoryQuantity
			annotations?:  timoniv1.#Annotations
		}
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"100m" | timoniv1.#CPUQuantity
				memory: *"256Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"1000m" | timoniv1.#CPUQuantity
				memory: *"512Mi" | timoniv1.#MemoryQuantity
			}
		}
	}

	// Environment variables (corresponds to .env in docker-compose.yml).
	// See .env.example in the repository root for all optional environment variables.
	env: {
		// Core (required)
		TUDUDI_USER_EMAIL:     *"admin@example.com" | string
		TUDUDI_USER_PASSWORD:  *"change-me-to-a-secure-password" | string
		TUDUDI_SESSION_SECRET: *"change-me-please-use-openssl-rand-hex-64" | string

		// Networking / reverse proxy
		TUDUDI_ALLOWED_ORIGINS: *"http://localhost:3002" | string
		TUDUDI_TRUST_PROXY:     *"false" | string

		// Storage / runtime user
		TUDUDI_UPLOAD_PATH: *"/app/uploads" | string
		TUDUDI_BACKUP_PATH: *"/app/backups" | string
		PUID:               *"1001" | string
		PGID:               *"1001" | string

		// Database (PostgreSQL)
		if postgres.enabled {
			DATABASE_URL: *"postgres://\(postgres.user):\(postgres.password)@\(metadata.name)-postgres:\(postgres.port)/\(postgres.database)" | string
		}
		DB_SSL:      *"false" | string
		DB_POOL_MAX: *"10" | string

		[string]: string
	}

	// Persistent storage volumes matching docker-compose.yml mounts:
	// - ./tududi_db:/app/db
	// - ./uploads:/app/uploads
	// - ./backups:/app/backups
	persistence: {
		db: #PersistenceVolume & {
			size: *"1Gi" | timoniv1.#MemoryQuantity
		}
		uploads: #PersistenceVolume & {
			size: *"5Gi" | timoniv1.#MemoryQuantity
		}
		backups: #PersistenceVolume & {
			size: *"5Gi" | timoniv1.#MemoryQuantity
		}
	}

	// Pod optional settings.
	automountServiceAccountToken: *false | bool
	podAnnotations?:              {[string]: string}
	podSecurityContext?: corev1.#PodSecurityContext
	imagePullSecrets?: [...timoniv1.#ObjectReference]
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]

	// Pods are scheduled on Linux nodes by default.
	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}

	// The affinity rules: `podAntiAffinity` accepts the `soft` (default),
	// `hard` and `none` presets for spreading the replicas across nodes,
	// or raw pod anti-affinity rules.
	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}

	// Test Job disabled by default.
	// The test image defaults are set in `images.cue`.
	test: {
		enabled: *false | bool
		image!:  timoniv1.#Image
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		sa:  #ServiceAccount & {#config: config}
		svc: #Service & {#config: config}
		cm:  #ConfigMap & {#config: config}

		if config.gatewayAPI.enabled {
			for i, r in config.gatewayAPI.httpRoutes {
				"httproute-\(i)": #HTTPRoute & {
					#config: config
					#route:  r
					#index:  i
				}
			}
		}

		if config.postgres.enabled {
			"svc-postgres": #PostgresService & {#config: config}
			"sts-postgres": #PostgresStatefulSet & {#config: config}
		}

		if !config.postgres.enabled && config.persistence.db.enabled && config.persistence.db.existingClaim == _|_ {
			"pvc-db": #PersistentVolumeClaim & {
				#config: config
				#name:   "db"
				#volume: config.persistence.db
			}
		}

		if config.persistence.uploads.enabled && config.persistence.uploads.existingClaim == _|_ {
			"pvc-uploads": #PersistentVolumeClaim & {
				#config: config
				#name:   "uploads"
				#volume: config.persistence.uploads
			}
		}

		if config.persistence.backups.enabled && config.persistence.backups.existingClaim == _|_ {
			"pvc-backups": #PersistentVolumeClaim & {
				#config: config
				#name:   "backups"
				#volume: config.persistence.backups
			}
		}

		deploy: #Deployment & {
			#config: config
			#cmName: objects.cm.metadata.name
		}
	}

	tests: {
		"test-svc": #TestJob & {#config: config}
	}
}
