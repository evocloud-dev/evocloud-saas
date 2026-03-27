package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#VarnishService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "varnish"
	}
	spec: corev1.#ServiceSpec & {
		type: #config.varnish.service.type
		ports: [
			{
				name:     "http"
				port:     #config.varnish.service.port
				protocol: "TCP"
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "varnish"
		}
	}
}

#VarnishAdminService: corev1.#Service & {
	#config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: timoniv1.#MetaComponent & {
		#Meta:      #config.metadata
		#Component: "varnish-admin"
	}
	spec: corev1.#ServiceSpec & {
		type:      "ClusterIP"
		clusterIP: "None"
		ports: [
			{
				name:     "tcp-admin"
				port:     #config.varnish.admin.port
				protocol: "TCP"
			},
		]
		selector: #config.selector.labels & {
			"app.kubernetes.io/component": "varnish"
		}
	}
}
