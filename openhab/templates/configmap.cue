package templates

#SitemapsConfigMapBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_config.fullname)-sitemaps"
		namespace: _config.namespace
		labels:    _config.metadata.labels
		annotations: {
			"helmforge.dev/config-sync": "startup-copy"
		}
	}
	data: _config.configMaps.sitemaps.files
}

#ThingsConfigMapBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_config.fullname)-things"
		namespace: _config.namespace
		labels:    _config.metadata.labels
		annotations: {
			"helmforge.dev/config-sync": "startup-copy"
		}
	}
	data: _config.configMaps.things.files
}

#ItemsConfigMapBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_config.fullname)-items"
		namespace: _config.namespace
		labels:    _config.metadata.labels
		annotations: {
			"helmforge.dev/config-sync": "startup-copy"
		}
	}
	data: _config.configMaps.items.files
}
