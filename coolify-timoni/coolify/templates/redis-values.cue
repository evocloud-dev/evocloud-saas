package templates

#RedisValues: {
	#config: #Config
	#name:   #config.metadata.name

	if #config.redis.enabled {
		// This is just a placeholder to maintain parity with the Helm structure
		// In Timoni, we handle this through the ConfigMap above or direct values
	}
}
