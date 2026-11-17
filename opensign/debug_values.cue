@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	server: {
		image: {
			repository: "docker.io/opensign/opensignserver"
			tag:        "main"
			digest:     "sha256:49819bc883aa5b0053106f2d60d49334231c723cc37c01a304a9322e46bfc06f"
		}
	}
	client: {
		image: {
			repository: "docker.io/opensign/opensign"
			tag:        "main"
			digest:     "sha256:093910c698c135e272a794ec1df81324c584b0c1011bb95da0c04ff22adb45ac"
		}
	}
	test: {
		enabled: true
		image: {
			repository: "docker.io/curlimages/curl"
			tag:        "latest"
			digest:     ""
		}
	}
}
