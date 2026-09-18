package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

#NetworkPolicy: networkingv1.#NetworkPolicy & {
	#config: #Config
	apiVersion: "networking/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/instance": #config.metadata.name
		}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: networkingv1.#NetworkPolicySpec & {
		podSelector: matchLabels: #config.selector.labels
		policyTypes: [
			if #config.networkPolicy.ingress != _|_ && len(#config.networkPolicy.ingress) > 0 {"Ingress"},
			if #config.networkPolicy.egress != _|_ && len(#config.networkPolicy.egress) > 0 {"Egress"},
		]
		if #config.networkPolicy.ingress != _|_ && len(#config.networkPolicy.ingress) > 0 {
			ingress: [
				{
					_from: [
						for item in #config.networkPolicy.ingress {
							if item.ipBlock != _|_ {
								ipBlock: {
									cidr: item.ipBlock.cidr
									if item.ipBlock.except != _|_ {
										except: item.ipBlock.except
									}
								}
							}
							if item.namespaceSelector != _|_ {
								namespaceSelector: {
									if item.namespaceSelector.matchLabels != _|_ {
										matchLabels: item.namespaceSelector.matchLabels
									}
									if item.namespaceSelector.matchExpressions != _|_ {
										matchExpressions: [
											for expr in item.namespaceSelector.matchExpressions {
												key:      expr.key
												operator: expr.operator
												if expr.values != _|_ {
													values: expr.values
												}
											},
										]
									}
								}
							}
							if item.podSelector != _|_ {
								podSelector: {
									if item.podSelector.matchLabels != _|_ {
										matchLabels: item.podSelector.matchLabels
									}
									if item.podSelector.matchExpressions != _|_ {
										matchExpressions: [
											for expr in item.podSelector.matchExpressions {
												key:      expr.key
												operator: expr.operator
												if expr.values != _|_ {
													values: expr.values
												}
											},
										]
									}
								}
							}
						},
					]
					if len(_from) > 0 {
						from: _from
					}
					_ports: [
						for item in #config.networkPolicy.ingress {
							if item.ports != _|_ {
								for p in item.ports {
									protocol: p.protocol
									port:     p.port
								}
							}
						},
					]
					if len(_ports) > 0 {
						ports: _ports
					}
				},
			]
		}
		if #config.networkPolicy.egress != _|_ && len(#config.networkPolicy.egress) > 0 {
			egress: [
				{
					_to: [
						for item in #config.networkPolicy.egress {
							if item.ipBlock != _|_ {
								ipBlock: {
									cidr: item.ipBlock.cidr
									if item.ipBlock.except != _|_ {
										except: item.ipBlock.except
									}
								}
							}
						},
					]
					if len(_to) > 0 {
						to: _to
					}
					_ports: [
						for item in #config.networkPolicy.egress {
							if item.ports != _|_ {
								for p in item.ports {
									protocol: p.protocol
									port:     p.port
								}
							}
						},
					]
					if len(_ports) > 0 {
						ports: _ports
					}
				},
			]
		}
	}
}
