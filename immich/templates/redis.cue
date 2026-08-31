package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#ValkeyStatefulSetBuilder: {
	_config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(_config.fullname)-valkey"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels & {
			"app.kubernetes.io/component": "cache"
		}
	}
	spec: appsv1.#StatefulSetSpec & {
		serviceName: "\(_config.fullname)-valkey-headless"
		replicas:    1
		selector: matchLabels: _config.metadata.labels & {
			"app.kubernetes.io/component": "cache"
		}
		template: corev1.#PodTemplateSpec & {
			metadata: labels: _config.metadata.labels & _config.commonLabels & {
				"app.kubernetes.io/component": "cache"
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _config.serviceAccountName
				automountServiceAccountToken: _config.serviceAccount.automountServiceAccountToken
				containers: [{
					name:            _config.valkeyName
					image:           "\(_config.valkey.image.repository):\(_config.valkey.image.tag)"
					imagePullPolicy: _config.valkey.image.pullPolicy
					ports: [{
						name:          "redis"
						containerPort: _config.valkey.service.ports.redis
					}]
					if _config.valkey.standalone.resources != _|_ {
						resources: _config.valkey.standalone.resources
					}
					securityContext: _config.valkey.securityContext
					volumeMounts: [{
						name:      "data"
						mountPath: "/data"
					}]
				}]
			}
		}
		if _config.valkey.standalone.persistence.enabled {
			volumeClaimTemplates: [{
				metadata: name: "data"
				spec: {
					accessModes: ["ReadWriteOnce"]
					resources: requests: storage: _config.valkey.standalone.persistence.size
				}
			}]
		}
	}
}

#ValkeyClientServiceBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(_config.fullname)-valkey-client"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels & {
			"app.kubernetes.io/component": "cache"
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "redis"
			port:       _config.valkey.service.ports.redis
			targetPort: "redis"
		}]
		selector: _config.metadata.labels & {
			"app.kubernetes.io/component": "cache"
		}
	}
}

#ValkeyHeadlessServiceBuilder: {
	_config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(_config.fullname)-valkey-headless"
		namespace: _config.namespace
		labels:    _config.metadata.labels & _config.commonLabels & {
			"app.kubernetes.io/component": "cache"
		}
	}
	spec: {
		clusterIP: "None"
		type:      "ClusterIP"
		ports: [{
			name:       "redis"
			port:       _config.valkey.service.ports.redis
			targetPort: "redis"
		}]
		selector: _config.metadata.labels & {
			"app.kubernetes.io/component": "cache"
		}
	}
}
