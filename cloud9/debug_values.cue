@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=cloud9 -t namespace=default -t mv=15.10.0 -t kv=1.28.0 build'.
values: {
	image: {
		repository: "ghcr.io/linuxserver/cloud9"
		pullPolicy: "IfNotPresent"
		tag:        "version-1.29.2@sha256:45c5fe102ff3390bcd4ea58db99023b7ea099a8462f5727973ec329bd4a8d6b4"
	}
	securityContext: {
		container: {
			readOnlyRootFilesystem: false
			runAsNonRoot:           false
			runAsUser:              0
			runAsGroup:             0
		}
	}
	resources: {
		requests: {
			cpu:    "75m"
			memory: "200Mi"
		}
		limits: {
			cpu:    "1500m"
			memory: "2400Mi"
		}
	}
	service: {
		main: {
			ports: {
				main: {
					port:       10070
					protocol:   "http"
					targetPort: 8000
				}
			}
		}
	}
	workload: {
		main: {
			podSpec: {
				containers: {
					main: {
						probes: {
							liveness: {
								type: "http"
								path: "/"
							}
							readiness: {
								type: "http"
								path: "/"
							}
							startup: {
								type: "http"
								path: "/"
							}
						}
						env: {}
					}
				}
			}
		}
	}
	persistence: {
		code: {
			enabled:   true
			mountPath: "/code"
		}
	}
	route: {
		enabled: false
	}
}
