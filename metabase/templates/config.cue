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
	// By default, the minimum Kubernetes version is set to 1.26.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.26.0"}

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
		repository: *"docker.io/metabase/metabase" | string
		tag:        *"v0.63.1" | string
		pullPolicy: *"IfNotPresent" | string
		digest:     *"" | string
	}
	imagePullSecrets: [...timoniv1.#ObjectReference] | *[]

	waitForDatabase: {
		image: timoniv1.#Image & {
			repository: *"docker.io/library/busybox" | string
			tag:        *"1.37" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
	}

	metabase: {
		port:                *3000 | int & >0 & <=65535
		encryptionSecretKey: *"" | string
		existingSecret:      *"" | string
		existingSecretKey:   *"encryption-secret-key" | string
		siteUrl:             *"" | string
		aiFeaturesEnabled:   *false | bool
		javaTimezone:        *"UTC" | string
		javaOpts:            *"" | string
		extraEnv:           [...corev1.#EnvVar] | *[]
	}

	database: {
		external: {
			host:                      *"" | string
			port:                      *"5432" | string
			name:                      *"metabase" | string
			username:                  *"metabase" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"password" | string
		}
	}

	serviceAccount: {
		create:      *false | bool
		name:        *"" | string
		annotations: {[string]: string}
	}

	service: {
		type:        *"ClusterIP" | "NodePort" | "LoadBalancer"
		port:        *80 | int & >0 & <=65535
		annotations: {[string]: string}
		ipFamilyPolicy?: string
		ipFamilies?: [...string]
	}



	gateway: {
		enabled:     *false | bool
		annotations: {[string]: string}
		parentRefs: [...{
			name:       string
			namespace?: string
		}]
		hostnames: [...string]
		path:     *"/" | string
		pathType: *"PathPrefix" | string
	}

	probes: {
		startup: {
			enabled:             *true | bool
			path:                *"/api/health" | string
			initialDelaySeconds: *90 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *30 | int
		}
		liveness: {
			enabled:             *true | bool
			path:                *"/api/health" | string
			initialDelaySeconds: *0 | int
			periodSeconds:       *15 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *3 | int
		}
		readiness: {
			enabled:             *true | bool
			path:                *"/api/health" | string
			initialDelaySeconds: *0 | int
			periodSeconds:       *10 | int
			timeoutSeconds:      *5 | int
			failureThreshold:    *3 | int
		}
	}

	resources:           corev1.#ResourceRequirements | *{}
	podSecurityContext:  corev1.#PodSecurityContext | *{
		runAsUser:           65510
		runAsGroup:          65510
		fsGroup:             65510
		seccompProfile: {
			type: "RuntimeDefault"
		}
	}
	securityContext:     corev1.#SecurityContext | *{
		allowPrivilegeEscalation: false
		readOnlyRootFilesystem:   true
		runAsNonRoot:             true
		capabilities: {
			drop: ["ALL"]
		}
	}

	nodeSelector: {[string]: string} | *{}
	tolerations: [...corev1.#Toleration] | *[]
	affinity: corev1.#Affinity | *{}
	topologySpreadConstraints: [...corev1.#TopologySpreadConstraint] | *[]
	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *30 | int

	podLabels: {[string]: string} | *{}
	podAnnotations: {[string]: string} | *{}

	extraVolumes:        [...corev1.#Volume] | *[]
	extraVolumeMounts:   [...corev1.#VolumeMount] | *[]
	extraInitContainers: [...corev1.#Container] | *[]
	extraManifests:       *[] | [...{...}]

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
		data: *[] | [...]
	}

	postgresql: {
		enabled:      *true | bool
		architecture: *"standalone" | string
		auth: {
			database: *"metabase" | string
			username: *"metabase" | string
			password: *"" | string
		}
		initdb: {
			scripts: {[string]: string} | *{"02-extensions.sql": "CREATE EXTENSION IF NOT EXISTS citext;\n"}
		}
		image: timoniv1.#Image & {
			repository: *"docker.io/library/postgres" | string
			tag:        *"18.4-trixie" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"8Gi" | string
			}
			resources?: corev1.#ResourceRequirements
		}
		podSecurityContext: corev1.#PodSecurityContext | *{
			runAsUser:           65510
			runAsGroup:          65510
			fsGroup:             65510
			seccompProfile: {
				type: "RuntimeDefault"
			}
		}
		securityContext:    corev1.#SecurityContext | *{
			allowPrivilegeEscalation: false
			readOnlyRootFilesystem:   true
			runAsNonRoot:             true
			capabilities: {
				drop: ["ALL"]
			}
		}
	}

	backup: {
		enabled:                    *false | bool
		schedule:                   *"0 3 * * *" | string
		suspend:                    *false | bool
		concurrencyPolicy:          *"Forbid" | string
		successfulJobsHistoryLimit: *3 | int
		failedJobsHistoryLimit:     *3 | int
		backoffLimit:               *1 | int
		archivePrefix:              *"metabase" | string
		images: {
			postgresql: *"docker.io/library/postgres:18.4-trixie" | string
			uploader:   *"docker.io/helmforge/mc:1.0.0" | string
		}
		resources: corev1.#ResourceRequirements | *{}
		s3: {
			endpoint:                *"" | string
			bucket:                  *"" | string
			prefix:                  *"metabase" | string
			createBucketIfNotExists: *true | bool
			existingSecret:          *"" | string
			existingSecretAccessKeyKey: *"access-key" | string
			existingSecretSecretKeyKey: *"secret-key" | string
			accessKey:               *"" | string
			secretKey:               *"" | string
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
				"\(metadata.name)-metabase"
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

	encryptionSecretName: [
		if metabase.existingSecret != "" {
			metabase.existingSecret
		},
		if metabase.existingSecret == "" {
			"\(fullname)-app"
		},
	][0]

	encryptionSecretKey: [
		if metabase.existingSecret != "" {
			metabase.existingSecretKey
		},
		if metabase.existingSecret == "" {
			"encryption-secret-key"
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

	backupDbHost: [
		if backup.database.host != "" {
			backup.database.host
		},
		if backup.database.host == "" {
			dbHost
		},
	][0]

	backupDbPort: [
		if backup.database.port != "" {
			backup.database.port
		},
		if backup.database.port == "" {
			dbPort
		},
	][0]

	backupDbName: [
		if backup.database.name != "" {
			backup.database.name
		},
		if backup.database.name == "" {
			dbName
		},
	][0]

	backupDbUsername: [
		if backup.database.username != "" {
			backup.database.username
		},
		if backup.database.username == "" {
			dbUsername
		},
	][0]

	backupDbPasswordSecretName: [
		if backup.database.existingSecret != "" {
			backup.database.existingSecret
		},
		if backup.database.existingSecret == "" {
			dbSecretName
		},
	][0]

	backupDbPasswordSecretKey: [
		if backup.database.existingSecret != "" {
			backup.database.existingSecretPasswordKey
		},
		if backup.database.existingSecret == "" {
			dbSecretPasswordKey
		},
	][0]

	serviceAccountName: [
		if serviceAccount.name != "" {
			serviceAccount.name
		},
		if serviceAccount.name == "" {
			if serviceAccount.create {
				fullname
			}
			if !serviceAccount.create {
				"default"
			}
		},
	][0]

	// Constraints validations
	if !postgresql.enabled {
		database: external: host: string & !=""
		if database.external.existingSecret == "" {
			database: external: password: string & !=""
		}
	}



	if backup.enabled {
		backup: s3: endpoint: string & !=""
		backup: s3: bucket:   string & !=""
		if backup.s3.existingSecret == "" {
			backup: s3: accessKey: string & !=""
			backup: s3: secretKey: string & !=""
		}
	}

	if externalSecrets.enabled {
		if metabase.existingSecret == "" {
			metabase: existingSecret: string & !=""
		}
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}

		svc: #Service & {#config: config}
		deploy: #Deployment & {#config: config}

		if config.metabase.existingSecret == "" {
			appSecret: #AppSecret & {#config: config}
		}

		if !config.postgresql.enabled && config.database.external.existingSecret == "" && config.database.external.password != "" {
			dbSecret: #DBSecret & {#config: config}
		}



		if config.gateway.enabled {
			httproute: #HTTPRoute & {#config: config}
		}

		if config.externalSecrets.enabled {
			externalSecret: #ExternalSecret & {#config: config}
		}

		if config.postgresql.enabled {
			pgSecret: #PGSecret & {#config: config}
			pgSVC:         #PGSVC & {#config: config}
			pgHeadlessSVC: #PGHeadlessSVC & {#config: config}
			pgDeploy:      #PGStatefulSet & {#config: config}
			if len(config.postgresql.initdb.scripts) > 0 {
				pgInitdb: #PGInitdbConfigMap & {#config: config}
			}
		}

		if config.backup.enabled {
			if config.backup.s3.existingSecret == "" {
				backupSecret: #BackupSecret & {#config: config}
			}
			backupScripts: #BackupScriptsConfigMap & {#config: config}
			backupCronJob: #BackupCronJob & {
				#config:            config
				#backupScriptsName: backupScripts.metadata.name
			}
		}
	}
}
