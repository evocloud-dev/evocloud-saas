package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"ghcr.io/alam00000/bentopdf" | string
		tag:        *"2.8.8" | string
		digest:     *"" | string
	}
	metrics: image: {
		repository: *"docker.io/nginx/nginx-prometheus-exporter" | string
		tag:        *"1.5.3" | string
		digest:     *"" | string
	}

}
