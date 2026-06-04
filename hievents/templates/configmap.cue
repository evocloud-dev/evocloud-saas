package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config._configMapName
		namespace: #config.metadata.namespace
		labels:    #config._baseLabels
	}
	data: {
		APP_NAME:                 #config.hieventsConfig.app.name
		APP_ENV:                  #config.hieventsConfig.app.env
		APP_DEBUG:                #config.hieventsConfig.app.debug
		APP_URL:                  #config.hieventsConfig.app.url
		APP_FRONTEND_URL:         #config.hieventsConfig.app.frontendUrl
		APP_TIMEZONE:             #config.hieventsConfig.app.timezone
		APP_LOCALE:               #config.hieventsConfig.app.locale
		SANCTUM_STATEFUL_DOMAINS: #config.hieventsConfig.app.sanctumStatefulDomains
		if #config.hieventsConfig.app.sessionDomain != "" {
			SESSION_DOMAIN: #config.hieventsConfig.app.sessionDomain
		}
		CORS_ALLOWED_ORIGINS:    #config.hieventsConfig.app.url + "," + #config.hieventsConfig.app.frontendUrl
		TRUSTED_PROXIES:         #config.hieventsConfig.app.trustedProxies
		DB_CONNECTION:           "pgsql"
		DB_HOST:                 #config._dbHost
		REDIS_HOST:              #config._redisHost
		QUEUE_CONNECTION:        #config.hieventsConfig.queue.connection
		FILESYSTEM_DISK:         #config._storageDisk
		FILESYSTEM_PUBLIC_DISK:  #config._publicDisk
		FILESYSTEM_PRIVATE_DISK: #config._privateDisk
	}
}
