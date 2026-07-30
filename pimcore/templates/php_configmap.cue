package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigMapPhpEnv: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-php-env"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		PHP_MEMORY_LIMIT:              #config.php.ini.pimcore.phpMemoryLimit
		PHP_MAX_EXECUTION_TIME:        "\(#config.php.ini.pimcore.phpMaxExecutionTime)"
		PHP_ERROR_REPORTING:          #config.php.ini.pimcore.phpErrorReporting
		PHP_DISPLAY_ERRORS:            #config.php.ini.pimcore.phpDisplayErrors
		PHP_DISPLAY_STARTUP_ERRORS:    "\(#config.php.ini.pimcore.phpDisplayStartupErrors)"
		PHP_POST_MAX_SIZE:             #config.php.ini.pimcore.phpPostMaxSize
		PHP_UPLOAD_MAX_FILESIZE:       #config.php.ini.pimcore.phpUploadMaxFilesize
		OPCACHE_ENABLE:                "\(#config.php.ini.pimcore.opcacheEnable)"
		OPCACHE_ENABLE_CLI:            "\(#config.php.ini.pimcore.opcacheEnableCli)"
		OPCACHE_MEMORY_CONSUMPTION:    "\(#config.php.ini.pimcore.opcacheMemoryConsumption)"
		OPCACHE_MAX_ACCELERATED_FILES: "\(#config.php.ini.pimcore.opcacheMaxAcceleratedFiles)"
		OPCACHE_VALIDATE_TIMESTAMPS:   "\(#config.php.ini.pimcore.opcacheValidateTimestamps)"
		OPCACHE_CONSISTENCY_CHECKS:    "\(#config.php.ini.pimcore.opcacheConsistencyChecks)"
	}
}

#ConfigMapPhpConfD30PimcoreIni: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-php-conf-d-30-pimcore-ini"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		"30-pimcore.ini": """
			memory_limit = ${PHP_MEMORY_LIMIT}
			max_execution_time = ${PHP_MAX_EXECUTION_TIME}
			error_reporting = ${PHP_ERROR_REPORTING}
			display_errors = ${PHP_DISPLAY_ERRORS}
			display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}
			post_max_size = ${PHP_POST_MAX_SIZE}
			upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}
			
			opcache.enable = ${OPCACHE_ENABLE}
			opcache.enable_cli = ${OPCACHE_ENABLE_CLI}
			opcache.memory_consumption = ${OPCACHE_MEMORY_CONSUMPTION}
			opcache.max_accelerated_files = ${OPCACHE_MAX_ACCELERATED_FILES}
			opcache.validate_timestamps = ${OPCACHE_VALIDATE_TIMESTAMPS}
			opcache.consistency_checks = ${OPCACHE_CONSISTENCY_CHECKS}
			"""
	}
}

#ConfigMapPhpFpmConf: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-php-fpm-conf"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		"php-fpm.conf": """
			[global]
			include=etc/php-fpm.d/*.conf
			"""
	}
}

#ConfigMapPhpFpmDzzzzWwwPoolConf: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-php-fpm-d-zzzz-www-pool-conf"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		"zzzz-www-pool.conf": """
			[www]
			user = \(#config.php.phpUser.userName)
			group = \(#config.php.phpUser.groupName)
			listen = 0.0.0.0:9000
			pm = \(#config.php.fpmPool.pm)
			pm.max_children = \(#config.php.fpmPool.pmMaxChildren)
			pm.start_servers = \(#config.php.fpmPool.pmStartServers)
			pm.min_spare_servers = \(#config.php.fpmPool.pmMinSpareServers)
			pm.max_spare_servers = \(#config.php.fpmPool.pmMaxSpareServers)
			pm.max_requests = \(#config.php.fpmPool.pmMaxRequests)
			pm.process_idle_timeout = \(#config.php.fpmPool.pmProcessIdleTimeout)
			; Discard the FPM access log. The upstream image's docker.conf sets
			; access.log = /proc/self/fd/2 (stderr), so every HTTP request emits a line
			; the node logging agent ships to Cloud Logging tagged severity=ERROR.
			; nginx already writes access logs to its own file, so the FPM copy is pure
			; duplicate noise. This pool conf loads after docker.conf (zzzz- prefix), so
			; this directive wins.
			access.log = /dev/null
			; FPM internal ping endpoint, intercepted by the FPM master before any
			; PHP worker dispatch — cache:clear-immune. Targeted by the K8s liveness
			; and startup probes via cgi-fcgi (see charts/pimcore/values.yaml php
			; livenessProbe / startupProbe).
			ping.path = /fpm-ping
			ping.response = pong
			"""
	}
}

#ConfigMapPhpIni: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-php-ini"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		"php.ini": """
			[PHP]
			engine = On
			short_open_tag = Off
			precision = 14
			output_buffering = 4096
			zlib.output_compression = Off
			implicit_flush = Off
			unserialize_callback_func =
			serialize_precision = -1
			disable_functions =
			disable_classes =
			zend.enable_gc = On
			expose_php = On
			request_terminate_timeout = 1200
			max_execution_time = 1200
			max_input_time = 1200
			memory_limit = -1
			error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
			display_errors = Off
			display_startup_errors = Off
			log_errors = On
			log_errors_max_len = 1024
			error_log = /var/www/var/logs/php_error.log
			ignore_repeated_errors = Off
			ignore_repeated_source = Off
			report_memleaks = On
			track_errors = Off
			html_errors = On
			variables_order = "EGPCS"
			request_order = "GP"
			register_argc_argv = Off
			auto_globals_jit = On
			post_max_size = 512M
			auto_prepend_file =
			auto_append_file =
			default_mimetype = "text/html"
			default_charset = "UTF-8"
			doc_root =
			user_dir =
			enable_dl = Off
			cgi.fix_pathinfo=0
			file_uploads = On
			upload_max_filesize = 512M
			max_file_uploads = 20
			allow_url_fopen = On
			allow_url_include = Off
			default_socket_timeout = 60
			realpath_cache_size = 4096k
			realpath_cache_ttl = 7200
			[CLI Server]
			cli_server.color = On
			[Date]
			date.timezone = Europe/Berlin
			[filter]
			[iconv]
			[intl]
			[sqlite3]
			[Pcre]
			[Pdo]
			[Pdo_mysql]
			pdo_mysql.cache_size = 2000
			pdo_mysql.default_socket=
			[Phar]
			[mail function]
			SMTP = localhost
			smtp_port = 25
			mail.add_x_header = On
			[SQL]
			sql.safe_mode = Off
			[ODBC]
			odbc.allow_persistent = On
			odbc.check_persistent = On
			odbc.max_persistent = -1
			odbc.max_links = -1
			odbc.defaultlrl = 4096
			odbc.defaultbinmode = 1
			[Interbase]
			ibase.allow_persistent = 1
			ibase.max_persistent = -1
			ibase.max_links = -1
			ibase.timestampformat = "%Y-%m-%d %H:%M:%S"
			ibase.dateformat = "%Y-%m-%d"
			ibase.timeformat = "%H:%M:%S"
			[MySQLi]
			mysqli.max_persistent = -1
			mysqli.allow_persistent = On
			mysqli.max_links = -1
			mysqli.cache_size = 2000
			mysqli.default_port = 3306
			mysqli.default_socket =
			mysqli.default_host =
			mysqli.default_user =
			mysqli.default_pw =
			mysqli.reconnect = Off
			[mysqlnd]
			mysqlnd.collect_statistics = On
			mysqlnd.collect_memory_statistics = Off
			[OCI8]
			[PostgreSQL]
			pgsql.allow_persistent = On
			pgsql.auto_reset_persistent = Off
			pgsql.max_persistent = -1
			pgsql.max_links = -1
			pgsql.ignore_notice = 0
			pgsql.log_notice = 0
			[bcmath]
			bcmath.scale = 0
			[browscap]
			[Session]
			session.use_strict_mode = 0
			session.use_cookies = 1
			session.use_only_cookies = 1
			session.name = PHPSESSID
			session.auto_start = 0
			session.cookie_lifetime = 0
			session.cookie_path = /
			session.serialize_handler = php
			session.gc_probability = 1
			session.gc_divisor = 1000
			session.gc_maxlifetime = 1440
			session.cache_limiter = nocache
			session.cache_expire = 180
			session.use_trans_sid = 0
			session.sid_length = 26
			session.trans_sid_tags = "a=href,area=href,frame=src,form="
			session.sid_bits_per_character = 5
			[Assertion]
			zend.assertions = -1
			[COM]
			[mbstring]
			[gd]
			[exif]
			[Tidy]
			tidy.clean_output = Off
			[soap]
			soap.wsdl_cache_enabled=1
			soap.wsdl_cache_dir="/tmp"
			soap.wsdl_cache_ttl=86400
			soap.wsdl_cache_limit = 5
			[sysvshm]
			[ldap]
			ldap.max_links = -1
			[mcrypt]
			[dba]
			[opcache]
			opcache.enable=1
			opcache.memory_consumption=256
			opcache.interned_strings_buffer=8
			opcache.max_accelerated_files=11000
			opcache.fast_shutdown=1
			[curl]
			[openssl]
			"""
	}
}


