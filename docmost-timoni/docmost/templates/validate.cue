package templates

#Config: {
	// replicaCount must be 1 in this alpha chart
	replicaCount: 1

	// Validate storage configurations using package-level references
	if #Config.storage.mode == "local" {
		_localGuard: true & (#Config.storage.local.enabled || #Config.storage.local.existingClaim != "")
	}

	if #Config.storage.mode == "s3" {
		_s3BucketGuard: true & (#Config.storage.s3.bucket != "")
	}

	if #Config.storage.mode == "s3" && #Config.storage.s3.existingSecret == "" {
		_s3SecretGuard: true & (#Config.storage.s3.accessKey != "" && #Config.storage.s3.secretKey != "")
	}
}
