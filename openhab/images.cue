package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/openhab/openhab" | string
		tag:        *"5.2.0" | string
		digest:     *"" | string
	}
}
