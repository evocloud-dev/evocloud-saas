package templates

import (
	"strings"

	corev1 "k8s.io/api/core/v1"
)

// #ConfigMap mirrors templates/configmap.yaml.
#ConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if len(#config.commonAnnotations) > 0 {
			annotations: #config.commonAnnotations
		}
	}
	data: {
		"server.yml": strings.Join([
			if #config.ntfy.baseUrl != "" {"base-url: \"\(#config.ntfy.baseUrl)\""},
			"listen-http: \":\(#config.containerPorts.http)\"",
			if !#config._dbEnabled {"cache-file: /var/cache/ntfy/cache.db"},
			if !#config._dbEnabled {"auth-file: /var/cache/ntfy/auth.db"},
			"auth-default-access: \"\(#config.ntfy.authDefaultAccess)\"",
			"behind-proxy: \(#config.ntfy.behindProxy)",
			if #config.ntfy.enableMetrics {"enable-metrics: true"},
			if #config.ntfy.enableMetrics && #config.ntfy.metricsListenHttp != "" {"metrics-listen-http: \"\(#config.ntfy.metricsListenHttp)\""},
			if #config.ntfy.attachmentTotalSizeLimit != "" {"attachment-total-size-limit: \"\(#config.ntfy.attachmentTotalSizeLimit)\""},
			if #config.ntfy.attachmentFileSizeLimit != "" {"attachment-file-size-limit: \"\(#config.ntfy.attachmentFileSizeLimit)\""},
			if #config.ntfy.attachmentExpiryDuration != "" {"attachment-expiry-duration: \"\(#config.ntfy.attachmentExpiryDuration)\""},
			if #config.ntfy.banFeed.enabled {"ban-file: \"\(#config.ntfy.banFeed.file)\""},
			if #config.ntfy.banFeed.enabled {"ban-window: \"\(#config.ntfy.banFeed.window)\""},
			if #config.ntfy.banFeed.enabled {"ban-threshold: \(#config.ntfy.banFeed.threshold)"},
			if #config.ntfy.banFeed.enabled && len(#config.ntfy.banFeed.weights) > 0 {
				"ban-weights:\n" + strings.Join([for w in #config.ntfy.banFeed.weights {"  - \"\(w)\""}], "\n")
			},
			if #config.smtp.enabled {"smtp-sender-addr: \"\(#config.smtp.senderAddr)\""},
			if #config.smtp.enabled && #config.smtp.senderFrom != "" {"smtp-sender-from: \"\(#config.smtp.senderFrom)\""},
			if #config.smtp.enabled && #config.smtp.senderUser != "" {"smtp-sender-user: \"\(#config.smtp.senderUser)\""},
			if #config.smtp.enabled && #config.smtp.senderVerify {"smtp-sender-verify: true"},
			if #config.oidc.enabled && #config.oidc.issuerUrl != "" {"oidc-issuer-url: \"\(#config.oidc.issuerUrl)\""},
			if #config.oidc.enabled && #config.oidc.clientId != "" {"oidc-client-id: \"\(#config.oidc.clientId)\""},
			if #config.oidc.enabled && #config.oidc.redirectUrl != "" {"oidc-redirect-url: \"\(#config.oidc.redirectUrl)\""},
			if #config.oidc.enabled && #config.oidc.logoutRedirectUrl != "" {"oidc-logout-redirect-url: \"\(#config.oidc.logoutRedirectUrl)\""},
			if #config.oidc.enabled && #config.oidc.defaultAccess != "" {"oidc-default-access: \"\(#config.oidc.defaultAccess)\""},
			if #config.ntfy.extraConfig != "" {strings.TrimSpace(#config.ntfy.extraConfig)},
		], "\n") + "\n"
	}
}
