package templates

import (
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
)

#NetworkPolicy: netv1.#NetworkPolicy & {
	#config: #Config

	_ingressPeers: [
		if len(#config.networkPolicy.ingressFrom) > 0 {
			#config.networkPolicy.ingressFrom
		},
		[{podSelector: {}}],
	][0]

	// Build the conditional PostgreSQL egress rule as a list (0 or 1 items).
	_pgEgress: [
		if #config.postgresql.enabled {
			{
				to: [
					{
						podSelector: matchLabels: {
							// The PostgreSQL subchart sets name=postgresql (not <release>-postgresql)
							"app.kubernetes.io/name":     "postgresql"
							"app.kubernetes.io/instance": #config.metadata.name
						}
					},
				]
				ports: [
					{
						protocol: corev1.#ProtocolTCP
						port:     #config.postgresql.service.port
					},
				]
			}
		},
	]

	// Build the conditional public-HTTPS egress rule as a list (0 or 1 items).
	_httpsEgress: [
		if #config.networkPolicy.allowPublicHttps {
			{
				to: [
					{
						ipBlock: {
							cidr: "0.0.0.0/0"
							except: [
								"0.0.0.0/8",
								"10.0.0.0/8",
								"100.64.0.0/10",
								"127.0.0.0/8",
								"169.254.0.0/16",
								"172.16.0.0/12",
								"192.0.0.0/24",
								"192.0.2.0/24",
								"192.168.0.0/16",
								"198.18.0.0/15",
								"198.51.100.0/24",
								"203.0.113.0/24",
								"224.0.0.0/4",
								"240.0.0.0/4",
							]
						}
					},
					{
						ipBlock: {
							cidr: "2000::/3"
							except: [
								"2001::/32",
								"2001:2::/48",
								"2001:db8::/32",
								"2002::/16",
							]
						}
					},
				]
				ports: [
					{
						protocol: corev1.#ProtocolTCP
						port:     443
					},
				]
			}
		},
	]

	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      #config.metadata.name
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: netv1.#NetworkPolicySpec & {
		podSelector: matchLabels: #config.selector.labels
		policyTypes: [netv1.#PolicyTypeIngress, netv1.#PolicyTypeEgress]
		ingress: [
			{
				from: _ingressPeers
				ports: [
					{
						protocol: corev1.#ProtocolTCP
						port:     3000
					},
				]
			},
			{
				// Allow admission helper to reach the bootstrap control port
				from: [
					{
						podSelector: matchLabels: {
							"app.kubernetes.io/name":     "\(#config.metadata.name)-admission"
							"app.kubernetes.io/instance": #config.metadata.name
						}
					},
				]
				ports: [
					{
						protocol: corev1.#ProtocolTCP
						port:     3011
					},
				]
			},
		]
		egress: [
			// Always: reach the admission helper for bootstrap HMAC handshake
			{
				to: [
					{
						podSelector: matchLabels: {
							"app.kubernetes.io/name":     "\(#config.metadata.name)-admission"
							"app.kubernetes.io/instance": #config.metadata.name
						}
					},
				]
				ports: [
					{
						protocol: corev1.#ProtocolTCP
						port:     8088
					},
				]
			},
			// Conditionally: PostgreSQL (when bundled)
			for r in _pgEgress {r},
			// Always: DNS
			{
				to: [for d in #config.networkPolicy.dnsEgress {d}]
				ports: [
					{
						protocol: corev1.#ProtocolUDP
						port:     53
					},
					{
						protocol: corev1.#ProtocolTCP
						port:     53
					},
				]
			},
			// Conditionally: public HTTPS for S3/OAuth/SMTP
			for r in _httpsEgress {r},
			// User-supplied extra egress rules
			for r in #config.networkPolicy.extraEgress {r},
		]
	}
}

#AdmissionNetworkPolicy: netv1.#NetworkPolicy & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(#config.metadata.name)-admission"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: netv1.#NetworkPolicySpec & {
		podSelector: matchLabels: {
			"app.kubernetes.io/name":     "\(#config.metadata.name)-admission"
			"app.kubernetes.io/instance": #config.metadata.name
		}
		policyTypes: [netv1.#PolicyTypeIngress, netv1.#PolicyTypeEgress]
		ingress: [
			{
				// Only the main app pod may reach the admission helper
				from: [
					{
						podSelector: matchLabels: #config.selector.labels
					},
				]
				ports: [
					{
						protocol: corev1.#ProtocolTCP
						port:     8088
					},
				]
			},
		]
		egress: [
			{
				// Admission helper calls back to the bootstrap container's control ports
				to: [
					{
						podSelector: matchLabels: #config.selector.labels
					},
				]
				ports: [
					{
						protocol: corev1.#ProtocolTCP
						port:     3010
					},
					{
						protocol: corev1.#ProtocolTCP
						port:     3011
					},
				]
			},
		]
	}
}
