@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=hexo -t namespace=default -t mv=10.0.7 -t kv=1.33.0 build'.
values: {
	image: {
		pullPolicy: "IfNotPresent"
		repository: "docker.io/fletchto99/hexo-dev-blog"
		tag:        "latest"
		digest:     "sha256:76b545d32ba15df60867e0dd3ef818bc833dcf9c23dac51e6efa355af2d8f6e2"
	}
	persistence: {
		config: {
			enabled:   true
			mountPath: "/config"
		}
	}
	securityContext: {
		container: {
			readOnlyRootFilesystem: false
			runAsGroup:             0
			runAsUser:              0
		}
	}
	service: {
		main: {
			ports: {
				main: {
					port:       10306
					protocol:   "http"
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
						env: {
							HEXO_PLUGINS: ""
						}
					}
				}
			}
		}
	}
}
