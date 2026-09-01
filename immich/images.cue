package main

// Container images tracked from upstream releases.
values: {
	image: {
		digest: *"" | string
	}
	machineLearning: image: {
		digest: *"" | string
	}
	postgresql: image: {
		digest: *"" | string
	}
	valkey: image: {
		digest: *"" | string
	}
	wait: image: {
		digest: *"" | string
	}
	test: image: {
		digest: *"" | string
	}
}
