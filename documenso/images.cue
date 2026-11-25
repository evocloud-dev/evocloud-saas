package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: "ghcr.io/documenso/documenso"
		tag:        "v2.22.0"
		digest:     "sha256:f9976d2142d34ee89506e161b0a5ec859a0c327f3fe0a398b46d3941fc8dd35e"
	}
	waitForServices: image: {
		repository: "docker.io/library/busybox"
		tag:        "1.37.0"
		digest:     "sha256:bdf57e528e45e4433820e045b29b4597825a1c9e38353532d90a01445013f82e"
	}
	postgresql: image: {
		repository: "docker.io/library/postgres"
		tag:        "18.6-trixie"
	}
	redis: image: {
		repository: "docker.io/valkey/valkey"
		tag:        "9.2"
	}
	inbucket: image: {
		repository: "docker.io/inbucket/inbucket"
		tag:        "main"
		digest:     "sha256:bcbdd450835688f45bcc1fbe0cdd2876422e0c92548b91dd5aa5ecda926b8ee9"
	}
}
