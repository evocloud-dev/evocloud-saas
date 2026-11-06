@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=traccar -t namespace=default -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	podAnnotations: "cluster-autoscaler.kubernetes.io/safe-to-evict": "true"
	image: {
		repository: "docker.io/traccar/traccar"
		tag:        "6.17"
		digest:     ""
	}
}
