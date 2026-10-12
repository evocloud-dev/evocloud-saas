@extern(embed)

package templates

import (
	"encoding/json"
	"strings"
	corev1 "k8s.io/api/core/v1"
)

_prepareSh:           string @embed(file="prepare.sh", type=text)
_configPhp:           string @embed(file="config.php", type=text)
_databasePhp:         string @embed(file="database.php", type=text)
_bootstrapPhp:        string @embed(file="bootstrap.php", type=text)
_metricsCheckPhp:     string @embed(file="metrics-check.php", type=text)
_metricsConfigurePhp: string @embed(file="metrics-configure.php", type=text)
_metricsSmokePhp:     string @embed(file="metrics-smoke.php", type=text)
_maintenancePhp:      string @embed(file="maintenance.php", type=text)
_runnerSh:            string @embed(file="runner.sh", type=text)
_smokePhp:            string @embed(file="smoke.php", type=text)
_databaseSmokePhp:    string @embed(file="database-smoke.php", type=text)

#ConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.#cmName
		namespace: #config.metadata.namespace
		labels:    #config.#labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}

	let _moodleSettings = {
		for k, v in #config.moodle if k != "adminPassword" && k != "extraConfig" && k != "extraEnv" && k != "extraEnvFrom" {
			"\(k)": v
		}
	}

	let _settings = {
		moodle:   _moodleSettings
		database: #config.database
		sessions: #config.sessions
		smtp:     #config.smtp
		metrics:  #config.metrics
	}

	let _phpTls = [
		if #config.database.type != "postgresql" && #config.database.tlsSecret != "" {
			"""
			; mysqlnd uses PHP's OpenSSL trust settings for Moodle's native driver.
			openssl.cafile=/opt/database-tls/ca.crt
			openssl.capath=/etc/ssl/certs
			"""
		},
		if #config.php.extraIni != "" {
			#config.php.extraIni
		},
	]

	let _phpIniBase = """
		; SPDX-License-Identifier: Apache-2.0
		memory_limit=\(#config.php.memoryLimit)
		upload_max_filesize=\(#config.php.uploadMaxFilesize)
		post_max_size=\(#config.php.postMaxSize)
		max_input_vars=\(#config.php.maxInputVars)
		max_execution_time=\(#config.php.maxExecutionTime)
		date.timezone=\(#config.moodle.timezone)
		display_errors=Off
		log_errors=On
		error_log=/proc/self/fd/2
		expose_php=Off
		session.save_path=/tmp
		opcache.enable=1
		opcache.validate_timestamps=0
		opcache.memory_consumption=128
		apc.enable_cli=1
		pcov.enabled=0
		"""

	let _phpIni = strings.Join([_phpIniBase, for part in _phpTls { part }], "\n")

	let _apacheListenMetrics = [
		if #config.metrics.enabled {
			"Listen 9090"
		},
	]

	let _apacheMetricsVirtualHost = [
		if #config.metrics.enabled {
			"""
			<LocationMatch "^/(r.php/)?monitoringexporter_prometheus/">
			  Require all denied
			</LocationMatch>
			<VirtualHost *:9090>
			  <Location />
			    Require all denied
			  </Location>
			  <LocationMatch "^/r.php/monitoringexporter_prometheus/metrics$">
			    Require all granted
			  </LocationMatch>
			</VirtualHost>
			"""
		},
	]

	let _apacheConfHeader = """
		# SPDX-License-Identifier: Apache-2.0
		ServerRoot /etc/apache2
		ServerName localhost
		PidFile /tmp/apache.pid
		DefaultRuntimeDir /tmp
		Mutex file:/tmp default
		Listen 8080
		"""

	let _apacheConfBody = """
		IncludeOptional /etc/apache2/mods-enabled/*.load
		IncludeOptional /etc/apache2/mods-enabled/*.conf
		User www-data
		Group www-data
		ServerTokens Prod
		ServerSignature Off
		TraceEnable Off
		ErrorLog /proc/self/fd/2
		LogLevel warn
		LogFormat "%h %l %u %t \\"%r\\" %>s %b" common
		CustomLog /proc/self/fd/1 common
		TypesConfig /etc/mime.types
		DirectoryIndex disabled
		DirectoryIndex index.php
		<FilesMatch "\\.php$">
		  SetHandler application/x-httpd-php
		</FilesMatch>
		StartServers 2
		MinSpareServers 1
		MaxSpareServers 2
		MaxRequestWorkers \(#config.apache.maxRequestWorkers)
		MaxConnectionsPerChild 1000
		<Directory />
		  AllowOverride None
		  Require all denied
		</Directory>
		DocumentRoot /var/www/html/public
		<Directory /var/www/html/public>
		  Options -Indexes +FollowSymLinks
		  AllowOverride None
		  Require all granted
		  FallbackResource /r.php
		</Directory>
		Alias /healthz.php /opt/helmforge/healthz.php
		Alias /readyz.php /opt/helmforge/readyz.php
		<Directory /opt/helmforge>
		  Require all denied
		  <FilesMatch "^(healthz|readyz)\\.php$">
		    Require all granted
		  </FilesMatch>
		</Directory>
		"""

	let _apacheConfParts = [
		_apacheConfHeader,
		for p in _apacheListenMetrics { p },
		_apacheConfBody,
		for p in _apacheMetricsVirtualHost { p },
	]

	let _apacheConf = strings.Join(_apacheConfParts, "\n")

	data: {
		"settings.json": json.Indent(json.Marshal(_settings), "", "    ")
		"extra-config.php": """
			<?php
			// SPDX-License-Identifier: Apache-2.0
			\(#config.moodle.extraConfig)
			"""
		"php.ini":     _phpIni
		"apache.conf": _apacheConf
		"prepare.sh":           _prepareSh
		"config.php":            _configPhp
		"database.php":          _databasePhp
		"bootstrap.php":         _bootstrapPhp
		"metrics-check.php":     _metricsCheckPhp
		"metrics-configure.php": _metricsConfigurePhp
		"metrics-smoke.php":     _metricsSmokePhp
		"maintenance.php":       _maintenancePhp
		"runner.sh":            _runnerSh
		"smoke.php":            _smokePhp
		"healthz.php": """
			<?php
			// SPDX-License-Identifier: Apache-2.0
			header('Content-Type: text/plain');
			echo "ok\\n";
			"""
		"readyz.php": """
			<?php
			// SPDX-License-Identifier: Apache-2.0
			header('Content-Type: text/plain');
			try {
			    require '/opt/helmforge/database.php';
			    $db = moodle_connection();
			    $installed = moodle_scalar($db, 'SELECT value FROM ' . moodle_table('config') . ' WHERE name=?', ['version']);
			    define('MOODLE_INTERNAL', true);
			    define('MATURITY_STABLE', 200);
			    require '/var/www/html/public/version.php';
			    if ($installed === null || (float)$installed !== (float)$version) {
			        throw new RuntimeException('Database version does not match code');
			    }
			    require '/opt/helmforge/metrics-check.php';
			    moodle_check_metrics($db);
			    if (is_file('/var/moodledata/climaintenance.html')) {
			        http_response_code(503);
			        echo "maintenance\\n";
			    } else {
			        echo "ready\\n";
			    }
			} catch (Throwable $e) {
			    http_response_code(503);
			    echo "not ready\\n";
			}
			"""
		"database-smoke.php": _databaseSmokePhp
	}
}
