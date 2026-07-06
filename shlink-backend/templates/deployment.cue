package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#env: {
	#name:  string
	#value: _
	name:   #name
	value:  "\(#value)"
}

#secretEnv: {
	#name: string
	#secretName: string
	#key: string
	name: #name
	valueFrom: secretKeyRef: {
		name: #secretName
		key:  #key
	}
}

#Deployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: #config.metadata & {
		name: #config.#serviceName
	}
	spec: appsv1.#DeploymentSpec & {
		if !#config.autoscaling.enabled {
			replicas: #config.replicaCount
		}
		revisionHistoryLimit: #config.revisionHistoryLimit
		if len(#config.deploymentStrategy) > 0 {
			strategy: #config.deploymentStrategy
		}
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels & #config.podLabels
				if len(#config.podAnnotations) > 0 {
					annotations: #config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				if len(#config.imagePullSecrets) > 0 {
					imagePullSecrets: #config.imagePullSecrets
				}
				serviceAccountName: #config.#serviceAccountName
				if len(#config.podSecurityContext) > 0 {
					securityContext: #config.podSecurityContext
				}
				containers: [{
					name:            "shlink-backend"
					image:           #config.image.reference
					imagePullPolicy: #config.image.pullPolicy
					if len(#config.securityContext) > 0 {
						securityContext: #config.securityContext
					}
					env: [
						#env & {#name: "DB_DRIVER", #value: #config.#databaseDriver},
						if #config.#databaseDriver != "sqlite" {
							#env & {#name: "DB_HOST", #value: #config.#databaseHost}
						},
						if #config.#databaseDriver != "sqlite" {
							#env & {#name: "DB_NAME", #value: #config.#databaseName}
						},
						if #config.#databaseDriver != "sqlite" {
							#secretEnv & {#name: "DB_PASSWORD", #secretName: #config.#databaseSecretName, #key: #config.#databasePasswordKey}
						},
						if #config.#databaseDriver != "sqlite" {
							#env & {#name: "DB_PORT", #value: #config.#databasePort}
						},
						if #config.#databaseDriver != "sqlite" {
							#env & {#name: "DB_USE_ENCRYPTION", #value: #config.config.database.useEncryption}
						},
						if #config.#databaseDriver != "sqlite" {
							#env & {#name: "DB_USER", #value: #config.#databaseUsername}
						},
						#env & {#name: "PORT", #value: #config.service.port},
						if #config.config.general.basePath != "" {
							#env & {#name: "BASE_PATH", #value: #config.config.general.basePath}
						},
						if #config.config.general.cacheNamespace != "" {
							#env & {#name: "CACHE_NAMESPACE", #value: #config.config.general.cacheNamespace}
						},
						if #config.config.general.defaultDomain != "" {
							#env & {#name: "DEFAULT_DOMAIN", #value: #config.config.general.defaultDomain}
						},
						if #config.config.general.initialApiKey != "" {
							#env & {#name: "INITIAL_API_KEY", #value: #config.config.general.initialApiKey}
						},
						#env & {#name: "IS_HTTPS_ENABLED", #value: #config.config.general.isHttpsEnabled},
						if #config.config.general.memoryLimit != "" {
							#env & {#name: "MEMORY_LIMIT", #value: #config.config.general.memoryLimit}
						},
						if #config.config.general.timezone != "" {
							#env & {#name: "TIMEZONE", #value: #config.config.general.timezone}
						},
						if #config.config.geolite.licenseKey != "" {
							#env & {#name: "GEOLITE_LICENSE_KEY", #value: #config.config.geolite.licenseKey}
						},
						#env & {#name: "SKIP_INITIAL_GEOLITE_DOWNLOAD", #value: #config.config.geolite.skipInitialDownload},
						if #config.config.matomo.enabled {
							#env & {#name: "MATOMO_ENABLED", #value: true}
						},
						if #config.config.matomo.enabled && (#config.config.matomo.auth.apiToken != "" || #config.config.matomo.auth.existingSecret != "") {
							#secretEnv & {#name: "MATOMO_API_TOKEN", #secretName: #config.#matomoSecretName, #key: "api-token"}
						},
						if #config.config.matomo.enabled && #config.config.matomo.baseUrl != "" {
							#env & {#name: "MATOMO_BASE_URL", #value: #config.config.matomo.baseUrl}
						},
						if #config.config.matomo.enabled && #config.config.matomo.siteId != "" {
							#env & {#name: "MATOMO_SITE_ID", #value: #config.config.matomo.siteId}
						},
						if #config.config.mercure.enabled && #config.config.mercure.internalHubUrl != "" {
							#env & {#name: "MERCURE_INTERNAL_HUB_URL", #value: #config.config.mercure.internalHubUrl}
						},
						if #config.config.mercure.enabled && (#config.config.mercure.auth.jwtSecret != "" || #config.config.mercure.auth.existingSecret != "") {
							#secretEnv & {#name: "MERCURE_JWT_SECRET", #secretName: #config.#mercureSecretName, #key: "jwt-secret"}
						},
						if #config.config.mercure.enabled && #config.config.mercure.publicHubUrl != "" {
							#env & {#name: "MERCURE_PUBLIC_HUB_URL", #value: #config.config.mercure.publicHubUrl}
						},
						if #config.config.qrCodes.defaultColors.background != "" {
							#env & {#name: "DEFAULT_QR_CODE_BG_COLOR", #value: #config.config.qrCodes.defaultColors.background}
						},
						if #config.config.qrCodes.defaultColors.foreground != "" {
							#env & {#name: "DEFAULT_QR_CODE_COLOR", #value: #config.config.qrCodes.defaultColors.foreground}
						},
						if #config.config.qrCodes.defaultErrorCorrection != "" {
							#env & {#name: "DEFAULT_QR_CODE_ERROR_CORRECTION", #value: #config.config.qrCodes.defaultErrorCorrection}
						},
						if #config.config.qrCodes.defaultFormat != "" {
							#env & {#name: "DEFAULT_QR_CODE_FORMAT", #value: #config.config.qrCodes.defaultFormat}
						},
						if #config.config.qrCodes.defaultLogoUrl != "" {
							#env & {#name: "DEFAULT_QR_CODE_LOGO_URL", #value: #config.config.qrCodes.defaultLogoUrl}
						},
						if #config.config.qrCodes.defaultMargin != 0 {
							#env & {#name: "DEFAULT_QR_CODE_MARGIN", #value: #config.config.qrCodes.defaultMargin}
						},
						if #config.config.qrCodes.defaultSize != 0 {
							#env & {#name: "DEFAULT_QR_CODE_SIZE", #value: #config.config.qrCodes.defaultSize}
						},
						#env & {#name: "DEFAULT_QR_CODE_ROUND_BLOCK_SIZE", #value: #config.config.qrCodes.defaultRoundBlockSize},
						#env & {#name: "QR_CODE_FOR_DISABLED_SHORT_URLS", #value: #config.config.qrCodes.codeForDisabledShortUrls},
						if #config.#rabbitmqEnabled {
							#env & {#name: "RABBITMQ_ENABLED", #value: true}
						},
						if #config.#rabbitmqEnabled {
							#env & {#name: "RABBITMQ_HOST", #value: #config.#rabbitmqHost}
						},
						if #config.#rabbitmqEnabled {
							#secretEnv & {#name: "RABBITMQ_PASSWORD", #secretName: #config.#rabbitmqSecretName, #key: "rabbitmq-password"}
						},
						if #config.#rabbitmqEnabled {
							#env & {#name: "RABBITMQ_PORT", #value: #config.#rabbitmqPort}
						},
						if #config.#rabbitmqEnabled {
							#env & {#name: "RABBITMQ_USER", #value: #config.#rabbitmqUsername}
						},
						if #config.#rabbitmqEnabled {
							#env & {#name: "RABBITMQ_USE_SSL", #value: #config.config.rabbitmq.useSsl}
						},
						if #config.#rabbitmqEnabled && #config.config.rabbitmq.vhost != "" {
							#env & {#name: "RABBITMQ_VHOST", #value: #config.config.rabbitmq.vhost}
						},
						if #config.config.redirects.defaultBaseUrlRedirect != "" {
							#env & {#name: "DEFAULT_BASE_URL_REDIRECT", #value: #config.config.redirects.defaultBaseUrlRedirect}
						},
						if #config.config.redirects.defaultInvalidShortUrlRedirect != "" {
							#env & {#name: "DEFAULT_INVALID_SHORT_URL_REDIRECT", #value: #config.config.redirects.defaultInvalidShortUrlRedirect}
						},
						if #config.config.redirects.defaultRegular404Redirect != "" {
							#env & {#name: "DEFAULT_REGULAR_404_REDIRECT", #value: #config.config.redirects.defaultRegular404Redirect}
						},
						if #config.config.redirects.cacheLifetime != 0 {
							#env & {#name: "REDIRECT_CACHE_LIFETIME", #value: #config.config.redirects.cacheLifetime}
						},
						if #config.config.redirects.extraPathMode != "" {
							#env & {#name: "REDIRECT_EXTRA_PATH_MODE", #value: #config.config.redirects.extraPathMode}
						},
						if #config.config.redirects.statusCode != 0 {
							#env & {#name: "REDIRECT_STATUS_CODE", #value: #config.config.redirects.statusCode}
						},
						if #config.#redisEnabled {
							#env & {#name: "REDIS_PUB_SUB_ENABLED", #value: #config.config.redis.pubSubEnabled}
						},
						if #config.#redisEnabled && #config.config.redis.sentinal.enabled {
							#env & {#name: "REDIS_SENTINEL_SERVICE", #value: #config.#redisSentinelService}
						},
						if #config.#redisEnabled {
							#env & {#name: "REDIS_SERVERS", #value: #config.#redisServers}
						},
						#env & {#name: "ROBOTS_ALLOW_ALL_SHORT_URLS", #value: #config.config.robots.allowAllShortUrls},
						if #config.config.robots.userAgents != "" {
							#env & {#name: "ROBOTS_USER_AGENTS", #value: #config.config.robots.userAgents}
						},
						#env & {#name: "AUTO_RESOLVE_TITLES", #value: #config.config.urlShortening.autoResolveTitles},
						if #config.config.urlShortening.defaultShortCodesLength != 0 {
							#env & {#name: "DEFAULT_SHORT_CODES_LENGTH", #value: #config.config.urlShortening.defaultShortCodesLength}
						},
						if #config.config.urlShortening.deleteShortUrlThreshold != "" {
							#env & {#name: "DELETE_SHORT_URL_THRESHOLD", #value: #config.config.urlShortening.deleteShortUrlThreshold}
						},
						#env & {#name: "MULTI_SEGMENT_SLUGS_ENABLED", #value: #config.config.urlShortening.multiSegmentSlugsEnabled},
						if #config.config.urlShortening.shortUrlMode != "" {
							#env & {#name: "SHORT_URL_MODE", #value: #config.config.urlShortening.shortUrlMode}
						},
						#env & {#name: "SHORT_URL_TRAILING_SLASH", #value: #config.config.urlShortening.shortUrlTrailingSlash},
						#env & {#name: "ANONYMIZE_REMOTE_ADDR", #value: #config.config.trackingVisits.anonymizeRemoteAddr},
						#env & {#name: "DISABLE_IP_TRACKING", #value: #config.config.trackingVisits.disableIpTracking},
						#env & {#name: "DISABLE_REFERRER_TRACKING", #value: #config.config.trackingVisits.disableReferrerTracking},
						#env & {#name: "DISABLE_TRACKING", #value: #config.config.trackingVisits.disable},
						if #config.config.trackingVisits.disableTrackingFrom != "" {
							#env & {#name: "DISABLE_TRACKING_FROM", #value: #config.config.trackingVisits.disableTrackingFrom}
						},
						if #config.config.trackingVisits.disableTrackingParam != "" {
							#env & {#name: "DISABLE_TRACK_PARAM", #value: #config.config.trackingVisits.disableTrackingParam}
						},
						#env & {#name: "DISABLE_UA_TRACKING", #value: #config.config.trackingVisits.disableUaTracking},
						#env & {#name: "TRACK_ORPHAN_VISITS", #value: #config.config.trackingVisits.trackOrphanVisits},
						for item in #config.extraEnv {item},
					]
					ports: [{
						name:          "http"
						containerPort: #config.service.port
						protocol:      "TCP"
					}]
					livenessProbe: {
						httpGet: {
							path: "/rest/health"
							port: "http"
						}
						initialDelaySeconds: 30
						periodSeconds:       10
						timeoutSeconds:      5
						failureThreshold:    6
					}
					readinessProbe: {
						httpGet: {
							path: "/rest/health"
							port: "http"
						}
						initialDelaySeconds: 15
						periodSeconds:       10
						timeoutSeconds:      5
						failureThreshold:    6
					}
					if len(#config.resources) > 0 {
						resources: #config.resources
					}
					volumeMounts: [
						{
							name:      "tmp-dir"
							mountPath: "/tmp"
						},
						{
							name:      "data-dir"
							mountPath: "/etc/shlink/data"
						}
					]
				}]
				volumes: [
					{
						name: "tmp-dir"
						emptyDir: {}
					},
					{
						name: "data-dir"
						emptyDir: {}
					}
				]
				if len(#config.nodeSelector) > 0 {
					nodeSelector: #config.nodeSelector
				}
				if len(#config.affinity) > 0 {
					affinity: #config.affinity
				}
				if len(#config.tolerations) > 0 {
					tolerations: #config.tolerations
				}
			}
		}
	}
}