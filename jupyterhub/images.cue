package main

// The container images tracked from the upstream releases.
values: {
	hub: image: {
		repository: *"quay.io/jupyterhub/k8s-hub" | string
		tag:        *"4.4.2" | string
		digest:     *"" | string
	}
	proxy: image: {
		repository: *"docker.io/jupyterhub/configurable-http-proxy" | string
		tag:        *"5.3.0" | string
		digest:     *"" | string
	}
	singleuser: image: {
		name:       *"quay.io/jupyter/base-notebook" | string
		tag:        *"2026-10-05" | string
		pullPolicy: *"IfNotPresent" | string
	}
}
