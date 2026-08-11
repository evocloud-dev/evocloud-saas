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

	nameOverride?:     string
	fullnameOverride?: string
	commonLabels: {[string]: string}
	replicaCount: *1 | int

	image: timoniv1.#Image & {
		repository: *"docker.io/wallabag/wallabag" | string
		tag:        *"2.6.14" | string
		pullPolicy: *"IfNotPresent" | string
		digest:     *"" | string
	}
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	wallabag: {
		port:              *80 | int
		domainName:        *"https://wallabag.example.com" | string
		secret:            *"" | string
		existingSecret:    *"" | string
		existingSecretKey: *"symfony-secret" | string
		registration:      *false | bool
		extraEnv:          *[] | [...corev1.#EnvVar]
		adminUser: {
			username: *"wallabag" | string
			email:    *"admin@example.com" | string
			password: *"changeit" | string
		}
	}

	database: {
		external: {
			host:                      *"" | string
			port:                      *"5432" | string
			name:                      *"wallabag" | string
			username:                  *"wallabag" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"password" | string
		}
	}

	externalRedis: {
		host: *"" | string
		port: *"6379" | string
	}

	persistence: {
		enabled:       *true | bool
		size:          *"2Gi" | string
		storageClass:  *"" | string
		accessModes:   *["ReadWriteOnce"] | [...string]
		existingClaim: *"" | string
	}

	serviceAccount: {
		create:      *true | bool
		name:        *"" | string
		annotations: {[string]: string}
	}

	service: {
		type:        *"ClusterIP" | "NodePort" | "LoadBalancer"
		port:        *80 | int
		annotations: {[string]: string}
	}


	probes: {
		startup: {
			enabled:             *true | bool
			initialDelaySeconds: *15 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
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

	resources:          corev1.#ResourceRequirements
	podSecurityContext?: corev1.#PodSecurityContext
	securityContext?:    corev1.#SecurityContext

	backup: {
		enabled:                    *false | bool
		schedule:                   *"0 3 * * *" | string
		suspend:                    *false | bool
		concurrencyPolicy:          *"Forbid" | "Allow" | "Replace"
		successfulJobsHistoryLimit: *3 | int
		failedJobsHistoryLimit:     *3 | int
		backoffLimit:               *1 | int
		archivePrefix:              *"wallabag" | string
		images: {
			postgresql: *"docker.io/library/postgres:18-alpine" | string
			uploader:   *"docker.io/helmforge/mc:1.0.0" | string
		}
		resources: corev1.#ResourceRequirements
		s3: {
			endpoint:                    *"" | string
			bucket:                      *"" | string
			prefix:                      *"wallabag" | string
			createBucketIfNotExists:     *true | bool
			existingSecret:              *"" | string
			existingSecretAccessKeyKey:  *"access-key" | string
			existingSecretSecretKeyKey:  *"secret-key" | string
			accessKey:                   *"" | string
			secretKey:                   *"" | string
		}
		database: {
			host:                      *"" | string
			port:                      *"" | string
			name:                      *"" | string
			username:                  *"" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"password" | string
			postgresDumpArgs:          *"" | string
		}
	}

	nodeSelector: {[string]: string}
	tolerations?: [...corev1.#Toleration]
	affinity?: corev1.#Affinity
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *30 | int

	podLabels: {[string]: string}
	podAnnotations: {[string]: string}

	extraVolumes:       *[] | [...corev1.#Volume]
	extraVolumeMounts: *[] | [...corev1.#VolumeMount]
	extraManifests:    *[] | [...{...}]

	postgresql: {
		enabled:      *true | bool
		architecture: *"standalone" | string
		auth: {
			database: *"wallabag" | string
			username: *"wallabag" | string
			password: *"change-me-please-db-password!" | string
		}
		image: timoniv1.#Image & {
			repository: *"docker.io/library/postgres" | string
			tag:        *"18.4-trixie" | string
			pullPolicy: *"IfNotPresent" | string
		}
		resources: corev1.#ResourceRequirements
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
		auth: {
			password: *"" | string
		}
		image: timoniv1.#Image & {
			repository: *"docker.io/library/redis" | string
			tag:        *"8.8.1" | string
			pullPolicy: *"IfNotPresent" | string
		}
		resources: corev1.#ResourceRequirements
		persistence: {
			enabled:      *true | bool
			size:         *"8Gi" | string
			storageClass: *"" | string
		}
		podSecurityContext?: corev1.#PodSecurityContext
		securityContext?:    corev1.#SecurityContext
	}

	// Computed helper fields (mirroring Helm template helpers)
	fullname: [
		if fullnameOverride != _|_ if fullnameOverride != "" {
			fullnameOverride
		},
		if fullnameOverride == _|_ || fullnameOverride == "" {
			if nameOverride != _|_ if nameOverride != "" {
				"\(metadata.name)-\(nameOverride)"
			}
			if nameOverride == _|_ || nameOverride == "" {
				"\(metadata.name)-wallabag"
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
				"\(metadata.name)-db"
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

	appSecretName: [
		if wallabag.existingSecret != "" {
			wallabag.existingSecret
		},
		if wallabag.existingSecret == "" {
			"\(fullname)-app"
		},
	][0]

	appSecretKey: [
		if wallabag.existingSecret != "" {
			wallabag.existingSecretKey
		},
		if wallabag.existingSecret == "" {
			"symfony-secret"
		},
	][0]

	redisHost: [
		if redis.enabled {
			"\(metadata.name)-redis-client"
		},
		if !redis.enabled {
			externalRedis.host
		},
	][0]

	redisPort: [
		if redis.enabled {
			"6379"
		},
		if !redis.enabled {
			"\(externalRedis.port)"
		},
	][0]

	dataClaimName: [
		if persistence.existingClaim != "" {
			persistence.existingClaim
		},
		if persistence.existingClaim == "" {
			"\(fullname)-data"
		},
	][0]

	backupDbHost: [
		if backup.database.host != "" {
			backup.database.host
		},
		if backup.database.host == "" {
			if postgresql.enabled {
				"\(metadata.name)-postgresql"
			}
			if !postgresql.enabled {
				database.external.host
			}
		},
	][0]

	backupDbPort: [
		if backup.database.port != "" {
			"\(backup.database.port)"
		},
		if backup.database.port == "" {
			if postgresql.enabled {
				"5432"
			}
			if !postgresql.enabled {
				"\(database.external.port)"
			}
		},
	][0]

	backupDbName: [
		if backup.database.name != "" {
			backup.database.name
		},
		if backup.database.name == "" {
			if postgresql.enabled {
				postgresql.auth.database
			}
			if !postgresql.enabled {
				database.external.name
			}
		},
	][0]

	backupDbUsername: [
		if backup.database.username != "" {
			backup.database.username
		},
		if backup.database.username == "" {
			if postgresql.enabled {
				postgresql.auth.username
			}
			if !postgresql.enabled {
				database.external.username
			}
		},
	][0]

	backupDbPasswordSecretName: [
		if backup.database.existingSecret != "" {
			backup.database.existingSecret
		},
		if backup.database.existingSecret == "" {
			if postgresql.enabled {
				"\(metadata.name)-postgresql-auth"
			}
			if !postgresql.enabled {
				if database.external.existingSecret != "" {
					database.external.existingSecret
				}
				if database.external.existingSecret == "" {
					"\(metadata.name)-db"
				}
			}
		},
	][0]

	backupDbPasswordSecretKey: [
		if backup.database.existingSecret != "" {
			backup.database.existingSecretPasswordKey
		},
		if backup.database.existingSecret == "" {
			if postgresql.enabled {
				"user-password"
			}
			if !postgresql.enabled {
				if database.external.existingSecret != "" {
					database.external.existingSecretPasswordKey
				}
				if database.external.existingSecret == "" {
					"password"
				}
			}
		},
	][0]

	backupSecretName: [
		if backup.s3.existingSecret != "" {
			backup.s3.existingSecret
		},
		if backup.s3.existingSecret == "" {
			"\(fullname)-backup"
		},
	][0]
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}

		if config.wallabag.existingSecret == "" {
			appSecret: #AppSecret & {#config: config}
		}

		adminSecret: #AdminSecret & {#config: config}

		if !config.postgresql.enabled && config.database.external.existingSecret == "" && config.database.external.password != "" {
			dbSecret: #DBSecret & {#config: config}
		}

		if config.backup.enabled && config.backup.s3.existingSecret == "" {
			backupSecret: #BackupSecret & {#config: config}
		}

		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PVC & {#config: config}
		}

		svc: #Service & {#config: config}


		if config.backup.enabled {
			backupCM:      #BackupConfigMap & {#config: config}
			backupCronJob: #BackupCronJob & {#config: config}
		}

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
