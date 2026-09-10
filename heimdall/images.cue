package main

// Container images tracked from upstream releases.
values: {
	image: {
		repository: *"docker.io/linuxserver/heimdall" | string
		tag:        *"2.8.2" | string
		digest:     *"" | string
	}
	backup: images: {
		archiver: *"docker.io/library/alpine:3.22" | string
		uploader: *"docker.io/helmforge/mc:1.0.0" | string
	}
}
