@if(debug)

package main

// Values used by debug_tool.cue and timoni mod vet --debug.
values: {
	replicaCount: 2
	podAnnotations: "cluster-autoscaler.kubernetes.io/safe-to-evict": "true"

	metrics: {
		enabled: true
		serviceMonitor: enabled: true
		prometheusRule: enabled: true
	}
	ingress: {
		enabled:          true
		ingressClassName: "traefik"
		hosts: [{
			host: "pdf.example.com"
			paths: [{
				path:     "/"
				pathType: "Prefix"
			}]
		}]
	}
	gatewayAPI: {
		enabled: true
		httpRoutes: [{
			parentRefs: [{
				name: "gateway"
			}]
		}]
	}
	podDisruptionBudget: enabled: true
	autoscaling: enabled:         true
	affinity: nodeAffinity: requiredDuringSchedulingIgnoredDuringExecution: nodeSelectorTerms: [{
		matchExpressions: [{
			key:      "kubernetes.io/os"
			operator: "In"
			values: ["linux"]
		}]
	}]
}
