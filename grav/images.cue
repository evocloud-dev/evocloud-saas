package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"ghcr.io/linuxserver/grav" | string
		tag:        *"2.2.9" | string
		digest:     *"sha256:4946e4f4f362efe45eafad32ceedde863229a3b84465e4818535f913763c880a" | string
	}
}
