package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/mattermost/mattermost-enterprise-edition" | string
		tag:        *"release-12.0" | string
		digest:     *"sha256:6e591e3aa84788b98727a63c6196f4d470f10efdfe053a200dd49cf56e7247aa" | string
	}
}
