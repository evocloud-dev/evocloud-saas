package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Elasticsearch: {
	#config: #Config

	#name: "\(#config.metadata.name)-elasticsearch"

	serviceHL: corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			namespace: #config.#namespace
			name:      "\(#name)-master-hl"
			labels:    #config.metadata.labels
		}
		spec: corev1.#ServiceSpec & {
			clusterIP: "None"
			publishNotReadyAddresses: true
			ports: [{
				name:       "http"
				port:       9200
				targetPort: "http"
			}, {
				name:       "transport"
				port:       9300
				targetPort: "transport"
			}]
			selector: "app.kubernetes.io/name": #name
		}
	}

	service: corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			namespace: #config.#namespace
			name:      #name
			labels:    #config.metadata.labels
		}
		spec: corev1.#ServiceSpec & {
			type: "ClusterIP"
			ports: [{
				name:       "http"
				port:       9200
				targetPort: "http"
			}, {
				name:       "transport"
				port:       9300
				targetPort: "transport"
			}]
			selector: "app.kubernetes.io/name": #name
		}
	}

	statefulSet: appsv1.#StatefulSet & {
		apiVersion: "apps/v1"
		kind:       "StatefulSet"
		metadata: {
			namespace: #config.#namespace
			name:      "\(#name)-master"
			labels:    #config.metadata.labels
		}
		spec: appsv1.#StatefulSetSpec & {
			replicas: 1
			selector: matchLabels: "app.kubernetes.io/name": #name
			serviceName: "\(#name)-master-hl"
			template: {
				metadata: labels: "app.kubernetes.io/name": #name
				spec: corev1.#PodSpec & {
					automountServiceAccountToken: #config.serviceAccount.automountServiceAccountToken
					serviceAccountName: #config.metadata.name
					securityContext: #config.elasticsearch.podSecurityContext

					if #config.elasticsearch.volumePermissions.enabled {
						initContainers: [{
							name:            "volume-permissions"
							image:           "\(#config.elasticsearch.image.repository):\(#config.elasticsearch.image.tag)"
							imagePullPolicy: "IfNotPresent"
							command: ["chown", "-R", "1000:1000", "/usr/share/opensearch/data"]
							securityContext: {
								runAsUser:                0
								runAsGroup:               0
								runAsNonRoot:             false
								allowPrivilegeEscalation: false
								readOnlyRootFilesystem:   true
								capabilities: {
									drop: ["ALL"]
									add: ["CHOWN", "DAC_OVERRIDE", "FOWNER"]
								}
							}
							volumeMounts: [{
								name:      "data"
								mountPath: "/usr/share/opensearch/data"
							}]
						}]
					}

					containers: [{
						name:            "opensearch"
						securityContext: #config.elasticsearch.securityContext
						resources:       #config.elasticsearch.resources
						image:           "\(#config.elasticsearch.image.repository):\(#config.elasticsearch.image.tag)"
						imagePullPolicy: #config.elasticsearch.image.pullPolicy
						env: [
							{
								name:  "OPENSEARCH_CLUSTER_NAME"
								value: "mastodon-opensearch"
							},
							{
								name:  "discovery.type"
								value: "single-node"
							},
							{
								name:  "OPENSEARCH_HEAP_SIZE"
								value: "512m"
							},
							{
								// Security plugin is disabled to allow plain HTTP communication.
								// In production, ensure the cluster is not exposed to the public internet.
								name:  "DISABLE_SECURITY_PLUGIN"
								value: "true"
							},
						]
						ports: [{
							name:          "http"
							containerPort: 9200
						}, {
							name:          "transport"
							containerPort: 9300
						}]
						livenessProbe: {
							tcpSocket: port: "http"
							initialDelaySeconds: 90
							periodSeconds:        10
							timeoutSeconds:       5
							successThreshold:     1
							failureThreshold:     6
						}
						readinessProbe: {
							tcpSocket: port: "http"
							initialDelaySeconds: 5
							periodSeconds:        10
							timeoutSeconds:       5
							successThreshold:     1
							failureThreshold:     6
						}
						volumeMounts: [
							{
								name:      "data"
								mountPath: "/usr/share/opensearch/data"
							},
							if #config.elasticsearch.securityContext.readOnlyRootFilesystem != _|_ && #config.elasticsearch.securityContext.readOnlyRootFilesystem == true {
								{
									name:      "opensearch-logs"
									mountPath: "/usr/share/opensearch/logs"
								}
							},
							if #config.elasticsearch.securityContext.readOnlyRootFilesystem != _|_ && #config.elasticsearch.securityContext.readOnlyRootFilesystem == true {
								{
									name:      "tmp"
									mountPath: "/tmp"
								}
							},
						]
					}]
					volumes: [
						if #config.elasticsearch.securityContext.readOnlyRootFilesystem != _|_ && #config.elasticsearch.securityContext.readOnlyRootFilesystem == true {
							{
								name: "opensearch-logs"
								emptyDir: {}
							}
						},
						if #config.elasticsearch.securityContext.readOnlyRootFilesystem != _|_ && #config.elasticsearch.securityContext.readOnlyRootFilesystem == true {
							{
								name: "tmp"
								emptyDir: {}
							}
						},
					]
				}
			}
			volumeClaimTemplates: [{
				metadata: name: "data"
				spec: corev1.#PersistentVolumeClaimSpec & {
					accessModes: ["ReadWriteOnce"]
					resources: requests: storage: "8Gi"
				}
			}]
		}
	}
}
