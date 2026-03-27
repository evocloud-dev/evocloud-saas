package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#in:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: #in.metadata & {
		// Keep the annotations if they exist
		if #in.service.annotations != _|_ {
			annotations: #in.service.annotations
		}
		labels: {
			"app.kubernetes.io/component": "app"
		}
	}

	spec: corev1.#ServiceSpec & {
		// Use the value from config/values instead of hardcoding
		type: #in.service.type
		
		selector: #in.selector.labels & {
			"app.kubernetes.io/component": "app"
		}
		

		if #in.service.loadBalancerIP != "" {
			loadBalancerIP: #in.service.loadBalancerIP
		}
		
		if len(#in.service.ipFamilies) > 0 {
			ipFamilies: #in.service.ipFamilies
		}
		
		if #in.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: #in.service.ipFamilyPolicy
		}
		
		// 2. STICKY SESSIONS
		if #in.service.sessionAffinity != "" {
			sessionAffinity: #in.service.sessionAffinity
		}
		
		if #in.service.sessionAffinityConfig != null {
			sessionAffinityConfig: #in.service.sessionAffinityConfig
		}
		
		ports: [
			{
				port:       #in.service.port
				targetPort: #in.nextcloud.containerPort
				protocol:   "TCP"
				name:       "http"
				if #in.service.nodePort != _|_ {
					nodePort: #in.service.nodePort
				}
			},
		]
	}
}
