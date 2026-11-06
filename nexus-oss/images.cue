package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/sonatype/nexus3" | string
		tag:        *"3.97.3@sha256:4b9a0efb605808c15927c751107b3f3308ae306c4b22715c96bf9bbabbb0e736" | string
		digest:     *"" | string
	}
}
