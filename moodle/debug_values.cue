@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	replicaCount: 1
	source: {
		mode:   "archive"
		url:    "https://download.moodle.org/download.php/direct/stable502/moodle-5.2.2.tgz"
		sha256: "72be209e7c0f5341b87de0bc993b2430087fda2769d8c3cc2f32736d1513e88c"
	}
	moodle: {
		wwwroot:       "http://localhost:8080"
		adminPassword: "Debug-password-123!"
	}
	postgresql: enabled: true
}
