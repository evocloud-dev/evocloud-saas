package main

// The container images tracked from the upstream releases.
values: {
	image: {
		repository: *"docker.io/traccar/traccar" | string
		tag:        *"6.17@sha256:b32d9346adf46df7c33c58577e17ad60f6feadd1f3cd87c876041f6c79317ef1" | string
		digest:     *"" | string
	}
	cnpg: image: {
		repository: *"ghcr.io/cloudnative-pg/postgresql" | string
		tag:        *"16.15" | string
		digest:     *"sha256:34cd4159d07b3410a1b29da35072e2e927a0905e717a61afa3814624a2e8859a" | string
	}
	initContainers: "system-cnpg-wait": image: {
		repository: *"oci.trueforge.org/containerforge/postgresql-client" | string
		tag:        *"9.6.24" | string
		digest:     *"sha256:d40ff61568601b7032a7e6892ca08e55f772d24b32a053d1c0c6b45a2c01ae93" | string
	}
}
