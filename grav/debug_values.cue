@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	image: {
		repository: "ghcr.io/linuxserver/grav"
		pullPolicy: "IfNotPresent"
		tag:        "2.2.9"
		digest:     "sha256:4946e4f4f362efe45eafad32ceedde863229a3b84465e4818535f913763c880a"
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
