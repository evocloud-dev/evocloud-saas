package templates

import (
	"list"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for Moodle.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion!: string
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.26.0"}

	// The moduleVersion is set from the user-supplied module version.
	moduleVersion!: string

	// The Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// The labels allows adding `metadata.labels` to all resources.
	metadata: labels: timoniv1.#Labels

	// The annotations allows adding `metadata.annotations` to all resources.
	metadata: annotations?: timoniv1.#Annotations

	// Name and resource naming overrides
	nameOverride:     *"" | string
	fullnameOverride: *"" | string
	commonLabels:     *{...} | {[string]: string}

	// Computed helper fields
	#name:     *(metadata.name) | string
	if nameOverride != "" {
		#name: nameOverride
	}

	#fullname: *(metadata.name) | string
	if fullnameOverride != "" {
		#fullname: fullnameOverride
	}

	#cmName: *(#fullname) | string

	#adminPassword: *(moodle.adminPassword) | string
	if moodle.adminPassword == "" {
		#adminPassword: "Aa1!change-me-moodle-admin-password"
	}

	#serviceAccountName: *(#fullname) | string
	if serviceAccount.name != "" {
		#serviceAccountName: serviceAccount.name
	}
	if !serviceAccount.create && serviceAccount.name == "" {
		#serviceAccountName: "default"
	}

	#postgresqlServiceAccountName: *("default") | string
	if postgresql.serviceAccount.name != "" {
		#postgresqlServiceAccountName: postgresql.serviceAccount.name
	}
	if postgresql.serviceAccount.create && postgresql.serviceAccount.name == "" {
		#postgresqlServiceAccountName: #dbFullname
	}

	#mysqlServiceAccountName: *("default") | string
	if mysql.serviceAccount.name != "" {
		#mysqlServiceAccountName: mysql.serviceAccount.name
	}
	if mysql.serviceAccount.create && mysql.serviceAccount.name == "" {
		#mysqlServiceAccountName: #dbFullname
	}

	#mariadbServiceAccountName: *("default") | string
	if mariadb.serviceAccount.name != "" {
		#mariadbServiceAccountName: mariadb.serviceAccount.name
	}
	if mariadb.serviceAccount.create && mariadb.serviceAccount.name == "" {
		#mariadbServiceAccountName: #dbFullname
	}

	#redisServiceAccountName: *("default") | string
	if redis.serviceAccount.name != "" {
		#redisServiceAccountName: redis.serviceAccount.name
	}
	if redis.serviceAccount.create && redis.serviceAccount.name == "" {
		#redisServiceAccountName: #redisFullname
	}

	#secretName: *("\(#fullname)-admin") | string
	if moodle.existingSecret != "" {
		#secretName: moodle.existingSecret
	}

	#metricsSecret: *("\(#fullname)-metrics") | string
	if metrics.existingSecret != "" {
		#metricsSecret: metrics.existingSecret
	}

	#metricsServiceName: *("\(#fullname)-metrics") | string

	#hasOverdueTasks: list.Contains(metrics.enabledMetrics, "overdue_tasks")

	#dataClaim: *("\(#fullname)-data") | string
	if persistence.existingClaim != "" {
		#dataClaim: persistence.existingClaim
	}

	#hasRWX: list.Contains(persistence.accessModes, "ReadWriteMany")

	// Bundled database helpers
	#isBundledDB: postgresql.enabled || mysql.enabled || mariadb.enabled

	#dbAppName: *(database.type) | string
	if postgresql.enabled {
		if postgresql.nameOverride != "" {
			#dbAppName: postgresql.nameOverride
		}
		if postgresql.nameOverride == "" {
			#dbAppName: "postgresql"
		}
	}
	if mysql.enabled {
		if mysql.nameOverride != "" {
			#dbAppName: mysql.nameOverride
		}
		if mysql.nameOverride == "" {
			#dbAppName: "mysql"
		}
	}
	if mariadb.enabled {
		if mariadb.nameOverride != "" {
			#dbAppName: mariadb.nameOverride
		}
		if mariadb.nameOverride == "" {
			#dbAppName: "mariadb"
		}
	}

	#dbFullname: *(#fullname + "-" + database.type) | string
	if postgresql.enabled {
		if postgresql.fullnameOverride != "" {
			#dbFullname: postgresql.fullnameOverride
		}
		if postgresql.fullnameOverride == "" {
			#dbFullname: metadata.name + "-postgresql"
		}
	}
	if mysql.enabled {
		if mysql.fullnameOverride != "" {
			#dbFullname: mysql.fullnameOverride
		}
		if mysql.fullnameOverride == "" {
			#dbFullname: metadata.name + "-mysql"
		}
	}
	if mariadb.enabled {
		if mariadb.fullnameOverride != "" {
			#dbFullname: mariadb.fullnameOverride
		}
		if mariadb.fullnameOverride == "" {
			#dbFullname: metadata.name + "-mariadb"
		}
	}

	#dbHost: string
	if postgresql.enabled {
		if postgresql.architecture == "replication" {
			#dbHost: #dbFullname + "-primary"
		}
		if postgresql.architecture != "replication" {
			#dbHost: #dbFullname
		}
	}
	if mysql.enabled {
		if mysql.architecture == "replication" {
			#dbHost: #dbFullname + "-source"
		}
		if mysql.architecture != "replication" {
			#dbHost: #dbFullname
		}
	}
	if mariadb.enabled {
		if mariadb.architecture == "replication" {
			#dbHost: #dbFullname + "-source"
		}
		if mariadb.architecture != "replication" {
			#dbHost: #dbFullname
		}
	}
	if !#isBundledDB {
		#dbHost: database.host
	}

	#dbPort: int
	if postgresql.enabled {
		#dbPort: postgresql.service.port
	}
	if mysql.enabled {
		#dbPort: mysql.service.port
	}
	if mariadb.enabled {
		#dbPort: mariadb.service.port
	}
	if !#isBundledDB {
		if database.port != 0 {
			#dbPort: database.port
		}
		if database.port == 0 {
			if database.type == "postgresql" {
				#dbPort: 5432
			}
			if database.type != "postgresql" {
				#dbPort: 3306
			}
		}
	}

	#dbName: string
	if postgresql.enabled {
		#dbName: postgresql.auth.database
	}
	if mysql.enabled {
		#dbName: mysql.auth.database
	}
	if mariadb.enabled {
		#dbName: mariadb.auth.database
	}
	if !#isBundledDB {
		#dbName: database.name
	}

	#dbUser: string
	if postgresql.enabled {
		#dbUser: postgresql.auth.username
	}
	if mysql.enabled {
		#dbUser: mysql.auth.username
	}
	if mariadb.enabled {
		#dbUser: mariadb.auth.username
	}
	if !#isBundledDB {
		#dbUser: database.username
	}

	#dbSecret: string
	if postgresql.enabled {
		if postgresql.auth.existingSecret != "" {
			#dbSecret: postgresql.auth.existingSecret
		}
		if postgresql.auth.existingSecret == "" {
			#dbSecret: #dbFullname + "-auth"
		}
	}
	if mysql.enabled {
		if mysql.auth.existingSecret != "" {
			#dbSecret: mysql.auth.existingSecret
		}
		if mysql.auth.existingSecret == "" {
			#dbSecret: #dbFullname + "-auth"
		}
	}
	if mariadb.enabled {
		if mariadb.auth.existingSecret != "" {
			#dbSecret: mariadb.auth.existingSecret
		}
		if mariadb.auth.existingSecret == "" {
			#dbSecret: #dbFullname + "-auth"
		}
	}
	if !#isBundledDB {
		#dbSecret: database.existingSecret
	}

	#dbKey: string
	if postgresql.enabled {
		#dbKey: postgresql.auth.existingSecretUserPasswordKey
	}
	if mysql.enabled {
		#dbKey: mysql.auth.existingSecretUserPasswordKey
	}
	if mariadb.enabled {
		#dbKey: mariadb.auth.existingSecretUserPasswordKey
	}
	if !#isBundledDB {
		#dbKey: database.existingSecretPasswordKey
	}

	// Redis helper fields
	#redisFullname: *(metadata.name + "-redis") | string
	if redis.fullnameOverride != "" {
		#redisFullname: redis.fullnameOverride
	}

	#redisHost: string
	if redis.enabled {
		#redisHost: #redisFullname + "-client"
	}
	if !redis.enabled {
		#redisHost: sessions.host
	}

	#redisSecret: string
	if redis.enabled {
		if redis.auth.existingSecret != "" {
			#redisSecret: redis.auth.existingSecret
		}
		if redis.auth.existingSecret == "" {
			#redisSecret: #redisFullname + "-auth"
		}
	}
	if !redis.enabled {
		#redisSecret: sessions.existingSecret
	}

	#redisKey: string
	if redis.enabled {
		#redisKey: redis.auth.existingSecretPasswordKey
	}
	if !redis.enabled {
		#redisKey: sessions.existingSecretPasswordKey
	}

	#dbPassword: string
	if postgresql.enabled {
		if postgresql.auth.password != "" {
			#dbPassword: postgresql.auth.password
		}
		if postgresql.auth.password == "" {
			#dbPassword: "Aa1!change-me-moodle-postgres-password"
		}
	}
	if mysql.enabled {
		if mysql.auth.password != "" {
			#dbPassword: mysql.auth.password
		}
		if mysql.auth.password == "" {
			#dbPassword: "Aa1!change-me-moodle-mysql-password"
		}
	}
	if mariadb.enabled {
		if mariadb.auth.password != "" {
			#dbPassword: mariadb.auth.password
		}
		if mariadb.auth.password == "" {
			#dbPassword: "Aa1!change-me-moodle-mariadb-password"
		}
	}
	if !#isBundledDB {
		#dbPassword: ""
	}

	#postgresPasswordKey: string
	if postgresql.enabled {
		#postgresPasswordKey: postgresql.auth.existingSecretPostgresPasswordKey
	}
	if !postgresql.enabled {
		#postgresPasswordKey: ""
	}

	#postgresAdminPassword: string
	if postgresql.enabled {
		if postgresql.auth.postgresPassword != "" {
			#postgresAdminPassword: postgresql.auth.postgresPassword
		}
		if postgresql.auth.postgresPassword == "" {
			#postgresAdminPassword: "Aa1!change-me-moodle-postgres-admin-password"
		}
	}
	if !postgresql.enabled {
		#postgresAdminPassword: ""
	}

	#mysqlRootPasswordKey: string
	if mysql.enabled {
		#mysqlRootPasswordKey: mysql.auth.existingSecretRootPasswordKey
	}
	if !mysql.enabled {
		#mysqlRootPasswordKey: ""
	}

	#mysqlUserPasswordKey: string
	if mysql.enabled {
		#mysqlUserPasswordKey: mysql.auth.existingSecretUserPasswordKey
	}
	if !mysql.enabled {
		#mysqlUserPasswordKey: ""
	}

	#mysqlReplicationPasswordKey: string
	if mysql.enabled {
		#mysqlReplicationPasswordKey: mysql.auth.existingSecretReplicationPasswordKey
	}
	if !mysql.enabled {
		#mysqlReplicationPasswordKey: ""
	}

	#mysqlRootPassword: string
	if mysql.enabled {
		if mysql.auth.rootPassword != "" {
			#mysqlRootPassword: mysql.auth.rootPassword
		}
		if mysql.auth.rootPassword == "" {
			#mysqlRootPassword: "Aa1!change-me-moodle-mysql-root-password"
		}
	}
	if !mysql.enabled {
		#mysqlRootPassword: ""
	}

	#mysqlUserPassword: string
	if mysql.enabled {
		if mysql.auth.password != "" {
			#mysqlUserPassword: mysql.auth.password
		}
		if mysql.auth.password == "" {
			#mysqlUserPassword: "Aa1!change-me-moodle-mysql-password"
		}
	}
	if !mysql.enabled {
		#mysqlUserPassword: ""
	}

	#mysqlReplicationPassword: string
	if mysql.enabled {
		if mysql.auth.replicationPassword != "" {
			#mysqlReplicationPassword: mysql.auth.replicationPassword
		}
		if mysql.auth.replicationPassword == "" {
			#mysqlReplicationPassword: "Aa1!change-me-moodle-mysql-replication-password"
		}
	}
	if !mysql.enabled {
		#mysqlReplicationPassword: ""
	}

	#mariadbRootPasswordKey: string
	if mariadb.enabled {
		#mariadbRootPasswordKey: mariadb.auth.existingSecretRootPasswordKey
	}
	if !mariadb.enabled {
		#mariadbRootPasswordKey: ""
	}

	#mariadbUserPasswordKey: string
	if mariadb.enabled {
		#mariadbUserPasswordKey: mariadb.auth.existingSecretUserPasswordKey
	}
	if !mariadb.enabled {
		#mariadbUserPasswordKey: ""
	}

	#mariadbReplicationPasswordKey: string
	if mariadb.enabled {
		#mariadbReplicationPasswordKey: mariadb.auth.existingSecretReplicationPasswordKey
	}
	if !mariadb.enabled {
		#mariadbReplicationPasswordKey: ""
	}

	#mariadbRootPassword: string
	if mariadb.enabled {
		if mariadb.auth.rootPassword != "" {
			#mariadbRootPassword: mariadb.auth.rootPassword
		}
		if mariadb.auth.rootPassword == "" {
			#mariadbRootPassword: "Aa1!change-me-moodle-mariadb-root-password"
		}
	}
	if !mariadb.enabled {
		#mariadbRootPassword: ""
	}

	#mariadbUserPassword: string
	if mariadb.enabled {
		if mariadb.auth.password != "" {
			#mariadbUserPassword: mariadb.auth.password
		}
		if mariadb.auth.password == "" {
			#mariadbUserPassword: "Aa1!change-me-moodle-mariadb-password"
		}
	}
	if !mariadb.enabled {
		#mariadbUserPassword: ""
	}

	#mariadbReplicationPassword: string
	if mariadb.enabled {
		if mariadb.auth.replicationPassword != "" {
			#mariadbReplicationPassword: mariadb.auth.replicationPassword
		}
		if mariadb.auth.replicationPassword == "" {
			#mariadbReplicationPassword: "Aa1!change-me-moodle-mariadb-replication-password"
		}
	}
	if !mariadb.enabled {
		#mariadbReplicationPassword: ""
	}

	#redisPassword: string
	if redis.enabled {
		if redis.auth.password != "" {
			#redisPassword: redis.auth.password
		}
		if redis.auth.password == "" {
			#redisPassword: "Aa1!change-me-moodle-redis-password"
		}
	}
	if !redis.enabled {
		#redisPassword: ""
	}

	// Standard Labels & Selectors
	#selectorLabels: {[string]: string} & {
		"app.kubernetes.io/name":     #name
		"app.kubernetes.io/instance": metadata.name
	}

	#labels: {[string]: string} & {
		"app.kubernetes.io/name":       #name
		"app.kubernetes.io/instance":   metadata.name
		"app.kubernetes.io/version":    moduleVersion
		"app.kubernetes.io/managed-by": "timoni"
		"app.kubernetes.io/part-of":    "helmforge"
		for k, v in commonLabels {
			"\(k)": v
		}
	}

	// Environment variable helper
	#env: [
		{name: "DB_HOST", value: "\(#dbHost)"},
		{name: "DB_PORT", value: "\(#dbPort)"},
		{name: "DB_NAME", value: "\(#dbName)"},
		{name: "DB_USER", value: "\(#dbUser)"},
		{
			name: "DB_PASSWORD"
			valueFrom: secretKeyRef: {
				name: #dbSecret
				key:  #dbKey
			}
		},
		if database.tlsSecret != "" && database.type == "postgresql" {
			{name: "PGSSLROOTCERT", value: "/opt/database-tls/ca.crt"}
		},
		if sessions.enabled {
			{name: "REDIS_HOST", value: "\(#redisHost)"}
		},
		if sessions.enabled && #redisSecret != "" {
			{
				name: "REDIS_PASSWORD"
				valueFrom: secretKeyRef: {
					name: #redisSecret
					key:  #redisKey
				}
			}
		},
		if smtp.existingSecret != "" {
			{
				name: "SMTP_PASSWORD"
				valueFrom: secretKeyRef: {
					name: smtp.existingSecret
					key:  smtp.existingSecretPasswordKey
				}
			}
		},
		for ev in moodle.extraEnv {
			ev
		},
	]

	// Mounts helper
	#mounts: [
		if metrics.enabled {
			{
				name:      "metrics-token"
				mountPath: "/opt/metrics-auth"
				readOnly:  true
			}
		},
		{
			name:      "code"
			mountPath: "/var/www/html"
			readOnly:  true
		},
		{
			name:      "data"
			mountPath: "/var/moodledata"
		},
		{
			name:      "config"
			mountPath: "/opt/helmforge"
			readOnly:  true
		},
		{
			name:      "config"
			mountPath: "/usr/local/etc/php/conf.d/zz-helmforge.ini"
			subPath:   "php.ini"
			readOnly:  true
		},
		if database.tlsSecret != "" {
			{
				name:      "database-tls"
				mountPath: "/opt/database-tls"
				readOnly:  true
			}
		},
		if sessions.tlsSecret != "" {
			{
				name:      "redis-tls"
				mountPath: "/opt/redis-tls"
				readOnly:  true
			}
		},
		for vm in extraVolumeMounts {
			vm
		},
	]

	// Application Configuration
	replicaCount: *1 | int & >=0

	image!: timoniv1.#Image

	imagePullSecrets: *[] | [...corev1.#LocalObjectReference]

	source: {
		mode:            *"archive" | "image"
		url:             *"https://download.moodle.org/download.php/direct/stable502/moodle-5.2.2.tgz" | string
		sha256:          *"72be209e7c0f5341b87de0bc993b2430087fda2769d8c3cc2f32736d1513e88c" | string
		imagePath:       *"/opt/moodle" | string
		downloadTimeout: *180 | int
	}

	moodle: {
		wwwroot:                   *"http://localhost:8080" | string
		siteName:                  *"Moodle Learning Platform" | string
		shortName:                 *"Moodle" | string
		language:                  *"en" | string
		adminUser:                 *"admin" | string
		adminEmail:                *"admin@example.com" | string
		adminPassword:             *"" | string
		existingSecret:            *"" | string
		existingSecretPasswordKey: *"admin-password" | string
		autoInstall:               *true | bool
		sslProxy:                  *false | bool
		reverseProxy:              *false | bool
		disableUpdateAutodeploy:   *true | bool
		noEmailEver:               *false | bool
		timezone:                  *"UTC" | string
		extraConfig:               *"" | string
		extraEnv:                  *[] | [...corev1.#EnvVar]
		extraEnvFrom:              *[] | [...corev1.#EnvFromSource]
	}

	database: {
		type:                      *"postgresql" | "mysql" | "mariadb"
		host:                      *"" | string
		port:                      *0 | int
		name:                      *"moodle" | string
		username:                  *"moodle" | string
		existingSecret:            *"" | string
		existingSecretPasswordKey: *"password" | string
		prefix:                    *"mdl_" | string
		sslMode:                   *"prefer" | string
		mysqlSslMode:              *"disable" | string
		collation:                 *"utf8mb4_unicode_ci" | string
		tlsSecret:                 *"" | string
		tlsCAKey:                  *"ca.crt" | string
		connectTimeout:            *180 | int
	}

	postgresql: {
		enabled:          *true | bool
		architecture:     *"standalone" | string
		nameOverride:     *"" | string
		fullnameOverride: *"" | string
		image!:           timoniv1.#Image
		auth: {
			database:                          *"moodle" | string
			username:                          *"moodle" | string
			password:                          *"" | string
			postgresPassword:                  *"" | string
			existingSecret:                    *"" | string
			existingSecretUserPasswordKey:     *"user-password" | string
			existingSecretPostgresPasswordKey: *"postgres-password" | string
		}
		service: {
			port: *5432 | int
		}
		resources: corev1.#ResourceRequirements & {
			requests: {cpu: *"250m" | string, memory: *"512Mi" | string}
			limits: {cpu: *"500m" | string, memory: *"1Gi" | string}
		}
		podSecurityContext: corev1.#PodSecurityContext & {
			fsGroup:             *999 | int
			fsGroupChangePolicy: *"OnRootMismatch" | string
			seccompProfile: type: *"RuntimeDefault" | string
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *999 | int
			runAsGroup:               *999 | int
			capabilities: drop: *["ALL"] | [...string]
		}
		persistence: {
			enabled:      *true | bool
			storageClass: *"" | string
			accessModes:  *["ReadWriteOnce"] | [...string]
			size:         *"8Gi" | string
		}
		serviceAccount: {
			create:      *false | bool
			name:        *"" | string
			annotations: *{...} | {[string]: string}
		}
		terminationGracePeriodSeconds: *120 | int
	}

	mysql: {
		enabled:          *false | bool
		architecture:     *"standalone" | string
		nameOverride:     *"" | string
		fullnameOverride: *"" | string
		image!:           timoniv1.#Image
		auth: {
			database:                             *"moodle" | string
			username:                             *"moodle" | string
			password:                             *"" | string
			rootPassword:                         *"" | string
			replicationPassword:                  *"" | string
			existingSecret:                       *"" | string
			existingSecretUserPasswordKey:        *"mysql-user-password" | string
			existingSecretRootPasswordKey:        *"mysql-root-password" | string
			existingSecretReplicationPasswordKey: *"mysql-replication-password" | string
		}
		service: {
			port: *3306 | int
		}
		resources: corev1.#ResourceRequirements & {
			requests: {cpu: *"250m" | string, memory: *"512Mi" | string}
			limits: {cpu: *"500m" | string, memory: *"1Gi" | string}
		}
		podSecurityContext: corev1.#PodSecurityContext & {
			fsGroup:             *999 | int
			fsGroupChangePolicy: *"OnRootMismatch" | string
			seccompProfile: type: *"RuntimeDefault" | string
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *999 | int
			runAsGroup:               *999 | int
			capabilities: drop: *["ALL"] | [...string]
		}
		persistence: {
			enabled:      *true | bool
			storageClass: *"" | string
			accessModes:  *["ReadWriteOnce"] | [...string]
			size:         *"8Gi" | string
		}
		serviceAccount: {
			create:      *false | bool
			name:        *"" | string
			annotations: *{...} | {[string]: string}
		}
		terminationGracePeriodSeconds: *120 | int
	}

	mariadb: {
		enabled:          *false | bool
		architecture:     *"standalone" | string
		nameOverride:     *"" | string
		fullnameOverride: *"" | string
		image!:           timoniv1.#Image
		auth: {
			database:                             *"moodle" | string
			username:                             *"moodle" | string
			password:                             *"" | string
			rootPassword:                         *"" | string
			replicationPassword:                  *"" | string
			existingSecret:                       *"" | string
			existingSecretUserPasswordKey:        *"mariadb-user-password" | string
			existingSecretRootPasswordKey:        *"mariadb-root-password" | string
			existingSecretReplicationPasswordKey: *"mariadb-replication-password" | string
		}
		service: {
			port: *3306 | int
		}
		resources: corev1.#ResourceRequirements & {
			requests: {cpu: *"250m" | string, memory: *"512Mi" | string}
			limits: {cpu: *"500m" | string, memory: *"1Gi" | string}
		}
		podSecurityContext: corev1.#PodSecurityContext & {
			fsGroup:             *999 | int
			fsGroupChangePolicy: *"OnRootMismatch" | string
			seccompProfile: type: *"RuntimeDefault" | string
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *999 | int
			runAsGroup:               *999 | int
			capabilities: drop: *["ALL"] | [...string]
		}
		persistence: {
			enabled:      *true | bool
			storageClass: *"" | string
			accessModes:  *["ReadWriteOnce"] | [...string]
			size:         *"8Gi" | string
		}
		serviceAccount: {
			create:      *false | bool
			name:        *"" | string
			annotations: *{...} | {[string]: string}
		}
		terminationGracePeriodSeconds: *120 | int
	}

	sessions: {
		enabled:                   *false | bool
		host:                      *"" | string
		port:                      *6379 | int
		database:                  *0 | int
		prefix:                    *"moodle_session_" | string
		existingSecret:            *"" | string
		existingSecretPasswordKey: *"redis-password" | string
		tlsSecret:                 *"" | string
		tlsCAKey:                  *"ca.crt" | string
		acquireLockTimeout:        *120 | int
		lockExpire:                *7200 | int
	}

	redis: {
		enabled:          *false | bool
		architecture:     *"standalone" | string
		nameOverride:     *"" | string
		fullnameOverride: *"" | string
		image!:           timoniv1.#Image
		auth: {
			enabled:                   *true | bool
			password:                  *"" | string
			existingSecret:            *"" | string
			existingSecretPasswordKey: *"redis-password" | string
		}
		service: {
			port: *6379 | int
		}
		resources: corev1.#ResourceRequirements & {
			requests: {cpu: *"100m" | string, memory: *"128Mi" | string}
			limits: {cpu: *"500m" | string, memory: *"512Mi" | string}
		}
		podSecurityContext: corev1.#PodSecurityContext & {
			fsGroup:             *999 | int
			fsGroupChangePolicy: *"OnRootMismatch" | string
			seccompProfile: type: *"RuntimeDefault" | string
		}
		securityContext: corev1.#SecurityContext & {
			allowPrivilegeEscalation: *false | bool
			readOnlyRootFilesystem:   *false | bool
			runAsNonRoot:             *true | bool
			runAsUser:                *999 | int
			runAsGroup:               *999 | int
			capabilities: drop: *["ALL"] | [...string]
		}
		persistence: {
			enabled:      *true | bool
			storageClass: *"" | string
			accessModes:  *["ReadWriteOnce"] | [...string]
			size:         *"8Gi" | string
		}
		serviceAccount: {
			create:      *false | bool
			name:        *"" | string
			annotations: *{...} | {[string]: string}
		}
		terminationGracePeriodSeconds: *60 | int
	}

	persistence: {
		enabled:       *true | bool
		existingClaim: *"" | string
		storageClass:  *"" | string
		accessModes:   *["ReadWriteOnce"] | [...string]
		size:          *"10Gi" | string
		retain:        *true | bool
		annotations:   *{...} | {[string]: string}
	}

	php: {
		memoryLimit:       *"256M" | string
		uploadMaxFilesize: *"64M" | string
		postMaxSize:       *"64M" | string
		maxInputVars:      *5000 | int
		maxExecutionTime:  *300 | int
		extraIni:          *"" | string
	}

	apache: {
		maxRequestWorkers: *8 | int
	}

	cron: {
		enabled:  *true | bool
		interval: *60 | int
		resources: corev1.#ResourceRequirements & {
			requests: {cpu: *"100m" | string, memory: *"256Mi" | string}
			limits: {cpu: *"1" | string, memory: *"1Gi" | string}
		}
	}

	adhoc: {
		enabled:   *false | bool
		keepAlive: *55 | int
		resources: corev1.#ResourceRequirements & {
			requests: {cpu: *"100m" | string, memory: *"256Mi" | string}
			limits: {cpu: *"1" | string, memory: *"1Gi" | string}
		}
	}

	maintenance: {
		enabled:               *false | bool
		runId:                 *"manual-1" | string
		action:                *"checks" | "upgrade" | "purge-caches" | "enable" | "disable" | string
		activeDeadlineSeconds: *1800 | int
	}

	metrics: {
		enabled:                *false | bool
		existingSecret:         *"" | string
		existingSecretTokenKey: *"token" | string
		plugin: {
			mode:   *"archive" | "image"
			url:    *"https://codeload.github.com/daniil-berg/moodle-tool_monitoring/tar.gz/23c45f66b6c3ed409b0749017b3387c1744016cc" | string
			sha256: *"dc7a5256e93e10b0514fcb752767e2554b7aa0cd24e8c8d74e54c33b358028e1" | string
		}
		enabledMetrics: *["courses", "overdue_tasks", "quiz_attempts_in_progress", "user_accounts", "users_online"] | [...string]
		serviceMonitor: {
			enabled:           *false | bool
			labels:            *{...} | {[string]: string}
			annotations:       *{...} | {[string]: string}
			interval:          *"60s" | string
			scrapeTimeout:     *"20s" | string
			relabelings:       *[] | [...]
			metricRelabelings: *[] | [...]
		}
		prometheusRule: {
			enabled:         *false | bool
			labels:          *{...} | {[string]: string}
			unavailableFor:  *"5m" | string
			overdueTasksFor: *"15m" | string
		}
	}

	smtp: {
		hosts:                     *"" | string
		security:                  *"tls" | "ssl" | "" | string
		username:                  *"" | string
		existingSecret:            *"" | string
		existingSecretPasswordKey: *"smtp-password" | string
		noReplyAddress:            *"noreply@example.com" | string
	}

	resources: corev1.#ResourceRequirements & {
		requests: {cpu: *"250m" | string, memory: *"512Mi" | string}
		limits: {cpu: *"2" | string, memory: *"2Gi" | string}
	}

	initResources: corev1.#ResourceRequirements & {
		requests: {cpu: *"250m" | string, memory: *"256Mi" | string}
		limits: {cpu: *"2" | string, memory: *"1Gi" | string}
	}

	podSecurityContext: corev1.#PodSecurityContext & {
		runAsUser:           *33 | int
		runAsGroup:          *33 | int
		runAsNonRoot:        *true | bool
		fsGroup:             *33 | int
		fsGroupChangePolicy: *"OnRootMismatch" | string
		seccompProfile: type: *"RuntimeDefault" | string
	}

	securityContext: corev1.#SecurityContext & {
		allowPrivilegeEscalation: *false | bool
		readOnlyRootFilesystem:   *true | bool
		capabilities: drop: *["ALL"] | [...string]
	}

	terminationGracePeriodSeconds: *120 | int
	podLabels:                     *{...} | {[string]: string}
	podAnnotations:                *{...} | {[string]: string}
	nodeSelector:                  *{...} | {[string]: string}
	tolerations:                   *[] | [...corev1.#Toleration]
	affinity:                      *{...} | _
	topologySpreadConstraints:     *[] | [...corev1.#TopologySpreadConstraint]
	priorityClassName:             *"" | string
	extraVolumes:                  *[] | [...corev1.#Volume]
	extraVolumeMounts:             *[] | [...corev1.#VolumeMount]

	serviceAccount: {
		create:      *true | bool
		name:        *"" | string
		annotations: *{...} | {[string]: string}
	}

	service: {
		type:        *"ClusterIP" | string
		port:        *80 | int & >0 & <=65535
		annotations: *{...} | {[string]: string}
		ipFamilyPolicy?: string
		ipFamilies?: [...string]
	}

	gatewayAPI: {
		enabled:          *false | bool
		gatewayClassName: *"" | string
		httpRoutes:       *[] | [...]
	}

	externalSecrets: {
		enabled:         *false | bool
		refreshInterval: *"1h" | string
		items:           *[] | [...]
	}

	autoscaling: {
		enabled:                        *false | bool
		minReplicas:                    *2 | int
		maxReplicas:                    *5 | int
		targetCPUUtilizationPercentage: *70 | int
	}

	pdb: {
		enabled:      *false | bool
		minAvailable: *1 | int | string
	}

	// Validations
	if replicaCount > 1 || autoscaling.enabled {
		persistence: enabled: true
		persistence: accessModes: ["ReadWriteMany", ...]
		sessions: enabled: true
	}

	if postgresql.enabled {
		database: type: "postgresql"
		mysql: enabled: false
		mariadb: enabled: false
	}
	if mysql.enabled {
		database: type: "mysql"
		postgresql: enabled: false
		mariadb: enabled: false
	}
	if mariadb.enabled {
		database: type: "mariadb"
		postgresql: enabled: false
		mysql: enabled: false
	}

	if !#isBundledDB {
		database: host: string & !=""
		database: existingSecret: string & !=""
	}

	if sessions.enabled && !redis.enabled {
		sessions: host: string & !=""
	}
	if redis.enabled {
		sessions: enabled: true
		redis: architecture: "standalone"
	}

	if pdb.enabled && !autoscaling.enabled {
		replicaCount: int & >1
	}

	if moodle.sslProxy {
		moodle: wwwroot: string & =~"^https://"
	}

	if database.type == "postgresql" && (database.sslMode =~ "^verify-") {
		database: tlsSecret: string & !=""
	}
	if database.type != "postgresql" && database.mysqlSslMode == "verify-full" {
		database: tlsSecret: string & !=""
	}

	if source.mode == "archive" {
		source: sha256: string & !=""
	}

	if externalSecrets.enabled {
		externalSecrets: items: [..._] & [_, ...]
	}

	if gatewayAPI.enabled {
		gatewayAPI: httpRoutes: [..._] & [_, ...]
	}

	if metrics.serviceMonitor.enabled {
		metrics: enabled: true
	}
	if metrics.prometheusRule.enabled {
		metrics: serviceMonitor: enabled: true
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			sa: #ServiceAccount & {#config: config}
		}
		cm: #ConfigMap & {#config: config}
		if config.moodle.existingSecret == "" {
			secret: #Secret & {#config: config}
		}
		if config.metrics.enabled && config.metrics.existingSecret == "" {
			secretMetrics: #SecretMetrics & {#config: config}
		}
		if config.persistence.enabled && config.persistence.existingClaim == "" {
			pvc: #PersistentVolumeClaim & {#config: config}
		}
		svc: #Service & {#config: config}
		if config.metrics.enabled {
			svcMetrics: #ServiceMetrics & {#config: config}
		}
		deploy: #Deployment & {#config: config}
		if config.maintenance.enabled {
			jobMaintenance: #JobMaintenance & {#config: config}
		}
		if config.autoscaling.enabled && !config.maintenance.enabled {
			hpa: #HorizontalPodAutoscaler & {#config: config}
		}
		if config.pdb.enabled {
			pdb: #PodDisruptionBudget & {#config: config}
		}
		if config.metrics.enabled && config.metrics.serviceMonitor.enabled {
			serviceMonitor: #ServiceMonitor & {#config: config}
		}
		if config.metrics.enabled && config.metrics.prometheusRule.enabled {
			prometheusRule: #PrometheusRule & {#config: config}
		}
		if config.gatewayAPI.enabled {
			for i, r in config.gatewayAPI.httpRoutes {
				"httproute-\(i)": #HTTPRoute & {#config: config, #route: r, #index: i}
			}
		}
		if config.externalSecrets.enabled {
			for i, item in config.externalSecrets.items {
				"externalsecret-\(i)": #ExternalSecret & {#config: config, #item: item, #index: i}
			}
		}
		if config.postgresql.enabled {
			if config.postgresql.auth.existingSecret == "" {
				postgresqlSecret: #PostgresqlSecret & {#config: config}
			}
			postgresqlConfig:      #PostgresqlConfig & {#config: config}
			postgresqlInitdb:      #PostgresqlInitdb & {#config: config}
			postgresqlHeadlessSvc: #PostgresqlHeadlessService & {#config: config}
			postgresqlSvc:         #PostgresqlService & {#config: config}
			postgresqlSts:         #PostgresqlStatefulSet & {#config: config}
		}
		if config.mysql.enabled {
			if config.mysql.auth.existingSecret == "" {
				mysqlSecret: #MysqlSecret & {#config: config}
			}
			mysqlConfig:      #MysqlConfig & {#config: config}
			mysqlInitdb:      #MysqlInitdb & {#config: config}
			mysqlHeadlessSvc: #MysqlHeadlessService & {#config: config}
			mysqlSvc:         #MysqlService & {#config: config}
			mysqlSts:         #MysqlStatefulSet & {#config: config}
		}
		if config.mariadb.enabled {
			if config.mariadb.auth.existingSecret == "" {
				mariadbSecret: #MariadbSecret & {#config: config}
			}
			mariadbConfig:      #MariadbConfig & {#config: config}
			mariadbInitdb:      #MariadbInitdb & {#config: config}
			mariadbHeadlessSvc: #MariadbHeadlessService & {#config: config}
			mariadbSvc:         #MariadbService & {#config: config}
			mariadbSts:         #MariadbStatefulSet & {#config: config}
		}
		if config.redis.enabled {
			if config.redis.auth.enabled && config.redis.auth.existingSecret == "" {
				redisSecret: #RedisSecret & {#config: config}
			}
			redisConfig:      #RedisConfig & {#config: config}
			redisHeadlessSvc: #RedisHeadlessService & {#config: config}
			redisSvc:         #RedisService & {#config: config}
			redisSts:         #RedisStatefulSet & {#config: config}
		}
	}
}
