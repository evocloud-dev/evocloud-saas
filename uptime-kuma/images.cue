package main

// The container images tracked from upstream releases.
values: {
	image: {
		repository: *"docker.io/louislam/uptime-kuma" | string
		tag:        *"2.5.4" | string
		digest:     *"" | string
	}
	backup: images: {
		uploader: {
			repository: *"docker.io/helmforge/mc" | string
			tag:        *"1.0.0" | string
			digest:     *"" | string
		}
		mysql: {
			repository: *"docker.io/library/mysql" | string
			tag:        *"8.4" | string
			digest:     *"" | string
		}
	}
	mysql: image: {
		repository: *"docker.io/library/mysql" | string
		tag:        *"9.7.2" | string
		digest:     *"" | string
	}
}
