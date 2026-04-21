package templates

import (
	corev1 "k8s.io/api/core/v1"
	"strings"
)

#ConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-env"
		labels:    #config.metadata.labels
	}
	data: {
		ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY:         #config.mastodon.secrets.activeRecordEncryption.primaryKey
		ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY:   #config.mastodon.secrets.activeRecordEncryption.deterministicKey
		ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT: #config.mastodon.secrets.activeRecordEncryption.keyDerivationSalt

		RAILS_LOG_LEVEL: #config.mastodon.logLevel.rails
		LOG_LEVEL:       #config.mastodon.logLevel.streaming

		DB_HOST: {
			if #config.postgresql.direct.hostname != null && #config.postgresql.direct.hostname != "" {
				#config.postgresql.direct.hostname
			}
			if #config.postgresql.direct.hostname == null || #config.postgresql.direct.hostname == "" {
				if #config.postgresql.enabled {
					"\(#config.metadata.name)-postgresql"
				}
				if !#config.postgresql.enabled {
					#config.postgresql.postgresqlHostname
				}
			}
		}
		DB_PORT: {
			if #config.postgresql.direct.port != null && #config.postgresql.direct.port != "" {
				"\(#config.postgresql.direct.port)"
			}
			if #config.postgresql.direct.port == null || #config.postgresql.direct.port == "" {
				if #config.postgresql.enabled {
					"5432"
				}
				if !#config.postgresql.enabled {
					"\(#config.postgresql.postgresqlPort)"
				}
			}
		}
		DB_NAME: {
			if #config.postgresql.direct.database != null && #config.postgresql.direct.database != "" {
				#config.postgresql.direct.database
			}
			if #config.postgresql.direct.database == null || #config.postgresql.direct.database == "" {
				#config.postgresql.auth.database
			}
		}
		DB_USER: #config.postgresql.auth.username

		if #config.postgresql.readReplica.hostname != "" {
			REPLICA_DB_HOST: #config.postgresql.readReplica.hostname
		}
		if "\(#config.postgresql.readReplica.port)" != "0" && "\(#config.postgresql.readReplica.port)" != "" {
			REPLICA_DB_PORT: "\(#config.postgresql.readReplica.port)"
		}
		if #config.postgresql.readReplica.auth.database != "" {
			REPLICA_DB_NAME: #config.postgresql.readReplica.auth.database
		}
		if #config.postgresql.readReplica.auth.username != "" {
			REPLICA_DB_USER: #config.postgresql.readReplica.auth.username
		}
		if #config.postgresql.readReplica.auth.password != "" {
			REPLICA_DB_PASS: #config.postgresql.readReplica.auth.password
		}

		PREPARED_STATEMENTS: "\(#config.mastodon.preparedStatements)"

		if #config.mastodon.locale != "" {
			DEFAULT_LOCALE: #config.mastodon.locale
		}

		if #config.elasticsearch.enabled {
			ES_ENABLED: "true"
			ES_PRESET:  #config.elasticsearch.preset
			ES_HOST:    "\(#config.metadata.name)-elasticsearch-master-hl.\(#config.metadata.namespace).svc.cluster.local"
			ES_PORT:    "9200"
		}
		if !#config.elasticsearch.enabled && #config.elasticsearch.hostname != "" {
			ES_ENABLED: "true"
			ES_PRESET:  #config.elasticsearch.preset
			ES_HOST:    #config.elasticsearch.hostname
			ES_PORT:    "\(#config.elasticsearch.port)"
		}

		if #config.elasticsearch.user != _|_ {
			ES_USER: #config.elasticsearch.user
		}
		if #config.elasticsearch.indexPrefix != _|_ {
			ES_PREFIX: #config.elasticsearch.indexPrefix
		}

		LOCAL_DOMAIN: #config.mastodon.local_domain
		if #config.mastodon.web_domain != null {
			WEB_DOMAIN: #config.mastodon.web_domain
		}
		if len(#config.mastodon.alternate_domains) > 0 {
			ALTERNATE_DOMAINS: strings.Join(#config.mastodon.alternate_domains, ",")
		}
		if #config.mastodon.singleUserMode {
			SINGLE_USER_MODE: "true"
		}
		if #config.mastodon.authorizedFetch {
			AUTHORIZED_FETCH: "true"
		}
		if #config.mastodon.limitedFederationMode {
			LIMITED_FEDERATION_MODE: "true"
		}

		MALLOC_ARENA_MAX: "2"
		NODE_ENV:         "production"
		RAILS_ENV:        "production"

		REDIS_HOST: {
			if #config.redis.hostname != null && #config.redis.hostname != "" {
				#config.redis.hostname
			}
			if #config.redis.hostname == null || #config.redis.hostname == "" {
				"\(#config.metadata.name)-redis-master"
			}
		}
		REDIS_PORT: {
			if #config.redis.port != null && #config.redis.port != 0 {
				"\(#config.redis.port)"
			}
			if #config.redis.port == null || #config.redis.port == 0 {
				"6379"
			}
		}
		if #config.redis.auth.password != "" {
			REDIS_PASSWORD: #config.redis.auth.password
		}

		if #config.redis.sidekiq.enabled {
			SIDEKIQ_REDIS_HOST: {
				if #config.redis.sidekiq.hostname != "" {
					#config.redis.sidekiq.hostname
				}
				if #config.redis.sidekiq.hostname == "" {
					"\(#config.metadata.name)-redis-master"
				}
			}
			SIDEKIQ_REDIS_PORT: {
				if #config.redis.sidekiq.port != 0 {
					"\(#config.redis.sidekiq.port)"
				}
				if #config.redis.sidekiq.port == 0 {
					"6379"
				}
			}
		}

		if #config.redis.cache.enabled {
			CACHE_REDIS_HOST: {
				if #config.redis.cache.hostname != null && #config.redis.cache.hostname != "" {
					#config.redis.cache.hostname
				}
				if #config.redis.cache.hostname == null || #config.redis.cache.hostname == "" {
					"\(#config.metadata.name)-redis-master"
				}
			}
			CACHE_REDIS_PORT: {
				if #config.redis.cache.port != null && #config.redis.cache.port != 0 {
					"\(#config.redis.cache.port)"
				}
				if #config.redis.cache.port == null || #config.redis.cache.port == 0 {
					"6379"
				}
			}
			if #config.redis.auth.password != "" {
				CACHE_REDIS_PASSWORD: #config.redis.auth.password
			}
		}

		if #config.mastodon.s3.enabled {
			S3_BUCKET:   #config.mastodon.s3.bucket
			S3_ENABLED:  "true"
			S3_ENDPOINT: #config.mastodon.s3.endpoint
			S3_HOSTNAME: #config.mastodon.s3.hostname
			S3_PROTOCOL: #config.mastodon.s3.protocol
			if #config.mastodon.s3.permission != "" {
				S3_PERMISSION: #config.mastodon.s3.permission
			}
			if #config.mastodon.s3.region != "" {
				S3_REGION: #config.mastodon.s3.region
			}
			if #config.mastodon.s3.alias_host != "" {
				S3_ALIAS_HOST: #config.mastodon.s3.alias_host
			}
			if #config.mastodon.s3.multipart_threshold != "" {
				S3_MULTIPART_THRESHOLD: #config.mastodon.s3.multipart_threshold
			}
		}

		if #config.mastodon.smtp.auth_method != "" {
			SMTP_AUTH_METHOD: #config.mastodon.smtp.auth_method
		}
		if #config.mastodon.smtp.ca_file != "" {
			SMTP_CA_FILE: #config.mastodon.smtp.ca_file
		}
		if #config.mastodon.smtp.delivery_method != "" {
			SMTP_DELIVERY_METHOD: #config.mastodon.smtp.delivery_method
		}
		if #config.mastodon.smtp.domain != "" {
			SMTP_DOMAIN: #config.mastodon.smtp.domain
		}
		if #config.mastodon.smtp.enable_starttls != "" {
			SMTP_ENABLE_STARTTLS: #config.mastodon.smtp.enable_starttls
		}
		if #config.mastodon.smtp.from_address != "" {
			SMTP_FROM_ADDRESS: #config.mastodon.smtp.from_address
		}
		if #config.mastodon.smtp.return_path != "" {
			SMTP_RETURN_PATH: #config.mastodon.smtp.return_path
		}
		SMTP_OPENSSL_VERIFY_MODE: #config.mastodon.smtp.openssl_verify_mode
		SMTP_PORT:                "\(#config.mastodon.smtp.port)"
		if #config.mastodon.smtp.reply_to != "" {
			SMTP_REPLY_TO: #config.mastodon.smtp.reply_to
		}
		if #config.mastodon.smtp.server != "" {
			SMTP_SERVER: #config.mastodon.smtp.server
		}
		SMTP_TLS: "\(#config.mastodon.smtp.tls)"

		if #config.mastodon.smtp.bulk.enabled {
			if #config.mastodon.smtp.bulk.auth_method != "" {
				BULK_SMTP_AUTH_METHOD: #config.mastodon.smtp.bulk.auth_method
			}
			if #config.mastodon.smtp.bulk.ca_file != "" {
				BULK_SMTP_CA_FILE: #config.mastodon.smtp.bulk.ca_file
			}
			if #config.mastodon.smtp.bulk.domain != "" {
				BULK_SMTP_DOMAIN: #config.mastodon.smtp.bulk.domain
			}
			if #config.mastodon.smtp.bulk.enable_starttls != "" {
				BULK_SMTP_ENABLE_STARTTLS: #config.mastodon.smtp.bulk.enable_starttls
			}
			if #config.mastodon.smtp.bulk.from_address != "" {
				BULK_SMTP_FROM_ADDRESS: #config.mastodon.smtp.bulk.from_address
			}
			BULK_SMTP_OPENSSL_VERIFY_MODE: #config.mastodon.smtp.bulk.openssl_verify_mode
			BULK_SMTP_PORT:                "\(#config.mastodon.smtp.bulk.port)"
			if #config.mastodon.smtp.bulk.server != "" {
				BULK_SMTP_SERVER: #config.mastodon.smtp.bulk.server
			}
			BULK_SMTP_TLS: "\(#config.mastodon.smtp.bulk.tls)"
		}

		STREAMING_CLUSTER_NUM: "\(#config.mastodon.streaming.workers)"
		if #config.mastodon.streaming.base_url != null {
			STREAMING_API_BASE_URL: #config.mastodon.streaming.base_url
		}
		if #config.mastodon.trusted_proxy_ip != null {
			TRUSTED_PROXY_IP: #config.mastodon.trusted_proxy_ip
		}

		if #config.externalAuth.oidc.enabled {
			OIDC_ENABLED:                          "\(#config.externalAuth.oidc.enabled)"
			OIDC_DISPLAY_NAME:                     #config.externalAuth.oidc.display_name
			OIDC_ISSUER:                           #config.externalAuth.oidc.issuer
			OIDC_DISCOVERY:                        "\(#config.externalAuth.oidc.discovery)"
			OIDC_SCOPE:                            "\(#config.externalAuth.oidc.scope)"
			OIDC_UID_FIELD:                        #config.externalAuth.oidc.uid_field
			OIDC_CLIENT_ID:                        "\(#config.externalAuth.oidc.client_id)"
			OIDC_CLIENT_SECRET:                    #config.externalAuth.oidc.client_secret
			OIDC_REDIRECT_URI:                     #config.externalAuth.oidc.redirect_uri
			OIDC_SECURITY_ASSUME_EMAIL_IS_VERIFIED: "\(#config.externalAuth.oidc.assume_email_is_verified)"
			if #config.externalAuth.oidc.client_auth_method != "" {OIDC_CLIENT_AUTH_METHOD: #config.externalAuth.oidc.client_auth_method}
			if #config.externalAuth.oidc.response_type != "" {OIDC_RESPONSE_TYPE: #config.externalAuth.oidc.response_type}
			if #config.externalAuth.oidc.response_mode != "" {OIDC_RESPONSE_MODE: #config.externalAuth.oidc.response_mode}
			if #config.externalAuth.oidc.display != "" {OIDC_DISPLAY: #config.externalAuth.oidc.display}
			if #config.externalAuth.oidc.prompt != "" {OIDC_PROMPT: #config.externalAuth.oidc.prompt}
			if #config.externalAuth.oidc.send_nonce != "" {OIDC_SEND_NONCE: #config.externalAuth.oidc.send_nonce}
			if #config.externalAuth.oidc.send_scope_to_token_endpoint != "" {OIDC_SEND_SCOPE_TO_TOKEN_ENDPOINT: "\(#config.externalAuth.oidc.send_scope_to_token_endpoint)"}
			if #config.externalAuth.oidc.idp_logout_redirect_uri != "" {OIDC_IDP_LOGOUT_REDIRECT_URI: #config.externalAuth.oidc.idp_logout_redirect_uri}
			if #config.externalAuth.oidc.http_scheme != "" {OIDC_HTTP_SCHEME: #config.externalAuth.oidc.http_scheme}
			if #config.externalAuth.oidc.host != "" {OIDC_HOST: #config.externalAuth.oidc.host}
			if #config.externalAuth.oidc.port != "" {OIDC_PORT: #config.externalAuth.oidc.port}
			if #config.externalAuth.oidc.jwks_uri != "" {OIDC_JWKS_URI: #config.externalAuth.oidc.jwks_uri}
			if #config.externalAuth.oidc.auth_endpoint != "" {OIDC_AUTH_ENDPOINT: #config.externalAuth.oidc.auth_endpoint}
			if #config.externalAuth.oidc.token_endpoint != "" {OIDC_TOKEN_ENDPOINT: #config.externalAuth.oidc.token_endpoint}
			if #config.externalAuth.oidc.user_info_endpoint != "" {OIDC_USER_INFO_ENDPOINT: #config.externalAuth.oidc.user_info_endpoint}
			if #config.externalAuth.oidc.end_session_endpoint != "" {OIDC_END_SESSION_ENDPOINT: #config.externalAuth.oidc.end_session_endpoint}
		}
		if #config.externalAuth.saml.enabled {
			SAML_ENABLED:            "\(#config.externalAuth.saml.enabled)"
			SAML_ACS_URL:            #config.externalAuth.saml.acs_url
			SAML_ISSUER:             #config.externalAuth.saml.issuer
			SAML_IDP_SSO_TARGET_URL: #config.externalAuth.saml.idp_sso_target_url
			SAML_IDP_CERT:           "\(#config.externalAuth.saml.idp_cert)"
			if #config.externalAuth.saml.idp_cert_fingerprint != "" {SAML_IDP_CERT_FINGERPRINT: "\(#config.externalAuth.saml.idp_cert_fingerprint)"}
			if #config.externalAuth.saml.name_identifier_format != "" {SAML_NAME_IDENTIFIER_FORMAT: #config.externalAuth.saml.name_identifier_format}
			if #config.externalAuth.saml.cert != "" {SAML_CERT: "\(#config.externalAuth.saml.cert)"}
			if #config.externalAuth.saml.private_key != "" {SAML_PRIVATE_KEY: "\(#config.externalAuth.saml.private_key)"}
			if #config.externalAuth.saml.want_assertion_signed != "" {SAML_SECURITY_WANT_ASSERTION_SIGNED: "\(#config.externalAuth.saml.want_assertion_signed)"}
			if #config.externalAuth.saml.want_assertion_encrypted != "" {SAML_SECURITY_WANT_ASSERTION_ENCRYPTED: "\(#config.externalAuth.saml.want_assertion_encrypted)"}
			if #config.externalAuth.saml.assume_email_is_verified != "" {SAML_SECURITY_ASSUME_EMAIL_IS_VERIFIED: "\(#config.externalAuth.saml.assume_email_is_verified)"}
			if #config.externalAuth.saml.uid_attribute != "" {SAML_UID_ATTRIBUTE: #config.externalAuth.saml.uid_attribute}
			if #config.externalAuth.saml.attributes_statements.uid != "" {SAML_ATTRIBUTES_STATEMENTS_UID: "\(#config.externalAuth.saml.attributes_statements.uid)"}
			if #config.externalAuth.saml.attributes_statements.email != "" {SAML_ATTRIBUTES_STATEMENTS_EMAIL: "\(#config.externalAuth.saml.attributes_statements.email)"}
			if #config.externalAuth.saml.attributes_statements.full_name != "" {SAML_ATTRIBUTES_STATEMENTS_FULL_NAME: "\(#config.externalAuth.saml.attributes_statements.full_name)"}
			if #config.externalAuth.saml.attributes_statements.first_name != "" {SAML_ATTRIBUTES_STATEMENTS_FIRST_NAME: "\(#config.externalAuth.saml.attributes_statements.first_name)"}
			if #config.externalAuth.saml.attributes_statements.last_name != "" {SAML_ATTRIBUTES_STATEMENTS_LAST_NAME: "\(#config.externalAuth.saml.attributes_statements.last_name)"}
			if #config.externalAuth.saml.attributes_statements.verified != "" {SAML_ATTRIBUTES_STATEMENTS_VERIFIED: "\(#config.externalAuth.saml.attributes_statements.verified)"}
			if #config.externalAuth.saml.attributes_statements.verified_email != "" {SAML_ATTRIBUTES_STATEMENTS_VERIFIED_EMAIL: "\(#config.externalAuth.saml.attributes_statements.verified_email)"}
		}
		if #config.externalAuth.oauth_global.omniauth_only {
			OMNIAUTH_ONLY: "true"
		}
		if #config.externalAuth.cas.enabled {
			CAS_ENABLED:                     "\(#config.externalAuth.cas.enabled)"
			CAS_URL:                         #config.externalAuth.cas.url
			CAS_HOST:                        #config.externalAuth.cas.host
			CAS_PORT:                        #config.externalAuth.cas.port
			CAS_SSL:                         "\(#config.externalAuth.cas.ssl)"
			if #config.externalAuth.cas.validate_url != "" {CAS_VALIDATE_URL: #config.externalAuth.cas.validate_url}
			if #config.externalAuth.cas.callback_url != "" {CAS_CALLBACK_URL: #config.externalAuth.cas.callback_url}
			if #config.externalAuth.cas.logout_url != "" {CAS_LOGOUT_URL: #config.externalAuth.cas.logout_url}
			if #config.externalAuth.cas.login_url != "" {CAS_LOGIN_URL: #config.externalAuth.cas.login_url}
			if #config.externalAuth.cas.uid_field != "" {CAS_UID_FIELD: "\(#config.externalAuth.cas.uid_field)"}
			if #config.externalAuth.cas.ca_path != "" {CAS_CA_PATH: #config.externalAuth.cas.ca_path}
			if #config.externalAuth.cas.disable_ssl_verification != "" {CAS_DISABLE_SSL_VERIFICATION: "\(#config.externalAuth.cas.disable_ssl_verification)"}
			if #config.externalAuth.cas.assume_email_is_verified != "" {CAS_SECURITY_ASSUME_EMAIL_IS_VERIFIED: "\(#config.externalAuth.cas.assume_email_is_verified)"}
			if #config.externalAuth.cas.keys.uid != "" {CAS_UID_KEY: "\(#config.externalAuth.cas.keys.uid)"}
			if #config.externalAuth.cas.keys.name != "" {CAS_NAME_KEY: "\(#config.externalAuth.cas.keys.name)"}
			if #config.externalAuth.cas.keys.email != "" {CAS_EMAIL_KEY: "\(#config.externalAuth.cas.keys.email)"}
			if #config.externalAuth.cas.keys.nickname != "" {CAS_NICKNAME_KEY: "\(#config.externalAuth.cas.keys.nickname)"}
			if #config.externalAuth.cas.keys.first_name != "" {CAS_FIRST_NAME_KEY: "\(#config.externalAuth.cas.keys.first_name)"}
			if #config.externalAuth.cas.keys.last_name != "" {CAS_LAST_NAME_KEY: "\(#config.externalAuth.cas.keys.last_name)"}
			if #config.externalAuth.cas.keys.location != "" {CAS_LOCATION_KEY: "\(#config.externalAuth.cas.keys.location)"}
			if #config.externalAuth.cas.keys.image != "" {CAS_IMAGE_KEY: "\(#config.externalAuth.cas.keys.image)"}
			if #config.externalAuth.cas.keys.phone != "" {CAS_PHONE_KEY: "\(#config.externalAuth.cas.keys.phone)"}
		}
		if #config.externalAuth.pam.enabled {
			PAM_ENABLED: "\( #config.externalAuth.pam.enabled )"
			if #config.externalAuth.pam.email_domain != "" {PAM_EMAIL_DOMAIN: #config.externalAuth.pam.email_domain}
			if #config.externalAuth.pam.default_service != "" {PAM_DEFAULT_SERVICE: #config.externalAuth.pam.default_service}
			if #config.externalAuth.pam.controlled_service != "" {PAM_CONTROLLED_SERVICE: #config.externalAuth.pam.controlled_service}
		}
		if #config.externalAuth.ldap.enabled {
			LDAP_ENABLED: "\( #config.externalAuth.ldap.enabled )"
			LDAP_HOST:    #config.externalAuth.ldap.host
			LDAP_PORT:    "\( #config.externalAuth.ldap.port )"
			LDAP_METHOD:  #config.externalAuth.ldap.method
			if #config.externalAuth.ldap.tls_no_verify != "" {LDAP_TLS_NO_VERIFY: "\( #config.externalAuth.ldap.tls_no_verify )"}
			if #config.externalAuth.ldap.base != "" {LDAP_BASE: #config.externalAuth.ldap.base}
			if #config.externalAuth.ldap.bind_dn != "" {LDAP_BIND_DN: #config.externalAuth.ldap.bind_dn}
			if #config.externalAuth.ldap.password != "" {LDAP_PASSWORD: #config.externalAuth.ldap.password}
			if #config.externalAuth.ldap.uid != "" {LDAP_UID: #config.externalAuth.ldap.uid}
			if #config.externalAuth.ldap.mail != "" {LDAP_MAIL: #config.externalAuth.ldap.mail}
			if #config.externalAuth.ldap.search_filter != "" {LDAP_SEARCH_FILTER: #config.externalAuth.ldap.search_filter}
			if #config.externalAuth.ldap.uid_conversion.enabled != "" {LDAP_UID_CONVERSION_ENABLED: "\( #config.externalAuth.ldap.uid_conversion.enabled )"}
			if #config.externalAuth.ldap.uid_conversion.search != "" {LDAP_UID_CONVERSION_SEARCH: #config.externalAuth.ldap.uid_conversion.search}
			if #config.externalAuth.ldap.uid_conversion.replace != "" {LDAP_UID_CONVERSION_REPLACE: #config.externalAuth.ldap.uid_conversion.replace}
		}
		if #config.mastodon.metrics.statsd.address != "" {
			STATSD_ADDR: #config.mastodon.metrics.statsd.address
		}
		if #config.mastodon.metrics.statsd.address == "" && #config.mastodon.metrics.statsd.exporter.enabled {
			STATSD_ADDR: "localhost:9125"
		}

		for k, v in #config.mastodon.extraEnvVars {
			"\(k)": v
		}

		if #config.mastodon.deepl.enabled {
			DEEPL_PLAN: #config.mastodon.deepl.plan
		}

		if #config.mastodon.hcaptcha.enabled {
			HCAPTCHA_SITE_KEY: #config.mastodon.hcaptcha.siteId
		}

		if #config.mastodon.cacheBuster.enabled {
			CACHE_BUSTER_ENABLED: "true"
			if #config.mastodon.cacheBuster.httpMethod != "" {
				CACHE_BUSTER_HTTP_METHOD: #config.mastodon.cacheBuster.httpMethod
			}
			if #config.mastodon.cacheBuster.authHeader != "" {
				CACHE_BUSTER_SECRET_HEADER: #config.mastodon.cacheBuster.authHeader
			}
		}
		if !#config.mastodon.cacheBuster.enabled {
			CACHE_BUSTER_ENABLED: "false"
		}

		if #config.timezone != "" {
			TZ: #config.timezone
		}
	}
}
