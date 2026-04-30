package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#AppConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(#config.metadata.name)-app-config"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "core"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	data: {
		APP_NAME:                 #config.config.APP_NAME
		APP_ENV:                  #config.config.APP_ENV
		APP_URL:                  #config.config.APP_URL
		APP_DEBUG:                "\(#config.config.APP_DEBUG)"
		REGISTRY_URL:             #config.global.registryUrl
		APP_OPTIMIZE:             "\(#config.config.APP_OPTIMIZE)"
		VIEW_COMPILED_PATH:       #config.config.VIEW_COMPILED_PATH
		SESSION_LIFETIME:         "\(#config.config.SESSION_LIFETIME)"
		SANCTUM_STATEFUL_DOMAINS: #config.config.SANCTUM_STATEFUL_DOMAINS
		PHP_MEMORY_LIMIT:         #config.config.PHP_MEMORY_LIMIT
		PHP_FPM_PM_CONTROL:       #config.config.PHP_FPM_PM_CONTROL
		PHP_FPM_PM_START_SERVERS: "\(#config.config.PHP_FPM_PM_START_SERVERS)"
		PHP_FPM_PM_MIN_SPARE_SERVERS: "\(#config.config.PHP_FPM_PM_MIN_SPARE_SERVERS)"
		PHP_FPM_PM_MAX_SPARE_SERVERS: "\(#config.config.PHP_FPM_PM_MAX_SPARE_SERVERS)"
		DB_CONNECTION:            #config.config.DB_CONNECTION
		DB_DATABASE:              #config.config.DB_DATABASE
		DB_PORT:                  "\(#config.config.DB_PORT)"

		if #config.postgresql.enabled {
			DB_HOST: "\(#config.metadata.name)-postgresql.\(#config.metadata.namespace).svc.cluster.local"
		}
		if !#config.postgresql.enabled {
			DB_HOST: #config.config.DB_HOST
		}

		if #config.redis.enabled {
			REDIS_HOST: "\(#config.metadata.name)-redis-master.\(#config.metadata.namespace).svc.cluster.local"
		}
		if !#config.redis.enabled {
			REDIS_HOST: #config.config.REDIS_HOST
		}

		REDIS_PORT:                  "\(#config.config.REDIS_PORT)"
		SOKETI_DEBUG:                "\(#config.config.SOKETI_DEBUG)"
		FILESYSTEM_DRIVER:           "local"
		FILESYSTEMS_DISK_LOCAL_ROOT: "/var/www/html/storage/app"
		CACHE_DRIVER:                "redis"
		SESSION_DRIVER:              "redis"
		QUEUE_CONNECTION:            "redis"
		LOG_CHANNEL:                 "single"
		LOG_DEPRECATIONS_CHANNEL:    "null"
		LOG_LEVEL:                   "info"
		BROADCAST_DRIVER:            "pusher"
		SESSION_SECURE_COOKIE:       "false"
		SESSION_HTTP_ONLY:           "true"
		SESSION_SAME_SITE:           "lax"
		COOLIFY_APP_ENV:             #config.config.APP_ENV
		COOLIFY_IS_CLOUD:            "false"
		COOLIFY_AUTOUPDATE:          "false"
		COOLIFY_STORAGE_PATH:        "/var/www/html/storage/app"
		COOLIFY_SSH_KEY_PATH:        "/var/www/html/storage/app/ssh/keys"
		COOLIFY_INTERNAL_PORT:       "\(#config.coolifyApp.service.targetPort)"
		SOKETI_INTERNAL_PORT:        "\(#config.soketi.service.appPort)"
		SOKETI_METRICS_PORT:         "\(#config.soketi.service.metricsPort)"
	}
}
