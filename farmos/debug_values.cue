@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=farmos -t namespace=default -t mv=10.0.1 -t kv=1.33.0 build'.
values: {
	image: {
		pullPolicy: "IfNotPresent"
		repository: "docker.io/farmos/farmos"
		tag:        "latest@sha256:0ead55792d93aaf9dc69d0e53e171a70163e4443d62df3bb7fb695c9487e3bc3"
	}
	persistence: {
		sitesdirectory: {
			enabled:   true
			mountPath: "/var/www/html/sites"
		}
	}
	postgresql: {
		enabled: true
		image: {
			pullPolicy: "IfNotPresent"
			repository: "docker.io/library/postgres"
			tag:        "16-alpine"
		}
		auth: {
			database: "farmos"
			username: "farmos"
			password: "farmos-secret-password"
		}
		service: {
			port: 5432
		}
		persistence: {
			enabled: true
			size:    "10Gi"
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
	securityContext: {
		container: {
			readOnlyRootFilesystem: false
			runAsGroup:             0
			runAsUser:              0
			capabilities: {
				add: [
					"NET_BIND_SERVICE",
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
					port:       80
					protocol:   "tcp"
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
					"farmos.example.com",
				]
			},
		]
	}
}
