package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#LiveSecret: corev1.#Secret & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-live-secrets"
	}
	type: "Opaque"
	stringData: {
		LIVE_SERVER_SECRET_KEY: #config.env.live_server_secret_key
		REDIS_URL:              "redis://\(#config.metadata.name)-redis.\(#config.#namespace).svc.cluster.local:6379/"
	}
}

#LiveConfigMap: corev1.#ConfigMap & {
	#config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-live-vars"
	}
	data: {
		API_BASE_URL:    "http://\(#config.metadata.name)-api.\(#config.#namespace).svc.cluster.local:8000/"
		LIVE_BASE_PATH:  "/live"
		IFRAMELY_URL:    "http://\(#config.metadata.name)-iframely.\(#config.#namespace).svc.cluster.local:8061/"
		
		LIVE_SENTRY_DSN:                #config.env.live_sentry_dsn
		LIVE_SENTRY_ENVIRONMENT:        #config.env.live_sentry_environment
		LIVE_SENTRY_TRACES_SAMPLE_RATE: #config.env.live_sentry_traces_sample_rate
	}
}
