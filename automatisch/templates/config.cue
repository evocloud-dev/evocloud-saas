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
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// The selector allows adding label selectors to Deployments and Services.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels: {[string]: string}
	replicas: *1 | int

	image: timoniv1.#Image & {
		repository: *"docker.io/automatischio/automatisch" | string
		tag:        *"0.15.0" | string
		pullPolicy: *"IfNotPresent" | string
		digest:     *"" | string
	}
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// Secrets required for Automatisch
	encryptionKey!:     string
	appSecretKey!:      string
	webhookSecretKey!:  string

	automatisch: {
		webAppUrl: *"http://localhost:3000" | string
		appEnv:    *"production" | string
		extraEnv:  *[] | [...corev1.#EnvVar]
	}

	database: {
		external: {
			host:                      *"" | string
			port:                      *"5432" | string
			name:                      *"automatisch" | string
			username:                  *"automatisch" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"password" | string
		}
	}

	redis_config: {
		external: {
			host:           *"" | string
			port:           *"6379" | string
			existingSecret: *"" | string
		}
	}

	serviceAccount: {
		create:      *false | bool
		name:        *"" | string
		annotations: {[string]: string}
	}

	service: {
		type:        *"ClusterIP" | "NodePort" | "LoadBalancer"
		port:        *80 | int
		annotations: {[string]: string}
	}

	ingress: {
		enabled:          *false | bool
		ingressClassName: *"traefik" | string
		annotations: {[string]: string}
		hosts: [...{
			host: string
			paths?: [...{
				path:     string
				pathType: string
			}]
		}]
		tls: [...{
			hosts: [...string]
			secretName: string
		}]
	}

	probes: {
		startup: {
			enabled:             *true | bool
			initialDelaySeconds: *10 | int
			periodSeconds:       *5 | int
			timeoutSeconds:      *3 | int
			failureThreshold:    *30 | int
		}
		liveness: {
			enabled:             *true | bool
			initialDelaySeconds: *0 | int
			periodSeconds:       *15 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *3 | int
		}
		readiness: {
			enabled:             *true | bool
			initialDelaySeconds: *0 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *3 | int
		}
	}

	resources?:          corev1.#ResourceRequirements
	podSecurityContext?: corev1.#PodSecurityContext
	securityContext?:    corev1.#SecurityContext

	nodeSelector: {[string]: string}
	tolerations?: [...corev1.#Toleration]
	affinity?: corev1.#Affinity
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *30 | int

	podLabels: {[string]: string}
	podAnnotations: {[string]: string}

	extraVolumes?:       [...corev1.#Volume]
	extraVolumeMounts?:  [...corev1.#VolumeMount]
	extraManifests:      *[] | [...{...}]

	postgresql: {
		enabled:      *true | bool
		architecture: *"standalone" | string
		auth: {
			database: *"automatisch" | string
			username: *"automatisch" | string
			password: *"" | string
		}
		image: timoniv1.#Image & {
			repository: *"docker.io/library/postgres" | string
			tag:        *"18.6-trixie" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		resources?: corev1.#ResourceRequirements
		persistence: {
			enabled:      *true | bool
			size:         *"8Gi" | string
			storageClass: *"" | string
		}
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
	}

	redis: {
		enabled:      *true | bool
		architecture: *"standalone" | string
		image: timoniv1.#Image & {
			repository: *"docker.io/library/redis" | string
			tag:        *"8.8.2" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		resources?: corev1.#ResourceRequirements
		persistence: {
			enabled:      *true | bool
			size:         *"8Gi" | string
			storageClass: *"" | string
		}
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
	}

	test: {
		enabled: *false | bool
	}

	// Computed helper fields (mirroring Helm template helpers)
	fullname: [
		if fullnameOverride != "" {
			fullnameOverride
		},
		if fullnameOverride == "" {
			if nameOverride != "" {
				"\(metadata.name)-\(nameOverride)"
			}
			if nameOverride == "" {
				"\(metadata.name)-automatisch"
			}
		},
	][0]

	dbHost: [
		if postgresql.enabled {
			"\(metadata.name)-postgresql"
		},
		if !postgresql.enabled {
			database.external.host
		},
	][0]

	dbPort: [
		if postgresql.enabled {
			"5432"
		},
		if !postgresql.enabled {
			"\(database.external.port)"
		},
	][0]

	dbName: [
		if postgresql.enabled {
			postgresql.auth.database
		},
		if !postgresql.enabled {
			database.external.name
		},
	][0]

	dbUsername: [
		if postgresql.enabled {
			postgresql.auth.username
		},
		if !postgresql.enabled {
			database.external.username
		},
	][0]

	dbSecretName: [
		if postgresql.enabled {
			"\(metadata.name)-postgresql-auth"
		},
		if !postgresql.enabled {
			if database.external.existingSecret != "" {
				database.external.existingSecret
			}
			if database.external.existingSecret == "" {
				"\(fullname)-db"
			}
		},
	][0]

	dbSecretPasswordKey: [
		if postgresql.enabled {
			"user-password"
		},
		if !postgresql.enabled {
			if database.external.existingSecret != "" {
				database.external.existingSecretPasswordKey
			}
			if database.external.existingSecret == "" {
				"password"
			}
		},
	][0]

	appSecretName: "\(fullname)-app"

	redisHost: [
		if redis.enabled {
			"\(metadata.name)-redis-master"
		},
		if !redis.enabled {
			redis_config.external.host
		},
	][0]

	redisPort: [
		if redis.enabled {
			"6379"
		},
		if !redis.enabled {
			"\(redis_config.external.port)"
		},
	][0]

	// Constraints validations
	if !postgresql.enabled {
		database: external: host: string & !=""
		if database.external.existingSecret == "" {
			database: external: password: string & !=""
		}
	}

	if !redis.enabled {
		redis_config: external: host: string & !=""
	}

	if ingress.enabled {
		ingress: hosts: [...{host: string & !=""}] & [_, ...]
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}

		appSecret: #AppSecret & {#config: config}

		if !config.postgresql.enabled && config.database.external.existingSecret == "" && config.database.external.password != "" {
			dbSecret: #DBSecret & {#config: config}
		}

		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}

		svc: #Service & {#config: config}

		deploy: #Deployment & {#config: config}

		if config.postgresql.enabled {
			pgSecret: #PGSecret & {#config: config}
			pgSVC:         #PGSVC & {#config: config}
			pgHeadlessSVC: #PGHeadlessSVC & {#config: config}
			pgDeploy:      #PGStatefulSet & {#config: config}
		}

		if config.redis.enabled {
			redisSVC:         #RedisSVC & {#config: config}
			redisHeadlessSVC: #RedisHeadlessSVC & {#config: config}
			redisDeploy:      #RedisStatefulSet & {#config: config}
		}
	}
}
