@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	podAnnotations: "cluster-autoscaler.kubernetes.io/safe-to-evict": "true"
	serviceAccount: {
		create: true
	}
	ingress: {
		enabled:   true
		className: "nginx"
	}
	autoscaling: {
		enabled: true
	}
	image: {
		repository: "adamzammit/limesurvey"
		tag:        "7.6.0"
		digest:     ""
	}
	mariadb: {
		enabled: true
		image: {
			repository: "docker.io/bitnamilegacy/mariadb"
			tag:        "12.0.2-debian-12-r0"
			digest:     ""
		}
	}
	test: {
		enabled: true
		image: {
			repository: "busybox"
			tag:        "latest"
			digest:     ""
		}
	}
}

