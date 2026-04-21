package templates

import (
	corev1 "k8s.io/api/core/v1"
	"strings"
)

#OIDCSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-oidc"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "oidc"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		let prefix = "OPENPROJECT_OPENID__CONNECT_\(strings.ToUpper(#config.openproject.oidc.provider))"
		"\(prefix)_DISPLAY__NAME":           #config.openproject.oidc.displayName
		"\(prefix)_HOST":                   #config.openproject.oidc.host
		"\(prefix)_IDENTIFIER":             #config.openproject.oidc.identifier
		"\(prefix)_SECRET":                 #config.openproject.oidc.secret
		"\(prefix)_AUTHORIZATION__ENDPOINT": #config.openproject.oidc.authorizationEndpoint
		"\(prefix)_TOKEN__ENDPOINT":         #config.openproject.oidc.tokenEndpoint
		"\(prefix)_USERINFO__ENDPOINT":      #config.openproject.oidc.userinfoEndpoint
		"\(prefix)_END__SESSION__ENDPOINT":   #config.openproject.oidc.endSessionEndpoint
		"\(prefix)_SCOPE":                   #config.openproject.oidc.scope
		for k, v in #config.openproject.oidc.attribute_map {
			"\(prefix)_ATTRIBUTE__MAP_\(strings.ToUpper(k))": v
		}
	}
}
