@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	collabora: {
		username:    "admin"
		password:    "changeme"
		server_name: "example.com"
		aliasgroups: [
			{
				host: "https://cloud.example.com"
			},
		]
		extra_params: "--o:ssl.enable=false --o:ssl.termination=true --o:welcome.enable=false --o:mount_jail_tree=false --o:user_interface.mode=default"
	}
	image: {
		repository: "docker.io/collabora/code"
		tag:        "26.04.3.2.1"
		digest:     "sha256:379b8f1fc955dd6d01ba24adf61d1b177048ddaae179ae8c1e6a6342daccb282"
	}
	test: {
		enabled: false
		image: {
			repository: "docker.io/curlimages/curl"
			tag:        "8.21.0"
			digest:     "sha256:7c12af72ceb38b7432ab85e1a265cff6ae58e06f95539d539b654f2cfa64bb13"
		}
	}
}
