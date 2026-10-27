package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"ghcr.io/linuxserver/grav" | string
		tag:        *"2.2.13" | string
		digest:     *"sha256:a355dd195ae6245bcae467fdfa10b71ae54f0f93c423eb54e3e4c1f920c6fce7" | string
	}
}
