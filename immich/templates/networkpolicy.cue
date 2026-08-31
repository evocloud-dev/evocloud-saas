package templates

#NetworkPolicyBuilder: {
	_config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      _config.fullname
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels
	}
	spec: {
		podSelector: matchLabels: _config.metadata.labels
		policyTypes: ["Ingress", "Egress"]
		ingress: {
			if len(_config.networkPolicy.ingress) > 0 {
				_config.networkPolicy.ingress
			}
			if len(_config.networkPolicy.ingress) == 0 {
				[{from: [{namespaceSelector: {}}]}]
			}
		}
		egress: {
			if len(_config.networkPolicy.egress) > 0 || len(_config.networkPolicy.extraEgress) > 0 {
				_config.networkPolicy.egress + _config.networkPolicy.extraEgress
			}
			if len(_config.networkPolicy.egress) == 0 && len(_config.networkPolicy.extraEgress) == 0 {
				[{}]
			}
		}
	}
}
