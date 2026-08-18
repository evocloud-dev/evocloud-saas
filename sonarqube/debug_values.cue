@if(debug)

package main

// Values used by debug_tool.cue.
// Debug example 'cue cmd -t debug -t name=test -t namespace=test -t mv=1.0.0 -t kv=1.28.0 build'.
values: {
	podAnnotations: "cluster-autoscaler.kubernetes.io/safe-to-evict": "true"
	tests: {
		enabled: true
		image: {
			repository: "docker.io/library/busybox"
			tag:        "1.37"
			digest:     ""
		}
	}
	affinity: nodeAffinity: requiredDuringSchedulingIgnoredDuringExecution: nodeSelectorTerms: [{
		matchExpressions: [{
			key:      "kubernetes.io/os"
			operator: "In"
			values: ["linux"]
		}]
	}]

	postgresql: {
		enabled: true
	}
	ingress: {
		enabled: true
		hosts: [{
			host: "sonar.example.com"
			paths: [{
				path:     "/"
				pathType: "Prefix"
			}]
		}]
	}
	networkPolicy: {
		enabled: true
	}
	pdb: {
		enabled: true
	}
	externalSecrets: {
		enabled: true
		secretStoreRef: name: "vault-backend"
		database: {
			enabled:           true
			passwordRemoteRef: key: "database/creds/sonar"
		}
		monitoringPasscode: {
			enabled:   true
			remoteRef: key: "monitoring/passcode"
		}
	}
	gatewayAPI: {
		enabled: true
		parentRefs: [{
			name:      "my-gateway"
			namespace: "gateway-system"
		}]
		matches: [{
			path: {
				type:  "PathPrefix"
				value: "/"
			}
		}]
	}
}
