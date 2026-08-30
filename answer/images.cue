package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/apache/answer" | string
		tag:        *"2.0.2" | string
		digest:     *"" | string
	}
	postgresql: image: {
		repository: *"docker.io/library/postgres" | string
		tag:        *"18.4-trixie" | string
		digest:     *"" | string
	}
	mysql: image: {
		repository: *"docker.io/library/mysql" | string
		tag:        *"9.7.2" | string
		digest:     *"" | string
	}
}
