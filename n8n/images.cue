package main

// Container images tracked from upstream releases.
values: {
	image: {
		repository: *"docker.io/n8nio/n8n" | string
		tag:        *"2.37.11" | string
		digest:     *"" | string
	}
	taskRunners: image: {
		repository: *"docker.io/n8nio/runners" | string
		tag:        *"2.37.11" | string
		digest:     *"" | string
	}
	postgresql: image: {
		repository: *"docker.io/library/postgres" | string
		tag:        *"18.6-alpine" | string
		digest:     *"" | string
	}
	mysql: image: {
		repository: *"docker.io/library/mysql" | string
		tag:        *"9.7" | string
		digest:     *"" | string
	}
	redis: image: {
		repository: *"docker.io/library/redis" | string
		tag:        *"8.10.1" | string
		digest:     *"" | string
	}
}
