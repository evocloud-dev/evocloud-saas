package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/fletchto99/hexo-dev-blog" | string
		tag:        *"4.3.2@sha256:0d35f27fa6c9330660591c539a558c865ed808bbc39a8eecf39b5324680153f5" | string
		digest:     *"" | string
	}
}
