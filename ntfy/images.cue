package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/binwiederhier/ntfy" | string
		tag:        *"v2.32.0" | string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
	}
	ntfy: database: waitImage: {
		repository: *"docker.io/library/busybox" | string
		tag:        *"1.37" | string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
	}
	postgresql: image: {
		repository: *"docker.io/library/postgres" | string
		tag:        *"18.6-trixie" | string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | "Always" | "Never"
	}
}
