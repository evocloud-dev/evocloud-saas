// SPDX-License-Identifier: Apache-2.0

package templates

import (
	"struct"

	networkingv1 "k8s.io/api/networking/v1"
)

#Ingress: networkingv1.#Ingress & {
	#config: #Config

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata: {
		name:      #config.fullname
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
		if struct.MinFields(#config.ingress.annotations, 1) {
			annotations: #config.ingress.annotations
		}
	}
	spec: {
		if #config.ingress.ingressClassName != "" {
			ingressClassName: #config.ingress.ingressClassName
		}
		if len(#config.ingress.tls) > 0 {
			tls: #config.ingress.tls
		}
		rules: [
			for hostValue in #config.ingress.hosts {
				let normalizedHost = hostValue & {
					paths: *[] | [...{
						path:     string
						pathType: string
					}]
				}
				{
					if normalizedHost.host != _|_ && normalizedHost.host != "" {
						host: normalizedHost.host
					}
					http: paths: [
						if len(normalizedHost.paths) == 0 {
							{
								path:     "/"
								pathType: "Prefix"
								backend: service: {
									name: #config.fullname
									port: name: "http"
								}
							}
						},
						for pathValue in normalizedHost.paths {
							{
								path:     pathValue.path
								pathType: pathValue.pathType
								backend: service: {
									name: #config.fullname
									port: name: "http"
								}
							}
						},
					]
				}
			},
		]
	}
}
