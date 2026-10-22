package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/semaphoreui/semaphore" | string
		tag:        *"v2.19.17" | string
		digest:     *"sha256:008dacd9f1adbd92e8a048f1786ae1dd9bed2a352aca2eb30b9837de5706e7f7" | string
	}
	cnpg: main: {
		image: {
			repository: *"ghcr.io/cloudnative-pg/postgresql" | string
			tag:        *"16.15" | string
			digest:     *"sha256:34cd4159d07b3410a1b29da35072e2e927a0905e717a61afa3814624a2e8859a" | string
		}
		waitImage: {
			repository: *"oci.trueforge.org/containerforge/postgresql-client" | string
			tag:        *"9.6.24" | string
			digest:     *"sha256:d40ff61568601b7032a7e6892ca08e55f772d24b32a053d1c0c6b45a2c01ae93" | string
		}
	}
}

