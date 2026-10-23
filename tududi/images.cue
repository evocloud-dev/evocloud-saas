package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/chrisvel/tududi" | string
		tag:        *"latest" | string
		digest:     *"" | string
	}
	postgres: image: {
		repository: *"docker.io/postgres" | string
		tag:        *"16-alpine" | string
		digest:     *"" | string
	}
	test: image: {
		repository: *"docker.io/curlimages/curl" | string
		tag:        *"8.21.0" | string
		digest:     *"sha256:7c12af72ceb38b7432ab85e1a265cff6ae58e06f95539d539b654f2cfa64bb13" | string
	}
}
