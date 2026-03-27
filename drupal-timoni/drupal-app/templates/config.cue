package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"list"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// The kubeVersion is a required field, set at apply-time
	// via timoni.cue by querying the user's Kubernetes API.
	kubeVersion: *"1.30.0" | string
	// Using the kubeVersion you can enforce a minimum Kubernetes minor version.
	// By default, the minimum Kubernetes version is set to 1.20.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}

	// The moduleVersion is set from the user-supplied module version.
	// This field is used for the `app.kubernetes.io/version` label.
	moduleVersion: *"1.0.0" | string

	// The Kubernetes metadata common to all resources.
	// The `metadata.name` and `metadata.namespace` fields are
	// set from the user-supplied instance name and namespace.
	metadata: timoniv1.#Metadata & {
		#Version: moduleVersion
		name:      *"default" | string
		namespace: *"default" | string
	}
	
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

	ingress: {
		enabled:   *false | bool
		className: *"" | string
		path:      *"/" | string
		annotations: timoniv1.#Annotations
		hosts: [...string]
		tls: [...{
			hosts: [...string]
			secretName: string
		}]
	}

	extraEnvVars: [...corev1.#EnvVar]

	netpol: {
		enabled: *false | bool
		openshift: enabled: *false | bool
	}
    
	drupal: {
		image:    *"drupalwxt/site-wxt" | string
		tag:      *"" | string
		imagePullPolicy: *"IfNotPresent" | string
		replicas: *1 | int
		username: *"admin" | string
		password:  *"" | string
		usePasswordFiles: *false | bool
		profile:  *"wxt" | string
		version:  *"d11" | "d9" | "d10" | "d11"
		siteRoot: *"/" | string
		initContainerImage: *"busybox:latest" | string
		volumePermissions: enabled: *false | bool
		siteEmail: *"admin@example.com" | string
		siteName:  *"Drupal WxT" | string
		smtp: {
			host:     *"mail" | string
			tls:      *false | bool
			starttls: *false | bool
			auth: {
				enabled:  *false | bool
				user:     *"" | string
				password: *"" | string
				method:   *"LOGIN" | string
			}
		}
		php: {
			ini: [string]: string
			fpm: string | *""
		}
		persistence: {
			enabled:      *false | bool
			existingClaim: *"" | string
			storageClass:  *"" | string
			accessMode:    *"ReadWriteOnce" | string
			size:          *"8Gi" | string
			iops:          *"" | string
			annotations:   timoniv1.#Annotations
		}
		cron: {
			enabled:                    *false | bool
			schedule:                   *"*/5 * * * *" | string
			successfulJobsHistoryLimit: *3 | int
			failedJobsHistoryLimit:     *1 | int
			preInstallScripts:          *"" | string
			resources:                  corev1.#ResourceRequirements
		}
		additionalCrons: [string]: {
			schedule:     string
			script:       string
			volumeMounts: [...corev1.#VolumeMount]
			volumes:      [...corev1.#Volume]
		}
		backup: {
			enabled:  *false | bool
			schedule: *"0 0 * * *" | string
			sqlDumpArgs: *"" | string
			filesArgs:   *"" | string
			privateArgs: *"" | string
			persistence: {
				enabled:       *false | bool
				existingClaim: *"" | string
				size: *"" | string
				accessMode: *"" | string
				iops: *"" | string
				storageClass: *"" | string
				annotations: timoniv1.#Annotations
			}
			volume?: {...}
			cleanup: enabled: *false | bool
		}
		autoscaling: {
			enabled:                          *false | bool
			minReplicas:                      *1 | int
			maxReplicas:                      *10 | int
			targetCPUUtilizationPercentage:    *80 | int
			targetMemoryUtilizationPercentage: *80 | int
		}
		podDisruptionBudget: {
			minAvailable?:   int | string
			maxUnavailable?: int | string
		}
		install:                    *false | bool
		backoffLimitInstall:        *5 | int
		reconfigure: {
			enabled:                *false | bool
			resources:              corev1.#ResourceRequirements
		}
		backoffLimitReconfigure:    *5 | int
		restore: {
			enabled:           *false | bool
			name:              *"latest" | string
			db:                *true | bool
			files:             *true | bool
			convert:           *false | bool
			suppressTarErrors: *false | bool
			volume?: {...}
		}
		migrate:                             *true | bool
		configSync: directory:               *"/private/config/sync" | string
		configSplit: enabled:                *false | bool
		preInstallScripts:                   *"" | string
		postInstallScripts:                  *"" | string
		preUpgradeScripts:                    *"" | string
		postUpgradeScripts:                   *"" | string
		dbAvailabilityScript:                *"until drush sql:query 'SELECT 1;' > /dev/null 2>&1; do echo Waiting for DB; sleep 3; done; echo DB available" | string
		cacheRebuildBeforeDatabaseMigration: *false | bool
		updateDBBeforeDatabaseMigration:      *true | bool
		disableDefaultFilesMount:            *false | bool
		extraSettings:                       *"" | string
		services:                            *"" | string
		extensions: enabled:                 *false | bool
		command?: [...string]
		args?: [...string]
		strategy:                            *"RollingUpdate" | "RollingUpdate" | "Recreate"
		healthcheck: {
			enabled: *true | bool
			probes?: {
				livenessProbe?:  corev1.#Probe
				readinessProbe?: corev1.#Probe
			}
		}
		conf: {
			php_ini: string | *"""
				[PHP]
				date.timezone = UTC
				zend.assertions	= 0
				upload_max_filesize = 32M
				post_max_size = 32M
				file_uploads = On
				memory_limit = 1024M
				display_errors = Off
				display_startup_errors = Off
				"""
			opcache: string | *"""
				opcache.memory_consumption=1024
				opcache.interned_strings_buffer=32
				opcache.max_accelerated_files=32531
				opcache.revalidate_freq=300
				opcache.fast_shutdown=1
				"""
			www_conf: string | *"""
				[www]
				user = www-data
				group = www-data
				listen = 127.0.0.1:9000
				pm = dynamic
				pm.max_children = 50
				pm.start_servers = 5
				pm.min_spare_servers = 5
				pm.max_spare_servers = 35
				"""
			settings_php: string | *"""
				<?php

				// Unknown drupal version specified.
				"""
			settings_d9:   string | *#DrupalSettings
			settings_d10:  string | *#DrupalSettings
			settings_d11:  string | *#DrupalSettings
			ssmtp_conf:   string | *#SSMTPConf
			pgbouncer_ini: string | *#PgBouncerConf
			userlist_txt:  string | *"drupal: password" | string
			proxysql_conf: string | *#ProxySQLConf
		}
		serviceAccount: {
			create:                       *true | bool
			name:                         *"" | string
			annotations?:                 timoniv1.#Annotations
			automountServiceAccountToken: *true | bool
		}
		serviceType:      *"ClusterIP" | string
		podAnnotations?:  timoniv1.#Annotations
		resources?:       corev1.#ResourceRequirements
		securityContext?: corev1.#PodSecurityContext
		tolerations:      [...corev1.#Toleration]
		nodeSelector:     [string]: string
		volumes:          [...corev1.#Volume]
		volumeMounts:     [...corev1.#VolumeMount]
		volumePermissions: enabled: *false | bool
	}

	nginx: {
		image:                *"drupalwxt/site-wxt" | string
		tag:                  *"" | string
		imagePullPolicy:      *"IfNotPresent" | string
		client_max_body_size: *"20m" | string
		real_ip_header:       *"X-Forwarded-For" | string
		gzip:                  *"gzip on;\n  gzip_proxied any;\n  gzip_static on;\n  gzip_vary on;\n  gzip_disable \"msie6\";\n  gzip_types application/ecmascript application/javascript application/json application/pdf application/postscript application/x-javascript image/svg+xml text/css text/csv text/javascript text/plain text/xml;" | string
		serviceType:          *"ClusterIP" | string
		replicas:             *1 | int
		resolver:             *"kube-dns.kube-system.svc.cluster.local" | string
		customLocations:      *"" | string
		rootLocationRules:    *"" | string
		podLabels:             timoniv1.#Labels
		podAnnotations:        timoniv1.#Annotations
		strategy:              *"RollingUpdate" | "RollingUpdate" | "Recreate"
		healthcheck: {
			enabled: *true | bool
			livenessProbe?:  corev1.#Probe
			readinessProbe?: corev1.#Probe
		}
		autoscaling: {
			enabled:                          *false | bool
			minReplicas:                      *1 | int
			maxReplicas:                      *10 | int
			targetCPUUtilizationPercentage:    *80 | int
			targetMemoryUtilizationPercentage: *80 | int
		}
		resources: corev1.#ResourceRequirements
		securityContext: fsGroup: *33 | int
		volumeMounts: [...corev1.#VolumeMount]
		volumes: [...corev1.#Volume]
		tolerations: [...corev1.#Toleration]
		nodeSelector?: [string]: string
		imagePullSecrets: [...corev1.#LocalObjectReference]
	}

	test: {
		enabled: *false | bool
		image: timoniv1.#Image & {
			repository: *"curlimages/curl" | string
			tag:        *"latest" | string
			digest:     *"" | string
		}
	}

	// azure block for storageclass
	azure: {
		storageClass: create: *false | bool
		azureFile: {
			...
			enabled:                 *false | bool
			skuName:                 *"Standard_LRS" | string
			protocol:                *"smb" | string
			folders:                 [...string]
			size:                    *"8Gi" | string
			accessMode:              *"ReadWriteMany" | string
			disableVolumeName:       *false | bool
			disablePVCreation:       *false | bool
			storageClass:            *"" | string
			annotations:             timoniv1.#Annotations
			initMediaIconsFolder:    *false | bool
		}
		sharedDisk: {
			...
			enabled:                 *false | bool
			maxShares:               *1 | int
			folders:                 [...string]
			size:                    *"8Gi" | string
			accessMode:              *"ReadWriteMany" | string
			disableVolumeName:       *false | bool
			disablePVCreation:       *false | bool
			storageClass:            *"" | string
			annotations:             timoniv1.#Annotations
			initMediaIconsFolder:    *false | bool
		}
	}

	// Workload settings
	resources: corev1.#ResourceRequirements
	securityContext: corev1.#SecurityContext & {
		allowPrivilegeEscalation: *false | bool
		capabilities: drop: *["ALL"] | [...string]
		readOnlyRootFilesystem: *true | bool
		runAsNonRoot:           *true | bool
		runAsUser:              *33 | int
	}
	podSecurityContext: corev1.#PodSecurityContext & {
		fsGroup: *33 | int
	}
	podAnnotations?: timoniv1.#Annotations
	service: {
		annotations?: timoniv1.#Annotations
		type:        *"ClusterIP" | string
	}

	// Affinity and more
	affinity?: corev1.#Affinity
	tolerations?: [corev1.#Toleration]
	topologySpreadConstraints?: [corev1.#TopologySpreadConstraint]
	imagePullSecrets?: [corev1.#LocalObjectReference]


	// The external allows configuring an outside database.
	external: {
		enabled:  *false | bool
		driver:   *"mysql" | string
		host:     *"mysql.example.org" | string
		port:     *3306 | int
		database: *"wxt" | string
		user:     *"wxt" | string
		password: *"password" | string
	}

	// The mysql allows configuring the internal database sub-chart.
	mysql: {
		...
		enabled: *false | bool
		image: {
			registry:   *"" | string
			repository: *"" | string
			tag:        *"" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			...
			database: *"wxt" | string
			username: *"wxt" | string
			password: *"password" | string
			rootPassword: *"password" | string
		}
		primary: {
			persistence: {
				enabled:      *false | bool
				storageClass: *"" | string
				accessMode:   *"ReadWriteOnce" | string
				size:         *"8Gi" | string
			}
			service: ports: mysql: *3306 | int
			resources?:  corev1.#ResourceRequirements
			extraFlags?: string
			strategy:    *"Recreate" | "RollingUpdate" | "Recreate"
		}
		volumePermissions: {
			enabled: *true | bool
			image: {
				registry:   *"docker.io" | string
				repository: *"bitnamilegacy/os-shell" | string
				tag:        *"12-debian-12" | string
			}
		}
	}

	postgresql: {
		...
		enabled: *false | bool
		image: {
			registry:   *"" | string
			repository: *"" | string
			tag:        *"" | string
			pullPolicy: *"IfNotPresent" | string
		}
		auth: {
			...
			database:         *"wxt" | string
			username:         *"wxt" | string
			password:         *"password" | string
			postgresPassword: *"password" | string
		}
		primary: {
			persistence: {
				enabled:      *false | bool
				storageClass: *"" | string
				accessMode:   *"ReadWriteOnce" | string
				size:         *"8Gi" | string
			}
			resources?: corev1.#ResourceRequirements
			extendedConfiguration?: string
			strategy:               *"Recreate" | "RollingUpdate" | "Recreate"
		}
		volumePermissions: {
			enabled: *true | bool
			image: {
				registry:   *"docker.io" | string
				repository: *"bitnamilegacy/os-shell" | string
				tag:        *"12-debian-12" | string
			}
		}
	}

	// Redis and Varnish blocks
	redis: {
		enabled: *false | bool
		image: {
			registry:   *"" | string
			repository: *"" | string
			tag:        *"" | string
			pullPolicy: *"IfNotPresent" | string
		}
		host:         *"" | string
		port:         *6379 | int
		architecture: *"standalone" | "standalone" | "sentinel"
		configuration?: string
		service: {
			port: *6379 | int
		}
		auth: {
			enabled: *true | bool
			password: *"secretpass" | string
			aclUsers: default: {
				permissions: *"" | string
				password:    *"secretpass" | string
			}
		}
		primary: {
			service: type: *"ClusterIP" | "ClusterIP" | "NodePort" | "LoadBalancer"
			persistence: enabled: *false | bool
		}
		replica: replicaCount: *0 | int
		queue: enabled: *true | bool
	}

	varnish: {
		enabled:      *false | bool
		replicaCount: *1 | int
		varnishd: {
			image:           *"varnish" | string
			tag:             *"" | string
			imagePullPolicy: *"IfNotPresent" | string
			imagePullSecrets: [...corev1.#LocalObjectReference]
		}
		service: {
			type: *"ClusterIP" | string
			port: *8080 | int
		}
		memorySize: *"100M" | string
		admin: {
			enabled: *false | bool
			port:    *6082 | int
			secret:  *"" | string
		}
		destinationRule: {
			enabled: *false | bool
			mode:    *"DISABLE" | string
		}
		clusterDomain:         *"cluster.local" | string
		varnishConfigContent?: string
		resources:             corev1.#ResourceRequirements
		nodeSelector: [string]: string
		tolerations: [...corev1.#Toleration]
		affinity: {
			podAffinity?:     corev1.#PodAffinity
			podAntiAffinity?: corev1.#PodAntiAffinity
			nodeAffinity?:    corev1.#NodeAffinity
		}
		volumes: [...corev1.#Volume]
		volumeMounts: [...corev1.#VolumeMount]
	}

	solr: {
		enabled: *false | bool
		image: {
			registry:   *"docker.io" | string
			repository: *"bitnamilegacy/solr" | string
			tag:        *"9.2.1-debian-11-r73" | string
			pullPolicy: *"IfNotPresent" | string
		}
		replicaCount:       *1 | int
		collectionReplicas: *1 | int
		cloudEnabled:   *false | bool
		cloudBootstrap: *false | bool
		zookeeper: {
			enabled: *false | bool
		}
		service: {
			type: *"ClusterIP" | string
			port: *8983 | int
		}
		persistence: {
			enabled:      *true | bool
			existingClaim: *"" | string
			storageClass:  *"" | string
			accessMode:    *"ReadWriteOnce" | string
			size:          *"8Gi" | string
		}
		resources: corev1.#ResourceRequirements
		strategy:  *"Recreate" | "RollingUpdate" | "Recreate"
		volumePermissions: {
			enabled: *true | bool
			image: {
				registry:   *"docker.io" | string
				repository: *"bitnamilegacy/os-shell" | string
				tag:        *"12-debian-12" | string
			}
		}
	}

	proxysql: {
		...
		enabled: *false | bool
		admin: {
			...
			user:     *"admin" | string
			password: *"admin" | string
		}
		configuration: {
			...
			maxConnections: *2048 | int
			stackSize:      *1048576 | int
			serverVersion:  *"5.5.30" | string
		}
		monitor: {
			...
			user:     *"monitor" | string
			password: *"monitor" | string
		}
	}
	
	pgbouncer: {
		enabled: *false | bool
		host:    *"postgres.default" | string
		user:    *"postgres" | string
		password: *"" | string
		poolSize: *20 | int
		maxClientConnections: *100 | int
		image: {
			registry:   *"docker.io" | string
			repository: *"bitnamilegacy/pgbouncer" | string
			tag:        *"1.19" | string
			pullPolicy: *"IfNotPresent" | string
		}
	}

	#SSMTPConf: """
		mailhub=\(drupal.smtp.host)
		FromLineOverride=YES
		\(#SSMTPTLS)
		\(#SSMTPSTARTTLS)
		\(#SSMTPAUTH)
		"""
	
	#SSMTPTLS: [if drupal.smtp.tls { "UseTLS=YES" }][0] | *""
	#SSMTPSTARTTLS: [if drupal.smtp.starttls { "UseSTARTTLS=YES" }][0] | *""
	#SSMTPAUTH: [if drupal.smtp.auth.enabled {
		"""
		AuthUser=\(drupal.smtp.auth.user)
		AuthPass=\(drupal.smtp.auth.password)
		AuthMethod=\(drupal.smtp.auth.method)
		"""
	}][0] | *""

	#PgBouncerConf: """
		[databases]
		* = host=\(pgbouncer.host) port=5432 user=\(pgbouncer.user)
		[pgbouncer]
		listen_addr = 0.0.0.0
		auth_file = /etc/pgbouncer/userlist.txt
		auth_type = trust
		server_tls_sslmode = verify-ca
		server_tls_ca_file = /etc/root.crt.pem
		listen_port = 5432
		unix_socket_dir =
		pool_mode = transaction
		default_pool_size = \(pgbouncer.poolSize)
		max_client_conn = \(pgbouncer.maxClientConnections)
		ignore_startup_parameters = extra_float_digits
		"""

	#ProxySQLConf: """
		datadir="/var/lib/proxysql"
		admin_variables=
		{
		    admin_credentials="\(proxysql.admin.user):\(proxysql.admin.password)"
		    mysql_ifaces="0.0.0.0:6032"
		    refresh_interval=2000
		}
		mysql_variables=
		{
		    threads=4
		    max_connections="\(proxysql.configuration.maxConnections)"
		    default_query_delay=0
		    default_query_timeout=36000000
		    have_compress=true
		    poll_timeout=2000
		    interfaces="0.0.0.0:3306;/tmp/proxysql.sock"
		    default_schema="information_schema"
		    stacksize="\(proxysql.configuration.stackSize)"
		    server_version="\(proxysql.configuration.serverVersion)"
		    connect_timeout_server=10000
		    monitor_history=60000
		    monitor_connect_interval=200000
		    monitor_ping_interval=200000
		    ping_interval_server_msec=10000
		    ping_timeout_server=200
		    commands_stats=true
		    sessions_sort=true
		    monitor_username="\(proxysql.monitor.user)"
		    monitor_password="\(proxysql.monitor.password)"
		}
		\(#ProxySQLBackends)
		mysql_query_rules =
		(
		    {
		            rule_id=1
		            active=1
		            match_digest="^SELECT .* FOR UPDATE"
		            destination_hostgroup=1
		            apply=1
		    },
		)
		"""

	#ProxySQLBackends: [
		if external.enabled {
			"""
			mysql_servers =
			(
			    { hostgroup_id=1, hostname="\(external.host)", port=3306 , weight=1, comment="write Group", use_ssl=1 },
			)
			mysql_users =
			(
			    { username = "\(external.user)" , password = "\(external.password)" , default_hostgroup = 1 , active = 1 }
			)
			"""
		},
		if !external.enabled && mysql.enabled {
			"""
			mysql_servers =
			(
			    { hostgroup_id=1, hostname="\(metadata.name)-mysql", port=3306 , weight=1, comment="write Group", use_ssl=1 },
			)
			mysql_users =
			(
			    { username = "\(mysql.auth.username)" , password = "\(mysql.auth.password)" , default_hostgroup = 1 , active = 1 }
			)
			"""
		},
		""
	][0]

	#DrupalSettings: """
		<?php
		$settings['hash_salt'] = 'default';
		$settings['update_free_access'] = FALSE;
		$settings['container_yamls'][] = $app_root . '/' . $site_path . '/services.yml';
		$settings['file_private_path'] =  '/private';
		$settings["config_sync_directory"] = '\(drupal.configSync.directory)';
		$settings['reverse_proxy'] = TRUE;
		$settings['reverse_proxy_addresses'] = ['0.0.0.0/0'];
		$settings['trusted_host_patterns'] = ['.*'];
		$settings['php_storage']['twig']['directory'] = '/cache/twig';

		\(#DBContent)

		\(#RedisSettings)

		if (is_file(__DIR__ . '/extra.settings.php')) {
		  include __DIR__ . '/extra.settings.php';
		}
		"""

	#DBContent: [
		if external.enabled {
			"""
			$databases['default']['default'] = [
			  'database' => '\(external.database)',
			  'username' => '\(external.user)',
			  'password' => getenv('EXTERNAL_PASSWORD') ?: '',
			  'host' => '\(external.host)',
			  'port' => \(external.port),
			  'prefix' => '',
			  'namespace' => 'Drupal\\\\Core\\\\Database\\\\Driver\\\\\(external.driver)',
			  'driver' => '\(external.driver)',
			  'collation' => 'utf8mb4_general_ci',
			];
			"""
		},
		if !external.enabled && mysql.enabled {
			"""
			$databases['default']['default'] = [
			  'database' => '\(mysql.auth.database)',
			  'username' => '\(mysql.auth.username)',
			  'password' => getenv('MYSQL_PASSWORD') ?: '',
			  'host' => '\(metadata.name)-mysql',
			  'port' => \(mysql.primary.service.ports.mysql),
			  'prefix' => '',
			  'namespace' => 'Drupal\\\\Core\\\\Database\\\\Driver\\\\mysql',
			  'driver' => 'mysql',
			  'collation' => 'utf8mb4_general_ci',
			  'pdo' => [
			    PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => false,
			  ],
			];
			"""
		},
		if !external.enabled && postgresql.enabled {
			"""
			$databases['default']['default'] = [
			  'database' => '\(postgresql.auth.database)',
			  'username' => '\(postgresql.auth.username)',
			  'password' => getenv('POSTGRES_PASSWORD') ?: '',
			  'host' => '\(metadata.name)-postgresql',
			  'port' => 5432,
			  'prefix' => '',
			  'namespace' => 'Drupal\\\\Core\\\\Database\\\\Driver\\\\pgsql',
			  'driver' => 'pgsql',
			  'collation' => 'utf8mb4_general_ci',
			];
			"""
		},
		""
	][0]

	#RedisSettings: [
		if redis.enabled {
			"""
			if (extension_loaded('redis')) {
			  $settings['cache']['default'] = 'cache.backend.redis';
			  $settings['redis.connection']['interface'] = 'PhpRedis';
			  $settings['redis.connection']['scheme'] = 'tcp';
			  $settings['redis.connection']['host'] = '\(metadata.name)-redis';
			  $settings['redis.connection']['port'] = '6379';
			  $settings['redis.connection']['password'] = getenv('REDIS_PASSWORD') ?: '';
			  $settings['redis.connection']['persistent'] = FALSE;
			  $settings['container_yamls'][] = 'modules/contrib/redis/example.services.yml';
			  $settings['container_yamls'][] = 'modules/contrib/redis/redis.services.yml';
			  $class_loader->addPsr4('Drupal\\\\redis\\\\', 'modules/contrib/redis/src');

			  $settings['bootstrap_container_definition'] = [
			    'parameters' => [],
			    'services' => [
			      'redis.factory' => [
			        'class' => 'Drupal\\redis\\ClientFactory',
			      ],
			      'cache.backend.redis' => [
			        'class' => 'Drupal\\redis\\Cache\\CacheBackendFactory',
			        'arguments' => ['@redis.factory', '@cache_tags_provider.container', '@serialization.phpserialize'],
			      ],
			      'cache.container' => [
			        'class' => '\\Drupal\\redis\\Cache\\PhpRedis',
			        'factory' => ['@cache.backend.redis', 'get'],
			        'arguments' => ['container'],
			      ],
			      'cache_tags_provider.container' => [
			        'class' => 'Drupal\\redis\\Cache\\RedisCacheTagsChecksum',
			        'arguments' => ['@redis.factory'],
			      ],
			      'serialization.phpserialize' => [
			        'class' => 'Drupal\\Component\\Serialization\\PhpSerialize',
			      ],
			    ],
			  ];
			  $settings['cache_prefix'] = 'drupal_';
			  $settings['cache']['bins']['bootstrap'] = 'cache.backend.chainedfast';
			  $settings['cache']['bins']['discovery'] = 'cache.backend.chainedfast';
			  $settings['cache']['bins']['config'] = 'cache.backend.chainedfast';
			  $settings['cache']['default'] = 'cache.backend.redis';
			  \( [ if redis.queue.enabled { "$settings['queue_default'] = 'queue.redis';" }, "" ][0] )
			}
			"""
		},
		""
	][0]

    // Consolidated env logic for vetting.
    #env: list.Concat([
        [
            {
                name:  "DB_NAME"
                value: external.database
            },
            if external.enabled {
                {
                    name: "EXTERNAL_PASSWORD"
                    valueFrom: secretKeyRef: {
                        name: metadata.name
                        key:  "database-password"
                    }
                }
            },
            if mysql.enabled {
                {
                    name: "MYSQL_PASSWORD"
                    valueFrom: secretKeyRef: {
                        name: "\(metadata.name)-mysql"
                        key:  "mysql-password"
                    }
                }
            },
            if postgresql.enabled {
                {
                    name: "POSTGRES_PASSWORD"
                    valueFrom: secretKeyRef: {
                        name: "\(metadata.name)-postgresql"
                        key:  "password"
                    }
                }
            },
            if redis.enabled {
                {
                    name: "REDIS_PASSWORD"
                    valueFrom: secretKeyRef: {
                        name: "\(metadata.name)-redis-auth"
                        key:  "default-password"
                    }
                }
            },
            if !drupal.usePasswordFiles {
                {
                    name: "DRUPAL_ADMIN_PASSWORD"
                    valueFrom: secretKeyRef: {
                        name: metadata.name
                        key:  "password"
                    }
                }
            },
        ],
        extraEnvVars,
    ])
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		"sa-drupal": #ServiceAccount & {#config: config}
		"svc-drupal": #DrupalService & {#config: config}
		"svc-nginx": #NginxService & {#config: config}
		"cm-drupal": #DrupalConfigMap & {#config: config}
		"cm-nginx": #NginxConfigMap & {#config: config}
		"secret-drupal": #DrupalSecret & {#config: config}
		"secret-ssmtp": #SSMTPSecret & {#config: config}
		if config.pgbouncer.enabled {
			"secret-pgbouncer": #PgBouncerSecret & {#config: config}
		}
		if config.proxysql.enabled {
			"secret-proxysql": #ProxySQLSecret & {#config: config}
		}
		if config.drupal.backup.enabled && config.drupal.backup.persistence.enabled && config.drupal.backup.persistence.existingClaim == "" {
			"pvc-backup": #DrupalBackupPersistentVolumeClaim & {#config: config}
		}
		"pvc-drupal": #PersistentVolumeClaim & {#config: config}
		"deploy-drupal": #DrupalDeployment & {#config: config, #cmName: objects["cm-drupal"].metadata.name, #pvcName: "\(config.metadata.name)-drupal"}
		"deploy-nginx": #NginxDeployment & {#config: config, #cmName: objects["cm-nginx"].metadata.name, #pvcName: "\(config.metadata.name)-drupal"}
		"ing-drupal": #Ingress & {#config: config}
		if config.netpol.enabled {
			"netpol-same-ns": #AllowSameNS & {#config: config}
		}
		if config.netpol.openshift.enabled {
			"netpol-openshift": #AllowOpenShiftIngress & {#config: config}
		}
		if config.azure.storageClass.create {
			"sc-azure": #StorageClass & {#config: config}
		}
		if config.drupal.cron.enabled {
			"cron-drupal": #DrupalCronJob & {#config: config, #cmName: objects["cm-drupal"].metadata.name}
		}
		if config.drupal.backup.enabled {
			"cron-backup": #DrupalBackupCronJob & {#config: config, #cmName: objects["cm-drupal"].metadata.name}
		}
		if config.drupal.install {
			"job-install": #SiteInstallJob & {#config: config, #cmName: objects["cm-drupal"].metadata.name}
		}
		if config.drupal.reconfigure.enabled {
			"job-reconfigure": #ReconfigureJob & {#config: config, #cmName: objects["cm-drupal"].metadata.name}
		}
		if config.drupal.autoscaling.enabled {
			"hpa-drupal": #DrupalHPA & {#config: config}
		}
		if config.nginx.autoscaling.enabled {
			"hpa-nginx": #NginxHPA & {#config: config}
		}
		if config.drupal.podDisruptionBudget != _|_ {
			"pdb-drupal": #PDB & {#config: config}
		}
		if config.varnish.enabled {
			"deploy-varnish": #VarnishDeployment & {#config: config}
			"svc-varnish":    #VarnishService & {#config: config}
			"cm-varnish":     #VarnishConfigMap & {#config: config}
			if config.varnish.admin.enabled {
				"svc-varnish-admin": #VarnishAdminService & {#config: config}
				"secret-varnish":    #VarnishSecret & {#config: config}
			}
			if config.varnish.destinationRule.enabled {
				"dr-varnish": #VarnishDestinationRule & {#config: config}
			}
		}

		if config.mysql.enabled {
			"pvc-mysql":    #MySQLPersistentVolumeClaim & {#config: config}
			"deploy-mysql": #MySQLDeployment & {#config: config}
			"svc-mysql":    #MySQLService & {#config: config}
			"secret-mysql": #MySQLSecret & {#config: config}
		}

		if config.postgresql.enabled {
			"pvc-postgresql":    #PostgreSQLPersistentVolumeClaim & {#config: config}
			"deploy-postgresql": #PostgreSQLDeployment & {#config: config}
			"svc-postgresql":    #PostgreSQLService & {#config: config}
			"secret-postgresql": #PostgreSQLSecret & {#config: config}
			if config.postgresql.primary.extendedConfiguration != _|_ {
				"cm-postgresql": #PostgreSQLConfigMap & {#config: config}
			}
		}

		if config.redis.enabled {
			"deploy-redis": #RedisDeployment & {#config: config}
			"svc-redis":    #RedisService & {#config: config}
			"secret-redis": #RedisSecret & {#config: config}
			if config.redis.configuration != _|_ {
				"cm-redis": #RedisConfigMap & {#config: config}
			}
		}

		if config.solr.enabled {
			"pvc-solr":    #SolrPersistentVolumeClaim & {#config: config}
			"deploy-solr": #SolrDeployment & {#config: config}
			"svc-solr":    #SolrService & {#config: config}
		}

		for v in config.azure.azureFile.folders {
			if config.azure.azureFile.enabled && !config.azure.azureFile.disablePVCreation {
				"pv-azure-\(v)": #PersistentVolume & {#config: config, #folder: v, #provider: "file"}
				"pvc-azure-\(v)": #PersistentVolumeClaimEx & {#config: config, #folder: v, #provider: "file"}
			}
		}
		for v in config.azure.sharedDisk.folders {
			if config.azure.sharedDisk.enabled && !config.azure.sharedDisk.disablePVCreation {
				"pv-shared-\(v)": #PersistentVolume & {#config: config, #folder: v, #provider: "shared"}
				"pvc-shared-\(v)": #PersistentVolumeClaimEx & {#config: config, #folder: v, #provider: "shared"}
			}
		}
		for k, v in config.drupal.additionalCrons {
			"cron-extra-\(k)": #ExtraCronJob & {#config: config, #cmName: "\(#config.metadata.name)-drupal", #cronName: k, #cron: v}
		}
	}

	tests: {
		if config.test.enabled {
			"test-job": #TestJob & {#config: config}
		}
	}
}