package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/mattermost/mattermost-enterprise-edition" | string
		tag:        *"release-12.1" | string
		digest:     *"sha256:077cbadc3e361324f8e5481046711d4648a83fca5ac62d55d77b8259527f3afc" | string
	}
}
