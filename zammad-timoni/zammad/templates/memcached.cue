package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#MemcachedServiceAccount: corev1.#ServiceAccount & {
	#config: #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      "\(#config.metadata.name)-memcached"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "memcached"
		}
	}
	automountServiceAccountToken: false
}

#MemcachedDeployment: appsv1.#Deployment & {
	#config: #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "\(#config.metadata.name)-memcached"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "memcached"
		}
	}
	spec: {
		replicas: 1
		selector: matchLabels: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "memcached"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/component": "memcached"
			}
			spec: {
				automountServiceAccountToken: false
				serviceAccountName:           "\(#config.metadata.name)-memcached"
				securityContext: {
					fsGroup: 11211
				}
				containers: [{
					name:            "memcached"
					image:           "docker.io/memcached:1.6.41@sha256:f7a252e7ba3fbbe9672c483354c5081d02b780122c3bb97bd311d5662b54d0ad"
					imagePullPolicy: "Always"
					securityContext: {
						allowPrivilegeEscalation: false
						runAsNonRoot:             true
						runAsUser:                11211
					}
					args: ["-m", "64", "-c", "1024"]
					ports: [{
						name:          "memcached"
						containerPort: 11211
					}]
					if #config.memcached.resources != _|_ {
						resources: #config.memcached.resources
					}
					livenessProbe: {
						tcpSocket: port: "memcached"
						initialDelaySeconds: 30
						periodSeconds:       10
					}
					readinessProbe: {
						tcpSocket: port: "memcached"
						initialDelaySeconds: 5
						periodSeconds:       10
					}
				}]
			}
		}
	}
}

#MemcachedService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-memcached"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "memcached"
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "memcached"
			port:       11211
			targetPort: "memcached"
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "memcached"
		}
	}
}
