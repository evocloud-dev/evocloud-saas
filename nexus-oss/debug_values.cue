@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=nexus -t namespace=default -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	image: {
		pullPolicy: "IfNotPresent"
		repository: "docker.io/sonatype/nexus3"
		tag:        "3.97.3@sha256:4b9a0efb605808c15927c751107b3f3308ae306c4b22715c96bf9bbabbb0e736"
		digest:     ""
	}
	persistence: {
		data: {
			enabled:   true
			mountPath: "/nexus-data"
		}
	}
	securityContext: {
		container: {
			runAsGroup: 200
			runAsUser:  200
		}
		pod: {
			fsGroup: 200
		}
	}
	service: {
		main: {
			ports: {
				main: {
					port:       10288
					targetPort: 8081
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
							INSTALL4J_ADD_VM_PARAMS: "-Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m -Djava.util.prefs.userRoot=${NEXUS_DATA}/javaprefs"
						}
					}
				}
			}
		}
	}
}
