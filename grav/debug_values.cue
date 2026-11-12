@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	image: {
		repository: "ghcr.io/linuxserver/grav"
		pullPolicy: "IfNotPresent"
		tag:        "2.2.29"
		digest:     "sha256:53495858dd2adc50add38e05972c58fca32034da0f0d7c50351ac1f09ee0e6b5"
	}
	service: {
		main: {
			ports: {
				main: {
					port:       10012
					targetPort: 80
				}
			}
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
					"grav.example.com",
				]
			},
		]
	}
	persistence: {
		config: {
			enabled:   true
			mountPath: "/config"
		}
		varrun: {
			enabled: true
		}
	}
	securityContext: {
		container: {
			readOnlyRootFilesystem: false
			runAsNonRoot:           false
			runAsUser:              0
			runAsGroup:             0
		}
	}
}
