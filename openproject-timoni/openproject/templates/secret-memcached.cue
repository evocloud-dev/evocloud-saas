package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#MemcachedSecret: corev1.#Secret & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      "\(#config.metadata.name)-memcached"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels & {
			"app.kubernetes.io/component": "memcached"
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		if #config.memcached.bundled {
			OPENPROJECT_CACHE__MEMCACHE__SERVER: "\(#config.metadata.name)-memcached:11211"
		}
		if !#config.memcached.bundled && #config.memcached.connection.host != null && #config.memcached.connection.port != null {
			OPENPROJECT_CACHE__MEMCACHE__SERVER: "\(#config.memcached.connection.host):\(#config.memcached.connection.port)"
		}
		if !#config.memcached.bundled && (#config.memcached.connection.host == null || #config.memcached.connection.port == null) {
			OPENPROJECT_CACHE__MEMCACHE__SERVER: ""
		}
	}
}
