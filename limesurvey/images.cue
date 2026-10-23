package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"adamzammit/limesurvey" | string
		tag:        *"7.7.0.1" | string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | string
	}
	mariadb: image: {
		repository: *"docker.io/bitnamilegacy/mariadb" | string
		tag:        *"12.0.2-debian-12-r0" | string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | string
	}
}

