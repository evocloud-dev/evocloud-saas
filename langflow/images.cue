package main

// Container images tracked from upstream releases.
values: {
	image: {
		repository: *"docker.io/langflowai/langflow" | string
		tag:        *"1.13.2" | string
		digest:     *"" | string
	}
}
