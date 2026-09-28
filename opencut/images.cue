package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/helmforge/opencut" | string
		tag:        *"v0.3.0" | string
		digest:     *"" | string
	}
	postgresql: image: {
		repository: *"docker.io/library/postgres" | string
		tag:        *"18.6-trixie" | string
		digest:     *"" | string
	}
	redis: image: {
		repository: *"docker.io/valkey/valkey" | string
		tag:        *"9.2" | string
		digest:     *"" | string
	}
	redisHttp: image: {
		repository: *"docker.io/hiett/serverless-redis-http" | string
		tag:        *"0.0.10" | string
		digest:     *"" | string
	}
	test: image: {
		repository: *"docker.io/library/busybox" | string
		tag:        *"1.37.0" | string
		digest:     *"" | string
	}
}
