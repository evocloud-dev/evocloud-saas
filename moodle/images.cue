package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/moodlehq/moodle-php-apache" | string
		tag:        *"8.4-bookworm" | string
		digest:     *"sha256:922af51668352004b4255cdc1f726a63f0cee7c1354eaf66dd8d5f2c7cc379b5" | string
	}
	postgresql: image: {
		repository: *"docker.io/library/postgres" | string
		tag:        *"18.6-trixie" | string
		digest:     *"" | string
	}
	mysql: image: {
		repository: *"docker.io/library/mysql" | string
		tag:        *"8.4" | string
		digest:     *"" | string
	}
	mariadb: image: {
		repository: *"docker.io/library/mariadb" | string
		tag:        *"11.8" | string
		digest:     *"" | string
	}
	redis: image: {
		repository: *"docker.io/valkey/valkey" | string
		tag:        *"8.10.1" | string
		digest:     *"" | string
	}
}
