package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigMapBackend: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-backend"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	data: {

		"BASEROW_ACCESS_TOKEN_LIFETIME_MINUTES":   "\(#config.backend.config.tokens.accessTokenLifetimeMinutes)"
		"BASEROW_AIRTABLE_IMPORT_SOFT_TIME_LIMIT": "\(#config.backend.config.airtableImportSoftTimeLimit)"
		if #config.backend.config.amountOfGunicornWorkers != "" {
			"BASEROW_AMOUNT_OF_GUNICORN_WORKERS": "\(#config.backend.config.amountOfGunicornWorkers)"
		}
		"BASEROW_BACKEND_DATABASE_LOG_LEVEL": "\(#config.backend.config.logging.databaseLogLevel)"
		"BASEROW_BACKEND_DEBUG":              "\(#config.backend.config.logging.backendDebug)"
		"BASEROW_BACKEND_LOG_LEVEL":          "\(#config.backend.config.logging.backendLogLevel)"
		"BASEROW_FILE_UPLOAD_SIZE_LIMIT_MB":              "\(#config.backend.config.fileUploadSizeLimit)"
		"BASEROW_REFRESH_TOKEN_LIFETIME_HOURS":           "\(#config.backend.config.tokens.refreshTokenLifetimeHours)"
		"BASEROW_ROW_PAGE_SIZE_LIMIT":                    "\(#config.backend.config.rowPageSizeLimit)"
		"BASEROW_SNAPSHOT_EXPIRATION_TIME_DAYS":          "\(#config.backend.config.snapshotExpirationTimeDays)"
		"BASEROW_SYNC_TEMPLATES_TIME_LIMIT":              "\(#config.backend.config.syncTemplatesTimeLimit)"
		"BASEROW_TRIGGER_SYNC_TEMPLATES_AFTER_MIGRATION": "\(#config.backend.config.triggerSyncTemplatesAfterMigration)"
		"BATCH_ROWS_SIZE_LIMIT":                          "\(#config.backend.config.batchRowsSizeLimit)"
		if #config.backend.config.dontUpdateFormulasAfterMigration != "" {
			"DONT_UPDATE_FORMULAS_AFTER_MIGRATION": "\(#config.backend.config.dontUpdateFormulasAfterMigration)"
		}
		if #config.backend.config.initialTableDataLimit != "" {
			"INITIAL_TABLE_DATA_LIMIT": "\(#config.backend.config.initialTableDataLimit)"
		}
		"MIGRATE_ON_STARTUP":              "false"
		if #config.backend.config.enableOtel {
			"BASEROW_ENABLE_OTEL": "true"
		}
		"POSTGRES_STARTUP_CHECK_ATTEMPTS": "\(#config.backend.config.postgresStartupCheckAttempts)"

		if #config.backend.config.additionalApps != "" {
			"ADDITIONAL_APPS": "\(#config.backend.config.additionalApps)"
		}
		if #config.backend.config.disableModelCache != "" {
			"BASEROW_DISABLE_MODEL_CACHE": "\(#config.backend.config.disableModelCache)"
		}
		if #config.backend.config.enableSecureProxySslHeader != "" {
			"BASEROW_ENABLE_SECURE_PROXY_SSL_HEADER": "\(#config.backend.config.enableSecureProxySslHeader)"
		}
		"BASEROW_INITIAL_CREATE_SYNC_TABLE_DATA_LIMIT": "\(#config.backend.config.initialCreateSyncTableDataLimit)"
		"BASEROW_JOB_CLEANUP_INTERVAL_MINUTES":         "\(#config.backend.config.jobs.cleanupIntervalMinutes)"
		"BASEROW_JOB_EXPIRATION_TIME_LIMIT":            "\(#config.backend.config.jobs.expirationTimeLimit)"
		"BASEROW_JOB_SOFT_TIME_LIMIT":                  "\(#config.backend.config.jobs.softTimeLimit)"
		"BASEROW_MAX_FILE_IMPORT_ERROR_COUNT":          "\(#config.backend.config.maxFileImportErrorCount)"
		"BASEROW_MAX_ROW_REPORT_ERROR_COUNT":           "\(#config.backend.config.maxRowReportErrorCount)"
		if #config.backend.config.waitInsteadOf409ConflictError != "" {
			"BASEROW_WAIT_INSTEAD_OF_409_CONFLICT_ERROR": "\(#config.backend.config.waitInsteadOf409ConflictError)"
		}
		if #config.backend.config.disableAnonymousPublicViewWsConnections != "" {
			"DISABLE_ANONYMOUS_PUBLIC_VIEW_WS_CONNECTIONS": "\(#config.backend.config.disableAnonymousPublicViewWsConnections)"
		}
		if #config.backend.config.hoursUntilTrashPermanentlyDeleted != "" {
			"HOURS_UNTIL_TRASH_PERMANENTLY_DELETED": "\(#config.backend.config.hoursUntilTrashPermanentlyDeleted)"
		}
		"MINUTES_UNTIL_ACTION_CLEANED_UP": "\(#config.backend.config.minutesUntilActionCleanedUp)"

		"BASEROW_AMOUNT_OF_WORKERS":         "\(#config.backend.config.celery.amountOfWorkers)"
		"BASEROW_CELERY_BEAT_DEBUG_LEVEL":   "\(#config.backend.config.celery.beatDebugLevel)"
		"BASEROW_CELERY_BEAT_STARTUP_DELAY": "\(#config.backend.config.celery.beatStartupDelay)"
		"BASEROW_RUN_MINIMAL":               "\(#config.backend.config.celery.runMinimal)"

		if #config.backend.config.email.smtp != "" {
			"EMAIL_SMTP": "\(#config.backend.config.email.smtp)"
			if #config.backend.config.email.smtpUseTls != "" {
				"EMAIL_SMTP_USE_TLS": "\(#config.backend.config.email.smtpUseTls)"
			}
			if #config.backend.config.email.smtpHost != "" {
				"EMAIL_SMTP_HOST": "\(#config.backend.config.email.smtpHost)"
			}
			if #config.backend.config.email.smtpPort != "" {
				"EMAIL_SMTP_PORT": "\(#config.backend.config.email.smtpPort)"
			}
			if #config.backend.config.email.smtpUser != "" {
				"EMAIL_SMTP_USER": "\(#config.backend.config.email.smtpUser)"
			}
			if #config.backend.config.email.fromEmail != "" {
				"FROM_EMAIL": "\(#config.backend.config.email.fromEmail)"
			}
		}

		"AWS_STORAGE_BUCKET_NAME": "\(#config.backend.config.aws.bucketName)"
		if #config.backend.config.aws.s3CustomDomain != "" {
			"AWS_S3_CUSTOM_DOMAIN": "\(#config.backend.config.aws.s3CustomDomain)"
		}
		if #config.backend.config.aws.s3EndpointUrl != "" {
			"AWS_S3_ENDPOINT_URL": "\(#config.backend.config.aws.s3EndpointUrl)"
		}
		if #config.backend.config.aws.s3RegionName != "" {
			"AWS_S3_REGION_NAME": "\(#config.backend.config.aws.s3RegionName)"
		}
		"MEDIA_ROOT": "\(#config.backend.config.media.root)"
		"MEDIA_URL":  "\(#config.backend.config.media.url)"

		if #config.backend.config.webhook.allowPrivateAddress != "" {
			"BASEROW_WEBHOOKS_ALLOW_PRIVATE_ADDRESS": "\(#config.backend.config.webhook.allowPrivateAddress)"
		}
		if #config.backend.config.webhook.ipBlacklist != "" {
			"BASEROW_WEBHOOKS_IP_BLACKLIST": "\(#config.backend.config.webhook.ipBlacklist)"
		}
		if #config.backend.config.webhook.ipWhitelist != "" {
			"BASEROW_WEBHOOKS_IP_WHITELIST": "\(#config.backend.config.webhook.ipWhitelist)"
		}
		"BASEROW_WEBHOOKS_MAX_CALL_LOG_ENTRIES":             "\(#config.backend.config.webhook.maxCallLogEntries)"
		"BASEROW_WEBHOOKS_MAX_CONSECUTIVE_TRIGGER_FAILURES": "\(#config.backend.config.webhook.maxConsecutiveTriggerFailures)"
		"BASEROW_WEBHOOKS_MAX_PER_TABLE":                    "\(#config.backend.config.webhook.maxPerTable)"
		"BASEROW_WEBHOOKS_MAX_RETRIES_PER_CALL":             "\(#config.backend.config.webhook.maxRetriesPerCall)"
		"BASEROW_WEBHOOKS_REQUEST_TIMEOUT_SECONDS":          "\(#config.backend.config.webhook.requestTimeoutSeconds)"
		"BASEROW_WEBHOOKS_URL_CHECK_TIMEOUT_SECS":           "\(#config.backend.config.webhook.urlCheckTimeoutSecs)"
		if #config.backend.config.webhook.urlRegexBlacklist != "" {
			"BASEROW_WEBHOOKS_URL_REGEX_BLACKLIST": "\(#config.backend.config.webhook.urlRegexBlacklist)"
		}

		if #config.global.baserow.assistantLLMModel != _|_ {
			"BASEROW_ENTERPRISE_ASSISTANT_LLM_MODEL": "\(#config.global.baserow.assistantLLMModel)"
		}
		if #config.embeddings.enabled {
			"BASEROW_EMBEDDINGS_API_URL": "http://\(#config.metadata.name)-embeddings"
		}

		// Database and Redis Settings
		if #config.postgresql.enabled {
			"DATABASE_HOST": "\(#config.metadata.name)-postgresql"
			"DATABASE_PORT": "5432"
			"DATABASE_NAME": "\(#config.postgresql.auth.database)"
			"DATABASE_USER": "\(#config.postgresql.auth.username)"
		}
		if !#config.postgresql.enabled {
			"DATABASE_HOST": "\(#config.externalPostgresql.hostname)"
			"DATABASE_PORT": "\(#config.externalPostgresql.port)"
			"DATABASE_NAME": "\(#config.externalPostgresql.auth.database)"
			"DATABASE_USER": "\(#config.externalPostgresql.auth.username)"
		}
		if #config.redis.enabled {
			"REDIS_HOST": "\(#config.metadata.name)-redis-master"
			"REDIS_PORT": "6379"
		}
		if !#config.redis.enabled {
			"REDIS_HOST": "\(#config.externalRedis.hostname)"
			"REDIS_PORT": "\(#config.externalRedis.port)"
		}
	}
}
