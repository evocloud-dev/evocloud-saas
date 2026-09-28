@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	opencut: {
		siteUrl:          "https://opencut.example.com"
		betterAuthSecret: "debug-better-auth-secret-key-32chars"
	}
	gateway: {
		enabled: true
		parentRefs: [{
			name: "my-gateway"
		}]
		hostnames: ["opencut.example.com"]
	}
	autoscaling: {
		enabled: true
	}
	test: {
		enabled: true
	}
}
