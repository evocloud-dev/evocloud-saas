package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#OpenSearchStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name: #config.metadata.name + "-opensearch"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels
	}
	spec: {
		serviceName: "opensearch"
		replicas: 1
		selector: {matchLabels: {app: #config.metadata.name + "-opensearch"}}
		template: {
			metadata: {labels: {app: #config.metadata.name + "-opensearch"}}
			spec: {
				automountServiceAccountToken: false
				serviceAccountName:           #config.metadata.name
				securityContext: {
					runAsUser:    1000
					runAsGroup:   1000
					fsGroup:      1000
					runAsNonRoot: true
					seccompProfile: type: "RuntimeDefault"
				}
				containers: [{
					name: #config.metadata.name + "-opensearch"
					image: #config.opensearch.image
					securityContext: {
						allowPrivilegeEscalation: false
						runAsNonRoot:             true
					}
					resources: {
						requests: {
							cpu:    "100m"
							memory: "512Mi"
						}
						limits: {
							cpu:    "1000m"
							memory: "2Gi"
						}
					}
					ports: [{containerPort: 9200, name: "http"}]
					env: [
						{name: "discovery.type", value: "single-node"},
						{name: "OPENSEARCH_INITIAL_ADMIN_PASSWORD", value: #config.opensearch.initialAdminPassword},
						if #config.opensearch.disableSecurityPlugin {
							{name: "DISABLE_SECURITY_PLUGIN", value: "true"}
						},
						{name: "OPENSEARCH_URL", value: "http://\(#config.metadata.name)-opensearch:9200"},
						{name: "OPENSEARCH_SCHEME", value: "http"},
						{name: "OPENSEARCH_SSL_VERIFY", value: "false"},
						{name: "OPENSEARCH_REJECT_UNAUTHORIZED", value: "0"},
					]
					volumeMounts: [{
						name:      "opensearch-data"
						mountPath: "/usr/share/opensearch/data"
					}]
				}]
			}
		}
		volumeClaimTemplates: [
			corev1.#PersistentVolumeClaim & {
				metadata: name: "opensearch-data"
				spec: corev1.#PersistentVolumeClaimSpec & {
					accessModes: ["ReadWriteOnce"]
					resources: {
						requests: storage: "10Gi"
					}
				}
			},
		]
	}
}

#OpenSearchService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name: #config.metadata.name + "-opensearch"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels
	}
	spec: {
		type: "ClusterIP"
		ports: [{port: 9200, targetPort: "http", name: "http"}]
		selector: {app: #config.metadata.name + "-opensearch"}
	}
}

#OpenSearchServiceAlias: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name: "opensearch"
		namespace: #config.metadata.namespace
		labels: #config.metadata.labels
	}
	spec: {
		type: "ClusterIP"
		ports: [{port: 9200, targetPort: "http", name: "http"}]
		selector: {app: #config.metadata.name + "-opensearch"}
	}
}
