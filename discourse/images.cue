package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/discourse/discourse" | string
		tag:        *"2026.7.5" | string
		digest:     *"sha256:284bdb7b6fa0e932d0e8a862c730d024abfeeb85c872dd7833154a134eeaa403" | string
	}
	waitForServices: image: {
		repository: *"docker.io/library/busybox" | string
		tag:        *"1.37.0-uclibc" | string
		digest:     *"" | string
	}
	postgresql: image: {
		repository: *"docker.io/pgvector/pgvector" | string
		tag:        *"0.8.7-pg18-trixie@sha256:5895949dfcdf308eb0cd31c950c93c14895c77f33fbedfecf1fa511ab1d4bcd2" | string
		digest:     *"" | string
	}
	redis: image: {
		repository: *"docker.io/valkey/valkey" | string
		tag:        *"9.2" | string
		digest:     *"" | string
	}
}
