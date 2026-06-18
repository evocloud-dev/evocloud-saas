package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ConfigMap: corev1.#ConfigMap & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.fullname
		namespace: #config.namespace
		labels:    #config.labels
	}
	data: {
		VITE_BASE_URL:               #config.#baseUrl
		VITE_SHORTCODE_BASE_URL:     #config.#shortcodeBaseUrl
		VITE_ADMIN_URL:              #config.#adminUrl
		VITE_BACKEND_GQL_URL:        #config.#backendGqlUrl
		VITE_BACKEND_WS_URL:         #config.#backendWsUrl
		VITE_BACKEND_API_URL:        #config.#backendApiUrl
		VITE_ALLOWED_AUTH_PROVIDERS: #config.#authProviders
		ENABLE_SUBPATH_BASED_ACCESS: "\(#config.enableSubpathBasedAccess)"
		HOPP_AIO_ALTERNATE_PORT:     "\(#config.service.containerPort)"
		WHITELISTED_ORIGINS:         #config.#whitelistedOrigins
		if #config.tosLink != "" {
			VITE_APP_TOS_LINK: #config.tosLink
		}
		if #config.privacyPolicyLink != "" {
			VITE_APP_PRIVACY_POLICY_LINK: #config.privacyPolicyLink
		}
		if #config.proxy.appUrl != "" {
			PROXY_APP_URL: #config.proxy.appUrl
		}
		if #config.mailer.enabled {
			MAILER_SMTP_ENABLE:        "true"
			MAILER_ADDRESS_FROM:       #config.mailer.from
			MAILER_USE_CUSTOM_CONFIGS: "\(#config.mailer.useCustomConfigs)"
			if #config.mailer.useCustomConfigs {
				MAILER_SMTP_HOST:               #config.mailer.host
				MAILER_SMTP_PORT:               "\(#config.mailer.port)"
				MAILER_SMTP_SECURE:             "\(#config.mailer.secure)"
				MAILER_SMTP_USER:               #config.mailer.user
				MAILER_TLS_REJECT_UNAUTHORIZED: "\(#config.mailer.tlsRejectUnauthorized)"
			}
		}
		if #config.auth.github.enabled {
			GITHUB_SCOPE:        #config.auth.github.scope
			GITHUB_CALLBACK_URL: #config.#githubCallbackUrl
		}
		if #config.auth.google.enabled {
			GOOGLE_SCOPE:        #config.auth.google.scope
			GOOGLE_CALLBACK_URL: #config.#googleCallbackUrl
		}
		if #config.auth.microsoft.enabled {
			MICROSOFT_SCOPE:        #config.auth.microsoft.scope
			MICROSOFT_CALLBACK_URL: #config.#microsoftCallbackUrl
		}
	}
}
