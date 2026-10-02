package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"ghcr.io/amruthpillai/reactive-resume" | string
		tag:        *"v5.3.0" | string
		digest:     *"sha256:c487ec5edcfe054bcb312fcd498f868e56f274756d0046b01c83f210855017ab" | string
	}
	proxy: image: {
		repository: *"docker.io/nginxinc/nginx-unprivileged" | string
		tag:        *"1.30.4-alpine" | string
		digest:     *"" | string
	}
	admission: image: {
		repository: *"docker.io/library/node" | string
		tag:        *"24.21.0-alpine" | string
		digest:     *"" | string
	}
	postgresql: image: {
		repository: *"docker.io/library/postgres" | string
		tag:        *"16-alpine" | string
		digest:     *"" | string
	}
}
