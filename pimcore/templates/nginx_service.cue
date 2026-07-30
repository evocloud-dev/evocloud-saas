package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceNginx: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-nginx"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		annotations: {
			if #config.metadata.annotations != _|_ {
				#config.metadata.annotations
			}
			for k, v in #config.nginx.annotations {
				"\(k)": v
			}
			if #config.nginx.backendConfig.enabled {
				"cloud.google.com/backend-config": "{\"default\":\"\(#config.metadata.name)-nginx\"}"
			}
		}
	}
	spec: {
		type: #config.nginx.service.type
		ports: [
			{
				port:       #config.nginx.service.port
				targetPort: 80
			},
		]
		selector: {
			"app.kubernetes.io/name":     #config.metadata.name
			"app.kubernetes.io/instance": "\(#config.metadata.name)-nginx"
		}
	}
}
