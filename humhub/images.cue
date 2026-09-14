package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"ghcr.io/mriedmann/humhub-phponly" | string
		tag:        *"1.17.2@sha256:3f00ef2b0ef98b4665acdad27f7f0c40325391182193bdb783c64e26a9b94b2c" | string
	}
	nginxImage: {
		repository: *"ghcr.io/mriedmann/humhub-nginx" | string
		tag:        *"1.17.2@sha256:47fb119e2e0a182546a93646efcb5cd3f480171398eb1551b31e2030ec93c578" | string
	}
	mariadb: image: {
		repository: *"docker.io/bitnamisecure/mariadb" | string
		tag:        *"latest@sha256:16c4d59ca1e33e557e5003596d244aefac4dd03220c8967ae12e3cee2a4c7dd9" | string
	}
	redis: image: {
		repository: *"docker.io/bitnamisecure/valkey" | string
		tag:        *"latest@sha256:b330d587970c5925265a12d367feba4b6cd89078c75ba118ffb70002834c1a7c" | string
	}
}
