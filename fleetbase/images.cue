package main

// The container images tracked for Fleetbase services.
values: {
	app: image: {
		repository: *"docker.io/fleetbase/fleetbase-api" | string
		tag:        *"v0.7.75" | string
		digest:     *"" | string
	}
	httpd: image: {
		repository: *"docker.io/nginx" | string
		tag:        *"stable-alpine" | string
		digest:     *"sha256:583b7f2fce1cdb8da5ad5c39ebd3c33b98b87d493190e548bdee1fa8c619c311" | string
	}
	console: image: {
		repository: *"docker.io/fleetbase/fleetbase-console" | string
		tag:        *"v0.7.75" | string
		digest:     *"" | string
	}
	socket: image: {
		repository: *"docker.io/socketcluster/socketcluster" | string
		tag:        *"v20.0.2" | string
		digest:     *"" | string
	}
	database: image: {
		repository: *"docker.io/mysql" | string
		tag:        *"8.4-oracle" | string
		digest:     *"sha256:a81d043930e51745522bd5c430961cf8286f0a23f0a9a2a6e0108f7ea71b0902" | string
	}
	cache: image: {
		repository: *"docker.io/valkey/valkey" | string
		tag:        *"9.2" | string
		digest:     *"sha256:247b5e730bdc9dc29fddb8274d1731b203a1a1a46af63eae3a9d55b4bf74853f" | string
	}
}
