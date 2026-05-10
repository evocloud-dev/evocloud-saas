package templates

import (
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

	// Global settings
	global: {
		namespace:        *"coolify" | string
		registryUrl:      *"ghcr.io" | string
		storageClassName: *"" | string
	}

	coolifyApp: {
		enabled:      *true | bool
		replicaCount: *1 | int & >0
		image: {
			repository: *"ghcr.io/coollabsio/coolify" | string
			tag:        *moduleVersion | string
			pullPolicy: *"IfNotPresent" | string
		}
		service: {
			type:       *"ClusterIP" | string
			port:       *8000 | int
			targetPort: *8080 | int
		}
		workingDir: *"/var/www/html" | string
		migration: {
			enabled:    *true | bool
			timeout:    *300 | int
			runSeeders: *true | bool
		}
		hostNetwork: enabled: *false | bool
		extraHosts: [...{
			name: string
			ip:   string
		}]
		resources: timoniv1.#ResourceRequirements
		healthCheck: {
			enabled:             *true | bool
			path:                *"/api/health" | string
			initialDelaySeconds: *30 | int
			periodSeconds:       *5 | int
			timeoutSeconds:      *2 | int
			failureThreshold:    *10 | int
			successThreshold:    *1 | int
		}
		php: {
			memoryLimit:          *"256M" | string
			fpmPmControl:         *"dynamic" | string
			fpmPmStartServers:    *1 | int
			fpmPmMinSpareServers: *1 | int
			fpmPmMaxSpareServers: *10 | int
			fpmPmMaxChildren:     *20 | int
			fpmPmMaxRequests:     *500 | int
		}
		podDisruptionBudget: {
			enabled:      *true | bool
			minAvailable: *1 | int
		}
		autoscaling: {
			enabled:                        *false | bool
			minReplicas:                    *1 | int
			maxReplicas:                    *10 | int
			targetCPUUtilizationPercentage: *80 | int
			targetMemoryUtilizationPercentage: *80 | int
		}
		initContainers: {
			setupStorage: resources: timoniv1.#ResourceRequirements
			migration: resources:    timoniv1.#ResourceRequirements
		}
	}

	postgresql: {
		enabled: *true | bool
		auth: {
			existingSecret: *"coolify-postgresql" | string
			secretKeys: {
				adminPasswordKey: *"postgres-password" | string
				userPasswordKey:  *"password" | string
			}
			postgresPassword: *"" | string
			username:         *"coolify" | string
			password:         *"" | string
			database:         *"coolify" | string
		}
		primary: {
			image: {
				repository: *"bitnami/postgresql" | string
				tag:        *"15.6.0" | string
				pullPolicy: *"IfNotPresent" | string
			}
			persistence: {
				enabled:      *true | bool
				size:         *"5Gi" | string
				accessModes:  *["ReadWriteOnce"] | [...string]
				storageClass: *"" | string
			}
			resources: timoniv1.#ResourceRequirements
			securityContext: {
				enabled:                *true | bool
				readOnlyRootFilesystem: *false | bool
			}
		}
		healthCheck: {
			enabled:             *true | bool
			initialDelaySeconds: *10 | int
			periodSeconds:       *5 | int
			timeoutSeconds:      *2 | int
			failureThreshold:    *10 | int
		}
	}

	redis: {
		enabled:      *true | bool
		architecture: *"standalone" | string
		auth: {
			enabled:                   *true | bool
			sentinel:                  *false | bool
			existingSecret:            *"coolify-redis" | string
			existingSecretPasswordKey: *"redis-password" | string
			password:                  *"" | string
		}
		image: {
			repository: *"bitnami/redis" | string
			tag:        *"7.2.4" | string
			pullPolicy: *"IfNotPresent" | string
		}
		master: {
			persistence: enabled: *false | bool
			resources: timoniv1.#ResourceRequirements
		}
		replica: {
			replicaCount: *0 | int
			persistence: enabled: *false | bool
		}
		persistence: {
			enabled:          *false | bool
			size:             *"2Gi" | string
			accessModes:      *["ReadWriteOnce"] | [...string]
			storageClassName: *"" | string
		}
		service: ports: redis: *6379 | int
		commonConfiguration: *"" | string
	}

	soketi: {
		enabled:      *true | bool
		replicaCount: *1 | int
		image: {
			repository: *"ghcr.io/coollabsio/coolify-realtime" | string
			tag:        *"1.0.8" | string
			pullPolicy: *"Always" | string
		}
		service: {
			type:        *"ClusterIP" | string
			appPort:     *6001 | int
			metricsPort: *6002 | int
		}
		debug:     *false | bool
		resources: timoniv1.#ResourceRequirements
		healthCheck: {
			enabled:             *true | bool
			initialDelaySeconds: *10 | int
			periodSeconds:       *5 | int
			timeoutSeconds:      *2 | int
			failureThreshold:    *10 | int
		}
		extraHosts: [...{
			name: string
			ip:   string
		}]
	}

	config: {
		APP_NAME:                 *"Coolify" | string
		APP_ENV:                  *"production" | string
		APP_URL:                  *"http://localhost:8000" | string
		APP_DEBUG:                *false | bool
		DB_DATABASE:              *"coolify" | string
		PHP_MEMORY_LIMIT:         *"256M" | string
		PHP_FPM_PM_CONTROL:       *"dynamic" | string
		PHP_FPM_PM_START_SERVERS: *1 | int
		PHP_FPM_PM_MIN_SPARE_SERVERS: *1 | int
		PHP_FPM_PM_MAX_SPARE_SERVERS: *10 | int
		SOKETI_DEBUG:             *false | bool
		DB_CONNECTION:            *"pgsql" | string
		DB_HOST:                  *"" | string
		DB_PORT:                  *5432 | int
		REDIS_HOST:               *"" | string
		REDIS_PORT:               *6379 | int
		REGISTRY_URL:             *"ghcr.io" | string
		APP_OPTIMIZE:             *true | bool
		VIEW_COMPILED_PATH:       *"/var/www/html/storage/framework/views" | string
		SESSION_LIFETIME:         *120 | int
		SANCTUM_STATEFUL_DOMAINS: *"localhost:8000,127.0.0.1:8000" | string
	}

	secrets: {
		APP_ID:              *"" | string
		APP_KEY:             *"" | string
		ROOT_USERNAME:       *"" | string
		ROOT_USER_EMAIL:     *"" | string
		ROOT_USER_PASSWORD:  *"" | string
		DB_USERNAME:         *"coolify" | string
		DB_PASSWORD:         *"" | string
		REDIS_PASSWORD:      *"" | string
		PUSHER_APP_ID:       *"" | string
		PUSHER_APP_KEY:      *"" | string
		PUSHER_APP_SECRET:   *"" | string
	}

	sharedDataPvc: {
		name:             *"" | string
		size:             *"10Gi" | string
		accessModes:      *["ReadWriteOnce"] | [...string]
		storageClassName: *"" | string
	}

	securityContext: {
		enabled:                  *true | bool
		fsGroup:                  *0 | int
		runAsUser:                *0 | int
		runAsGroup:               *0 | int
		runAsNonRoot:             *false | bool
		allowPrivilegeEscalation: *true | bool
		readOnlyRootFilesystem:   *false | bool
		capabilities: {
			drop: *["ALL"] | [...string]
			add:  *["CHOWN", "SETUID", "SETGID", "DAC_OVERRIDE", "FOWNER", "SETPCAP"] | [...string]
		}
	}

	networkPolicy: {
		enabled: *false | bool
		ingress: [..._]
		egress:  [..._]
	}

	serviceMonitor: {
		enabled:   *false | bool
		namespace: *"" | string
		labels:    timoniv1.#Labels
	}

	ingress: {
		enabled:     *false | bool
		className:   *"" | string
		annotations: timoniv1.#Annotations
		hosts: [...{
			host: string
			paths: [...{
				path:     string
				pathType: string
			}]
		}]
		tls: [...{
			secretName: string
			hosts: [...string]
		}]
	}

	test: {
		enabled: *false | bool
		image: {
			repository: string | *"curlimages/curl"
			tag:        string | *"latest"
			pullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
		}
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config


	objects: {
		if config.metadata.namespace != "" {
			ns: #Namespace & {#config: config}
		}
		pvc: #SharedPVC & {#config: config}
		secret: #AppSecret & {#config: config}
		if config.postgresql.enabled {
			pgSec: (#PostgreSQLSecret & {#config: config}).secret
		}
		if config.redis.enabled {
			rdSec: (#RedisSecret & {#config: config}).secret
		}
		appCM: #AppConfigMap & {#config: config}
		appDep: #CoolifyAppDeployment & {#config: config}
		appSvc: #CoolifyAppService & {#config: config}
		if config.coolifyApp.podDisruptionBudget.enabled {
			appPDB: (#CoolifyAppPDB & {#config: config}).pdb
		}
		if config.coolifyApp.autoscaling.enabled {
			appHPA: #CoolifyAppHPA & {#config: config}
		}
		if config.ingress.enabled {
			appIng: (#CoolifyAppIngress & {#config: config}).ingress
		}
		if config.soketi.enabled {
			sokDep: #SoketiDeployment & {#config: config}
			sokSvc: #SoketiService & {#config: config}
		}
		if config.postgresql.enabled {
			pgConf: (#SubchartConfig & {#config: config}).postgresqlConfig
			pgSvc:  (#PostgreSQL & {#config:     config}).service
			pgHls:  (#PostgreSQL & {#config:     config}).headlessService
			pgSts:  (#PostgreSQL & {#config:     config}).statefulSet
		}
		if config.redis.enabled {
			rdConf: (#SubchartConfig & {#config: config}).redisConfig
			rdSvc:  (#Redis & {#config:          config}).service
			rdHls:  (#Redis & {#config:          config}).headlessService
			rdSts:  (#Redis & {#config:          config}).statefulSet
		}
	}






	tests: {}


}

