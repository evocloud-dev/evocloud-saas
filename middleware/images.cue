package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/middlewareeng/middleware" | string
		tag:        *"0.3.1" | string
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
	test: image: {
		repository: *"docker.io/curlimages/curl" | string
		tag:        *"8.21.0" | string
		digest:     *"" | string
	}
}
