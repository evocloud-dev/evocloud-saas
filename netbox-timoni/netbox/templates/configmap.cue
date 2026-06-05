package templates

import (
	"encoding/yaml"
	corev1 "k8s.io/api/core/v1"
)

#ConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.commonAnnotations != _|_ {
			annotations: #config.commonAnnotations
		}
	}
	data: {
		"configuration.py": #ConfigurationPy

		"netbox.yaml": yaml.Marshal({
			ALLOWED_HOSTS:                 #config.allowedHosts
			ALLOWED_HOSTS_INCLUDES_POD_ID: #config.allowedHostsIncludesPodIP

			DATABASES: {
				default: {
					HOST: {
						if #config.postgresql.enabled { "\(#config._fullname)-postgresql" }
						if !#config.postgresql.enabled { #config.externalDatabase.host }
					}
					USER: {
						if #config.postgresql.enabled { #config.postgresql.auth.username }
						if !#config.postgresql.enabled { #config.externalDatabase.username }
					}
					NAME: {
						if #config.postgresql.enabled { #config.postgresql.auth.database }
						if !#config.postgresql.enabled { #config.externalDatabase.database }
					}
					PORT: {
						if #config.postgresql.enabled { 5432 }
						if !#config.postgresql.enabled { #config.externalDatabase.port }
					}
					ENGINE:                      #config.externalDatabase.engine
					OPTIONS:                     #config.externalDatabase.options
					CONN_MAX_AGE:                #config.externalDatabase.connMaxAge
					DISABLE_SERVER_SIDE_CURSORS: #config.externalDatabase.disableServerSideCursors
				}
				for k, v in #config.additionalDatabases {
					"\(k)": {
						ENGINE:                      v.engine
						NAME:                        v.database
						USER:                        v.username
						HOST:                        v.host
						PORT:                        v.port
						CONN_MAX_AGE:                v.connMaxAge
						OPTIONS:                     v.options
						DISABLE_SERVER_SIDE_CURSORS: v.disableServerSideCursors
					}
				}
			}

			ADMINS:                      #config.admins
			ALLOW_TOKEN_RETRIEVAL:       #config.allowTokenRetrieval
			AUTH_PASSWORD_VALIDATORS:    #config.authPasswordValidators
			ALLOWED_URL_SCHEMES:         #config.allowedUrlSchemes
			BANNER_TOP:                  #config.banner.top
			BANNER_BOTTOM:               #config.banner.bottom
			BANNER_LOGIN:                #config.banner.login
			BASE_PATH:                   #config.basePath
			CHANGELOG_RETENTION:         #config.changelogRetention
			CUSTOM_VALIDATORS:           #config.customValidators
			DEFAULT_USER_PREFERENCES:     #config.defaultUserPreferences
			CORS_ORIGIN_ALLOW_ALL:       #config.cors.originAllowAll
			CORS_ORIGIN_WHITELIST:       #config.cors.originWhitelist
			CORS_ORIGIN_REGEX_WHITELIST: #config.cors.originRegexWhitelist
			CSRF_TRUSTED_ORIGINS:        #config.csrf.trustedOrigins
			DATA_UPLOAD_MAX_MEMORY_SIZE: #config.dataUploadMaxMemorySize
			DEBUG:                       #config.debug
			DEFAULT_LANGUAGE:            #config.defaultLanguage

			EMAIL: {
				SERVER:       #config.email.server
				PORT:         #config.email.port
				USERNAME:     #config.email.username
				USE_SSL:      #config.email.useSSL
				USE_TLS:      #config.email.useTLS
				SSL_CERTFILE: #config.email.sslCertFile
				SSL_KEYFILE:  #config.email.sslKeyFile
				TIMEOUT:      #config.email.timeout
				FROM_EMAIL:   #config.email.from
			}

			ENFORCE_GLOBAL_UNIQUE:             #config.enforceGlobalUnique
			EXEMPT_VIEW_PERMISSIONS:           #config.exemptViewPermissions
			FIELD_CHOICES:                     #config.fieldChoices
			FILE_UPLOAD_MAX_MEMORY_SIZE:       #config.fileUploadMaxMemorySize
			GRAPHQL_ENABLED:                   #config.graphQlEnabled
			HTTP_PROXIES:                      #config.httpProxies
			INTERNAL_IPS:                      #config.internalIPs
			JOB_RETENTION:                     #config.jobRetention
			LOGGING:                           #config.logging
			LOGIN_PERSISTENCE:                 #config.loginPersistence
			LOGIN_REQUIRED:                    #config.loginRequired
			LOGIN_TIMEOUT:                     #config.loginTimeout
			LOGOUT_REDIRECT_URL:               #config.logoutRedirectUrl
			MAINTENANCE_MODE:                  #config.maintenanceMode
			MAPS_URL:                          #config.mapsUrl
			MAX_PAGE_SIZE:                     #config.maxPageSize
			MEDIA_ROOT:                        "/opt/netbox/netbox/media"
			STORAGES:                          #config.storages
			METRICS_ENABLED:                   #config.metrics.enabled
			PAGINATE_COUNT:                    #config.paginateCount
			PLUGINS:                           #config.plugins
			PLUGINS_CONFIG:                    #config.pluginsConfig
			POWERFEED_DEFAULT_AMPERAGE:        #config.powerFeedDefaultAmperage
			POWERFEED_DEFAULT_MAX_UTILIZATION: #config.powerFeedMaxUtilisation
			POWERFEED_DEFAULT_VOLTAGE:         #config.powerFeedDefaultVoltage
			PREFER_IPV4:                       #config.preferIPv4
			RACK_ELEVATION_DEFAULT_UNIT_HEIGHT: #config.rackElevationDefaultUnitHeight
			RACK_ELEVATION_DEFAULT_UNIT_WIDTH:  #config.rackElevationDefaultUnitWidth
			REMOTE_AUTH_ENABLED:                #config.remoteAuth.enabled
			REMOTE_AUTH_BACKEND:                #config.remoteAuth.backends
			REMOTE_AUTH_HEADER:                 #config.remoteAuth.header
			REMOTE_AUTH_USER_FIRST_NAME:        #config.remoteAuth.userFirstName
			REMOTE_AUTH_USER_LAST_NAME:         #config.remoteAuth.userLastName
			REMOTE_AUTH_USER_EMAIL:             #config.remoteAuth.userEmail
			REMOTE_AUTH_AUTO_CREATE_USER:       #config.remoteAuth.autoCreateUser
			REMOTE_AUTH_AUTO_CREATE_GROUPS:     #config.remoteAuth.autoCreateGroups
			REMOTE_AUTH_DEFAULT_GROUPS:         #config.remoteAuth.defaultGroups
			REMOTE_AUTH_DEFAULT_PERMISSIONS:    #config.remoteAuth.defaultPermissions
			REMOTE_AUTH_GROUP_SYNC_ENABLED:     #config.remoteAuth.groupSyncEnabled
			REMOTE_AUTH_GROUP_HEADER:           #config.remoteAuth.groupHeader
			REMOTE_AUTH_SUPERUSER_GROUPS:       #config.remoteAuth.superuserGroups
			REMOTE_AUTH_SUPERUSERS:             #config.remoteAuth.superusers
			REMOTE_AUTH_STAFF_GROUPS:           #config.remoteAuth.staffGroups
			REMOTE_AUTH_STAFF_USERS:            #config.remoteAuth.staffUsers
			REMOTE_AUTH_GROUP_SEPARATOR:        #config.remoteAuth.groupSeparator
			RELEASE_CHECK_URL:                  #config.releaseCheck.url

			REDIS: {
				tasks: {
					if #config.valkey.enabled {
						HOST: "\(#config._fullname)-valkey-primary"
						PORT: 6379
					}
					if !#config.valkey.enabled {
						if len(#config.tasksDatabase.sentinels) > 0 {
							SENTINELS:        #config.tasksDatabase.sentinels
							SENTINEL_SERVICE: {
								if #config.valkey.enabled { #config.valkey.sentinel.primarySet }
								if !#config.valkey.enabled { #config.tasksDatabase.sentinelService }
							}
							SENTINEL_TIMEOUT: #config.tasksDatabase.sentinelTimeout
						}
						if len(#config.tasksDatabase.sentinels) == 0 {
							HOST: #config.tasksDatabase.host
							PORT: #config.tasksDatabase.port
						}
					}
					USERNAME:                 #config.tasksDatabase.username
					DATABASE:                 #config.tasksDatabase.database
					SSL:                      #config.tasksDatabase.ssl
					INSECURE_SKIP_TLS_VERIFY: #config.tasksDatabase.insecureSkipTlsVerify
					CA_CERT_PATH:             #config.tasksDatabase.caCertPath
				}
				caching: {
					if #config.valkey.enabled {
						HOST: "\(#config._fullname)-valkey-primary"
						PORT: 6379
					}
					if !#config.valkey.enabled {
						if len(#config.cachingDatabase.sentinels) > 0 {
							SENTINELS:        #config.cachingDatabase.sentinels
							SENTINEL_SERVICE: {
								if #config.valkey.enabled { #config.valkey.sentinel.primarySet }
								if !#config.valkey.enabled { #config.cachingDatabase.sentinelService }
							}
							SENTINEL_TIMEOUT: #config.cachingDatabase.sentinelTimeout
						}
						if len(#config.cachingDatabase.sentinels) == 0 {
							HOST: #config.cachingDatabase.host
							PORT: #config.cachingDatabase.port
						}
					}
					USERNAME:                 #config.cachingDatabase.username
					DATABASE:                 #config.cachingDatabase.database
					SSL:                      #config.cachingDatabase.ssl
					INSECURE_SKIP_TLS_VERIFY: #config.cachingDatabase.insecureSkipTlsVerify
					CA_CERT_PATH:             #config.cachingDatabase.caCertPath
				}
			}

			REPORTS_ROOT:        "/opt/netbox/netbox/reports"
			RQ_DEFAULT_TIMEOUT:  #config.rqDefaultTimeout
			SCRIPTS_ROOT:        "/opt/netbox/netbox/scripts"
			CSRF_COOKIE_NAME:    #config.csrf.cookieName
			SESSION_COOKIE_NAME: #config.sessionCookieName
			ENABLE_LOCALIZATION: #config.enableLocalization
			TIME_ZONE:           #config.timeZone
			DATE_FORMAT:         #config.dateFormat
			SHORT_DATE_FORMAT:   #config.shortDateFormat
			TIME_FORMAT:         #config.timeFormat
			SHORT_TIME_FORMAT:   #config.shortTimeFormat
			DATETIME_FORMAT:     #config.dateTimeFormat
			SHORT_DATETIME_FORMAT: #config.shortDateTimeFormat
		})

		if #config.remoteAuth.enabled && #config.remoteAuth.ldap.serverUri != "" {
			"ldap_config.py": #LDAPConfigPy
			"ldap.yaml": yaml.Marshal({
				AUTH_LDAP_SERVER_URI:          #config.remoteAuth.ldap.serverUri
				AUTH_LDAP_BIND_DN:             #config.remoteAuth.ldap.bindDn
				AUTH_LDAP_START_TLS:           #config.remoteAuth.ldap.startTls
				LDAP_IGNORE_CERT_ERRORS:       #config.remoteAuth.ldap.ignoreCertErrors
				if #config.remoteAuth.ldap.caCertDir != "" {
					LDAP_CA_CERT_DIR: #config.remoteAuth.ldap.caCertDir
				}
				if #config.remoteAuth.ldap.caCertData != "" {
					LDAP_CA_CERT_FILE: "/etc/netbox/config/ldap/ldap_ca.crt"
				}
				AUTH_LDAP_USER_DN_TEMPLATE:    #config.remoteAuth.ldap.userDnTemplate
				AUTH_LDAP_USER_SEARCH_BASEDN:  #config.remoteAuth.ldap.userSearchBaseDn
				AUTH_LDAP_USER_SEARCH_ATTR:    #config.remoteAuth.ldap.userSearchAttr
				AUTH_LDAP_GROUP_SEARCH_BASEDN: #config.remoteAuth.ldap.groupSearchBaseDn
				AUTH_LDAP_GROUP_SEARCH_CLASS:  #config.remoteAuth.ldap.groupSearchClass
				AUTH_LDAP_GROUP_TYPE:          #config.remoteAuth.ldap.groupType
				AUTH_LDAP_FIND_GROUP_PERMS:    #config.remoteAuth.ldap.findGroupPerms
				AUTH_LDAP_MIRROR_GROUPS:       #config.remoteAuth.ldap.mirrorGroups
				AUTH_LDAP_MIRROR_GROUPS_EXCEPT: #config.remoteAuth.ldap.mirrorGroupsExcept
				AUTH_LDAP_CACHE_TIMEOUT:       #config.remoteAuth.ldap.cacheTimeout
				AUTH_LDAP_REQUIRE_GROUP_LIST:  #config.remoteAuth.ldap.requireGroupDn
				AUTH_LDAP_IS_ADMIN_LIST:       #config.remoteAuth.ldap.isAdminDn
				AUTH_LDAP_IS_SUPERUSER_LIST:   #config.remoteAuth.ldap.isSuperUserDn
				AUTH_LDAP_USER_ATTR_MAP: {
					first_name: #config.remoteAuth.ldap.attrFirstName
					last_name:  #config.remoteAuth.ldap.attrLastName
					email:      #config.remoteAuth.ldap.attrMail
				}
			})
			if #config.remoteAuth.ldap.caCertData != "" {
				"ldap_ca.crt": #config.remoteAuth.ldap.caCertData
			}
		}

		for i, c in #config.extraConfig {
			if c.values != _|_ {
				"extra-\(i).yaml": yaml.Marshal(c.values)
			}
		}
	}
}
