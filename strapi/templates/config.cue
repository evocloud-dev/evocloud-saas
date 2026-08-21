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

	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels:     {[string]: string}

	replicaCount: *1 | int & >0

	image: timoniv1.#Image & {
		repository: *"docker.io/helmforge/strapi-base" | string
		tag:        *"5.50.2" | string
		digest:     *"" | string
	}

	imagePullSecrets: *[] | [...corev1.LocalObjectReference]

	strapi: {
		host:              *"0.0.0.0" | string
		port:              *1337 | int
		url:               *"" | string
		nodeEnv:           *"production" | string
		telemetryDisabled: *true | bool
		command:           *[] | [...string]
		args:              *[] | [...string]
		extraEnv:          *[] | [...corev1.EnvVar]

		upload: {
			provider: *"local" | "aws-s3" | "cloudinary"
			s3: {
				enabled:                    *false | bool
				endpoint:                   *"" | string
				region:                     *"us-east-1" | string
				bucket:                     *"" | string
				prefix:                     *"" | string
				existingSecret:             *"" | string
				existingSecretAccessKeyKey: *"access-key" | string
				existingSecretSecretKeyKey: *"secret-key" | string
				accessKey:                  *"" | string
				secretKey:                  *"" | string
				acl:                        *"private" | string
				baseUrl:                    *"" | string
				params:                     {[string]: string}
			}
			cloudinary: {
				enabled:                 *false | bool
				cloudName:               *"" | string
				apiKey:                  *"" | string
				apiSecret:               *"" | string
				existingSecret:          *"" | string
				existingSecretApiKeyKey: *"api-key" | string
				existingSecretApiSecretKey: *"api-secret" | string
			}
		}

		performance: {
			nodeOptions:   *"" | string
			logLevel:      *"info" | string
			prettyPrint:   *false | bool
			forceJsonLogs: *true | bool
		}

		admin: {
			path:          *"/admin" | string
			autoOpen:      *false | bool
			jwtExpiration: *"7d" | string
			rateLimit: {
				enabled:    *true | bool
				max:        *5 | int
				timeWindow: *900000 | int
			}
			forgotPassword: {
				enabled: *true | bool
			}
		}

		email: {
			provider:       *"none" | "smtp" | "sendgrid"
			defaultFrom:    *"noreply@example.com" | string
			defaultReplyTo: *"" | string
			smtp: {
				host:                      *"" | string
				port:                      *587 | int
				username:                  *"" | string
				password:                  *"" | string
				existingSecret:            *"" | string
				existingSecretPasswordKey: *"smtp-password" | string
				secure:                    *false | bool
				requireTLS:                *true | bool
				ignoreTLS:                 *false | bool
			}
			sendgrid: {
				apiKey:                  *"" | string
				existingSecret:          *"" | string
				existingSecretApiKeyKey: *"sendgrid-api-key" | string
			}
		}

		graphql: {
			playgroundEnabled: *false | bool
			endpoint:          *"/graphql" | string
			introspection:     *false | bool
			maxDepth:          *10 | int
			maxComplexity:     *1000 | int
			apolloSandbox:     *false | bool
		}

		api: {
			rest: {
				defaultLimit: *25 | int
				maxLimit:     *100 | int
			}
		}

		server: {
			bodyParser: {
				jsonLimit: *"1mb" | string
				formLimit: *"56kb" | string
				textLimit: *"1mb" | string
			}
			compression: enabled: *true | bool
			cron: enabled:        *true | bool
			logger: level:        *"info" | string
		}
	}

	secrets: {
		existingSecret:                     *"" | string
		existingSecretAppKeysKey:           *"app-keys" | string
		existingSecretApiTokenSaltKey:       *"api-token-salt" | string
		existingSecretAdminJwtSecretKey:     *"admin-jwt-secret" | string
		existingSecretJwtSecretKey:          *"jwt-secret" | string
		existingSecretTransferTokenSaltKey: *"transfer-token-salt" | string
		appKeys:                            *"" | string
		apiTokenSalt:                       *"" | string
		adminJwtSecret:                     *"" | string
		jwtSecret:                          *"" | string
		transferTokenSalt:                  *"" | string
	}

	database: {
		mode: *"auto" | "sqlite" | "external" | "postgresql" | "mysql"
		sqlite: {
			directory: *"/opt/app/.tmp" | string
			filename:  *"data.db" | string
		}
		external: {
			vendor:                    *"postgres" | "mysql"
			host:                      *"" | string
			port:                      *"" | string
			name:                      *"strapi" | string
			username:                  *"strapi" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"database-password" | string
			ssl: enabled:              *false | bool
		}
		pool: {
			min:                  *2 | int
			max:                  *10 | int
			acquireTimeoutMillis: *30000 | int
			idleTimeoutMillis:    *30000 | int
		}
	}

	postgresql: {
		enabled:      *true | bool
		architecture: *"standalone" | string
		image?: {
			repository: *"docker.io/library/postgres" | string
			tag:        *"18.4-trixie" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			database:                  *"strapi" | string
			username:                  *"strapi" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"database-password" | string
		}
		primary: {
			persistence: {
				enabled:      *true | bool
				size:         *"8Gi" | string
				storageClass: *"" | string
			}
			resources?: {[string]: _}
		}
	}

	mysql: {
		enabled:      *false | bool
		architecture: *"standalone" | string
		image?: {
			repository: *"docker.io/library/mysql" | string
			tag:        *"9.7.1" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			database:                  *"strapi" | string
			username:                  *"strapi" | string
			password:                  *"" | string
			rootPassword:              *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"database-password" | string
		}
		primary: {
			persistence: {
				enabled:      *true | bool
				size:         *"8Gi" | string
				storageClass: *"" | string
			}
			resources?: {[string]: _}
		}
	}

	persistence: {
		enabled:       *true | bool
		storageClass:  *"" | string
		accessMode:    *"ReadWriteOnce" | string
		size:          *"5Gi" | string
		existingClaim: *"" | string
		annotations:   {[string]: string}
		uploads: {
			mountPath: *"/opt/app/public/uploads" | string
			subPath:   *"uploads" | string
		}
		sqlite: subPath: *"sqlite" | string
	}

	resources: {[string]: _}

	podSecurityContext: {
		fsGroup: *65510 | int
		seccompProfile?: {
			type: string
		}
	}

	securityContext: {
		runAsNonRoot:             *true | bool
		runAsUser:                *65510 | int
		runAsGroup:               *65510 | int
		allowPrivilegeEscalation: *false | bool
		capabilities: drop: *["ALL"] | [...string]
		seccompProfile?: {
			type: string
		}
	}

	startupProbe: {
		enabled:             *true | bool
		initialDelaySeconds: *10 | int
		periodSeconds:       *5 | int
		timeoutSeconds:      *3 | int
		failureThreshold:    *30 | int
	}

	livenessProbe: {
		enabled:             *true | bool
		initialDelaySeconds: *0 | int
		periodSeconds:       *15 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *3 | int
	}

	readinessProbe: {
		enabled:             *true | bool
		initialDelaySeconds: *0 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *3 | int
	}

	service: {
		type:           *"ClusterIP" | string
		port:           *80 | int
		annotations:    {[string]: string}
		ipFamilyPolicy: null | string
		ipFamilies:     *[] | [...string]
	}

	ingress: {
		enabled:          *false | bool
		ingressClassName: *"" | string
		annotations:      {[string]: string}
		hosts: *[] | [...{
			host: string
			paths: [...{
				path:     string
				pathType: string
			}]
		}]
		tls: *[] | [...{
			hosts: [...string]
			secretName?: string
		}]
	}

	gatewayAPI: {
		enabled:    *false | bool
		apiVersion: *"gateway.networking.k8s.io/v1" | string
		annotations: {[string]: string}
		parentRefs: *[] | [...{
			name:       string
			namespace?: string
			group?:     string
			kind?:      string
			sectionName?: string
		}]
		hostnames: *[] | [...string]
		matches: *[] | [...{
			path?: {
				type:  string
				value: string
			}
		}]
	}

	serviceAccount: {
		create:                       *false | bool
		name:                         *"" | string
		annotations:                  {[string]: string}
		automountServiceAccountToken: *false | bool
	}

	backup: {
		enabled:                    *false | bool
		schedule:                   *"0 3 * * *" | string
		suspend:                    *false | bool
		concurrencyPolicy:          *"Forbid" | string
		successfulJobsHistoryLimit: *3 | int
		failedJobsHistoryLimit:     *3 | int
		backoffLimit:               *1 | int
		archivePrefix:              *"strapi" | string
		images: {
			utility:    *"docker.io/library/alpine:3.22" | string
			postgresql: *"docker.io/library/postgres:18.3-alpine" | string
			mysql:      *"docker.io/library/mysql:8.4" | string
			uploader:   *"docker.io/helmforge/mc:1.0.0" | string
		}
		resources: {[string]: _}
		s3: {
			endpoint:                *"" | string
			bucket:                  *"" | string
			prefix:                  *"strapi" | string
			createBucketIfNotExists: *true | bool
			existingSecret:          *"" | string
			existingSecretAccessKeyKey: *"access-key" | string
			existingSecretSecretKeyKey: *"secret-key" | string
			accessKey:              *"" | string
			secretKey:              *"" | string
		}
		database: {
			host:                      *"" | string
			port:                      *"" | string
			name:                      *"" | string
			username:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"database-password" | string
			postgresDumpArgs:          *"" | string
			mysqlDumpArgs:             *"--single-transaction --quick --skip-lock-tables --no-tablespaces" | string
		}
	}

	externalSecrets: {
		enabled: *false | bool
		items:   *[] | [..._]
	}

	nodeSelector:              {[string]: string}
	tolerations:               *[] | [...corev1.Toleration]
	affinity:                  {[string]: _}
	topologySpreadConstraints: *[] | [...corev1.TopologySpreadConstraint]
	priorityClassName:         *"" | string
	terminationGracePeriodSeconds: *30 | int

	podLabels:      {[string]: string}
	podAnnotations: {[string]: string}
	extraVolumeMounts: *[] | [...corev1.VolumeMount]
	extraVolumes:      *[] | [...corev1.Volume]
	extraManifests:    *[] | [..._]

	// Internal computed helper fields
	fullname: [
		if fullnameOverride != "" {
			fullnameOverride
		},
		if fullnameOverride == "" {
			if nameOverride != "" {
				"\(metadata.name)-\(nameOverride)"
			}
			if nameOverride == "" {
				metadata.name
			}
		},
	][0]

	// Computed Database Mode
	resolvedDbMode: [
		if database.mode != "auto" {
			database.mode
		},
		if database.mode == "auto" {
			if database.external.host != "" || database.external.existingSecret != "" {
				"external"
			}
			if database.external.host == "" && database.external.existingSecret == "" {
				if postgresql.enabled {
					"postgresql"
				}
				if !postgresql.enabled && mysql.enabled {
					"mysql"
				}
				if !postgresql.enabled && !mysql.enabled {
					"sqlite"
				}
			}
		},
	][0]

	// App secret name reference
	appSecretName: [
		if secrets.existingSecret != "" {
			secrets.existingSecret
		},
		if secrets.existingSecret == "" {
			"\(fullname)-app"
		},
	][0]

	// Computed Database Host
	databaseHost: [
		if resolvedDbMode == "postgresql" {"\(fullname)-postgresql"},
		if resolvedDbMode == "mysql" {"\(fullname)-mysql"},
		if resolvedDbMode == "external" {database.external.host},
		"",
	][0]

	// Computed Database Port
	databasePort: [
		if resolvedDbMode == "postgresql" {"5432"},
		if resolvedDbMode == "mysql" {"3306"},
		if resolvedDbMode == "external" {
			if database.external.port != "" {database.external.port}
			if database.external.port == "" {
				if database.external.vendor == "postgres" {"5432"}
				if database.external.vendor != "postgres" {"3306"}
			}
		},
		"",
	][0]
}

#Instance: {
	config: #Config

	objects: {
		sa: #ServiceAccount & {#config: config}

		if config.serviceAccount.create {
			serviceAccount: sa
		}

		if config.secrets.existingSecret == "" {
			appSecret: #Secret & {#config: config}
		}

		if config.resolvedDbMode == "external" && config.database.external.existingSecret == "" {
			dbSecret: #DatabaseSecret & {#config: config}
		}

		if config.backup.enabled && config.backup.s3.existingSecret == "" {
			backupSecret: #BackupSecret & {#config: config}
		}

		if config.strapi.upload.provider == "aws-s3" && config.strapi.upload.s3.enabled && config.strapi.upload.s3.existingSecret == "" {
			uploadS3Secret: #UploadS3Secret & {#config: config}
		}

		if config.strapi.upload.provider == "cloudinary" && config.strapi.upload.cloudinary.enabled && config.strapi.upload.cloudinary.existingSecret == "" {
			uploadCloudinarySecret: #UploadCloudinarySecret & {#config: config}
		}

		if config.strapi.email.provider == "smtp" && config.strapi.email.smtp.existingSecret == "" && config.strapi.email.smtp.password != "" {
			smtpEmailSecret: #SMTPEmailSecret & {#config: config}
		}

		if config.strapi.email.provider == "sendgrid" && config.strapi.email.sendgrid.existingSecret == "" && config.strapi.email.sendgrid.apiKey != "" {
			sendgridEmailSecret: #SendGridEmailSecret & {#config: config}
		}

		dbConfigMap: #DatabaseConfigMap & {#config: config}
		configMap: dbConfigMap

		service: #Service & {#config: config}

		deployment: #Deployment & {#config: config}

		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PVC & {#config: config}
		}

		if config.postgresql.enabled && config.resolvedDbMode == "postgresql" {
			pgSecret: #PGSecret & {#config: config}
			pgSVC:    #PGSVC & {#config: config}
			pgHeadlessSVC: #PGHeadlessSVC & {#config: config}
			pgSts:    #PGSts & {#config: config}
		}

		if config.mysql.enabled && config.resolvedDbMode == "mysql" {
			mySecret: #MySQLSecret & {#config: config}
			mySVC:    #MySQLSVC & {#config: config}
			myHeadlessSVC: #MySQLHeadlessSVC & {#config: config}
			mySts:    #MySQLSts & {#config: config}
		}

		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}

		if config.gatewayAPI.enabled {
			httproute: #HTTPRoute & {#config: config}
		}

		if config.backup.enabled {
			backupConfigMap: #BackupConfigMap & {#config: config}
			backupCronJob:   #BackupCronJob & {#config: config}
		}

		if config.externalSecrets.enabled {
			for i, item in config.externalSecrets.items {
				"externalSecret_\(i)": #ExternalSecret & {
					#config: config
					#item:   item
				}
			}
		}
	}
}
