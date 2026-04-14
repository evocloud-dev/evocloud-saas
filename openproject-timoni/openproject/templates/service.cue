package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: {
	#config: #Config

	if #config.service.enabled || #config.ingress.enabled {
		web: corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      #config.metadata.name
				namespace: #config.metadata.namespace
				labels: #config.metadata.labels & {
					"app.kubernetes.io/component": "openproject"
				}
				if #config.metadata.annotations != _|_ {
					annotations: #config.metadata.annotations
				}
			}
			spec: corev1.#ServiceSpec & {
				type: #config.service.type
				if #config.service.type == "LoadBalancer" && #config.service.loadBalancerIP != "" {
					loadBalancerIP: #config.service.loadBalancerIP
				}
				if #config.service.sessionAffinity.enabled {
					sessionAffinity: "ClientIP"
					sessionAffinityConfig: clientIP: timeoutSeconds: #config.service.sessionAffinity.timeoutSeconds
				}
				ports: [
					for name, p in #config.service.ports {
						{
							port:       p.port
							targetPort: name
							protocol:   p.protocol
							"name":     name
							if #config.service.type == "NodePort" && p.nodePort != 0 {
								nodePort: p.nodePort
							}
						}
					},
					if #config.metrics.enabled {
						{
							port:       #config.metrics.port
							targetPort: "metrics"
							protocol:   "TCP"
							"name":     "metrics"
						}
					},
				]
				selector: #config.selector.labels & {
					"openproject/process": "web"
				}
			}
		}
	}

	if #config.hocuspocus.enabled {
		hocuspocus: corev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				name:      "\(#config.metadata.name)-hocuspocus"
				namespace: #config.metadata.namespace
				labels: #config.metadata.labels & {
					"app.kubernetes.io/component": "openproject"
				}
			}
			spec: corev1.#ServiceSpec & {
				type: #config.hocuspocus.service.type
				if #config.hocuspocus.service.type == "LoadBalancer" && #config.hocuspocus.service.loadBalancerIP != "" {
					loadBalancerIP: #config.hocuspocus.service.loadBalancerIP
				}
				ports: [{
					port:       #config.hocuspocus.service.port
					targetPort: 1234
					protocol:   "TCP"
					"name":     "http"
				}]
				selector: #config.selector.labels & {
					"openproject/process": "hocuspocus"
				}
			}
		}
	}
}
