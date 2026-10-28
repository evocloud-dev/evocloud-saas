@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	image: {
		repository: "docker.io/jgraph/drawio"
		tag:        "32.6.1@sha256:3d0a5a5ffb4f76abcecd9d17ae1373e3eefd0db07b657c545637dc9c6a7412e1"
		pullPolicy: "IfNotPresent"
	}
	securityContext: {
		container: {
			readOnlyRootFilesystem: false
			runAsNonRoot:           false
			runAsUser:              0
			runAsGroup:             0
			capabilities: {
				add: [
					"CHOWN",
					"SETUID",
					"SETGID",
					"FOWNER",
					"DAC_OVERRIDE",
				]
				drop: [
					"ALL",
				]
			}
		}
	}
	service: {
		main: {
			ports: {
				main: {
					port:       10214
					targetPort: 8080
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
	gatewayAPI: {
		enabled: true
		httpRoutes: [
			{
				parentRefs: [
					{
						name:      "main-gateway"
						namespace: "gateway-system"
					},
				]
				hostnames: [
					"drawio.example.com",
				]
			},
		]
	}
}
