package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"ghcr.io/toeverything/affine" | string
		tag:        *"0.27.4" | string
		digest:     *"" | string
	}
	postgresql: image: {
		repository: *"pgvector/pgvector" | string
		tag:        *"0.8.7-pg18-bookworm@sha256:2358fcba361ed2233a5ed81b5fe4ca779ccb304120ce531a3bf51c0ed7e2bc11" | string
		digest:     *"" | string
	}
	redis: image: {
		repository: *"docker.io/valkey/valkey" | string
		tag:        *"9.2" | string
		digest:     *"" | string
	}
}