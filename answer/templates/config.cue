package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Config: {
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	moduleVersion!: string

	metadata: timoniv1.#Metadata & {#Version: moduleVersion}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	selector: timoniv1.#Selector & {#Name: metadata.name}

	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels: {[string]: string}

	image: timoniv1.#Image & {
		repository: *"docker.io/apache/answer" | string
		tag:        *"2.0.2" | string
		pullPolicy: *"IfNotPresent" | string
		digest:     *"" | string
	}
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	answer: {
		siteUrl:                *"" | string
		siteName:               *"Apache Answer" | string
		language:               *"en-US" | string
		contactEmail:           *"admin@example.com" | string
		externalContentDisplay: *"ask_before_display" | "always_display" | string
		autoInstall:            *true | bool
		logLevel:               *"INFO" | "DEBUG" | "WARN" | "ERROR" | string
		notifications: {
			newQuestionEmail: {
				queueSize:           *1024 | int
				sendIntervalSeconds: *0 | int
			}
		}
		extraEnv: *[] | [...corev1.#EnvVar]
	}

	admin: {
		name:                      *"admin" | string
		password:                  *"" | string
		email:                     *"admin@example.com" | string
		existingSecret:            *"" | string
		existingSecretPasswordKey: *"admin-password" | string
	}

	database: {
		mode: *"auto" | "sqlite" | "external" | "postgresql" | "mysql" | string
		sqlite: {
			file: *"/data/answer.db" | string
		}
		external: {
			vendor:                    *"postgres" | "mysql" | string
			host:                      *"" | string
			port:                      *"" | string
			name:                      *"answer" | string
			username:                  *"answer" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"database-password" | string
		}
	}

	postgresql: {
		enabled:      *false | bool
		architecture: *"standalone" | string
		image: timoniv1.#Image & {
			repository: *"docker.io/library/postgres" | string
			tag:        *"18.4-trixie" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		auth: {
			database: *"answer" | string
			username: *"answer" | string
			password: *"" | string
		}
		resources?:                    timoniv1.#ResourceRequirements
		podSecurityContext?:           corev1.#PodSecurityContext
		securityContext?:              corev1.#SecurityContext
		automountServiceAccountToken?: bool
		serviceAccountName?:           string
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"8Gi" | string
			}
		}
	}

	mysql: {
		enabled:      *false | bool
		architecture: *"standalone" | string
		image: timoniv1.#Image & {
			repository: *"docker.io/library/mysql" | string
			tag:        *"9.7.2" | string
			pullPolicy: *"IfNotPresent" | string
			digest:     *"" | string
		}
		auth: {
			database:     *"answer" | string
			username:     *"answer" | string
			password:     *"" | string
			rootPassword: *"" | string
		}
		resources?:                    timoniv1.#ResourceRequirements
		podSecurityContext?:           corev1.#PodSecurityContext
		securityContext?:              corev1.#SecurityContext
		automountServiceAccountToken?: bool
		serviceAccountName?:           string
		standalone: {
			persistence: {
				enabled: *true | bool
				size:    *"8Gi" | string
			}
		}
	}

	persistence: {
		enabled:       *true | bool
		storageClass:  *"" | string
		accessMode:    *"ReadWriteOnce" | string
		size:          *"5Gi" | string
		existingClaim: *"" | string
		annotations:   {[string]: string}
	}

	resources?: corev1.#ResourceRequirements

	automountServiceAccountToken?: bool

	podSecurityContext?: corev1.#PodSecurityContext
	securityContext?:    corev1.#SecurityContext

	startupProbe: {
		enabled:             *true | bool
		path:                *"/healthz" | string
		initialDelaySeconds: *10 | int
		periodSeconds:       *5 | int
		timeoutSeconds:      *3 | int
		failureThreshold:    *30 | int
	}

	livenessProbe: {
		enabled:             *true | bool
		path:                *"/healthz" | string
		initialDelaySeconds: *0 | int
		periodSeconds:       *15 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *3 | int
	}

	readinessProbe: {
		enabled:             *true | bool
		path:                *"/healthz" | string
		initialDelaySeconds: *0 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *3 | int
	}

	service: {
		type:            *"ClusterIP" | "NodePort" | "LoadBalancer" | string
		port:            *80 | int
		annotations:     {[string]: string}
		ipFamilyPolicy?: null | string
		ipFamilies?:     [...string]
	}

	gateway: {
		enabled:     *false | bool
		annotations: {[string]: string}
		parentRefs: *[] | [...{
			name:       string
			namespace?: string
		}]
		hostnames: *[] | [...string]
		path:     *"/" | string
		pathType: *"PathPrefix" | string
	}

	serviceAccount: {
		create:      *false | bool
		name:        *"" | string
		annotations: {[string]: string}
	}

	backup: {
		enabled:                    *false | bool
		schedule:                   *"0 3 * * *" | string
		suspend:                    *false | bool
		concurrencyPolicy:          *"Forbid" | "Replace" | "Allow" | string
		successfulJobsHistoryLimit: *3 | int
		failedJobsHistoryLimit:     *3 | int
		backoffLimit:               *1 | int
		archivePrefix:              *"answer" | string
		images: {
			sqlite:     *"docker.io/library/alpine:3.22" | string
			postgresql: *"docker.io/library/postgres:18.4-alpine" | string
			mysql:      *"docker.io/library/mysql:8.4" | string
			uploader:   *"docker.io/helmforge/mc:1.0.0" | string
		}
		resources: corev1.#ResourceRequirements
		s3: {
			endpoint:                   *"" | string
			bucket:                     *"" | string
			prefix:                     *"answer" | string
			createBucketIfNotExists:    *true | bool
			existingSecret:             *"" | string
			existingSecretAccessKeyKey: *"access-key" | string
			existingSecretSecretKeyKey: *"secret-key" | string
			accessKey:                  *"" | string
			secretKey:                  *"" | string
		}
		database: {
			host:                      *"" | string
			port:                      *"" | string
			name:                      *"" | string
			username:                  *"" | string
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"database-password" | string
			postgresDumpArgs:          *"" | string
			mysqlDumpArgs:             *"--single-transaction --quick --skip-lock-tables --no-tablespaces" | string
		}
	}

	priorityClassName:             *"" | string
	terminationGracePeriodSeconds: *30 | int
	nodeSelector:                  {[string]: string}
	tolerations?:                  [...corev1.#Toleration]
	affinity?:                     corev1.#Affinity
	topologySpreadConstraints?:    [...corev1.#TopologySpreadConstraint]
	podLabels:                     {[string]: string}
	podAnnotations:                {[string]: string}
	extraVolumeMounts:             *[] | [...corev1.#VolumeMount]
	extraVolumes:                  *[] | [...corev1.#Volume]
	extraManifests:                *[] | [...{...}]

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
		admin: {
			enabled: *false | bool
			data:    *[] | [...{...}]
		}
		database: {
			enabled: *false | bool
			data:    *[] | [...{...}]
		}
		backup: {
			enabled: *false | bool
			data:    *[] | [...{...}]
		}
	}

	// Computed helper fields
	fullname: [
		if fullnameOverride != "" {
			fullnameOverride
		},
		if fullnameOverride == "" {
			if nameOverride != "" {
				"\(metadata.name)-\(nameOverride)"
			}
			if nameOverride == "" {
				"\(metadata.name)-answer"
			}
		},
	][0]

	databaseMode: [
		if database.mode == "auto" {
			if database.external.host != "" || database.external.existingSecret != "" {
				"external"
			}
			if !(database.external.host != "" || database.external.existingSecret != "") {
				if postgresql.enabled {
					"postgresql"
				}
				if !postgresql.enabled {
					if mysql.enabled {
						"mysql"
					}
					if !mysql.enabled {
						"sqlite"
					}
				}
			}
		},
		database.mode,
	][0]

	databaseVendor: [
		if databaseMode == "external" {
			database.external.vendor
		},
		if databaseMode == "postgresql" {
			"postgres"
		},
		if databaseMode == "mysql" {
			"mysql"
		},
		if databaseMode == "sqlite" {
			"sqlite3"
		},
	][0]

	dbType: [
		if databaseVendor == "sqlite3" {
			"sqlite3"
		},
		if databaseVendor == "mysql" {
			"mysql"
		},
		"postgres",
	][0]

	databaseHost: [
		if databaseMode == "external" {
			database.external.host
		},
		if databaseMode == "postgresql" {
			"\(fullname)-postgresql"
		},
		if databaseMode == "mysql" {
			"\(fullname)-mysql"
		},
		"",
	][0]

	databasePort: [
		if databaseMode == "external" {
			if database.external.port != "" {
				database.external.port
			}
			if database.external.port == "" {
				if database.external.vendor == "mysql" {
					"3306"
				}
				if database.external.vendor != "mysql" {
					"5432"
				}
			}
		},
		if databaseMode == "postgresql" {
			"5432"
		},
		if databaseMode == "mysql" {
			"3306"
		},
		"",
	][0]

	databaseName: [
		if databaseMode == "external" {
			database.external.name
		},
		if databaseMode == "postgresql" {
			postgresql.auth.database
		},
		if databaseMode == "mysql" {
			mysql.auth.database
		},
		"",
	][0]

	databaseUsername: [
		if databaseMode == "external" {
			database.external.username
		},
		if databaseMode == "postgresql" {
			postgresql.auth.username
		},
		if databaseMode == "mysql" {
			mysql.auth.username
		},
		"",
	][0]

	databasePasswordValue: [
		if databaseMode == "external" {
			database.external.password
		},
		if databaseMode == "postgresql" || postgresql.enabled {
			postgresql.auth.password
		},
		if databaseMode == "mysql" || mysql.enabled {
			mysql.auth.password
		},
		"",
	][0]

	dbHostPort: [
		if databaseHost != "" && databasePort != "" {
			"\(databaseHost):\(databasePort)"
		},
		if databaseHost != "" && databasePort == "" {
			databaseHost
		},
		"",
	][0]

	adminSecretName: [
		if admin.existingSecret != "" {
			admin.existingSecret
		},
		"\(fullname)-admin",
	][0]

	adminSecretKey: [
		if admin.existingSecret != "" {
			admin.existingSecretPasswordKey
		},
		"admin-password",
	][0]

	databaseSecretName: [
		if databaseMode == "external" && database.external.existingSecret != "" {
			database.external.existingSecret
		},
		"\(fullname)-database",
	][0]

	databaseSecretKey: [
		if databaseMode == "external" && database.external.existingSecret != "" {
			database.external.existingSecretPasswordKey
		},
		"database-password",
	][0]

	siteUrl: [
		if answer.siteUrl != "" {
			answer.siteUrl
		},
		if answer.siteUrl == "" {
			if gateway.enabled && len(gateway.hostnames) > 0 {
				"https://\(gateway.hostnames[0])"
			}
			if !(gateway.enabled && len(gateway.hostnames) > 0) {
				"http://localhost:80"
			}
		},
	][0]

	serviceAccountName: [
		if serviceAccount.create {
			if serviceAccount.name != "" {
				serviceAccount.name
			}
			if serviceAccount.name == "" {
				fullname
			}
		},
		if !serviceAccount.create {
			if serviceAccount.name != "" {
				serviceAccount.name
			}
			if serviceAccount.name == "" {
				"default"
			}
		},
	][0]
}

#Instance: {
	config: #Config

	objects: {
		if config.admin.existingSecret == "" {
			secretAdmin: #SecretAdmin & {#config: config}
		}

		let mode = config.databaseMode
		if mode != "sqlite" && !(mode == "external" && config.database.external.existingSecret != "") {
			secretDatabase: #SecretDatabase & {#config: config}
		}

		if config.backup.enabled && config.backup.s3.existingSecret == "" {
			secretBackup: #SecretBackup & {#config: config}
		}

		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PVC & {#config: config}
		}

		deployment: #Deployment & {#config: config}
		service:    #Service & {#config: config}

		if config.gateway.enabled {
			httproute: #HTTPRoute & {#config: config}
		}

		if config.serviceAccount.create {
			serviceAccount: #ServiceAccount & {#config: config}
		}

		if config.backup.enabled {
			backupCM:      #BackupConfigMap & {#config: config}
			backupCronJob: #BackupCronJob & {#config: config}
		}

		if config.externalSecrets.enabled {
			if config.externalSecrets.admin.enabled && config.admin.existingSecret != "" {
				esAdmin: #ExternalSecretAdmin & {#config: config}
			}
			if config.externalSecrets.database.enabled && config.database.external.existingSecret != "" {
				esDatabase: #ExternalSecretDatabase & {#config: config}
			}
			if config.externalSecrets.backup.enabled && config.backup.s3.existingSecret != "" {
				esBackup: #ExternalSecretBackup & {#config: config}
			}
		}

		if config.postgresql.enabled {
			pgSecret:      #PostgreSQLSecret & {#config: config}
			pgSVC:         #PostgreSQLService & {#config: config}
			pgHeadlessSVC: #PostgreSQLHeadlessService & {#config: config}
			pgDeploy:      #PostgreSQLStatefulSet & {#config: config}
		}

		if config.mysql.enabled {
			mysqlSecret:      #MySQLSecret & {#config: config}
			mysqlSVC:         #MySQLService & {#config: config}
			mysqlHeadlessSVC: #MySQLHeadlessService & {#config: config}
			mysqlDeploy:      #MySQLStatefulSet & {#config: config}
		}

		for idx, m in config.extraManifests {
			"extra-manifest-\(idx)": m
		}
	}
}
