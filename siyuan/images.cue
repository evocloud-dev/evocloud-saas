package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/b3log/siyuan" | string
		tag:        *"v3.8.3" | string
		digest:     *"" | string
	}
}
