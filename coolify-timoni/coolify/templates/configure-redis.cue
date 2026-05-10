package templates

#ConfigureRedis: {
	#config: #Config
	#name:   #config.metadata.name

	if #config.redis.enabled {
		// Parity placeholder
	}
}
