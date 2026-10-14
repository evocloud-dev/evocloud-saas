package main

// The container images tracked for Fleetbase services.
values: {
	app: image: {
		repository: *"docker.io/fleetbase/fleetbase-api" | string
		tag:        *"latest" | string
		digest:     *"" | string
	}
	httpd: image: {
		repository: *"docker.io/nginx" | string
		tag:        *"stable-alpine" | string
		digest:     *"" | string
	}
	console: image: {
		repository: *"docker.io/fleetbase/fleetbase-console" | string
		tag:        *"latest" | string
		digest:     *"" | string
	}
	socket: image: {
		repository: *"docker.io/socketcluster/socketcluster" | string
		tag:        *"v17.4.0" | string
		digest:     *"" | string
	}
	database: image: {
		repository: *"docker.io/mysql" | string
		tag:        *"8.0-oracle" | string
		digest:     *"" | string
	}
	cache: image: {
		repository: *"docker.io/redis" | string
		tag:        *"4-alpine" | string
		digest:     *"" | string
	}
}
