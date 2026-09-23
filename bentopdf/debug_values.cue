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
