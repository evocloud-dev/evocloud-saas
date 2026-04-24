package templates

import (
	corev1 "k8s.io/api/core/v1"
	appsv1 "k8s.io/api/apps/v1"
)

#PostgresService: corev1.#Service & {
	#config: #Config

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-pgdb"
		labels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-pgdb"
		}
	}
	spec: {
		type: "ClusterIP"
		if !#config.services.postgres.assign_cluster_ip {
			clusterIP: "None"
		}
		ports: [{
			name:       "pgdb-5432"
			port:       5432
			protocol:   "TCP"
			targetPort: 5432
		}]
		selector: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-pgdb"
		}
	}
}

#PostgresStatefulSet: appsv1.#StatefulSet & {
	#config: #Config

	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		namespace: #config.#namespace
		name:      "\(#config.metadata.name)-pgdb-wl"
	}
	spec: {
		serviceName: "\(#config.metadata.name)-pgdb"
		// Replicas omitted to match literal Helm chart defaults
		selector: matchLabels: {
			"app.name": "\(#config.#namespace)-\(#config.metadata.name)-pgdb"
		}
		template: {
			metadata: {
				labels: {
					"app.name": "\(#config.#namespace)-\(#config.metadata.name)-pgdb"
				}
				annotations: {
					timestamp: "placeholder"
				}
			}
			spec: {
				// {{- include "plane.podScheduling" .Values.services.postgres }}
				nodeSelector: #config.services.postgres.nodeSelector
				tolerations:  #config.services.postgres.tolerations
				affinity:     #config.services.postgres.affinity

				containers: [{
					name:            "\(#config.metadata.name)-pgdb"
					image:           #config.services.postgres.image
					imagePullPolicy: "IfNotPresent"
					stdin:           true
					tty:             true
					resources:       #config.services.postgres.resources
					env: [{
						name:  "PGDATA"
						value: "/var/lib/postgresql/data/plane"
					}]
					envFrom: [{
						secretRef: {
							name:     "\(#config.metadata.name)-pgdb-secrets"
							optional: false
						}
					}]
					if #config.extraEnv != [] {
						env: [
							for e in #config.extraEnv {e},
						]
					}
					volumeMounts: [{
						name:      "pvc-\(#config.metadata.name)-pgdb-vol"
						mountPath: "/var/lib/postgresql/data"
					}, {
						name:      "init-script"
						mountPath: "/docker-entrypoint-initdb.d"
					}]
				}]
				volumes: [{
					name: "init-script"
					configMap: {
						name:         "\(#config.metadata.name)-pgdb-vars"
						defaultMode: 0o755
					}
				}]
			}
		}
		volumeClaimTemplates: [{
			metadata: name: "pvc-\(#config.metadata.name)-pgdb-vol"
			spec: {
				accessModes: ["ReadWriteOnce"]
				storageClassName: #config.env.storageClass
				resources: requests: storage: #config.services.postgres.volumeSize
			}
		}]
	}
}
