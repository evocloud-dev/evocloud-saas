package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Memcached: {
	#config: #Config

	if #config.memcached.bundled {
		objects: {
			if #config.memcached.auth.existingSecret == "" {
				secret: corev1.#Secret & {
					apiVersion: "v1"
					kind:       "Secret"
					metadata: {
						if #config.memcached.auth.existingSecret != "" {
							name: #config.memcached.auth.existingSecret
						}
						if #config.memcached.auth.existingSecret == "" {
							name: "\(#config.metadata.name)-memcached"
						}
						namespace: #config.metadata.namespace
						labels:    #config.metadata.labels & #config.memcached.commonLabels
						if #config.metadata.annotations != _|_ {
							annotations: #config.metadata.annotations
						}
					}
					type: "Opaque"
					stringData: {
						"memcached-password": ""
					}
				}
			}

			svc: corev1.#Service & {
				apiVersion: "v1"
				kind:       "Service"
				metadata: {
					name:      "\(#config.metadata.name)-memcached"
					namespace: #config.metadata.namespace
					labels:    #config.metadata.labels & #config.memcached.commonLabels
					if #config.metadata.annotations != _|_ {
						annotations: #config.metadata.annotations
					}
				}
				spec: corev1.#ServiceSpec & {
					type: "ClusterIP"
					ports: [{
						name:       "tcp-memcached"
						port:       11211
						targetPort: "tcp-memcached"
					}]
					selector: {
						"app.kubernetes.io/name":     "memcached"
						"app.kubernetes.io/instance": #config.metadata.name
					}
				}
			}

			sts: appsv1.#StatefulSet & {
				apiVersion: "apps/v1"
				kind:       "StatefulSet"
				metadata: {
					name:      "\(#config.metadata.name)-memcached"
					namespace: #config.metadata.namespace
					labels:    #config.metadata.labels & #config.memcached.commonLabels
					if #config.metadata.annotations != _|_ {
						annotations: #config.metadata.annotations
					}
				}
				spec: appsv1.#StatefulSetSpec & {
					replicas: 1
					serviceName: "\( #config.metadata.name )-memcached"
					selector: matchLabels: {
						"app.kubernetes.io/name":     "memcached"
						"app.kubernetes.io/instance": #config.metadata.name
					}
					template: {
						metadata: labels: {
							"app.kubernetes.io/name":     "memcached"
							"app.kubernetes.io/instance": #config.metadata.name
						}
						spec: corev1.#PodSpec & {
							if #config.memcached.global.containerSecurityContext.enabled {
								securityContext: fsGroup: 1001
							}
							containers: [{
								name:            "memcached"
								image:           #config.memcached.image.reference
								imagePullPolicy: #config.memcached.image.imagePullPolicy
								command: [
									"memcached",
									"-m", "64",
									"-v",
								]
								ports: [{
									name:          "tcp-memcached"
									containerPort: 11211
								}]
								if #config.memcached.global.containerSecurityContext.enabled {
									securityContext: {
										allowPrivilegeEscalation: #config.memcached.global.containerSecurityContext.allowPrivilegeEscalation
										capabilities:             #config.memcached.global.containerSecurityContext.capabilities
										seccompProfile:           #config.memcached.global.containerSecurityContext.seccompProfile
										readOnlyRootFilesystem:   (!#config.develop && #config.memcached.global.containerSecurityContext.readOnlyRootFilesystem)
										runAsNonRoot:             #config.memcached.global.containerSecurityContext.runAsNonRoot
									}
								}
							}]
						}
					}
				}
			}
		}
	}
}
