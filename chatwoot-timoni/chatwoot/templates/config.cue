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
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	// The moduleVersion is set from the user-supplied module version.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	// Global settings
	image: {
		repository: *"chatwoot/chatwoot" | string
		tag:        *"v4.12.1" | string
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
	}
	imagePullSecrets?: [...{name: string}]
	
	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	autoscaling: {
		...
		apiVersion: *"autoscaling/v2" | string
	}

	serviceAccount: {
		...
		create: *true | bool
		name: *"" | string
	}

	// Component-specific settings
	web: {
		replicaCount: *1 | int & >0
		hpa: {
			enabled:          *false | bool
			cputhreshold:     *75 | int
			memorythreshold:  *75 | int
			minpods:          *1 | int
			maxpods:          *10 | int
		}
		resources?: corev1.#ResourceRequirements
		livenessProbe:  *#DefaultProbe | corev1.#Probe
		readinessProbe: *#DefaultProbe | corev1.#Probe
		startupProbe: *#DefaultStartupProbe | corev1.#Probe
	}

	#DefaultStartupProbe: corev1.#Probe & {
		initialDelaySeconds: *30 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *60 | int
	}

	worker: {
		replicaCount: *2 | int & >=0
		hpa: {
			enabled:          *false | bool
			cputhreshold:     *75 | int
			memorythreshold:  *75 | int
			minpods:          *2 | int
			maxpods:          *10 | int
		}
		resources?: corev1.#ResourceRequirements
	}

	postgresql: {
		...
		enabled:      *true | bool
		nameOverride: *"chatwoot-postgresql" | string
		image: {
			registry:   *"ghcr.io" | string
			repository: *"chatwoot/pgvector" | string
			tag:        *"14.4.0-debian-11-r0" | string
		}
		auth: {
			username:         *"postgres" | string
			postgresPassword: *"postgres" | string
			database:         *"chatwoot_production" | string
			existingSecret?:   string
		}
		postgresqlHost?: string
		postgresqlPort:  *5432 | int
	}

	redis: {
		...
		enabled:      *true | bool
		nameOverride: *"chatwoot-redis" | string
		image: {
			repository: *"bitnamilegacy/redis" | string
			tag:        *"6.2.7-debian-11-r3" | string
		}
		auth: {
			password: *"redis" | string
			existingSecret?: string
		}
		host?: string
		port:  *6379 | int
		sentinel: {
			enabled:    *false | bool
			image: {
				repository: *"bitnamilegacy/redis" | string
				tag: *"6.2.9-debian-11-r0" | string
			}
			masterSet:  *"mymaster" | string
			sentinelSet: *"" | string
		}
	}

	services: {
		name:         *"chatwoot" | string
		internalPort: *3000 | int
		targetPort:   *3000 | int
		type:         *"LoadBalancer" | string
		annotations?: {[string]: string}
	}

	service: {
		type: *"ClusterIP" | string
		port: *80 | int
	}

	ingress: {
		enabled: *false | bool
		annotations?: {[string]: string}
		ingressClassName?: string
		hosts: [...{
			host: string
			paths: [...{
				path:     string
				pathType: *"Prefix" | string
				backend?: {
					service: {
						name: string
						port: number: int
					}
				}
			}]
		}]
		tls: [...{
			secretName?: string
			hosts: [...string]
		}]
	}

	hooks: {
		...
		migrate: {
			...
			hookAnnotation: *"post-install,post-upgrade" | string
			resources:      corev1.#ResourceRequirements & {
				limits: memory:   *"1000Mi" | timoniv1.#MemoryQuantity
				requests: memory: *"1000Mi" | timoniv1.#MemoryQuantity
			}
		}
	}

	env: [string]: string

	existingEnvSecret: *"" | string

	// Common pod settings
	podAnnotations?: {[string]: string}
	podSecurityContext?: corev1.#PodSecurityContext
	securityContext?:    corev1.#SecurityContext
	nodeSelector?: {[string]: string}
	tolerations?: [...corev1.#Toleration]
	affinity?: corev1.#Affinity

	#DefaultProbe: corev1.#Probe & {
		initialDelaySeconds: *15 | int
		periodSeconds:       *15 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *3 | int
	}

	test: {
		...
		enabled: *false | bool
	}
	// Helper fields for derived values
	#postgresql: {
		host: *postgresql.nameOverride | string
		if !postgresql.enabled {
			host: postgresql.postgresqlHost
		}
		port: *5432 | int
		if !postgresql.enabled {
			port: postgresql.postgresqlPort
		}
		database: postgresql.auth.database
		user:     postgresql.auth.username
		password: postgresql.auth.postgresPassword
	}

	#redis: {
		host: *("\(redis.nameOverride)-master") | string
		if !redis.enabled {
			host: redis.host
		}
		port: *6379 | int
		if !redis.enabled {
			port: redis.port
		}
		password: redis.auth.password
		url:      *"redis://:\(password)@\(host):\(port)" | string
		sentinels: *"" | string
		if redis.sentinel.enabled {
			sentinels: redis.sentinel.sentinelSet
		}
		sentinelMasterName: redis.sentinel.masterSet
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		sa: #ServiceAccount & {#config: config}
		env: #Secret & {#config: config}
		
		web: #WebDeployment & {#config: config}
		"web-svc": #WebService & {#config: config}
		if config.web.hpa.enabled {
			"web-hpa": #WebHPA & {#config: config}
		}

		worker: #WorkerDeployment & {#config: config}
		if config.worker.hpa.enabled {
			"worker-hpa": #WorkerHPA & {#config: config}
		}

		if config.postgresql.enabled {
			pg: #Postgresql & {#config: config}
			"pg-svc": #PostgresqlService & {#config: config}
		}

		if config.redis.enabled {
			redis: #Redis & {#config: config}
			"redis-svc": #RedisService & {#config: config}
			"redis-master-svc": #RedisMasterService & {#config: config}
			"redis-sentinel-svc": #RedisSentinelService & {#config: config}
		}

		migrate: #MigrationJob & {#config: config}

		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}
	}

	tests: {
		[string]: _
	}
}
