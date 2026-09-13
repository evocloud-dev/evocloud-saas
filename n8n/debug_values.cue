@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	image: {
		repository: "docker.io/nginx"
		tag:        "1-alpine"
		repository: "docker.io/n8nio/n8n"
		tag:        "2.35.3"
		digest:     ""
	}
	test: {
		enabled: true
		image: {
			repository: "docker.io/curlimages/curl"
			tag:        "latest"
			digest:     ""
		}
		enabled: false
	}
	affinity: nodeAffinity: requiredDuringSchedulingIgnoredDuringExecution: nodeSelectorTerms: [{
		matchExpressions: [{
			key:      "kubernetes.io/os"
			operator: "In"
			values: ["linux"]
		}]
	}]
}
