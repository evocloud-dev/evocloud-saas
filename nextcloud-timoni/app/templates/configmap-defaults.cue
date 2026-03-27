package templates

// _defaultConfigs is the CUE equivalent of Helm's files/defaultConfigs/*.tpl directory.
// It is a lookup table mapping each config filename to its PHP content.
//
// Helm reads these via: {{ tpl ($.Files.Get (printf "files/defaultConfigs/%s.tpl" $filename)) $ }}
// Timoni embeds the content here as CUE string literals.
//
// Note: imaginary.config.php uses the release name — see configmap.cue for dynamic version.
_defaultConfigs: {
	".htaccess": ""

	"apache-pretty-urls.config.php": """
		<?php
		$CONFIG = array (
		  'htaccess.RewriteBase' => '/',
		);
		"""

	"apcu.config.php": """
		<?php
		$CONFIG = array (
		  'memcache.local' => '\\OC\\Memcache\\APCu',
		);
		"""

	"apps.config.php": """
		<?php
		$CONFIG = array(
		  'apps_paths' => array(
		    0 => array (
		      'path' => OC::$SERVERROOT . '/apps',
		      'url' => '/apps',
		      'writable' => false,
		    ),
		    1 => array (
		      'path' => OC::$SERVERROOT . '/custom_apps',
		      'url' => '/custom_apps',
		      'writable' => true,
		    ),
		  ),
		);
		"""

	"autoconfig.php": """
		<?php
		$autoconfig_enabled = false;
		if (getenv('SQLITE_DATABASE')) {
		    $AUTOCONFIG['dbtype'] = 'sqlite';
		    $AUTOCONFIG['dbname'] = getenv('SQLITE_DATABASE');
		    $autoconfig_enabled = true;
		} elseif (getenv('MYSQL_DATABASE') && getenv('MYSQL_USER') && getenv('MYSQL_PASSWORD') && getenv('MYSQL_HOST')) {
		    $AUTOCONFIG['dbtype'] = 'mysql';
		    $AUTOCONFIG['dbname'] = getenv('MYSQL_DATABASE');
		    $AUTOCONFIG['dbuser'] = getenv('MYSQL_USER');
		    $AUTOCONFIG['dbpass'] = getenv('MYSQL_PASSWORD');
		    $AUTOCONFIG['dbhost'] = getenv('MYSQL_HOST');
		    $autoconfig_enabled = true;
		} elseif (getenv('POSTGRES_DB') && getenv('POSTGRES_USER') && getenv('POSTGRES_PASSWORD') && getenv('POSTGRES_HOST')) {
		    $AUTOCONFIG['dbtype'] = 'pgsql';
		    $AUTOCONFIG['dbname'] = getenv('POSTGRES_DB');
		    $AUTOCONFIG['dbuser'] = getenv('POSTGRES_USER');
		    $AUTOCONFIG['dbpass'] = getenv('POSTGRES_PASSWORD');
		    $AUTOCONFIG['dbhost'] = getenv('POSTGRES_HOST');
		    $autoconfig_enabled = true;
		}
		if ($autoconfig_enabled) {
		    $AUTOCONFIG['directory'] = getenv('NEXTCLOUD_DATA_DIR') ?: '/var/www/html/data';
		}
		"""

	// imaginary.config.php.tpl in Helm uses {{ template "nextcloud.fullname" . }} for the URL.
	// In Timoni, this is dynamically injected in #ConfigMap by using CUE interpolation.
	// This stub is overridden in #ConfigMap when imaginary.config.php is enabled.
	"imaginary.config.php": """
		<?php
		$CONFIG = array (
		  'preview_imaginary_url' => 'http://nextcloud-imaginary',
		  'enable_previews' => true,
		  'enabledPreviewProviders' => array (
		    'OC\\Preview\\Imaginary',
		    'OC\\Preview\\ImaginaryPDF',
		  ),
		);
		"""

	"redis.config.php": """
		<?php
		if (getenv('REDIS_HOST')) {
		  $CONFIG = array(
		    'memcache.distributed' => '\\OC\\Memcache\\Redis',
		    'memcache.locking' => '\\OC\\Memcache\\Redis',
		    'redis' => array(
		      'host' => getenv('REDIS_HOST'),
		      'password' => getenv('REDIS_HOST_PASSWORD_FILE') ? trim(file_get_contents(getenv('REDIS_HOST_PASSWORD_FILE'))) : (string) getenv('REDIS_HOST_PASSWORD'),
		    ),
		  );
		  if (getenv('REDIS_HOST_PORT') !== false) {
		    $CONFIG['redis']['port'] = (int) getenv('REDIS_HOST_PORT');
		  } elseif (getenv('REDIS_HOST')[0] != '/') {
		    $CONFIG['redis']['port'] = 6379;
		  }
		  if (getenv('REDIS_HOST_USER') !== false) {
		    $CONFIG['redis']['user'] = (string) getenv('REDIS_HOST_USER');
		  }
		}
		"""

	"reverse-proxy.config.php": """
		<?php
		$overwriteHost = getenv('OVERWRITEHOST');
		if ($overwriteHost) {
		  $CONFIG['overwritehost'] = $overwriteHost;
		}
		$overwriteProtocol = getenv('OVERWRITEPROTOCOL');
		if ($overwriteProtocol) {
		  $CONFIG['overwriteprotocol'] = $overwriteProtocol;
		}
		$overwriteCliUrl = getenv('OVERWRITECLIURL');
		if ($overwriteCliUrl) {
		  $CONFIG['overwrite.cli.url'] = $overwriteCliUrl;
		}
		$overwriteWebRoot = getenv('OVERWRITEWEBROOT');
		if ($overwriteWebRoot) {
		  $CONFIG['overwritewebroot'] = $overwriteWebRoot;
		}
		$trustedProxies = getenv('TRUSTED_PROXIES');
		if ($trustedProxies) {
		  $CONFIG['trusted_proxies'] = array_filter(array_map('trim', explode(' ', $trustedProxies)));
		}
		$forwardedForHeaders = getenv('FORWARDED_FOR_HEADERS');
		if ($forwardedForHeaders) {
		  $CONFIG['forwarded_for_headers'] = array_filter(array_map('trim', explode(' ', $forwardedForHeaders)));
		}
		"""

	"s3.config.php": """
		<?php
		if (getenv('OBJECTSTORE_S3_BUCKET')) {
		  $use_ssl = getenv('OBJECTSTORE_S3_SSL');
		  $use_path = getenv('OBJECTSTORE_S3_USEPATH_STYLE');
		  $use_legacyauth = getenv('OBJECTSTORE_S3_LEGACYAUTH');
		  $autocreate = getenv('OBJECTSTORE_S3_AUTOCREATE');
		  $CONFIG = array(
		    'objectstore' => array(
		      'class' => '\\OC\\Files\\ObjectStore\\S3',
		      'arguments' => array(
		        'bucket' => getenv('OBJECTSTORE_S3_BUCKET'),
		        'region' => getenv('OBJECTSTORE_S3_REGION') ?: '',
		        'hostname' => getenv('OBJECTSTORE_S3_HOST') ?: '',
		        'port' => getenv('OBJECTSTORE_S3_PORT') ?: '',
		        'storageClass' => getenv('OBJECTSTORE_S3_STORAGE_CLASS') ?: '',
		        'objectPrefix' => getenv("OBJECTSTORE_S3_OBJECT_PREFIX") ? getenv("OBJECTSTORE_S3_OBJECT_PREFIX") : "urn:oid:",
		        'autocreate' => strtolower($autocreate) !== 'false',
		        'use_ssl' => strtolower($use_ssl) !== 'false',
		        'use_path_style' => $use_path == true && strtolower($use_path) !== 'false',
		        'legacy_auth' => $use_legacyauth == true && strtolower($use_legacyauth) !== 'false'
		      )
		    )
		  );
		  if (getenv('OBJECTSTORE_S3_KEY')) {
		    $CONFIG['objectstore']['arguments']['key'] = getenv('OBJECTSTORE_S3_KEY');
		  } else {
		    $CONFIG['objectstore']['arguments']['key'] = '';
		  }
		  if (getenv('OBJECTSTORE_S3_SECRET')) {
		    $CONFIG['objectstore']['arguments']['secret'] = getenv('OBJECTSTORE_S3_SECRET');
		  } else {
		    $CONFIG['objectstore']['arguments']['secret'] = '';
		  }
		}
		"""

	"smtp.config.php": """
		<?php
		if (getenv('SMTP_HOST') && getenv('MAIL_FROM_ADDRESS') && getenv('MAIL_DOMAIN')) {
		  $CONFIG = array (
		    'mail_smtpmode' => 'smtp',
		    'mail_smtphost' => getenv('SMTP_HOST'),
		    'mail_smtpport' => getenv('SMTP_PORT') ?: (getenv('SMTP_SECURE') ? 465 : 25),
		    'mail_smtpsecure' => getenv('SMTP_SECURE') ?: '',
		    'mail_smtpauth' => getenv('SMTP_NAME') && (getenv('SMTP_PASSWORD') || getenv('SMTP_PASSWORD_FILE')),
		    'mail_smtpauthtype' => getenv('SMTP_AUTHTYPE') ?: 'LOGIN',
		    'mail_smtpname' => getenv('SMTP_NAME') ?: '',
		    'mail_from_address' => getenv('MAIL_FROM_ADDRESS'),
		    'mail_domain' => getenv('MAIL_DOMAIN'),
		  );
		  if (getenv('SMTP_PASSWORD_FILE')) {
		      $CONFIG['mail_smtppassword'] = trim(file_get_contents(getenv('SMTP_PASSWORD_FILE')));
		  } elseif (getenv('SMTP_PASSWORD')) {
		      $CONFIG['mail_smtppassword'] = getenv('SMTP_PASSWORD');
		  } else {
		      $CONFIG['mail_smtppassword'] = '';
		  }
		}
		"""

	"swift.config.php": """
		<?php
		if (getenv('OBJECTSTORE_SWIFT_URL')) {
		    $autocreate = getenv('OBJECTSTORE_SWIFT_AUTOCREATE');
		  $CONFIG = array(
		    'objectstore' => [
		      'class' => 'OC\\\\Files\\\\ObjectStore\\\\Swift',
		      'arguments' => [
		        'autocreate' => $autocreate == true && strtolower($autocreate) !== 'false',
		        'user' => [
		          'name' => getenv('OBJECTSTORE_SWIFT_USER_NAME'),
		          'password' => getenv('OBJECTSTORE_SWIFT_USER_PASSWORD'),
		          'domain' => [
		            'name' => (getenv('OBJECTSTORE_SWIFT_USER_DOMAIN')) ?: 'Default',
		          ],
		        ],
		        'scope' => [
		          'project' => [
		            'name' => getenv('OBJECTSTORE_SWIFT_PROJECT_NAME'),
		            'domain' => [
		              'name' => (getenv('OBJECTSTORE_SWIFT_PROJECT_DOMAIN')) ?: 'Default',
		            ],
		          ],
		        ],
		        'serviceName' => (getenv('OBJECTSTORE_SWIFT_SERVICE_NAME')) ?: 'swift',
		        'region' => getenv('OBJECTSTORE_SWIFT_REGION'),
		        'url' => getenv('OBJECTSTORE_SWIFT_URL'),
		        'bucket' => getenv('OBJECTSTORE_SWIFT_CONTAINER_NAME'),
		      ]
		    ]
		  );
		}
		"""

	"upgrade-disable-web.config.php": """
		<?php
		$CONFIG = array (
		  'upgrade.disable-web' => true,
		);
		"""

	"maintenance.config.php": """
		<?php
		$maintenanceWindowStart = getenv('MAINTENANCE_WINDOW_START');
		if ($maintenanceWindowStart !== false) {
		  $CONFIG['maintenance_window_start'] = (int) $maintenanceWindowStart;
		}

		$forceSTS = getenv('NEXTCLOUD_FORCE_STS');
		if ($forceSTS === 'true') {
		  $CONFIG['force_sts_set'] = true;
		  @header('Strict-Transport-Security: max-age=15768000; includeSubDomains');
		}

		$overwriteProtocol = getenv('OVERWRITEPROTOCOL');
		if ($overwriteProtocol) {
		  $CONFIG['overwriteprotocol'] = $overwriteProtocol;
		}

		$bruteForceProtection = getenv('NEXTCLOUD_BRUTEFORCE_PROTECTION');
		if ($bruteForceProtection === 'false') {
		  $CONFIG['auth.bruteforce.protection.enabled'] = false;
		}

		$bruteForceWhitelist = getenv('NEXTCLOUD_BRUTEFORCE_WHITELISTED_IPS');
		if ($bruteForceWhitelist) {
		  $CONFIG['bruteforce.ignore.whitelist'] = explode(' ', $bruteForceWhitelist);
		}
		"""
}
