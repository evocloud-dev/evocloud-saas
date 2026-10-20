package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/jgraph/drawio" | string
		tag:        *"32.5.5@sha256:30fefe1cf6e48c78f8816cdcd969d0a402a6bfd5077252cf5bb0428fd8ceaf69" | string
		digest:     *"" | string
		pullPolicy: *"IfNotPresent" | string
	}
}
