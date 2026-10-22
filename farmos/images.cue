package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/farmos/farmos" | string
		tag:        *"latest@sha256:0ead55792d93aaf9dc69d0e53e171a70163e4443d62df3bb7fb695c9487e3bc3" | string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | string
	}
	postgresql: {
		image: {
			repository: *"docker.io/library/postgres" | string
			tag:        *"16-alpine" | string
			digest:     *"" | string
			pullPolicy: *"IfNotPresent" | string
		}
	}
}
