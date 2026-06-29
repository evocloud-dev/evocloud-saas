package templates

import (
	"strings"

	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#ElasticsearchStatefulSet: appsv1.#StatefulSet & {
	#config: #Config
	_heapSize: string
	if #config.elasticsearch != _|_ && #config.elasticsearch.master != _|_ && #config.elasticsearch.master.heapSize != _|_ {
		_heapSize: #config.elasticsearch.master.heapSize
	}
	if #config.elasticsearch == _|_ || #config.elasticsearch.master == _|_ || #config.elasticsearch.master.heapSize == _|_ {
		_heapSize: "256m"
	}
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "\(#config.metadata.name)-elasticsearch-master"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "elasticsearch"
		}
	}
	spec: {
		serviceName: "\(#config.metadata.name)-elasticsearch-master-hl"
		replicas:    1
		selector: matchLabels: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "elasticsearch"
		}
		template: {
			metadata: labels: {
				"app.kubernetes.io/instance":  #config.metadata.name
				"app.kubernetes.io/component": "elasticsearch"
			}
			spec: {
				automountServiceAccountToken: false
				serviceAccountName:           #config._serviceAccountName
				securityContext: {
					fsGroup:             1001
					runAsUser:           1001
					runAsGroup:          1001
					runAsNonRoot:        true
				}
				initContainers: [{
					name:            "sysctl"
					image:           "docker.io/bitnamilegacy/os-shell:12-debian-12-r43"
					imagePullPolicy: "IfNotPresent"
					command: ["/bin/bash", "-ec", "CURRENT=`sysctl -n vm.max_map_count`; DESIRED=\"262144\"; if [ \"$DESIRED\" -gt \"$CURRENT\" ]; then sysctl -w vm.max_map_count=262144; fi; CURRENT=`sysctl -n fs.file-max`; DESIRED=\"65536\"; if [ \"$DESIRED\" -gt \"$CURRENT\" ]; then sysctl -w fs.file-max=65536; fi;\n"]
					securityContext: {
						privileged:   true
						runAsUser:    0
						runAsNonRoot: false
					}
				}, {
					name:            "copy-default-plugins"
					image:           "docker.io/bitnamilegacy/elasticsearch:8.18.0-debian-12-r2"
					imagePullPolicy: "IfNotPresent"
					securityContext: {
						allowPrivilegeEscalation: false
						runAsNonRoot:            true
						capabilities: drop: ["ALL"]
						if !strings.Contains(#config.elasticsearch.image.repository, "opensearch") {
							runAsUser:              1001
							runAsGroup:             1001
							readOnlyRootFilesystem: true
						}
						if strings.Contains(#config.elasticsearch.image.repository, "opensearch") {
							runAsUser:              1000
							runAsGroup:             1000
							readOnlyRootFilesystem: false
						}
					}
					command: ["/bin/bash"]
					args: ["-ec", ". /opt/bitnami/scripts/libfs.sh\n. /opt/bitnami/scripts/elasticsearch-env.sh\nif ! is_dir_empty \"$DB_DEFAULT_PLUGINS_DIR\"; then\n    cp -nr \"$DB_DEFAULT_PLUGINS_DIR\"/* /plugins\nfi\n"]
					volumeMounts: [{
						name:      "empty-dir"
						mountPath: "/tmp"
						subPath:   "tmp-dir"
					}, {
						name:      "plugins"
						mountPath: "/plugins"
					}]
				}]
				containers: [{
					name:            "elasticsearch"
					image:           #config._elasticsearchImageRef
					imagePullPolicy: #config.elasticsearch.image.pullPolicy
					securityContext: {
						allowPrivilegeEscalation: false
						runAsNonRoot:            true
						capabilities: drop: ["ALL"]
						if !strings.Contains(#config.elasticsearch.image.repository, "opensearch") {
							runAsUser:              1001
							runAsGroup:             1001
							readOnlyRootFilesystem: true
						}
						if strings.Contains(#config.elasticsearch.image.repository, "opensearch") {
							runAsUser:              1000
							runAsGroup:             1000
							readOnlyRootFilesystem: false
						}
					}
					env: [
						if strings.Contains(#config.elasticsearch.image.repository, "opensearch") {
							{
								name:  "DISABLE_SECURITY_PLUGIN"
								value: "true"
							}
						},
						if strings.Contains(#config.elasticsearch.image.repository, "opensearch") {
							{
								name:  "discovery.type"
								value: "single-node"
							}
						},
						if strings.Contains(#config.elasticsearch.image.repository, "opensearch") {
							{
								name:  "compatibility.override_main_response_version"
								value: "true"
							}
						},
						if strings.Contains(#config.elasticsearch.image.repository, "opensearch") {
							{
								name:  "OPENSEARCH_JAVA_OPTS"
								value: "-Xms\(_heapSize) -Xmx\(_heapSize) -Dcompatibility.override_main_response_version=true"
							}
						},
						{
							name:  "BITNAMI_DEBUG"
							value: "false"
						}, {
						name: "MY_POD_NAME"
						valueFrom: fieldRef: fieldPath: "metadata.name"
					}, {
						name:  "ELASTICSEARCH_IS_DEDICATED_NODE"
						value: "no"
					}, {
						name:  "ELASTICSEARCH_NODE_ROLES"
						value: "master"
					}, {
						name:  "ELASTICSEARCH_TRANSPORT_PORT_NUMBER"
						value: "9300"
					}, {
						name:  "ELASTICSEARCH_HTTP_PORT_NUMBER"
						value: "9200"
					}, {
						name:  "ELASTICSEARCH_CLUSTER_NAME"
						value: "zammad"
					}, {
						name:  "ELASTICSEARCH_HEAP_SIZE"
						value: _heapSize
					}]
					ports: [{
						name:          "rest-api"
						containerPort: 9200
					}, {
						name:          "transport"
						containerPort: 9300
					}]
					if #config.elasticsearch.master.resources != _|_ {
						resources: #config.elasticsearch.master.resources
					}
					livenessProbe: {
						tcpSocket: port: "rest-api"
						initialDelaySeconds: 180
						periodSeconds:       10
						timeoutSeconds:      5
					}
					readinessProbe: {
						if !strings.Contains(#config.elasticsearch.image.repository, "opensearch") {
							exec: command: ["/opt/bitnami/scripts/elasticsearch/healthcheck.sh"]
						}
						if strings.Contains(#config.elasticsearch.image.repository, "opensearch") {
							tcpSocket: port: "rest-api"
						}
						initialDelaySeconds: 90
						periodSeconds:       10
						timeoutSeconds:      5
					}
					volumeMounts: [{
						name:      "empty-dir"
						mountPath: "/tmp"
						subPath:   "tmp-dir"
					}, {
						name:      "empty-dir"
						mountPath: "/opt/bitnami/elasticsearch/config"
						subPath:   "app-conf-dir"
					}, {
						name:      "empty-dir"
						mountPath: "/opt/bitnami/elasticsearch/tmp"
						subPath:   "app-tmp-dir"
					}, {
						name:      "empty-dir"
						mountPath: "/opt/bitnami/elasticsearch/logs"
						subPath:   "app-logs-dir"
					}, {
						name:      "plugins"
						mountPath: "/opt/bitnami/elasticsearch/plugins"
					}, {
						name:      "empty-dir"
						mountPath: "/bitnami/elasticsearch"
						subPath:   "app-volume-dir"
					}, {
						name:      "data"
						mountPath: "/bitnami/elasticsearch/data"
					}]
				}]
				volumes: [{
					name: "empty-dir"
					emptyDir: {}
				}, {
					name: "plugins"
					emptyDir: {}
				}]
			}
		}
		volumeClaimTemplates: [{
			apiVersion: "v1"
			kind:       "PersistentVolumeClaim"
			metadata: name: "data"
			spec: {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: "8Gi"
			}
		}]
	}
}

#ElasticsearchService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-elasticsearch"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "elasticsearch"
		}
	}
	spec: {
		type: "ClusterIP"
		ports: [{
			name:       "http"
			port:       9200
			targetPort: "rest-api"
			protocol:   "TCP"
		}, {
			name:       "transport"
			port:       9300
			targetPort: "transport"
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "elasticsearch"
		}
	}
}

#ElasticsearchHeadlessService: corev1.#Service & {
	#config: #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(#config.metadata.name)-elasticsearch-master-hl"
		namespace: #config.metadata.namespace
		labels:    #config.metadata.labels & {
			"app.kubernetes.io/component": "elasticsearch"
		}
	}
	spec: {
		clusterIP: "None"
		ports: [{
			name:       "http"
			port:       9200
			targetPort: "rest-api"
			protocol:   "TCP"
		}, {
			name:       "transport"
			port:       9300
			targetPort: "transport"
			protocol:   "TCP"
		}]
		selector: {
			"app.kubernetes.io/instance":  #config.metadata.name
			"app.kubernetes.io/component": "elasticsearch"
		}
	}
}
