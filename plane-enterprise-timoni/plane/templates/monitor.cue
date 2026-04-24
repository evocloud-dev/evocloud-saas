package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#MonitorService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-monitor"
	}
	spec: {
		type: "ClusterIP"
		if !#config.services.monitor.assign_cluster_ip {
		clusterIP: "None"
		}
		ports: [{
			name:       "monitor-8080"
			port:       8080
			protocol:   "TCP"
			targetPort: 8080
		}]
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-monitor"
		}
	}
}

#MonitorDeployment: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-monitor-wl"
	}
	spec: {
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-monitor"
		}
		serviceName: "\(#config.metadata.name)-monitor"
		template: {
			metadata: {
				labels: {
				"app.name": "\(#config.#namespace)-\(#config.metadata.name)-monitor"
			}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				containers: [{
					name:            "\(#config.metadata.name)-monitor"
					image:           "\(#config.services.monitor.image):\(#config.planeVersion)"
					imagePullPolicy: "Always"
					stdin:           true
					tty:             true
					if #config.airgapped.enabled {
						command: ["prime-monitor"]
						args: ["start-airgapped"]
					}
					resources: #config.services.monitor.resources
					envFrom: [{configMapRef: name: "\(#config.metadata.name)-monitor-vars"}]
					volumeMounts: [{
						mountPath: "/app"
						name:      "pvc-\(#config.metadata.name)-monitor-vol"
					}]
				}]
				serviceAccount:     "\(#config.metadata.name)-srv-account"
				serviceAccountName: "\(#config.metadata.name)-srv-account"
			}
		}
		volumeClaimTemplates: [{
			metadata: name: "pvc-\(#config.metadata.name)-monitor-vol"
			spec: {
				accessModes: ["ReadWriteOnce"]
				resources: requests: storage: "100Mi"
				storageClassName: #config.env.storageClass
				volumeMode:       "Filesystem"
			}
		}]
	}
}
