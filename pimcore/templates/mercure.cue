package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#MercureDeployment: appsv1.#Deployment & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-mercure"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		replicas: #config.mercure.replicas
		selector: matchLabels: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "mercure"
		}
		template: {
			metadata: {
				labels: {
					"app.kubernetes.io/name":      #config.metadata.name
					"app.kubernetes.io/instance":  #config.metadata.name
					"app.kubernetes.io/component": "mercure"
				}
				annotations: {
					"seccomp.security.alpha.kubernetes.io/pod": "runtime/default"
					"container.seccomp.security.alpha.kubernetes.io/pod": "runtime/default"
				}
			}
			spec: {
				automountServiceAccountToken: false
				securityContext: {
					seccompProfile: type: "RuntimeDefault"
				}
				containers: [
					{
						name:            "mercure"
						image:           "\(#config.mercure.image.registry):\(#config.mercure.image.tag)"
						imagePullPolicy: #config.mercure.image.pullPolicy
						securityContext: {
							allowPrivilegeEscalation: false
						}
						ports: [{containerPort: 80, name: "http"}]
						env: [
							{name: "SERVER_NAME", value: ":80"},
							{name: "MERCURE_PUBLISHER_JWT_KEY", value: #config.mercure.publisherJwtKey},
							{name: "MERCURE_SUBSCRIBER_JWT_KEY", value: #config.mercure.subscriberJwtKey},
							{name: "MERCURE_EXTRA_DIRECTIVES", value: #config.mercure.extraDirectives},
						]
						if #config.mercure.resources != _|_ {
							resources: #config.mercure.resources
						}
					},
				]
			}
		}
	}
}

#MercureService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-mercure"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		type: "ClusterIP"
		ports: [{port: 80, targetPort: 80, name: "http"}]
		selector: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "mercure"
		}
	}
}

#MercureServiceAlias: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "mercure"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels
	}
	spec: {
		type: "ClusterIP"
		ports: [{port: 80, targetPort: 80, name: "http"}]
		selector: {
			"app.kubernetes.io/name":      #config.metadata.name
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "mercure"
		}
	}
}
