package templates

import (
	"list"
	networkingv1 "k8s.io/api/networking/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#NetworkPolicy: networkingv1.#NetworkPolicy & {
	#config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "sonarqube"
	}
	metadata: {
		name: #config.fullname
		labels: "app.kubernetes.io/component": "sonarqube"
	}
	spec: networkingv1.#NetworkPolicySpec & {
		podSelector: matchLabels: #config.selector.labels & {
			"app.kubernetes.io/component": "sonarqube"
		}

		let _egressEnabled = #config.networkPolicy.egress.enabled
		let _extraEgress = #config.networkPolicy.egress.extraEgress
		let _hasEgress = _egressEnabled || len(_extraEgress) > 0

		policyTypes: list.Concat([
			["Ingress"],
			[
				if _hasEgress {
					"Egress"
				},
			],
		])

		let _ingressAllowSame = #config.networkPolicy.ingress.allowSameNamespace
		let _ingressExtra = #config.networkPolicy.ingress.extraFrom
		let _hasIngress = _ingressAllowSame || len(_ingressExtra) > 0

		ingress: [
			if _hasIngress {
				from: list.Concat([
					[
						if _ingressAllowSame {
							podSelector: {}
						},
					],
					_ingressExtra,
				])
				ports: [
					{
						protocol: "TCP"
						port:     "http"
					},
				]
			},
		]

		if _hasEgress {
			let _egress = #config.networkPolicy.egress
			let _extraTo = _egress.extraTo

			egress: list.Concat([
				[
					if _egress.enabled {
						if _egress.allowDNS {
							to: [
								{namespaceSelector: {}},
							]
							ports: [
								{protocol: "UDP", port: 53},
								{protocol: "TCP", port: 53},
							]
						}
					},
					if _egress.enabled {
						if _egress.allowHTTP {
							to: [
								{namespaceSelector: {}},
							]
							ports: [
								{protocol: "TCP", port: 80},
							]
						}
					},
					if _egress.enabled {
						if _egress.allowHTTPS {
							ports: [
								{protocol: "TCP", port: 443},
							]
						}
					},
					if _egress.enabled {
						if _egress.allowPostgreSQL {
							ports: [
								{protocol: "TCP", port: _egress.postgresqlPort},
							]
						}
					},
					if _egress.enabled {
						if len(_extraTo) > 0 {
							to: _extraTo
						}
					},
				],
				_extraEgress,
			])
		}
	}
}
