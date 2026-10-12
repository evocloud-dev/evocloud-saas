package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ProxyService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#proxyServiceName
		namespace: #config.metadata.namespace
		labels:    #config.#componentLabels & {#component: "proxy"}
		if #config.service.annotations != _|_ {
			annotations: #config.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: #config.service.type
		if #config.service.ipFamilyPolicy != null && #config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if len(#config.service.ipFamilies) > 0 {
			ipFamilies: #config.service.ipFamilies
		}
		ports: [
			{
				name:       "http"
				port:       #config.service.port
				targetPort: "http"
				protocol:   "TCP"
			},
		]
		selector: #config.#selectorLabels & {#component: "proxy"}
	}
}

#ProxyApiService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#proxyApiFullname
		namespace: #config.metadata.namespace
		labels:    #config.#componentLabels & {#component: "proxy-api"}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: corev1.#ServiceTypeClusterIP
		if #config.service.ipFamilyPolicy != null && #config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if len(#config.service.ipFamilies) > 0 {
			ipFamilies: #config.service.ipFamilies
		}
		ports: [
			{
				name:       "proxy-api"
				port:       #config.service.proxyApiPort
				targetPort: "api"
				protocol:   "TCP"
			},
		]
		selector: #config.#selectorLabels & {#component: "proxy"}
	}
}

#HubService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      #config.#hubFullname
		namespace: #config.metadata.namespace
		labels:    #config.#componentLabels & {#component: "hub"}
		if #config.metadata.annotations != _|_ {
			annotations: #config.metadata.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: corev1.#ServiceTypeClusterIP
		if #config.service.ipFamilyPolicy != null && #config.service.ipFamilyPolicy != "" {
			ipFamilyPolicy: #config.service.ipFamilyPolicy
		}
		if len(#config.service.ipFamilies) > 0 {
			ipFamilies: #config.service.ipFamilies
		}
		ports: [
			{
				name:       "hub"
				port:       8081
				targetPort: "hub"
				protocol:   "TCP"
			},
		]
		selector: #config.#selectorLabels & {#component: "hub"}
	}
}
