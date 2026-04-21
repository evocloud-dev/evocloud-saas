package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config._fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.service.annotations != _|_ || #config.commonAnnotations != _|_ {
			annotations: {
				for k, v in #config.service.annotations {
					"\(k)": v
				}
				for k, v in #config.commonAnnotations {
					"\(k)": v
				}
			}
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		ports: [
			{
				port:       #config.service.port
				targetPort: "http"
				protocol:   "TCP"
				name:       "http"
				if (#config.service.type == "NodePort" || #config.service.type == "LoadBalancer") && #config.service.nodePort != _|_ && #config.service.nodePort != "" {
					nodePort: #config.service.nodePort
				}
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "netbox"
		}
		if #config.service.clusterIP != _|_ && #config.service.clusterIP != "" && #config.service.type == "ClusterIP" {
			clusterIP: #config.service.clusterIP
		}
		if #config.service.clusterIPs != _|_ && #config.service.type == "ClusterIP" {
			clusterIPs: #config.service.clusterIPs
		}
		if #config.service.externalIPs != _|_ && len(#config.service.externalIPs) > 0 {
			externalIPs: #config.service.externalIPs
			clusterIPs: #config.service.externalIPs
		}
		if #config.service.sessionAffinity != _|_ {
			sessionAffinity: #config.service.sessionAffinity
		}
		if #config.service.sessionAffinityConfig != _|_ {
			sessionAffinityConfig: #config.service.sessionAffinityConfig
		}
		if #config.service.ipFamilyPolicy != _|_ && #config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if #config.service.type == "LoadBalancer" || #config.service.type == "NodePort" {
			if #config.service.externalTrafficPolicy != _|_ {
				externalTrafficPolicy: #config.service.externalTrafficPolicy
			}
		}
		if #config.service.type == "LoadBalancer" {
			if #config.service.loadBalancerSourceRanges != _|_ {
				loadBalancerSourceRanges: #config.service.loadBalancerSourceRanges
			}
			if #config.service.loadBalancerIP != _|_ && #config.service.loadBalancerIP != "" {
				loadBalancerIP: #config.service.loadBalancerIP
			}
			if #config.service.loadBalancerClass != _|_ && #config.service.loadBalancerClass != "" {
				loadBalancerClass: #config.service.loadBalancerClass
			}
		}
	}
}
