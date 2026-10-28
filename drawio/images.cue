package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/jgraph/drawio" | string
		tag:        *"32.6.1@sha256:3d0a5a5ffb4f76abcecd9d17ae1373e3eefd0db07b657c545637dc9c6a7412e1" | string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | string
	}
}
