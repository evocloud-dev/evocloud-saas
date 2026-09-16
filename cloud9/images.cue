package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"ghcr.io/linuxserver/cloud9" | string
		tag:        *"version-1.29.2@sha256:45c5fe102ff3390bcd4ea58db99023b7ea099a8462f5727973ec329bd4a8d6b4" | string
	}
}
