package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#OpensearchService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-opensearch"
		labels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-opensearch"
		}
	}
	spec: {
		type: "ClusterIP"
		if !#config.services.opensearch.assign_cluster_ip {
			clusterIP: "None"
		}
		ports: [{
			name:       "opensearch-9200"
			port:       9200
			protocol:   "TCP"
			targetPort: 9200
		}]
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-opensearch"
		}
	}
}

#OpensearchStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-opensearch-wl"
	}
	spec: {
		serviceName: "\(#config.metadata.name)-opensearch"
		// Replicas omitted to match literal Helm chart defaults
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-opensearch"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-opensearch"
				}
			}
			spec: {
				// {{- include "plane.podScheduling" .Values.services.opensearch }}
				nodeSelector: #config.services.opensearch.nodeSelector
				tolerations:  #config.services.opensearch.tolerations
				affinity:     #config.services.opensearch.affinity

				securityContext: {
					fsGroup: 1000
				}
				containers: [{
					name:            "\(#config.metadata.name)-opensearch"
					image:           #config.services.opensearch.image
					imagePullPolicy: "IfNotPresent"
					stdin:           true
					tty:             true
					resources:       #config.services.opensearch.resources
					securityContext: {
						runAsUser:    1000
						runAsNonRoot: true
					}
					envFrom: [{
						secretRef: {
							name:     "\(#config.metadata.name)-opensearch-secrets"
							optional: false
						}
					}]
					env: [
						{name: "discovery.type", value: "single-node"},
						{name: "bootstrap.memory_lock", value: "false"},
						{name: "OPENSEARCH_JAVA_OPTS", value: "-Xms256m -Xmx256m"},
						{
							name: "OPENSEARCH_USER"
							valueFrom: secretKeyRef: {
								name: "\(#config.metadata.name)-opensearch-secrets"
								key:  "OPENSEARCH_USERNAME"
							}
						},
						for e in #config.extraEnv {e},
					]
					command: ["/bin/bash", "/usr/share/opensearch/bin/opensearch-docker-entrypoint.sh"]
					volumeMounts: [{
						name:      "pvc-\(#config.metadata.name)-opensearch-vol"
						mountPath: "/usr/share/opensearch/data"
					}, {
						name:      "init-script"
						mountPath: "/usr/share/opensearch/bin/opensearch-docker-entrypoint.sh"
						subPath:   "create-user.sh"
					}]
				}]
				volumes: [{
					name: "init-script"
					configMap: {
						name:         "\(#config.metadata.name)-opensearch-init"
						defaultMode: 0o755
					}
				}]
			}
		}
		volumeClaimTemplates: [{
			metadata: name: "pvc-\(#config.metadata.name)-opensearch-vol"
			spec: {
				accessModes: ["ReadWriteOnce"]
				storageClassName: #config.env.storageClass
				resources: requests: storage: #config.services.opensearch.volumeSize
			}
		}]
	}
}
