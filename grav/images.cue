package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"ghcr.io/linuxserver/grav" | string
		tag:        *"2.2.29" | string
		digest:     *"sha256:53495858dd2adc50add38e05972c58fca32034da0f0d7c50351ac1f09ee0e6b5" | string
	}
}
