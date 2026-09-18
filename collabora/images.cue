package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/collabora/code" | string
		tag:        *"26.04.4.1.1" | string
		digest:     *"sha256:1efda3043e8b9cb437d1b6c6efe20cc3753760e634de012b8dac391da488bf97" | string
	}
	test: image: {
		repository: *"docker.io/curlimages/curl" | string
		tag:        *"8.21.0" | string
		digest:     *"sha256:7c12af72ceb38b7432ab85e1a265cff6ae58e06f95539d539b654f2cfa64bb13" | string
	}
}
